---
tags:
  - ansible
  - hardening
  - rocky-linux
  - security
  - homelab
created: 2026-06-07
updated: "2026-07-01"
status: Complete
title: Ansible Hardening Rocky Linux 9
---

# Ansible Hardening — Rocky Linux 9

> **Goal:** 1 playbook = full hardening, 5 menit, skor Lynis 85/100.

---

## 0. Prerequisites

| Node            | IP              | Role         | OS            |
| --------------- | --------------- | ------------ | ------------- |
| ansible-control | 192.168.130.128 | Control node | Ubuntu 24.04  |
| rocky           | 192.168.130.129 | Managed node | Rocky Linux 9 |

Di Ubuntu

```
ssh-keygen -t ed25519 -C "ansible-control"
ssh-copy-id -i ~/.ssh/id_ed25519.pub rocky@192.168.130.129
```

**SSH key auth:** Control node → Rocky (passwordless)

```bash
# Di control node, verify
ssh rocky@192.168.130.129 "echo 'SSH OK'"
```

---

## 1. One-Paste: Create All Files

**Run di control node (Ubuntu):**

```bash
mkdir -p ~/ansible-hardening && cd ~/ansible-hardening

mkdir -p roles/{bootstrap,hardening}/{tasks,templates,handlers}
mkdir -p group_vars lynis-reports
```

### 1.1 ansible.cfg

```bash
cat > ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory.ini
host_key_checking = False
timeout = 30
retry_files_enabled = False
interpreter_python = auto_silent
log_path = ./ansible.log
roles_path = ./roles

[privilege_escalation]
become = False
become_method = sudo
become_user = root

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
EOF
```

### 1.2 inventory.ini

```bash
cat > inventory.ini << 'EOF'
[control]
ubuntu ansible_host=127.0.0.1 ansible_connection=local ansible_user=ubuntu-host

[nodes]
rocky ansible_host=192.168.130.129 ansible_user=rocky

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
```

### 1.3 group_vars/all.yml

```bash
cat > group_vars/all.yml << 'EOF'
---
ssh_port: 22
ssh_users:
  - rocky
fail2ban_bantime: 3600
fail2ban_maxretry: 3
EOF
```

### 1.4 site.yml (Entry Point)

```bash
cat > site.yml << 'EOF'
---
- name: Bootstrap Rocky Linux 9
  hosts: nodes
  become: yes
  roles:
    - bootstrap
  tags: bootstrap

- name: Harden Rocky Linux 9
  hosts: nodes
  become: yes
  roles:
    - hardening
  tags: hardening
EOF
```

### 1.5 lynis-scan.yml (Audit)

```bash
cat > lynis-scan.yml << 'EOF'
---
- name: Run Lynis audit
  hosts: nodes
  become: yes
  tasks:
    - name: Remove old report
      ansible.builtin.file:
        path: /var/log/lynis-report.dat
        state: absent

    - name: Run Lynis audit
      ansible.builtin.command: lynis audit system --quick
      register: lynis_output
      changed_when: false

    - name: Show hardening index
      ansible.builtin.debug:
        msg: "{{ lynis_output.stdout | regex_search('Hardening index.*') }}"
EOF
```

---

## 2. Bootstrap Role (Install Packages)

### 2.1 roles/bootstrap/tasks/main.yml

```bash
cat > roles/bootstrap/tasks/main.yml << 'EOF'
---
- name: Enable EPEL repository
  ansible.builtin.dnf:
    name: epel-release
    state: present

- name: Install base tools
  ansible.builtin.dnf:
    name:
      - vim
      - curl
      - wget
      - htop
      - net-tools
      - bash-completion
      - git
    state: present

- name: Install security tools
  ansible.builtin.dnf:
    name:
      - lynis
      - aide
      - rkhunter
      - fail2ban
      - audit
      - psacct
      - sysstat
    state: present

- name: Ensure services enabled (stopped, save RAM)
  ansible.builtin.service:
    name: "{{ item }}"
    enabled: yes
    state: stopped
  loop:
    - fail2ban
    - psacct
    - sysstat
  ignore_errors: yes

- name: Install Docker CE repo
  ansible.builtin.yum_repository:
    name: docker-ce-stable
    description: Docker CE Stable
    baseurl: https://download.docker.com/linux/centos/$releasever/$basearch/stable
    gpgcheck: yes
    gpgkey: https://download.docker.com/linux/centos/gpg
    enabled: yes

- name: Install Docker CE
  ansible.builtin.dnf:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-compose-plugin
    state: present

- name: Add rocky to docker group
  ansible.builtin.user:
    name: rocky
    groups: docker
    append: yes
EOF
```

---

## 3. Hardening Role (Config & Lockdown)

### 3.1 Main Task Loader

