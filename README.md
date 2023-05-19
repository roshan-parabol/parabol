RethinkDB deployment and administration in GCP

# Initial Setup
[Install terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

[Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

Installed [gcloud cli](https://cloud.google.com/sdk/docs/install) to connect with the GCP project locally so you can run terraform commands to manage infrastructure.

Run `gcloud init` and login to GCP and select the project

Run `gcloud auth application-default login` to use your credentials for terraform.

# Terraform

We use terraform to manage infrastructure components.

### Files

The relevant files can be found in Terraform folder.

`firewall.tf` contains the firewall settings to allow ssh access locally to connect to VM and tcp access to connect via load balancer.

`instance.tf` contains the google VM instance config.

`load_balancer.tf` contains config for load balancer which exposes the GCP VM over external network on port 8080

`network.tf` contains the VPC network settings in use by the VM

`permissions.tf` contains IAM permissions and service accounts

`storage.tf` contains the persistent disk and the GCS storage bucket.

`variables.tf` contains all the common values / variables used across all the files.

### Deployment commands
To deploy the changes
``` bash
cd Terraform
terraform init
# this should display what infrastructure changes will be deployed.
terraform plan 
# this applies/deploys the changes
terraform apply 
# this will delete everything from GCP
terraform destroy 
```

### What do we have so far?

We created a ubuntu based VM using  `ubuntu-2204-lts` as image and `e2-standard-2` machine type. The VM machine uses a persistent ssd disk connected on VPC network with only internal facing IP address. To access the VM, we have added a firewall rule to allow users to ssh into the VM.

SSH command for ansible user that was created to be able to deploy to VM via Ansible.
``` bash
gcloud compute ssh ansible@rethinkdb-vm-28vc --zone=us-central1-a --project parabol-bp-roshan-rathod
```

We have a load balancer configured that exposes the internal facing VM to external IP to allow us to access the rethink db admin panel via browser. For SSL we need a domain name.

We have a GCS bucket which will be used to store the backups of rethinkdb.


# Ansible

We use Ansible to install dependencies and deploy rethinkdb.

### Files

All files are under Ansible folder.

We used [GCE Dynamic Inventory](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html#gce-dynamic-inventory) approach to be able to connect to the GCM VM via SSH.

`ansible.cfg` contains the ansible configuration which uses gcp_compute plugin and the ssh setup related to it are store in `group_vars` and `misc` folder

`gcp_inventory.ini` defines the host

`gcp_inventory.yaml` doesn't work but was an attempt to connect using service account to connect to VM.

We have two `playbooks`:
`install_dependencies.yaml` used to install any dependencies on the VM. For now, it installs docker, docker-compose and its dependencies.

`deploy_rethinkdb.yaml` checks if docker and docker compose exists and installs rethinkdb using the jinja template file for docker-compose setup - `docker-compose.yaml.j2`

To install via ansible, we use SSH keys. You can generate one using this [guide](https://cloud.google.com/compute/docs/connect/create-ssh-keys) to create and add it to the VM.

Once you have the SSH keys setup, you can test the connection from you local machine using below command:

``` bash
ansible all -i misc/inventory.gcp.yml -m ping --private-key=</path/to/your/key>
```

Example:
``` bash
➜  Ansible git:(main) ✗ ansible all -i misc/inventory.gcp.yml -m ping --private-key=/Users/roshanrathod/.ssh/id_rsa_ansible


10.0.0.10 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

To run the playbooks, you can use the following command:


Command below would first setup docker and docker compose on the VM and then install rethinkdb using docker compose.

``` bash
ansible-playbook -i misc/inventory.gcp.yml playbooks/install_dependencies.yaml playbooks/deploy_rethinkdb.yaml --become -e "ansible_become_password=<password>" --private-key=</path/to/your/key>
```

PS: I have setup a user in the VM called ansible, you can setup your own user or if you use current VM that exists this should work.


Please note:

Any `*service_account*.json` file is service account credentials file and can be retrieved from the GCP console. They are not in the github repository.

docker-compose.yaml.j2 requires cert.pem and key.pem that are generated when you create a self signed certificate. You can remove the certificate option if you do not want SSL enabled or can generate a self signed cert using this [guide](https://rethinkdb.com/docs/security/).