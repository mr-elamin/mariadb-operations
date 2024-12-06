#!/bin/bash

# Check if the database name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <database_name>"
  exit 1
fi

# Set variables
dbname=$1
dbuser=$dbname
dbpass=$(pwgen -s 16 1 | tr -d '\n')
secret_name="${dbname}-db-secret"
mariadburl="mariadb://${dbuser}:${dbpass}@mariadb-primary.mariadb.svc.cluster.local:3306/${dbname}"

# Create the database and user, and grant privileges
mariadb -h mariadb-primary.mariadb.svc.cluster.local -uroot -p"${MARIADB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${dbname}\`;
CREATE USER IF NOT EXISTS \`${dbuser}\`@'%' IDENTIFIED BY '${dbpass}';
GRANT ALL PRIVILEGES ON \`${dbname}\`.* TO \`${dbuser}\`@'%';
FLUSH PRIVILEGES;
EOF

# Check if the database and user creation was successful
if [ $? -ne 0 ]; then
  echo "Failed to create database or user."
  exit 1
fi

# Create the Kubernetes secret
kubectl create secret generic $secret_name --namespace admin \
  --from-literal=database=$dbname \
  --from-literal=mariadb-password=$dbpass \
  --from-literal=mariadburl=$mariadburl

# Check if the secret creation was successful
if [ $? -ne 0 ]; then
  echo "Failed to create Kubernetes secret."
  exit 1
fi

echo "Database and user created successfully."
echo "Kubernetes secret '${secret_name}' created successfully."
echo "MariaDB URL: ${mariadburl}"
echo "Database: ${dbname}"
echo "User: ${dbuser}"
echo "Password: ${dbpass}"