```bash
cat > roles/hardening/tasks/main.yml << 'EOF'
---
- include_tasks: ssh.yml
- include_tasks: fail2ban.yml
- include_tasks: auditd.yml
- include_tasks: aide.yml
- include_tasks: sysctl.yml
- include_tasks: pam.yml
EOF
```

### 3.2 SSH Hardening

```bash
cat > roles/hardening/tasks/ssh.yml << 'EOF'
---
- name: Deploy hardened sshd_config
  ansible.builtin.template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    owner: root
    group: root
    mode: '0600'
    backup: yes
  notify: Restart sshd

- name: Ensure sshd enabled
  ansible.builtin.service:
    name: sshd
    state: started
    enabled: yes
EOF
```

### 3.3 Fail2ban

```bash
cat > roles/hardening/tasks/fail2ban.yml << 'EOF'
---
- name: Install fail2ban
  ansible.builtin.dnf:
    name: fail2ban
    state: present

- name: Deploy jail config
  ansible.builtin.template:
    src: fail2ban-jail.local.j2
    dest: /etc/fail2ban/jail.local
    owner: root
    group: root
    mode: '0644'
  notify: Restart fail2ban

- name: Ensure fail2ban enabled
  ansible.builtin.service:
    name: fail2ban
    state: started
    enabled: yes
EOF
```

### 3.4 Auditd

```bash
cat > roles/hardening/tasks/auditd.yml << 'EOF'
---
- name: Install audit
  ansible.builtin.dnf:
    name: audit
    state: present

- name: Deploy audit rules
  ansible.builtin.template:
    src: audit.rules.j2
    dest: /etc/audit/rules.d/hardening.rules
    owner: root
    group: root
    mode: '0600'
  notify: Restart auditd

- name: Ensure auditd enabled
  ansible.builtin.service:
    name: auditd
    state: started
    enabled: yes
EOF
```

### 3.5 AIDE

```bash
cat > roles/hardening/tasks/aide.yml << 'EOF'
---
- name: Install AIDE
  ansible.builtin.dnf:
    name: aide
    state: present

- name: Initialize AIDE database
  ansible.builtin.command: aide --init
  args:
    creates: /var/lib/aide/aide.db.gz
  ignore_errors: yes

- name: Move AIDE database
  ansible.builtin.command: mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
  args:
    creates: /var/lib/aide/aide.db.gz
  ignore_errors: yes

- name: Daily AIDE cron
  ansible.builtin.cron:
    name: "AIDE daily check"
    minute: "0"
    hour: "3"
    job: "/usr/sbin/aide --check | mail -s 'AIDE Check $(hostname)' root@localhost"
    state: present
EOF
```

### 3.6 Sysctl

```bash
cat > roles/hardening/tasks/sysctl.yml << 'EOF'
---
- name: Deploy sysctl hardening
  ansible.builtin.template:
    src: sysctl-hardening.conf.j2
    dest: /etc/sysctl.d/99-hardening.conf
    owner: root
    group: root
    mode: '0644'
  notify: Reload sysctl

- name: Apply sysctl immediately
  ansible.builtin.command: sysctl --system
  changed_when: true
EOF
```

### 3.7 PAM

```bash
cat > roles/hardening/tasks/pam.yml << 'EOF'
---
- name: Select authselect profile
  ansible.builtin.command: authselect select sssd --force
  changed_when: true
  ignore_errors: yes

- name: Enable faillock
  ansible.builtin.command: authselect enable-feature with-faillock
  changed_when: true
  ignore_errors: yes

- name: Enable pwhistory
  ansible.builtin.command: authselect enable-feature with-pwhistory
  changed_when: true
  ignore_errors: yes

- name: Apply authselect
  ansible.builtin.command: authselect apply-changes
  changed_when: true

- name: Configure pwquality
  ansible.builtin.lineinfile:
    path: /etc/security/pwquality.conf
    regexp: "^{{ item.key }}"
    line: "{{ item.key }} = {{ item.value }}"
  loop:
    - { key: "minlen", value: "12" }
    - { key: "minclass", value: "3" }
    - { key: "maxrepeat", value: "2" }
    - { key: "gecoscheck", value: "1" }

- name: Configure faillock
  ansible.builtin.lineinfile:
    path: /etc/security/faillock.conf
    regexp: "^{{ item.key }}"
    line: "{{ item.key }} = {{ item.value }}"
  loop:
    - { key: "deny", value: "5" }
    - { key: "fail_interval", value: "900" }
    - { key: "unlock_time", value: "600" }
    - { key: "even_deny_root", value: "true" }

- name: Set password expiration
  ansible.builtin.command: chage -M 90 -m 1 -W 7 rocky
  changed_when: true
EOF
```

---

## 4. Templates

### 4.1 sshd_config.j2

