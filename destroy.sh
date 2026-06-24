#!/bin/bash
set -e

echo "=========================================="
echo "Removing Cloud-1 Terraform resources..."
echo "=========================================="

echo "Parsing deployment variables..."
project_name=$(grep '^project_name:' ansible/group_vars/all.yml | awk -F '"' '{print $2}')
SSH_NAME=$(grep '^ssh_name:' ansible/group_vars/all.yml | awk -F '"' '{print $2}')
BASEDOMAIN=$(grep '^base_name:' ansible/group_vars/all.yml | awk -F '"' '{print $2}')
SUBDOMAIN=$(grep '^subdomain:' ansible/group_vars/all.yml | awk -F '"' '{print $2}')
VM_NAME=$(echo "$BASEDOMAIN" | tr '.' '-' | tr -d ' \r\n')

if [ -z "$project_name" ] || [ -z "$SSH_NAME" ] || [ -z "$BASEDOMAIN" ] || [ -z "$SUBDOMAIN" ] || [ -z "$VM_NAME" ]; then
  echo "Error: Could not parse required variables from group_vars/all.yml"
  exit 1
fi

export TF_VAR_vm_name="$VM_NAME"
export TF_VAR_base_domain="$BASEDOMAIN"
export TF_VAR_subdomain="$SUBDOMAIN"
export TF_VAR_ssh_name="$SSH_NAME"
export TF_VAR_project_name="$project_name"

cd terraform

echo "Initializing Terraform..."
terraform init

if terraform state list >/dev/null 2>&1; then
    echo "Destroying Terraform-managed resources..."
    terraform destroy -auto-approve
    echo "Terraform resources removed successfully."
else
    echo "No Terraform state found. Nothing to remove."
fi

echo "=========================================="
echo "Cleanup complete!"
echo "=========================================="
