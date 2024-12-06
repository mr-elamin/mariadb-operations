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
