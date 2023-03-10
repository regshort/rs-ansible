#!/bin/bash
ansible_cmd="ansible-playbook"

$ansible_cmd playbooks/create-ssh-local.yml
sleep 5
# remove key and readd key
# ssh-add -l | grep -q "$key_file" && ssh-add -d "$key_file"
# ssh-add "$key_file"

# run server creation we need to split playbooks because of inventory 
$ansible_cmd playbooks/hetzner_initiate.yml
# this is the main playbook doing stuff on server
sleep 20
$ansible_cmd playbooks/initiate.yml
