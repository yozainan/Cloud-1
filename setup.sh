#!/bin/bash
set -e

echo "=========================================="
echo "Setting up Cloud-1 Local Environment..."
echo "=========================================="

echo "Checking prerequisites (curl, wget, gpg)..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl wget gpg software-properties-common

# install Terraform (HashiCorp Official Repo)
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found. Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -qq
    sudo apt-get install -y -qq terraform
    echo "Terraform installed successfully!"
else
    echo "Terraform is already installed. Skipping."
fi

# install Ansible (Official PPA)
if ! command -v ansible &> /dev/null; then
    echo "Ansible not found. Installing Ansible..."
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt-get install -y -qq ansible
    echo "Ansible installed successfully!"
else
    echo "Ansible is already installed. Skipping."
fi

# install ansible docker collection
echo "Ensuring Ansible community.docker collection is installed..."
ansible-galaxy collection install community.docker

echo "=========================================="
echo "Setup Complete! You are ready to code."
echo "Terraform version: $(terraform -v | head -n 1)"
echo "Ansible version: $(ansible --version | head -n 1)"
echo "=========================================="
