#!/bin/bash
echo -n "Do you want to run with debugging? (y/n): "
read answer

if [ "$answer" == "y" ]; then
  echo "Running with debugging enabled."
  ansible_cmd="ansible-playbook -v"
else
  echo "Running without debugging."
  ansible_cmd="ansible-playbook"
fi

# ssh key to add
key_file=ssh/id_rsa 

# ask for vault pw
if [ -z "$HCLOUD_TOKEN" ]; then
  echo "Error: HCLOUD_TOKEN environment variable is not set."
  exit 1
fi
echo "Enter the Ansible Vault password: " 
read -s password
# temp write to read it in ansible
echo $password > vault_pass.txt
# add hcloud token to running user env
# ansible-playbook -v playbooks/setup-enviroment-variables-local.yml --vault-password-file=vault_pass.txt
# ask if we want to save dbs from running hosts right now
echo -n "Do you want to dump current dbs (will overwrite dbs/*)? (y/n): "
read answer

if [ "$answer" == "y" ]; then
  echo "dumping dbs"
  $ansible_cmd playbooks/create-db-dumps.yml
else
  echo "not dumping dbs"
fi

# create local ssh keys
$ansible_cmd playbooks/create-ssh-local.yml
sleep 5
# remove key and readd key
ssh-add -l | grep -q "$key_file" && ssh-add -d "$key_file"
ssh-add "$key_file"

# run server creation we need to split playbooks because of inventory 
$ansible_cmd playbooks/hetzner_initiate.yml --vault-password-file=vault_pass.txt
sleep 30
# this is the main playbook doing stuff on server
$ansible_cmd playbooks/initiate.yml --vault-password-file=vault_pass.txt
$ansible_cmd -i inventory/todelete/hcloud.yml playbooks/remove-servers-hetzner.yml --vault-password-file=vault_pass.txt
$ansible_cmd playbooks/update-dns.yml --vault-password-file=vault_pass.txt

# echo "Do you want to update Cloudflare DNS (yes/no) [yes]?"
# read -r answer

# answer=${answer:-yes}

# if [ "$answer" == "yes" ]; then
#  $ansible_cmd playbooks/update-dns.yml --vault-password-file=vault_pass.txt
# else
#   echo "Cloudflare DNS update skipped."
# fi

# remove pw file
rm vault_pass.txt