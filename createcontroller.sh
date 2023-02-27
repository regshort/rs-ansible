#!/bin/bash
read -s -p "Enter the Ansible Vault password: " password
echo $password > vault_pass.txt
ansible_cmd=ansible-playbook
$ansible_cmd playbooks/create-controller-server.yml --vault-password-file=vault_pass.txt

$ansible_cmd -i inventory/controller/hcloud.yml playbooks/create-controller-initiate.yml --vault-password-file=vault_pass.txt


rm vault_pass.txt