---
title: Infrastructure as Code — Terraform & Ansible Praktis
tags:
  - devops
  - iac
  - terraform
  - ansible
  - infrastructure
  - automation
  - library
aliases:
  - Terraform State Management
  - Ansible Playbook Guide
  - IaC Terraform Ansible
created: "2026-07-30"
updated: "2026-07-30"
status: pending
cssclasses:
  - wide-table
---

# 🏗️ Infrastructure as Code — Terraform & Ansible Praktis

> Panduan implementasi Infrastructure as Code (IaC) dengan Terraform (provisioning) dan Ansible (configuration management). Bukan teori doang — ini workflow lengkap dari init sampe production, modular structure, state management, Vault integration, dan troubleshooting. Vault udah punya [[ansible-hardening-rocky-linux-9]] (Ansible untuk hardening spesifik) — catatan ini general-purpose: Terraform untuk setup cloud infra, Ansible untuk config management di server yang udah jalan.

> [!tip] Kenapa Dua Tools?
> Terraform = **provisioning** (bikin VM, VPC, network, DB — desired state via HCL). Ansible = **configuration** (install package, copy config, start service — idempotent via YAML). Kombinasi: Terraform bikin infra, Ansible configurin di dalamnya. Jangan pilih salah satu — pake keduanya.

## Daftar Isi

