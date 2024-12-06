#!/bin/bash

# Set variables
backup_dir="/backup"

# Function to list backup files and prompt the user to select one
select_backup_file() {
  echo "Available backups:"
  ls ${backup_dir}
  read -p "Enter the name of the backup file to restore: " backup_file
}

# Check if the backup file name is provided
if [ -z "$1" ]; then
  select_backup_file
else
  backup_file=$1
fi

# Check if the backup file exists
if [ ! -f "${backup_dir}/${backup_file}" ]; then
  echo "Backup file ${backup_file} does not exist."
  exit 1
fi

# Extract the database name from the backup file name
dbname=$(echo ${backup_file} | cut -d'_' -f1)

# Check if the database exists
db_exists=$(mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES LIKE '${dbname}';" | grep "${dbname}")

# Create the database if it does not exist
if [ -z "$db_exists" ]; then
  mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE DATABASE \`${dbname}\`;"
  db_newly_created=true
else
  db_newly_created=false
fi

# Restore the database
mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" ${dbname} < ${backup_dir}/${backup_file}

# Sleep for 2 seconds to allow the restore to finish
sleep 2

# Check if the restore was successful
if ! mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "USE ${dbname};" > /dev/null 2>&1; then
  # Sleep for an additional 5 seconds if the restore was not successful
  sleep 5
  if ! mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "USE ${dbname};" > /dev/null 2>&1; then
    echo "Failed to restore database ${dbname} from backup file ${backup_file}."
    exit 1
  fi
fi

# Set variables for user creation
dbuser=$dbname
dbpass=$(pwgen -s 16 1 | tr -d '\n')
secret_name="${dbname}-db-secret"
mariadburl="mariadb://${dbuser}:${dbpass}@mariadb-primary.mariadb.svc.cluster.local:3306/${dbname}"

# Create the user and grant privileges if the database was newly created
if [ "$db_newly_created" = true ]; then
  mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" <<EOF
CREATE USER '${dbuser}'@'%' IDENTIFIED BY '${dbpass}';
GRANT ALL PRIVILEGES ON \`${dbname}\`.* TO '${dbuser}'@'%';
FLUSH PRIVILEGES;
EOF

  # Sleep for 2 seconds to allow the user creation and grant to finish
  sleep 2

  # Check if the user creation and grant were successful
  if [ $? -ne 0 ]; then
    echo "Failed to create user ${dbuser} or grant privileges."
    exit 1
  fi

  # Create the Kubernetes secret
  kubectl create secret generic $secret_name --namespace admin \
    --from-literal=database=$dbname \
    --from-literal=password=$dbpass \
    --from-literal=mariadburl=$mariadburl

  # Sleep for 2 seconds to allow the secret creation to finish
  sleep 2

  # Check if the secret creation was successful
  if [ $? -ne 0 ]; then
    echo "Failed to create Kubernetes secret ${secret_name}."
    exit 1
  fi
fi

echo "Database ${dbname} restored successfully from backup file ${backup_file}."
if [ "$db_newly_created" = true ]; then
  echo "User ${dbuser} created and granted privileges on database ${dbname}."
  echo "Kubernetes secret '${secret_name}' created successfully."
  echo "MariaDB URL: ${mariadburl}"
fi
