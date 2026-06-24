#!/bin/bash
set -e

# Parse dynamic variables from Ansible config
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

if [ "$SUBDOMAIN" = "@" ]; then
  FULL_DOMAIN="$BASEDOMAIN"
else
  FULL_DOMAIN="${SUBDOMAIN}.${BASEDOMAIN}"
fi

export TF_VAR_vm_name="$VM_NAME"
export TF_VAR_base_domain="$BASEDOMAIN"
export TF_VAR_subdomain="$SUBDOMAIN"
export TF_VAR_ssh_name="$SSH_NAME"
export TF_VAR_project_name="$project_name"

# Terraform Phase
echo "Running Terraform..."
cd terraform
terraform init
terraform apply -auto-approve

# extract IP for ansible
IP=$(terraform output -raw server_public_ip)

if [ -z "$IP" ]; then
  echo "Error: Could not extract IP from Terraform."
  exit 1
fi

HOSTS_FILE="../ansible/inventory/hosts.ini"

# Check if the IP is already in the hosts file
if ! grep -q "$IP ansible_user=root" "$HOSTS_FILE" 2>/dev/null; then
  echo "New IP detected. Updating Ansible inventory..."
  echo "[webservers]" > "$HOSTS_FILE"
  echo "$IP ansible_user=root" >> "$HOSTS_FILE"
  
  echo "Waiting for the new server to fully boot..."
  sleep 10
else
  echo "Server IP is unchanged. Skipping boot delay."
fi

# DNS Propagation Check
check_dns() {
  local domain=$1
  local target_ip=$2
  echo "Checking global DNS propagation for $domain..."
  while true; do
    # Try dig with Cloudflare DNS first for global view, fallback to system getent
    if command -v dig >/dev/null 2>&1; then
      resolved_ip=$(dig @1.1.1.1 +short "$domain" | grep -E '^[0-9.]+$' | head -n1)
    else
      resolved_ip=$(getent ahosts "$domain" | grep -E '^[0-9.]+$' | head -n1 | awk '{print $1}')
    fi
    
    if [ "$resolved_ip" = "$target_ip" ]; then
      echo "✓ $domain is successfully resolving to $target_ip!"
      break
    fi
    
    echo "  ... still waiting for DNS to update (currently resolving to: ${resolved_ip:-none}). Retrying in 10s..."
    sleep 10
  done
}

echo "=========================================="
check_dns "$FULL_DOMAIN" "$IP"
sleep 5
echo "=========================================="

# Ansible Phase
echo "Running Ansible..."
cd ../ansible
/usr/bin/ansible-playbook -i inventory/hosts.ini playbook.yml

echo "=========================================="
echo "Deployment successful!"
echo "=========================================="