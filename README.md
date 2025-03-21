# MariaDB Kubernetes Operations

This repository contains scripts for managing MariaDB databases in a Kubernetes cluster environment. The scripts are designed to be run inside a container to perform various database operations. The container image `ubuntu-command-central:24.04` includes all necessary tools and scripts located in `/opt/scripts`.

## Important Notice

The container runs as root, which can be dangerous if left running. It is advised to scale the deployment to zero replicas after completing the operations.

## Environment Variable

All operations require the MariaDB root password to be passed to the container as an environment variable `MARIADB_ROOT_PASSWORD`.

An existing secret with the MariaDB root password must be present in the namespace in which the deployment is created. The secret name should be `mariadb-credentials` and the key containing the root password should be named `mariadb-root-password`.

## Scripts Overview

1. **mariadb-connect-to-database.sh**
   - Connects the terminal to the MariaDB database.

2. **mariadb-show-databases.sh**
   - Lists all available databases.

3. **mariadb-create-database.sh**
   - Creates a database by passing the database name. It also creates a user for this database and stores the password and the database URL in the `admin` namespace in a secret named `<dbname>-db-secret`.

4. **mariadb-create-database-namespaced.sh**
   - Accepts the database name and the namespace in which the database credentials should be created. The secret is named `<dbname>-db-secret`.

5. **mariadb-create-backup.sh**
   - Creates a backup by passing the database name and saves the backup to the PVC in the `/backup` directory.

6. **mariadb-drop-database.sh**
   - Accepts an argument with the database name to be deleted and deletes the associated secret in the `admin` namespace.

7. **mariadb-drop-database-namespaced.sh**
   - Accepts the database name to drop and the namespace in which the secret for this database is stored to be deleted as well.

8. **mariadb-list-backup.sh**
   - Lists the files in the `/backup` directory.

9. **mariadb-restore-backup.sh**
   - Lists the available backups in the `/backup` directory and lets you select one backup to restore.

## Deployment

The deployment YAML file includes all necessary tools to manage the database. The PVC YAML file is required for storing and restoring the backup. The PVC will be mounted in the container in the `/backup` directory.

**Note**: The container runs the SSH service (`sshd`), and port 22 will be open to allow SSH access inside the container using ingress.

## Usage

1. **Create the namespace and secrets**:
   - Create a namespace called `admin` and create the required secrets in it:
     - The secret named `mariadb-credentials` containing the key `mariadb-root-password` for the MariaDB root password.
     - The secret named `user-passwords` containing the key `root-password` for the root user to access the container through ingress or NodePort via SSH.

   ```bash
   kubectl create namespace admin
   kubectl create secret generic mariadb-credentials --from-literal=mariadb-root-password=<your-mariadb-root-password> -n admin
   kubectl create secret generic user-passwords --from-literal=root-password=<your-system-root-password> -n admin

2. **Create the PVC**:
   - Ensure the PVC is configured with the correct storage class to persist the backups.

3. **Deploy the container**:
   - Apply the deployment and PVC YAML files to your Kubernetes cluster.

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/mr-elamin/mariadb-operations/main/pvc.yaml
   kubectl apply -f https://raw.githubusercontent.com/mr-elamin/mariadb-operations/main/ubuntu-command-central-deployment.yaml
   ```

4. **Optionally, deploy the service**:
   - Apply the service YAML file to expose the container through NodePort or ingress.

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/mr-elamin/mariadb-operations/main/ubuntu-command-central-service.yaml
   ```

   **Attention**: There is a security risk when using NodePort.

5. **Run the scripts**:
   - Connect to the container and run the desired script. The scripts are exported to `$PATH` and can be run from anywhere in the terminal without specifying the full path.

   ```bash
   kubectl exec -it <pod-name> -- /bin/bash
   mariadb-connect-to-database.sh
   ```

6. **Scale down the deployment**:
   - After completing the operations, scale down the deployment to zero replicas to avoid security risks.

   ```bash
   kubectl scale deployment mariadb-operations --replicas=0
   ```

## Issues

For any problems, feel free to open an issue.

## License

This project is licensed under the MIT License.
```