1. [[#1. Fundamental — Provisioning vs Configuration]]
2. [[#2. Terraform — Setup & Init]]
3. [[#3. Terraform — State Management]]
4. [[#4. Terraform — Module Structure]]
5. [[#5. Terraform — Remote State dengan Backend]]
6. [[#6. Ansible — Inventory & Setup]]
7. [[#7. Ansible — Playbook Structure]]
8. [[#8. Ansible — Roles & Galaxy]]
9. [[#9. Ansible — Vault & Secrets]]
10. [[#10. Terraform + Ansible — Integrasi]]
11. [[#11. Koneksi ke Vault]]

---

## 1. Fundamental — Provisioning vs Configuration

```
┌─────────────────────────────────────────────────────┐
│                  Infrastructure as Code              │
├─────────────────────┬───────────────────────────────┤
│   Terraform         │   Ansible                     │
│   (Provisioning)    │   (Configuration)             │
├─────────────────────┼───────────────────────────────┤
│ Declarative (HCL)   │   Imperative + Declarative    │
│ Desired state       │   Task-based YAML             │
│ Push-based          │   Push-based (SSH)            │
│ Stateful (tfstate)  │   Stateless (idempotent)      │
│ Bikin: VPC, VM, DB  │   Install: nginx, node, docker│
│ Infra lifecycle     │   Config management           │
│ Multi-cloud         │   Agentless (SSH)             │
└─────────────────────┴───────────────────────────────┘
```

**Workflow recommended:**

```bash
# 1. Terraform: provisioning
terraform init
terraform plan -out=tfplan
terraform apply tfplan
# Output: VM IP, DB connection string

# 2. Ansible: configure di dalamnya
ansible-playbook -i inventory.yml site.yml --extra-vars "db_url=$(terraform output db_url)"
```

---

## 2. Terraform — Setup & Init

### Install

```bash
# Fedora
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf -y install terraform

# Ubuntu
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify
terraform version
terraform -help
```

### Basic Structure

```hcl
# main.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure provider
provider "aws" {
  region = "ap-southeast-1"
  # Credentials dari env AWS_ACCESS_KEY_ID / AWS_PROFILE
}

# Resource: VPS / EC2
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 24.04
  instance_type = "t3.small"
  tags = {
    Name = "web-server"
    Env  = "production"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt update && apt install -y nginx
  EOF
}

# Output
output "instance_ip" {
  value = aws_instance.web.public_ip
  description = "Public IP web server"
}

output "instance_id" {
  value = aws_instance.web.id
}
```

### Workflow

```bash
# Init — download providers, init backend
terraform init

# Format & validate
terraform fmt -recursive         # format HCL
terraform validate               # syntax check

# Plan — preview perubahan (read-only)
terraform plan
terraform plan -out=tfplan        # save plan

# Apply — eksekusi
terraform apply tfplan            # dari saved plan
terraform apply -auto-approve     # langsung (hati-hati!)

# Destroy — hapus semua resource
terraform plan -destroy
terraform destroy
```

---

## 3. Terraform — State Management

`terraform.tfstate` = JSON yang nyatet resource apa yang udah di-provision. **FILE KERAMAT — jangan diedit manual!**

### Best Practices State

```hcl
# ✅ Remote state via S3/Blob/GCS
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "production/network/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"   # prevent concurrent apply
  }
}
```

```bash
# State commands
terraform state list                       # semua resource yang di-track
terraform state show aws_instance.web      # detail satu resource
terraform state rm aws_instance.web         # remove dari state (jangan destroy)
terraform state mv module.old module.new    # rename/move resource
terraform import aws_instance.web i-12345   # import existing resource

# Untuk recovery — jangan pernah edit langsung!
terraform state pull > backup.tfstate       # backup state
terraform state push backup.tfstate         # restore state
```

### Shared State Pitfall

> [!warning] Jangan share state file via git! Isinya plain-text credentials + resource IDs. Selalu pake remote backend (S3/GCS/Azure) dengan encryption + locking.

---

## 4. Terraform — Module Structure

Project layout untuk production:

```
terraform/
├── environments/
│   ├── production/
│   │   ├── main.tf            # backend + provider
│   │   ├── network.tf         # vpc, subnet, sg
│   │   ├── compute.tf         # ec2/instance
│   │   ├── database.tf        # rds
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars   # nilai variabel production
│   └── staging/
│       └── ... (sama tapi berbeda nilai)
├── modules/
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/
│   │   └── ...
│   └── database/
│       └── ...
└── global/
    ├── iam.tf
    └── route53.tf
```

### Module Example

```hcl
# modules/compute/main.tf
resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = var.security_groups

  tags = merge(var.tags, {
    Name = var.name
  })
}

# variables.tf
variable "name" { type = string }
variable "ami" { type = string }
variable "instance_type" { type = string, default = "t3.micro" }
variable "subnet_id" { type = string }
variable "security_groups" { type = list(string), default = [] }
variable "tags" { type = map(string), default = {} }

# outputs.tf
output "instance_id" { value = aws_instance.this.id }
output "private_ip" { value = aws_instance.this.private_ip }

# --- Panggil dari production/main.tf ---
module "web_server" {
  source = "../../modules/compute"

  name       = "web-prod-01"
  ami        = data.aws_ami.ubuntu.id
  subnet_id  = module.network.public_subnet_ids[0]
  tags       = { Environment = "production", Terraform = "true" }
}
```

---

## 5. Terraform — Data Sources & Remote State

```hcl
# Data source — baca existing resource
data "aws_vpc" "existing" {
  tags = { Name = "main-vpc" }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-24.04-*"]
  }
}

# Read output dari state lain
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "mycompany-terraform-state"
    key    = "production/network/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

resource "aws_instance" "web" {
  subnet_id = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
}
```

---

## 6. Ansible — Inventory & Setup

### Install

```bash
pip install ansible
# atau
sudo apt install ansible          # Ubuntu 24.04: ansible 9+
sudo dnf install ansible           # Fedora
ansible --version
```

### Inventory — Host Definition

```ini
# inventory-production.ini
[web]
web-01 ansible_host=192.168.1.10 ansible_user=dev
web-02 ansible_host=192.168.1.11 ansible_user=dev

[db]
db-master ansible_host=192.168.1.20 ansible_user=admin
db-replica ansible_host=192.168.1.21 ansible_user=admin

[all:vars]
ansible_ssh_private_key_file=~/.ssh/deploy_key
ansible_python_interpreter=/usr/bin/python3
```

```yaml
# inventory-production.yml (YAML format — better)
all:
  children:
    web:
      hosts:
        web-01:
          ansible_host: 192.168.1.10
        web-02:
          ansible_host: 192.168.1.11
    db:
      hosts:
        db-master:
          ansible_host: 192.168.1.20
        db-replica:
          ansible_host: 192.168.1.21
  vars:
    ansible_user: dev
    ansible_ssh_private_key_file: ~/.ssh/deploy_key
```

### Ad-hoc Commands

```bash
ansible all -i inventory-production.yml -m ping                     # test koneksi
ansible web -i inventory.yml -m command -a "uptime"                 # run command
ansible db -i inventory.yml -m shell -a "df -h | grep /dev/sda"    # shell
ansible all -i inventory.yml -m apt -a "name=nginx state=latest" -b # install package
ansible all -i inventory.yml -m systemd -a "name=nginx state=restarted" -b
```

---

## 7. Ansible — Playbook Structure

```yaml
# setup-web.yml
---
- name: Configure Web Servers
  hosts: web
  become: yes
  vars:
    nginx_port: 80
    app_user: dev

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Copy Nginx config
      template:
        src: "templates/nginx.conf.j2"
        dest: "/etc/nginx/sites-available/default"
      notify: restart nginx

    - name: Enable site
      file:
        src: /etc/nginx/sites-available/default
        dest: /etc/nginx/sites-enabled/default
        state: link
      notify: restart nginx

    - name: Start Nginx
      systemd:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
```

### Variables & Templates

```yaml
# group_vars/all.yml — semua host
nginx_port: 80
app_domain: myapp.example.com

# group_vars/web.yml — hanya group web
node_version: "22"
app_repo: "git@github.com:org/myapp.git"
```

```nginx
{# templates/nginx.conf.j2 — Jinja2 template #}
server {
    listen {{ nginx_port }};
    server_name {{ app_domain }};
    root /var/www/{{ app_user }}/dist;
    index index.html;
}
```

### Run Playbook

```bash
# Dry run
ansible-playbook -i inventory.yml setup-web.yml --check --diff

# Real
ansible-playbook -i inventory.yml setup-web.yml -v
ansible-playbook -i inventory.yml setup-web.yml --tags "nginx,config"  # hanya tag tertentu
ansible-playbook -i inventory.yml setup-web.yml --start-at-task "Copy Nginx config"  # skip ke task

# Limit ke host tertentu
ansible-playbook -i inventory.yml setup-web.yml --limit web-01
```

---

## 8. Ansible — Roles & Galaxy

### Role Structure

```
roles/
├── common/
│   ├── tasks/
│   │   └── main.yml       # Task utama
│   ├── handlers/
│   │   └── main.yml       # Service restart triggers
│   ├── templates/
│   │   └── nginx.conf.j2  # Template files
│   ├── files/
│   │   └── custom.conf    # Static files
│   ├── vars/
│   │   └── main.yml       # Role variables
│   ├── defaults/
│   │   └── main.yml       # Default variables (low priority)
│   └── meta/
│       └── main.yml       # Dependencies
└── nginx/
    └── ...
```

```yaml
# site.yml — main playbook
- hosts: all
  roles:
    - common # base setup: user, timezone, repo, firewall
    - role: nginx
      vars:
        nginx_port: 443
        ssl_cert: "{{ vault_ssl_cert }}"

- hosts: db
  roles:
    - postgresql
    - redis
```

### Ansible Galaxy — Community Roles

```bash
# Install roles dari Galaxy
ansible-galaxy install geerlingguy.nginx
ansible-galaxy install geerlingguy.postgresql
ansible-galaxy install devsec.hardening        # CIS hardening

# requirements.yml — version-locked
cat > requirements.yml << EOF
roles:
- src: geerlingguy.nginx
  version: 3.1.4
- src: devsec.hardening
  version: 8.5.0
collections:
- name: community.docker
  version: ">=3.4.0"
EOF

ansible-galaxy install -r requirements.yml
```

---

## 9. Ansible — Vault & Secrets

```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit
ansible-vault edit secrets.yml

# View
ansible-vault view secrets.yml

# Encrypt existing
ansible-vault encrypt group_vars/all/vault.yml
ansible-vault decrypt group_vars/all/vault.yml     # ⚠️ Hati-hati!

# Rekey (ganti password)
ansible-vault rekey secrets.yml
```

```yaml
# group_vars/all/vault.yml — encrypted dengan vault password
vault_db_password: Sup3rS3cr3t!
vault_api_key: sk-abc123def456
vault_ssl_cert: |
  -----BEGIN CERTIFICATE-----
  MIIFazCCA1OgAwIBAgI...
  -----END CERTIFICATE-----
```

```yaml
# Run dengan vault
ansible-playbook site.yml --ask-vault-pass
# Atau dengan file password
ansible-playbook site.yml --vault-password-file .vault_pass

# Atau script (better — gak commit password)
ansible-playbook site.yml --vault-password-file ~/.bin/get_vault_pass.sh
```

```bash
#!/bin/bash
# ~/.bin/get_vault_pass.sh — ambil dari 1Password / Bitwarden / env
op read "op://Infrastructure/Ansible Vault/password"
```

---

## 10. Terraform + Ansible — Integrasi

### Local Exec — Trigger Ansible dari Terraform

```hcl
# main.tf
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.small"

  # Output pemanggilan Ansible setelah provisioning
  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' configure-web.yml -u ubuntu --private-key ~/.ssh/deploy_key"

    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }
}

# Atau remote-exec — SSH langsung dari Terraform
provisioner "remote-exec" {
  inline = [
    "sudo apt update",
    "sudo apt install -y nginx",
  ]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/deploy_key")
    host        = self.public_ip
  }
}
```

> [!tip] Local-exec lebih baik daripada remote-exec — pake Ansible yang udah mature idempotent-nya. Terraform provisioner cuma untuk bootstrapping minimal.

### Dynamic Inventory — Terraform Output → Ansible

```bash
# generate_inventory.sh
#!/bin/bash
terraform output -json | jq -r '
{
  "web": {
    "hosts": {
      (.web_ip.value[] | gsub("[\[\]"]"; "")): {
        "ansible_user": "ubuntu"
      }
    }
  }
}
' > inventory.json

ansible-playbook -i inventory.json configure-web.yml
```

---

## 11. Koneksi ke Vault

| Catatan                             | Koneksi                                                                    |
| ----------------------------------- | -------------------------------------------------------------------------- |
| [[ansible-hardening-rocky-linux-9]] | Ansible untuk hardening spesifik Rocky Linux — catatan ini general-purpose |
| [[cicd-github-actions-praktik]]     | CI/CD pipeline — Terraform apply otomatis dari pipeline                    |
| [[linux-hardening-audit-praktis]]   | Ansible bisa otomasi semua hardening di catatan itu                        |
| [[vps-hardening-playbook]]          | Hardening VPS — bisa di-ansible-kan                                        |
| [[cicd-guide]]                      | CI/CD konseptual — link ke deployment pipeline                             |
| [[infrastructure-administrator]]    | Admin tasks — IaC adalah subset administrasi modern                        |

## References

1. Terraform Documentation — https://developer.hashicorp.com/terraform/docs
2. Terraform Best Practices — https://developer.hashicorp.com/terraform/language/state
3. Ansible Documentation — https://docs.ansible.com/ansible/latest/index.html
4. Ansible Best Practices — https://docs.ansible.com/ansible/latest/tips_ansible_vault.html
5. Integrasi Terraform + Ansible — https://developer.hashicorp.com/terraform/tutorials/provision/ansible
6. Ansible Galaxy — https://galaxy.ansible.com/
7. OpenTofu (Terraform fork) — https://opentofu.org/