```bash
cat > roles/hardening/templates/sshd_config.j2 << 'EOF'
# {{ ansible_managed }}
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

Port {{ ssh_port | default(22) }}
AddressFamily any
ListenAddress 0.0.0.0

SyslogFacility AUTHPRIV
LogLevel VERBOSE

LoginGraceTime 60
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
MaxAuthTries 3
MaxSessions 2

ClientAliveInterval 200
ClientAliveCountMax 2
TCPKeepAlive no

AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no

AllowUsers {{ ssh_users | join(' ') }}

AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

Subsystem sftp /usr/libexec/openssh/sftp-server
EOF
```

### 4.2 fail2ban-jail.local.j2

```bash
cat > roles/hardening/templates/fail2ban-jail.local.j2 << 'EOF'
[DEFAULT]
bantime = {{ fail2ban_bantime | default(3600) }}
findtime = 600
maxretry = {{ fail2ban_maxretry | default(3) }}
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/secure
maxretry = {{ fail2ban_maxretry | default(3) }}
bantime = {{ fail2ban_bantime | default(3600) }}
EOF
```

### 4.3 audit.rules.j2

```bash
cat > roles/hardening/templates/audit.rules.j2 << 'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /var/log/lastlog -p wa -k logins
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -S setresuid -S setresgid -k privilege_escalation
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=-1 -k file_deletion
-a always,exit -F arch=b64 -S mount -S umount2 -k mount_ops
-w /sbin/insmod -p x -k kernel_modules
-w /sbin/rmmod -p x -k kernel_modules
-w /sbin/modprobe -p x -k kernel_modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k kernel_modules
EOF
```

### 4.4 sysctl-hardening.conf.j2

```bash
cat > roles/hardening/templates/sysctl-hardening.conf.j2 << 'EOF'
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 3 3 3
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 1
kernel.sysrq = 0
fs.suid_dumpable = 0
vm.mmap_rnd_bits = 32
vm.mmap_rnd_compat_bits = 16
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
net.core.bpf_jit_harden = 2
dev.tty.ldisc_autoload = 0
fs.protected_fifos = 2
fs.protected_regular = 2
EOF
```

---

## 5. Handlers

```bash
cat > roles/hardening/handlers/main.yml << 'EOF'
---
- name: Restart sshd
  ansible.builtin.service:
    name: sshd
    state: restarted

- name: Restart fail2ban
  ansible.builtin.service:
    name: fail2ban
    state: restarted

- name: Restart auditd
  ansible.builtin.service:
    name: auditd
    state: restarted

- name: Reload sysctl
  ansible.builtin.command: sysctl --system
  changed_when: false
EOF
```

---

## 6. Execution

### 6.1 Syntax Check

```bash
cd ~/ansible-hardening
ansible-playbook -i inventory.ini site.yml --syntax-check
```

### 6.2 Dry Run

```bash
ansible-playbook -i inventory.ini site.yml --check -K
```

### 6.3 Real Run (Bootstrap + Hardening)

```bash
ansible-playbook -i inventory.ini site.yml -K
```

### 6.4 Lynis Audit

```bash
ansible-playbook -i inventory.ini lynis-scan.yml -K
```

---

## 7. Results

| Metric                         | Value                     |
| ------------------------------ | ------------------------- |
| Baseline Lynis                 | 67/100                    |
| Manual hardening (6 jam)       | 83/100                    |
| **Ansible playbook (5 menit)** | **85/100**                |
| Time saved                     | ~6 jam → 5 menit          |
| Reproducible                   | ✅ 1, 20, atau 100 server |

---

## 8. File Tree

```
ansible-hardening/
├── ansible.cfg
├── inventory.ini
├── site.yml
├── lynis-scan.yml
├── group_vars/
│   └── all.yml
├── lynis-reports/
└── roles/
    ├── bootstrap/
    │   └── tasks/
    │       └── main.yml
    └── hardening/
        ├── tasks/
        │   ├── main.yml
        │   ├── ssh.yml
        │   ├── fail2ban.yml
        │   ├── auditd.yml
        │   ├── aide.yml
        │   ├── sysctl.yml
        │   └── pam.yml
        ├── handlers/
        │   └── main.yml
        └── templates/
            ├── sshd_config.j2
            ├── fail2ban-jail.local.j2
            ├── audit.rules.j2
            └── sysctl-hardening.conf.j2
```

---

## 9. Next Steps

| Phase                 | Role                     | Status      |
| --------------------- | ------------------------ | ----------- |
| Bootstrap + Hardening | `bootstrap`, `hardening` | ✅ Complete |
| Docker deployment     | `docker`                 | ⏳ Planned  |
| Application stack     | `nextcloud`, `wordpress` | ⏳ Planned  |
| Monitoring            | `prometheus`, `wazuh`    | ⏳ Planned  |
| Multi-node scale      | Dynamic inventory        | ⏳ Planned  |

---

_Created: 2026-06-07_
_Status: Production-ready baseline_
