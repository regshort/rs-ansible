#!/bin/bash
# ssh key to add
key_file=ansible/ssh/id_rsa 
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
# ansible-playbook -v ansible/playbooks/setup-enviroment-variables-local.yml --vault-password-file=vault_pass.txt

# create local ssh keys
ansible-playbook -v ansible/playbooks/create-ssh-local.yml
sleep 5
# remove key and readd key
ssh-add -l | grep -q "$key_file" && ssh-add -d "$key_file"
ssh-add "$key_file"

# run server creation we need to split playbooks because of inventory 
ansible-playbook -v ansible/pre-main.yml --vault-password-file=vault_pass.txt
sleep 20
# this is the main playbook doing stuff on server
ansible-playbook -v ansible/main.yml --vault-password-file=vault_pass.txt

echo "Do you want to update Cloudflare DNS (yes/no) [yes]?"
read -r answer

answer=${answer:-yes}

if [ "$answer" == "yes" ]; then
  ansible-playbook -v ansible/playbooks/update-dns.yml --vault-password-file=vault_pass.txt
else
  echo "Cloudflare DNS update skipped."
fi

# remove pw file
rm vault_pass.txt