#!/bin/bash

# Check if the database name and namespace are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <database_name> <namespace>"
  exit 1
fi

# Set variables
dbname=$1
namespace=$2

# Check if the database name contains an underscore or dot
if [[ "$dbname" == *"_"* ]] || [[ "$dbname" == *"."* ]]; then
  echo "Error: Database name '$dbname' contains an invalid character (_ or .). Database names cannot contain underscores or dots."
  exit 1
fi

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

# Create the Kubernetes secret in the specified namespace
kubectl create secret generic $secret_name --namespace $namespace \
  --from-literal=database=$dbname \
  --from-literal=mariadb-password=$dbpass \
  --from-literal=mariadburl=$mariadburl

# Check if the secret creation was successful
if [ $? -ne 0 ]; then
  echo "Failed to create Kubernetes secret."
  exit 1
fi

echo "Database and user created successfully."
echo "Kubernetes secret '${secret_name}' created successfully in namespace '${namespace}'."
echo "MariaDB URL: ${mariadburl}"
echo "Database: ${dbname}"
echo "User: ${dbuser}"
echo "Password: ${dbpass}"
