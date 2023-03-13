# Swarm

We followed mostly [this blog post](https://blog.okami101.io/2022/02/setup-a-docker-swarm-cluster-part-ii-hetzner-cloud-nfs/#create-the-cloud-servers-and-networks-
)
### Info
- `docker service ls` on `manager` to see running services
- `traefik.sw.x.x` also shows all 
- `docker stack deploy -c portainer-agent-stack.yml portainer` to deploy a stack on swarm
This basically builds a full stack with docker.
- Glusterfs for storage.
  - echo "data-01:/volume-01 /mnt/storage-pool glusterfs defaults,_netdev,x-systemd.automount 0 0" | sudo tee -a /etc/fstab install-gluster-client.yml
- Docker swarm
  - manager is box that orchestrates everything
- Restic backups
  - `setup-restic.yml` has config (TODO)
- Prometheus, Grafana, Loki
  - Data Sources:
    - `http://prometheus:9090`: Prometheus
    - `http://data-01:3100`: Loki
  - Dashboards:
    - Prometheus:
      - `11939`: Docker Swarm dashboard
      - `1860`: For Node exporter
      - `9628`: For PostgreSQL exporter
    - Loki:
      - create new dashboard, add panel, `{swarm_stack="$stack"}` query, log view
      - define `stack` with Prometheus, query: `label_values(container_last_seen, container_label_com_docker_stack_namespace)` in dashboard settings
      - now you have a log view with drop down
- Postgres, Redis, s3
- All on `data` (todo login)
- Adminer to see database for deving
- DB dump is made from `setup-restic.yml`

#### Grafana note:
The Available Disk Space metrics card should indicate N/A because not properly configured for Hetzner disks. Just edit the card and change the PromQL inside Metrics browser field by replacing device="rootfs", mountpoint="/" by device="/dev/sda1", mountpoint="/host".

### TODO
- Template our stack files and config files so ansible can fill them
- Password and secrets (vault)
- Node Tags
  - production (webworker, streamworker)
  - build (cicd)
- Deploy as code
  - cicd
    - build all images on ansible runner first so we can deploy apps
  - grafana
- Hardening all
- Backups (not working atm)

### cron template

more info [here](https://blog.okami101.io/2022/02/setup-a-docker-swarm-cluster-part-iii-cluster-initialization/#distributed-cron-jobs-)

```yaml
    deploy:
      labels:
        - swarm.cronjob.enable=true
        - swarm.cronjob.schedule=5 * * * *
        - swarm.cronjob.skip-running=true
      replicas: 0
      restart_policy:
        condition: none
```

### app secrets

All secrets we need to deploy fullapp:

- Local Database creds
- Local registry creds
- Swarm apps login
- Linux boxes passwords
- SSH key (servers)
- Frontend
  - Auths
    - NEXTAUTH
    - SENDGRID
    - GITHUB
    - GOOGLE
    - DISCORD
    - REDDIT

## restic

setup-restic.yml has creates a backup service that runs periodically can be redeployed to overwrite settings

the backup location needs `rustic init` ran on it before with the same pw i think not automated

## you need to do this before running.

This project uses `ansible-vault` to encrypt our variables the password is saved in our keychain.

- **setup a project on [hetzner cloud](https://console.hetzner.cloud/projects)**

  - make an api key for the project. (`hetzner_api_token`)
  - add the ssh key from this repo `ssh/id_rsa.pub` to the project.

- Setup github user access token

  - (needs perms for keys)

- Put the hetzner api key and the github key it into `vars/sensitive.yml#github_access_token`)

because of ansible.cfg you don't need to setup any inventory or ssh keys but make sure your `/etc/ansible/hosts` is empty otherwise it could build on these hosts because this uses `hosts:all` a lot

**OLD README BELOW**

We should probably make `containers` for each repo so we do not need to care about installing repos and only need to do initiation

### Things to fix:

- containerize/dockerize apps
- env variables & ssh key on machine that runs the playbooks should be encrypted
- permissions when creating user because of pw prompts i've made sudo with no pw
- hardcoded ports and nginx configs
- change hardcoded repo files, maybe add a playbook for each repo into repo or add it here so its not hardcoded
- automate cloudflare cert stuff
  **FIRST TIME USING ANSIBLE COULD ALL BE WRONG lol**

### Whats done:

- Simple initiation [initiation](../../components/initiation.md)
  - Create server from Object
  - Create network for servers
  - Add ssh keys to server
  - Change hostname (and hosts)
  - Change root password
  - create user
  - add ssh key to box
  - simple ssh hardening
  - history fix
  - update ubuntu
  - create ssh key
  - upload keys to github user
  - copy CF origin ssl
  - copy nginx-config
- web
  - Push schema to dba
- dba
  - run pg2arrow, b2f
  - copy arrow files to str
- str

## you need to do this before running.

This project uses `ansible-vault` to encrypt our variables the password is saved in our keychain.

- **setup a project on [hetzner cloud](https://console.hetzner.cloud/projects)**

  - make an api key for the project. (`hetzner_api_token`)
  - add the ssh key from this repo `ssh/id_rsa.pub` to the project.

- Setup github user access token

  - (needs perms for keys)

- Put the hetzner api key and the github key it into `vars/sensitive.yml#github_access_token`)

because of ansible.cfg you don't need to setup any inventory or ssh keys but make sure your `/etc/ansible/hosts` is empty otherwise it could build on these hosts because this uses `hosts:all` a lot

## run

**this will delete all networks and boxes in this project** (hetzner deploy script for now cleans up in the future we could deploy alongside and only delete at the end)
`[dbdump|dbrestore|backdump|backrestore|dns] [args]`
`./fulldeploy.sh ` runs all

What create-server.sh does:

- FIXME: check for $HETZNER_CLOUD env (having trouble automating this)
- Ask for vault password save it to file to pass it to playbooks
- Create Local SSH keys
- ssh-add the new key
- create servers with generated key
- run main playbook to install everything for now its called form `main.yml`
- asks us if we want to update the cloudflare dns to the new servers
- removes temp pw file

## hosted runner installation

Make sure the box can access github

Pre install
`sudo apt-add-repository ppa:ansible/ansible`
`sudo apt update && sudo apt upgrade`
`git clone git@github.com:regshort/rs-ansible`

Install
`sudo apt install ansible python3-pip`
`pip install hcloud`

Add env variable
`vim ~/.bashrc`
`export HCLOUD_TOKEN=XXX`

### controller playbook

We create a controller and clone this git, we setup everything needed to run it.
