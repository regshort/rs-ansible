#!/bin/bash
echo "WARNING: This script will REPLACE the current servers and UPDATE DNS to the new ones. Are you sure you want to continue? (y/n)"
read -r response

if [[ ! $response =~ ^[Yy]$ ]]
then
  echo "Aborting."
  exit 1
fi

# Initialize variables
debug=0
dbdump=1
backdump=1
dbrestore=1
backrestore=1
dns=1

# Loop through the arguments and set variables for each operation based on the flags
while [ $# -gt 0 ]; do
  case $1 in
    "debugging")
      # Set variable for dbdump operation
      debug=1
      ;;
    "dbdump")
      # Set variable for dbdump operation
      dbdump=1
      ;;
    "backdump")
      # Set variable for backdump operation
      backdump=1
      ;;
    "dbrestore")
      # Set variable for dbrestore operation
      dbrestore=1
      ;;
    "backrestore")
      # Set variable for backrestore operation
      backrestore=1
      ;;
    "dns")
      # Set variable for DNS update operation
      dns=1
      ;;
    *)
      # Print usage message if invalid flag is passed
      echo "Usage: $0 [dbdump|dbrestore|backdump|backrestore|dns] [args]"
      exit 1
      ;;
  esac
  shift
done

read -s -p "Enter the Ansible Vault password: " password
echo $password > vault_pass.txt

ansible_cmd="ansible-playbook"
if [[ $debug -eq 1 ]]; then
  echo "Running with debugging enabled."
  ansible_cmd="ansible-playbook -v"
else
  echo "Running without debugging."
fi

if [[ $dbdump -eq 1 ]]; then
    $ansible_cmd playbooks/create-db-dumps.yml
fi

if [[ $backdump -eq 1 ]]; then
    $ansible_cmd playbooks/create-back-dump.yml
fi

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

if [[ $dbrestore -eq 1 ]]; then
  $ansible_cmd playbooks/restore-back-dump.yml
fi

if [[ $backrestore -eq 1 ]]; then
  $ansible_cmd playbooks/restore-db.yml
fi

if [[ $dns -eq 1 ]]; then
  $ansible_cmd playbooks/update-dns.yml --vault-password-file=vault_pass.txt
fi

rm vault_pass.txt