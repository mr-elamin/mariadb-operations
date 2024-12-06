#!/bin/bash

# Function to list all databases and prompt the user to select one
select_database() {
  echo "Available databases:"
  mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES;" | tail -n +2
  read -p "Enter the name of the database to backup: " dbname

  # Check if the selected database exists
  db_exists=$(mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES LIKE '${dbname}';" | grep "${dbname}")
  if [ -z "$db_exists" ]; then
    echo "Invalid database name selected."
    exit 1
  fi
}

# Check if the database name is provided
if [ -z "$1" ]; then
  select_database
else
  dbname=$1
fi

# Set variables
backup_dir="/backup"
backup_file="${backup_dir}/${dbname}_$(date +%Y%m%d%H%M%S).sql"

# Check if the database exists
db_exists=$(mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES LIKE '${dbname}';" | grep "${dbname}")

if [ -z "$db_exists" ]; then
  echo "Database ${dbname} does not exist."
  exit 1
fi

# Create the backup
mariadb-dump -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" ${dbname} > ${backup_file}

# Sleep for 2 seconds to allow the backup to finish
sleep 2

# Check if the backup file exists
if [ ! -f "${backup_file}" ]; then
  # Sleep for an additional 5 seconds if the backup file does not exist
  sleep 5
  if [ ! -f "${backup_file}" ]; then
    echo "Failed to create backup for database ${dbname}."
    exit 1
  fi
fi

# Set the correct permissions for the backup file
chown 1000:1000 ${backup_file}
chmod 644 ${backup_file}

echo "Backup for database ${dbname} created successfully at ${backup_file}."
