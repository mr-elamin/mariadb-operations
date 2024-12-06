#!/bin/bash

# Check if the database name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <database_name>"
  exit 1
fi

# Set variables
dbname=$1
secret_name="${dbname}-db-secret"

# Check if the database exists
db_exists=$(mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES LIKE '${dbname}';" | grep "${dbname}")

if [ -z "$db_exists" ]; then
  echo "Database ${dbname} does not exist."
  exit 1
fi

# Ask for confirmation
read -p "Are you sure you want to delete the database '${dbname}' and its associated user and secret? (yes/no): " confirmation

# Check confirmation
if [ "$confirmation" != "yes" ]; then
  echo "Database deletion cancelled."
  exit 0
fi

# Drop the database and user
mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" <<EOF
DROP DATABASE IF EXISTS \`${dbname}\`;
DROP USER IF EXISTS \`${dbname}\`@'%';
EOF

# Sleep for 2 seconds to allow the deletion to finish
sleep 2

# Check if the database and user were successfully dropped
if mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "USE \`${dbname}\`;" > /dev/null 2>&1; then
  # Sleep for an additional 5 seconds if the deletion was not successful
  sleep 5
  if mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "USE \`${dbname}\`;" > /dev/null 2>&1; then
    echo "Failed to delete database ${dbname} or user ${dbname}."
    exit 1
  fi
fi

# Delete the Kubernetes secret
kubectl delete secret $secret_name --namespace admin

# Sleep for 2 seconds to allow the secret deletion to finish
sleep 2

# Check if the secret was successfully deleted
if kubectl get secret $secret_name --namespace admin > /dev/null 2>&1; then
  # Sleep for an additional 5 seconds if the secret deletion was not successful
  sleep 5
  if kubectl get secret $secret_name --namespace admin > /dev/null 2>&1; then
    echo "Failed to delete Kubernetes secret ${secret_name}."
    exit 1
  fi
fi

echo "Database ${dbname}, user ${dbname}, and Kubernetes secret ${secret_name} deleted successfully."
