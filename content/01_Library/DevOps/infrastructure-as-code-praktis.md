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
11. [[#11. State Locking — Mencegah Konflik di Remote State]]
12. [[#12. Terraform Workspaces vs Directory-per-Environment]]
13. [[#13. Ansible — Push Mode vs Pull Mode]]
14. [[#14. Ansible AWX / Tower — Enterprise Management]]
15. [[#15. Idempotency — Cara Kerja Check Mode & Batasannya]]
16. [[#16. Ansible Strategies — Delegation, Serial, Throttle]]
17. [[#17. Full Workflow — Terraform Plan → Apply → Ansible]]
18. [[#18. OpenTofu — Fork Open Source Terraform]]
19. [[#19. Terragrunt — DRY Patterns untuk Multi-Environment]]
20. [[#20. Koneksi ke Vault]]

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
    - common                 # base setup: user, timezone, repo, firewall
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

## 11. State Locking — Mencegah Konflik di Remote State

State locking mencegah dua orang (atau CI pipeline + developer) menjalankan `terraform apply` bersamaan pada state yang sama. Tanpa locking, dua apply bisa saling timpa dan corrupt state.

### AWS DynamoDB

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "production/network/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Buat tabel DynamoDB dengan primary key `LockID` (string). Terraform otomatis bikin row pas apply, hapus pas selesai. Jika apply kedua jalan duluan, Terraform akan **fail dengan error locking** — bukan overwrite. Harga: gratisan (hampir 0 biaya).

```bash
# Create DynamoDB lock table via AWS CLI
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

### Consul (HashiCorp)

Untuk on-prem atau multi-cloud tanpa AWS, Consul bisa jadi backend + lock provider:

```hcl
terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    path    = "terraform/production/network"
    scheme  = "https"
  }
}
```

Consul menggunakan session locking via key-value store. Keuntungan: lock TTL otomatis (jika Terraform crash, lock akan release setelah TTL expire). Cocok untuk enterprise yang udah pake Consul untuk service discovery.

### PostgreSQL

Backend PostgreSQL tersedia via `pg` provider:

```hcl
terraform {
  backend "pg" {
    conn_str = "postgres://user:pass@postgres.example.com:5432/terraform?sslmode=require"
    schema_name = "terraform_production"
  }
}
```

PostgreSQL menggunakan `pg_advisory_lock()` untuk state locking. Pilih backend berdasarkan ekosistem tim: AWS team → DynamoDB, HashiCorp shop → Consul, on-prem → PostgreSQL.

---

## 12. Terraform Workspaces vs Directory-per-Environment

Dua strategi utama mengelola environment (dev/staging/prod) di Terraform.

### Workspaces

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new production
terraform workspace select production
```

Workspaces menggunakan satu state file per environment: `terraform.tfstate.d/<env>/`. Cukup untuk environment yang strukturnya identik.

```hcl
# Diferensiasi via workspace name
resource "aws_instance" "web" {
  instance_type = terraform.workspace == "production" ? "t3.medium" : "t3.micro"
  tags = {
    Environment = terraform.workspace
  }
}
```

**Kelebihan:** Satu direktori, no duplication, cepat.  
**Kekurangan:** Semua resource di satu file — lebih mudah error, lebih susah review PR. Tidak bisa punya provider version berbeda per environment. Tidak cocok untuk compliance yang strict separation.

### Directory-per-Environment

```
environments/
├── dev/
│   ├── main.tf
│   ├── backend.tf          # s3 key: dev/
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   └── backend.tf          # s3 key: staging/
└── production/
    ├── main.tf
    ├── backend.tf          # s3 key: production/
    └── terraform.tfvars
```

**Kelebihan:** Isolasi total — satu error di staging gak ngaruh ke prod. Backend terpisah, state terpisah. Bisa punya provider version berbeda. Review PR lebih mudah karena perubahan per environment jelas.  
**Kekurangan:** Duplikasi kode. Perubahan struktural perlu di-copy ke semua folder. Solusi: shared modules di `modules/` dipanggil dari setiap environment.

> [!tip] **Rekomendasi:** Directory-per-environment untuk production. Workspaces cukup untuk project kecil (< 20 resource) atau POC. Di enterprise, directory-per-environment + Terragrunt adalah standar de facto.

---

## 13. Ansible — Push Mode vs Pull Mode

Ansible default adalah **push mode**: control node SSH ke target dan push konfigurasi. Tapi ada **pull mode** via `ansible-pull`.

### Push Mode (Default)

```bash
# Control node push ke semua server
ansible-playbook -i production.ini site.yml
```

| Pro | Kontra |
|-----|--------|
| Control penuh — tau kapan konfigurasi jalan | Target harus reachable via SSH |
| Lebih mudah debug — output langsung | Butuh VPN/tunnel untuk server di NAT |
| Integrasi CI/CD natural (GitHub Actions push) | Gak jalan kalau server offline pas push |

**Use case:** Cloud VPS, datacenter servers, environment dengan VPN.

### Pull Mode (ansible-pull)

```bash
# Di target server — cron job
ansible-pull -U https://github.com/org/ansible-config.git -C production --accept-host-key
```

Target server git clone playbook dari repo, lalu apply ke dirinya sendiri via local connection.

**Use case:**
- **IoT / Edge devices:** Server di lokasi terpencil, NAT, intermittent connectivity
- **Immutable infrastructure:** Auto-repair — server restart apply konfigurasi dari git HEAD
- **Air-gapped:** Server yang gak boleh konek inbound

```yaml
# /etc/cron.d/ansible-pull — jalankan tiap 30 menit
*/30 * * * * root ansible-pull -o -U https://github.com/org/ansible-config.git \
  -C production -d /var/lib/ansible/local --clean
```

Flag `-o` (--only-if-changed): skip kalau git commit sama (hemat resource). `--clean`: hapus file yang gak ada di repo.

| Pro | Kontra |
|-----|--------|
| Gak perlu SSH inbound — aman | Timing gak terprediksi (jadwal cron) |
| Auto-repair — server pull konfigurasi terbaru | Error lebih susah di-debug |
| Skala ribuan device tanpa control node | Butuh Git credentials di setiap device |

---

## 14. Ansible AWX / Tower — Enterprise Management

AWX (upstream FOSS) dan Red Hat Ansible Automation Platform (licensed) adalah web UI + API untuk manage Ansible di skala tim.

### Fitur Utama

- **Job Templates:** Form YAML + parameter — tinggal klik "Launch" tanpa perlu `ansible-playbook` manual
- **Surveys:** Input form untuk user non-teknis — isi variable via dropdown/text field
- **RBAC:** Tim infra bisa akses job tertentu, developer gak bisa destroy production
- **Credentials:** Simpan SSH key, Vault password, cloud API key — team gak perlu tau secret-nya
- **Inventory Sync:** Dynamic inventory dari AWS EC2, DigitalOcean, vSphere
- **Workflow Templates:** Rantai job — job A sukses → jalan job B, fail → notifikasi Slack

### Install AWX dengan Podman / Docker

```bash
git clone https://github.com/ansible/awx-operator.git
cd awx-operator
make deploy
```

Atau container sederhana:

```yaml
# docker-compose.yml (untuk testing)
services:
  awx-web:
    image: ansible/awx:latest
    ports:
      - "8080:80"
    environment:
      POSTGRES_DB: awx
      POSTGRES_USER: awx
      POSTGRES_PASSWORD: sekret
```

### Contoh Trigger via API

```bash
# Trigger job via AWX API (untuk CI/CD)
curl -X POST https://awx.example.com/api/v2/job_templates/5/launch/ \
  -H "Authorization: Bearer $(awx-cli token)" \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": {"target_env": "staging"}}'
```

> [!tip] **Kapan pake AWX?** Tim > 3 orang; perlu audit log; non-teknis perlu deploy; atau compliance butuh separator credential. Untuk personal atau tim kecil (1-2 orang), CLI Ansible + Makefile sudah cukup.

---

## 15. Idempotency — Cara Kerja Check Mode & Batasannya

Ansible modules dirancang untuk **idempotent**: jalan berkali-kali hasilnya sama. Tapi idempotency bukan magic — ada mekanisme spesifik.

### Check Mode (`--check`)

```bash
ansible-playbook site.yml --check
ansible-playbook site.yml --check --diff  # tampilkan perubahan
```

Check mode: Ansible **simulasi** perubahan tanpa benar-benar menjalankan. Module ngasih tau "saya akan ubah ini" tanpa mengubah state server.

**Cara kerja:**
- Module `file`, `copy`, `template`: compare state existing vs desired → report changed jika beda
- Module `apt`, `yum`: cek package version tanpa install
- Module `systemd`: cek status service tanpa start/stop
- Module `command`, `shell`: **tidak bisa check mode** — mereka selalu `changed` di check mode. Solusi: gunakan `changed_when` atau `creates`/`removes`.

### Kapan Ansible TIDAK Idempotent?

1. **Command / Shell module tanpa guard:**
   ```yaml
   - name: ❌ Jangan — selalu changed
     command: /opt/deploy.sh
   - name: ✅ Lebih baik dengan guard
     shell: /opt/deploy.sh --tag {{ version }}
     when: current_version != version
   ```

2. **Script yang tidak stateless:**
   ```yaml
   - name: ❌ Append tiap jalan
     shell: echo "log entry" >> /var/log/app.log
   ```

3. **API calls via `uri` module** — HTTP POST biasanya gak idempotent tanpa idempotency key.

4. **Docker container restart** — `docker_container` dengan `restart: yes` tiap jalan selalu restart.

5. **`lineinfile` tanpa regex** — insert line baru tiap jalan:
   ```yaml
   - name: ❌ Insert tanpa regex — duplikat tiap jalan
     lineinfile:
       path: /etc/hosts
       line: "127.0.0.1 myapp.local"
   - name: ✅ Dengan regex
     lineinfile:
       path: /etc/hosts
       regexp: ".*myapp\\.local$"
       line: "127.0.0.1 myapp.local"
   ```

> [!important] **Testing idempotency:** Jalankan playbook dua kali. Jika hasil kedua ada `changed` (selain handler yang memang perlu restart), berarti ada module yang tidak idempotent. Gunakan `--check --diff` dulu sebelum apply.

---

## 16. Ansible Strategies — Delegation, Serial, Throttle

Ansible secara default menjalankan task **parallel ke semua host** dalam satu batch. Tapi production sering butuh kontrol lebih.

### `serial` — Rolling Update

```yaml
- name: Rolling update web servers — 1 server at a time
  hosts: web
  serial: 1          # atau serial: "20%" untuk 20% host tiap batch
  tasks:
    - name: Stop service
      systemd:
        name: nginx
        state: stopped
    - name: Update binary
      copy:
        src: /build/app-latest
        dest: /usr/local/bin/app
    - name: Start service
      systemd:
        name: nginx
        state: started
      register: result
    - name: Health check sebelum lanjut
      uri:
        url: "http://{{ ansible_host }}/health"
        status_code: 200
      register: health
      until: health.status == 200
      retries: 5
      delay: 3
```

Dengan `serial: 1`, Ansible deploy ke satu server → health check → baru lanjut server berikutnya. Zero-downtime deployment.

### `run_once` — Task yang Cukup Sekali

```yaml
- name: Buat database — cukup 1x meski ada 3 db host
  postgresql_db:
    name: myapp
    state: present
  run_once: yes
  delegate_to: "{{ groups.db[0] }}"  # jalan di host pertama group db

- name: Generate shared secret
  shell: openssl rand -base64 32
  run_once: yes
  register: shared_secret
```

### `delegate_to` — Jalankan di Host Lain

```yaml
- name: Register IP ke DNS — jalankan dari localhost
  uri:
    url: "https://api.cloudflare.com/client/v4/zones/{{ zone_id }}/dns_records"
    method: POST
    body: '{"type":"A","name":"{{ inventory_hostname }}","content":"{{ ansible_default_ipv4.address }}"}'
  delegate_to: localhost

- name: Notifikasi Slack
  slack:
    token: "{{ slack_token }}"
    msg: "Deploy selesai: {{ inventory_hostname }}"
  delegate_to: localhost
```

### `throttle` — Batasi Concurrency per Task

```yaml
- name: Restart service — jangan semua host barengan
  systemd:
    name: myapp
    state: restarted
  throttle: 3     # max 3 host bersamaan
```

Berguna untuk tasks yang berat (reboot, DB migration, pulling large Docker images). Bedanya dengan `serial`: `throttle` membatasi satu task, `serial` membatasi seluruh playbook per batch.

### Strategy Plugin

```yaml
- hosts: all
  strategy: free    # tiap host jalan sendiri — gak nunggu host lain
  tasks:
    - command: /opt/long-task.sh
```

Strategies lain: `linear` (default — nunggu semua host selesai task sebelum lanjut), `free` (masing-masing host independen), `debug` (step-by-step). Paling sering dipakai tetap `linear` untuk prediktabilitas.

---

## 17. Full Workflow — Terraform Plan → Apply → Ansible

Workflow produksi yang recommended:

```bash
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│  Terraform   │ ──► │  Manual      │ ──► │  Terraform       │ ──► │  Generate      │
│  plan -out=  │     │  Approve     │     │  apply tfplan    │     │  Inventory     │
└──────────────┘     └──────────────┘     └──────────┬───────┘     └───────┬────────┘
                                                      │                     │
                                                      ▼                     ▼
                                                ┌──────────────────────────────┐
                                                │  ansible-playbook site.yml   │
                                                │  -i dynamic_inventory.json   │
                                                └──────────────────────────────┘
```

### CI/CD Separation

```yaml
# .github/workflows/deploy.yml — GitHub Actions
jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: terraform plan -out=tfplan   # Always run plan

  approve:
    needs: plan
    runs-on: ubuntu-latest
    environment: production               # GitHub Environments — manual approval
    steps:
      - run: echo "Approved by ${{ github.actor }}"

  apply:
    needs: approve
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Terraform Apply
        run: terraform apply tfplan
      - name: Generate Dynamic Inventory
        run: |
          terraform output -json > /tmp/tf_output.json
          ./scripts/generate_inventory.py /tmp/tf_output.json > inventory.json
      - name: Ansible Playbook
        run: ansible-playbook -i inventory.json site.yml -v
```

**Kenapa manual approve?** Terraform bisa destroy/create resource berbayar. Automated apply = risiko biaya membengkak atau data hilang. `terraform plan` read-only → safe di CI. `terraform apply` butuh human eyes.

### Dynamic Inventory Script

```python
#!/usr/bin/env python3
# scripts/generate_inventory.py
import json, sys

tf = json.load(sys.stdin)
inventory = {
    "web": {
        "hosts": {},
        "vars": {"ansible_user": "ubuntu"}
    },
    "db": {
        "hosts": {},
        "vars": {"ansible_user": "ubuntu"}
    }
}
for ip in tf.get("web_ip", {}).get("value", []):
    inventory["web"]["hosts"][ip] = {}
print(json.dumps(inventory, indent=2))
```

---

## 18. OpenTofu — Fork Open Source Terraform

OpenTofu adalah fork open-source Terraform yang lahir dari peristiwa HashiCorp pindah ke BSL (Business Source License) di Agustus 2023. Lisensi saat ini: MPL 2.0 (true open source).

### Migrasi dari Terraform

```bash
# Install OpenTofu
# curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh

# Migrasi — cukup ganti binary
alias terraform='tofu'

# Atau setup alias permanen
echo 'alias terraform="tofu"' >> ~/.bashrc

# Inisialisasi ulang provider
tofu init -migrate-state   # migrate state jika ada

# Semua command identik
tofu init
tofu plan
tofu apply
```

### Kompatibilitas Saat Ini

- **HCL syntax**: 100% kompatibel — file `.tf` yang sama bisa dipakai Terraform dan OpenTofu
- **Provider registry**: Sama — gunakan source `hashicorp/aws`, `digitalocean/digitalocean`, dll
- **State format**: Kompatibel — bisa switch antara Terraform dan OpenTofu
- **CLI flags**: Sebagian besar identik dengan tambahan fitur eksklusif OpenTofu
- **Backend**: S3, GCS, Azurerm, etc — semua support

### Fitur Eksklusif OpenTofu

- **Client-side encryption** untuk state file (end-to-end, provider gak bisa lihat state)
- **`tofu test`** — built-in test framework (belum ada di Terraform)
- **Provider caching** yang lebih agresif
- **`.tofu/` directory** sebagai alternatif `.terraform/` untuk provider lock

> [!tip] **Kapan migrasi?** Jika tim butuh fitur eksklusif (client-side encryption, testing). Jika masih comfortable dengan Terraform, belum urgent — HashiCorp tetap maintain Terraform. Tapi untuk project open-source, OpenTofu recommended agar lisensi tetap MPL 2.0.

---

## 19. Terragrunt — DRY Patterns untuk Multi-Environment

Terragrunt by Gruntwork adalah thin wrapper yang membuat Terraform lebih DRY (Don't Repeat Yourself). Solusi untuk masalah duplikasi di directory-per-environment.

### Install

```bash
# Via binary
curl -Lo /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64
chmod +x /usr/local/bin/terragrunt
```

### Struktur dengan Terragrunt

```
live/
├── terragrunt.hcl              # Root config — semua environment inherit
├── dev/
│   ├── vpc/
│   │   └── terragrunt.hcl      # Panggil module vpc
│   ├── ecs/
│   │   └── terragrunt.hcl      # Panggil module ecs
│   └── rds/
│       └── terragrunt.hcl
├── staging/
│   └── ... (inherits root config)
└── production/
    └── ... (inherits root config + override)
```

### Dependency Blocks

```hcl
# production/vpc/terragrunt.hcl
terraform {
  source = "../../modules/vpc"
}

inputs = {
  vpc_cidr = "10.0.0.0/16"
  env      = "production"
}

# production/rds/terragrunt.hcl
terraform {
  source = "../../modules/rds"
}

dependency "vpc" {
  config_path = "../vpc"        # otomatis baca state VPC

  mock_outputs = {
    vpc_id     = "mock-vpc-id"
    subnet_ids = ["mock-subnet-1", "mock-subnet-2"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.subnet_ids
}
```

Dengan mock_outputs, `terragrunt plan` tetap jalan meski VPC belum di-apply.

### before_hook / after_hook

```hcl
# root terragrunt.hcl
terraform {
  before_hook "check_ov" {
    commands     = ["apply", "plan"]
    execute      = ["op", "run", "--", "echo", "1Password session OK"]
    run_on_error = false        # gagal kalau 1Password gak jalan
  }

  after_hook "generate_inventory" {
    commands     = ["apply"]
    execute      = ["python3", "scripts/generate_inventory.py"]
  }
}
```

Hooks powerful untuk: inject secrets via 1Password sebelum apply, cleanup resources, generate inventory otomatis, slack notification.

### Perintah Terragrunt

```bash
# Apply semua resource di semua environment
terragrunt run-all apply

# Hanya environment tertentu
cd production/vpc && terragrunt apply

# Dry-run semua
terragrunt run-all plan

# Destroy — hati-hati!
terragrunt run-all destroy
```

> [!tip] Terragrunt + directory-per-environment adalah standar enterprise yang paling mature. Gunakan root `terragrunt.hcl` untuk backend config, provider version, dan hooks. Setiap child hanya define source module + inputs + dependencies.

---

## 20. Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[ansible-hardening-rocky-linux-9]] | Ansible untuk hardening spesifik Rocky Linux — catatan ini general-purpose |
| [[cicd-github-actions-praktik]] | CI/CD pipeline — Terraform apply otomatis dari pipeline |
| [[linux-hardening-audit-praktis]] | Ansible bisa otomasi semua hardening di catatan itu |
| [[hardening-setup]] | Hardening VPS — bisa di-ansible-kan |
| [[cicd-guide]] | CI/CD konseptual — link ke deployment pipeline |
| [[infrastructure-administrator]] | Admin tasks — IaC adalah subset administrasi modern |

## References

1. Terraform Documentation — https://developer.hashicorp.com/terraform/docs
2. Terraform Best Practices — https://developer.hashicorp.com/terraform/language/state
3. Ansible Documentation — https://docs.ansible.com/ansible/latest/index.html
4. Ansible Best Practices — https://docs.ansible.com/ansible/latest/tips_ansible_vault.html
5. Integrasi Terraform + Ansible — https://developer.hashicorp.com/terraform/tutorials/provision/ansible
6. Ansible Galaxy — https://galaxy.ansible.com/
7. OpenTofu (Terraform fork) — https://opentofu.org/
---

audited
---
