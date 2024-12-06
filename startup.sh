#!/bin/bash

set -e

echo "Starting SSH key generation..."
# Generate SSH host keys if not present
ssh-keygen -A

echo "Generating password hashes..."
# Generate password hashes
ROOT_HASH=$(mkpasswd -m sha-512 ${ROOT_PASSWORD})

echo "Replacing password hashes in /etc/shadow..."
# Replace password hashes in /etc/shadow
sed -i "s|^root:[^:]*|root:${ROOT_HASH}|" /etc/shadow

echo "Setting up SSH authorized keys..."
# Ensure the .ssh directory exists and has the correct permissions
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Add the public key to the authorized_keys file
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHW6dBL66n0J0F9YY0YYgerXAcZblVdFKdAXS1BEnuG8nUtu/F97g9ca4vtjkkYuyUMyCtDdEjzLPqEtiGZXqXChETfDgFGQZnnlGVhI1NHyO9/zHu9s1ciaIHmb/HWe0mX+j2QGM+EEW7WSOk52mJ+qmS30JVPKZAbKuA+SjyGr0+s49lZLyjRVkqkU8YXZj3wDoqlYXvIjg8+LEAujGkof0HgxZRKPLC+2Gz0oFiTeqzcp5FRucUivj4Chn2MnjN7EULlXcxcvk2DtNsoZ3H9PILEF12yiLThysBkBQHpwNADjum85Jc9ZVJkK9tIKaaEIQ7qb1VAhKRV7UBN/feZ+tKLaCN19lRyE4m2VJn6gW0Y1QBenRTcEryw3LxI/H45srZ7XV7maCoDKEGESfGjbGsmPb2uGEn537K/trOw75kga+FTRYM+EgH3HnWbyW7cJm9/owja+zx7DN9WBTRHEpAeLwYO13XCtHMRDp0NRS455kNdE0uL/+wKUrvVCEg50GfcoigK38sZe11DTdkCgsfIKwVp6zYlqjFTnn2zAiEflPEZboNRm7ta3fNVyYO3RLGLS4n8vhWxHlTR75a/TxunUZsypvriLjKTQ0gyHH5FJJGIIdM8D/Smr/4Ovytd1nKHigz8yNaILViCpcFJ/mloa5ry/9U0pSocRxH8w== mr-elamin@pop-os" > /root/.ssh/authorized_keys

# Set the correct permissions for the authorized_keys file
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh

echo "Configuring SSH daemon..."
# Ensure the SSH daemon listens on port 22
sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config

echo "Setting permissions for Kubernetes config..."
# Ensure the Kubernetes config file has the correct permissions
chmod 600 /root/.kube/config

echo "Starting SSH service..."
# Start SSH service
/usr/sbin/sshd

# Sleep indefinitely to keep the container running
echo "Entering sleep mode..."
sleep infinity
