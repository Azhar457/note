---
title: Ansible Hardening Rocky Linux 9 — Automasi CIS Benchmark + Lynis Tracker
tags:
  - infrastructure
  - devops
  - ansible
  - hardening
  - rockylinux9
  - cis-benchmark
  - lynis
  - homelab
aliases:
  - Rocky Linux Hardening Ansible
  - CIS Rocky 9 Automation
created: "2026-07-19"
updated: "2026-07-19"
status: active
---

> [!abstract] Ringkasan
> Catatan ini menjelaskan cara **meng-hardening server Rocky Linux 9** secara otomatis menggunakan **Ansible** dengan rule mengikuti **CIS Benchmark Level 1 / Level 2**. Dilengkapi dengan **Lynis** sebagai tracker auditing pasca-deploy, plus integrasi CI/CD untuk enforcement di setiap provisioning. Pendekatan ini subject untuk homelab dan VPS produksi (lihat [[homelab-security-architecture-synthesis]]).

## Daftar Isi

1. [Mengapa Otomasi Hardening?](#mengapa-otomasi-hardening)
2. [Prasyarat](#prasyarat)
3. [Arsitektur Playbook](#arsitektur-playbook)
4. [Implementasi Step-by-Step](#implementasi-step-by-step)
5. [Role-Ansible Detail](#role-ansible-detail)
6. [Integrasi Lynis untuk Tracking](#integrasi-lynis-untuk-tracking)
7. [CI/CD Enforcement](#cicd-enforcement)
8. [Verifikasi & Rollback](#verifikasi--rollback)
9. [Pitfalls](#pitfalls)
10. [Catatan Terkait](#catatan-terkaitan)

---

## Mengapa Otomasi Hardening?

| Pendekatan                                  | Pro                                       | Kontra                                                    |
| ------------------------------------------- | ----------------------------------------- | --------------------------------------------------------- |
| **Manual**                                  | Bisa detail per-host                      | Tidak reproducible. Drift antar server setelah 2-3 bulan. |
| **Bash script ad-hoc**                      | Cepat ditulis                             | Tidak ada idempotency. State drift susah dilacak.         |
| **Ansible (rekomendasi)**                   | Idempotent, versioned di git, declarative | Butuh initial learning curve                              |
| **Config Management lengkap (Puppet/Salt)** | Powerful, real-time                       | Overkill untuk ≤ 50 server. Setup cost besar.             |

Untuk skala VPS-prod (≤ 10 instance) + homelab, **Ansible** sweet spot: setup 1-2 hari, maintain ringan.

---

## Prasyarat

| Komponen     | Versi                    | Catatan                                                          |
| ------------ | ------------------------ | ---------------------------------------------------------------- |
| Rocky Linux  | 9.x (latest)             | Target host. RHEL-9 clone.                                       |
| Ansible Core | 2.15+                    | Control node (laptop / CI-runner).                               |
| Python       | 3.9+                     | Default di Rocky 9.                                              |
| SSH access   | key-based, sudo NOPASSWD | Untuk user provisioner.                                          |
| Lynis        | 3.0+                     | Audit tool. Install via `dnf install lynis` atau GitHub release. |
| git          | 2.x+                     | Version control untuk playbook.                                  |

**Control node:** Bisa laptop Fedora 44 (cara lihat [[podman-networking-ufw]]) atau container khusus. Wajib satu network dengan target host (atau pakai `ansible_ssh_common_args` melalui bastion).

---

## Arsitektur Playbook

```
ansible-hardening-rocky/
├── ansible.cfg                 # Default inventory + remote_user
├── inventory/
│   ├── production.ini          # VPS prod ([REDACTED], dll)
│   └── homelab.ini             # Internal lab
├── group_vars/
│   ├── all.yml                 # Variabel global
│   ├── cis_level1.yml          # Override untuk level 1 server
│   └── cis_level2.yml          # Override untuk high-security
├── roles/
│   ├── cis_baseline/           # Rule wajib (L1)
│   ├── cis_hardened/           # Aturan agresif (L2)
│   ├── auditd_stig/            # Audit daemon + STIG rules
│   ├── ssh_hardening/          # SSH config secure
│   ├── firewall_base/          # Firewalld rules
│   ├── account_lockdown/       # Pam_faillock, password policy
│   └── lynis_tracker/          # Audit berkala + report diff
├── playbooks/
│   ├── site.yml                # Entry point: apply seluruh roles
│   ├── dryrun.yml              # ansible-playbook --check
│   └── audit_only.yml          # Hanya jalankan Lynis, no change
├── files/
│   ├── sshd_config.hardened
│   ├── password-quality.conf
│   └── audit.rules.stig
└── templates/
    └── issue.j2                # MOTD + legal warning
```

Pattern ini dipinjam dari `dev-sec/ansible-collection-hardening` (open source, MIT) tapi ditulis ulang agar **familiar dengan struktur vault**: setiap role punya README.md + testify dir.

---

## Implementasi Step-by-Step

### Step 1 — Setup Control Node

```bash
# Install ansible-core + dependencies di laptop Fedora
sudo dnf install ansible-core python3-jinja2 python3-pyyaml openssh-clients

# Verify
ansible --version  # Harus 2.15+
```

### Step 2 — Bootstrap SSH Key ke Target

```bash
# Asumsi host sudah punya user dengan sudo NOPASSWD
ssh-copy-id -i ~/.ssh/id_ed25519.pub provisioner@<target-ip>

# Test ansible ping
ansible all -i inventory/production.ini -m ping
# Expected: "pong" / success
```

### Step 3 — Tulis Inventory Minimal

```ini
# inventory/production.ini
[vps_prod]
[REDACTED] ansible_host=[VPS1_IP] ansible_user=provisioner
vps2-kuldi ansible_host=[KULDI_IP] ansible_user=provisioner

[vps_prod:vars]
ansible_become=true
ansible_become_method=sudo
ansible_python_interpreter=/usr/bin/python3
```

### Step 4 — First Run: Dry-Run

```bash
# Lihat apa yang akan berubah TANPA eksekusi
ansible-playbook -i inventory/production.ini playbooks/dryrun.yml --check --diff

# Output diff untuk sshd_config, pam.d/, firewalld, dll.
# Review, lalu...
```

### Step 5 — Apply Level 1

```bash
ansible-playbook -i inventory/production.ini playbooks/site.yml --tags cis_level1
```

### Step 6 — Verify dengan Lynis

```bash
ansible-playbook -i inventory/production.ini playbooks/audit_only.yml
# Output: laporan Lynis per host, disimpan di artifacts/lynis-<host>-<timestamp>.txt
```

---

## Role-Ansible Detail

| Role               | Tujuan                                                              | Tags     |
| ------------------ | ------------------------------------------------------------------- | -------- |
| `cis_baseline`     | CIS Level 1: partition, AIDE, disable unused services, sysctl       | `cis_l1` |
| `cis_hardened`     | CIS Level 2: SELinux enforcing, MAC, AppArmor strict                | `cis_l2` |
| `auditd_stig`      | Audit daemon + 50+ STIG rules dari DISA STIG profile                | `stig`   |
| `ssh_hardening`    | `sshd_config`: no root login, no password auth, MaxAuthTries 3, ... | `ssh`    |
| `firewall_base`    | Firewalld: default deny, allow 22/80/443 only                       | `fw`     |
| `account_lockdown` | pam_faillock (10 fail → lock 15 min), password minlen 14, history 5 | `pam`    |
| `lynis_tracker`    | Cron weekly Lynis scan + diff vs baseline                           | `audit`  |

### Contoh: Role `ssh_hardening`

```yaml
# roles/ssh_hardening/tasks/main.yml
- name: Backup sshd_config
  ansible.builtin.copy:
    src: /etc/ssh/sshd_config
    dest: /etc/ssh/sshd_config.backup-{{ ansible_date_time.date }}
    remote_src: true

- name: Deploy hardened sshd_config
  ansible.builtin.template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    owner: root
    group: root
    mode: "0600"
  notify: restart_sshd

- name: Regenerate host keys (ed25519 only)
  ansible.builtin.command: ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
  args:
    creates: /etc/ssh/ssh_host_ed25519_key
```

```jinja2
# roles/ssh_hardening/templates/sshd_config.j2
Port {{ ssh_port | default(22) }}
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries {{ ssh_max_auth_tries | default(3) }}
ClientAliveInterval {{ ssh_client_alive_interval | default(300) }}
ClientAliveCountMax {{ ssh_client_alive_count | default(2) }}
AllowGroups {{ ssh_allow_groups | default('ssh-users') }}
```

---

## Integrasi Lynis untuk Tracking

```yaml
# roles/lynis_tracker/tasks/main.yml
- name: Ensure lynis installed
  ansible.builtin.package:
    name: lynis
    state: present

- name: Run weekly Lynis audit
  ansible.builtin.cron:
    name: "lynis-weekly"
    minute: "30"
    hour: "4"
    weekday: "0"
    user: root
    job: >
      /usr/bin/lynis audit system --quiet --no-colors
      --report-file /var/log/lynis-report-$(date +\%Y\%m\%d).txt
      --logfile /var/log/lynis.log
  notify: lynis_audit_done

- name: Diff vs baseline
  ansible.builtin.shell: |
    lynis_baseline="/srv/lynis/baseline.txt"
    current="/var/log/lynis-report-$(date +%Y%m%d).txt"
    diff -u "$lynis_baseline" "$current" | tee /srv/lynis/diff-$(date +%Y%m%d).txt
  register: lynis_diff
  changed_when: "'Hardening index' in lynis_diff.stdout"
```

**Baseline awal:** Jalankan `lynis audit system` manual sekali, copy report-nya ke `/srv/lynis/baseline.txt` di semua host. Diff mingguan tunjukkan drift.

---

## CI/CD Enforcement

Pendekatan **principled**: setiap provisioning baru (VPS spin-up) wajib lulus pipeline.

```yaml
# .github/workflows/hardening-check.yml (contoh)
name: Hardening Compliance Check
on:
  schedule:
    - cron: "0 6 * * 1" # Senin 06:00 UTC

jobs:
  lynis-audit:
    runs-on: ubuntu-latest
    steps:
      - name: Lynis against target
        uses: ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: provisioner
          key: ${{ secrets.VPS_KEY }}
          script: |
            sudo lynis audit system --quiet --no-colors
            HARDENING=$(grep "Hardening index" /var/log/lynis.log | tail -1 | awk '{print $NF}')
            echo "Score=$HARDENING"
            if (( $(echo "$HARDENING < 75" | bc -l) )); then
              echo "::error::Hardening score below threshold!"
              exit 1
            fi
```

Skor target: **Lynis Hardening Index ≥ 75** (Level 1) atau **≥ 85** (Level 2).

---

## Verifikasi & Rollback

| Item                      | Expected                                       | Perintah                                           |
| ------------------------- | ---------------------------------------------- | -------------------------------------------------- |
| SSH login root            | **Gagal**                                      | `ssh root@<host>`                                  |
| SSH login dengan password | **Gagal**                                      | Test dengan `-o PreferredAuthentications=password` |
| Lynis Hardening Index     | ≥ 75                                           | `grep "Hardening index" /var/log/lynis.log`        |
| CIS sections "OK"         | ≥ 85%                                          | `lynis show details`                               |
| Auditd status             | active (running)                               | `systemctl status auditd`                          |
| Firewalld                 | default zone 'public', services 22/80/443 only | `firewall-cmd --list-all`                          |

**Rollback:**

```bash
# Restore dari backup sshd_config
sudo cp /etc/ssh/sshd_config.backup-$(date +%Y-%m-%d) /etc/ssh/sshd_config
sudo systemctl restart sshd

# Full re-provision via playbook idempotent (re-run akan menyamakan state)
ansible-playbook -i inventory/production.ini playbooks/site.yml
```

---

## Pitfalls

1. **Lock-out karena SSH hardening.** Jika salah setting `AllowGroups` atau `PasswordAuthentication no` tapi user belum ada SSH key → **terkunci**. Solusi: selalu `--check` dulu + buka konsol VPS sebelum apply.
2. **SELinux `enforcing` di production.** Bisa block service yang tidak expecting. Test di staging dulu, atau pakai `permissive` saat transisi, audit log, baru enforce.
3. **Lynis false positives.** "Suggestion" ≠ "Vulnerability". Beberapa suggestion Lynis seperti disable IPv6 tidak applicable untuk deployment tertentu. Always review manual.
4. **State drift setelah manual edit.** Admin lokal edit `/etc/ssh/sshd_config` langsung → besok playbook re-run overwrite. Solusi: ansible-pull cron, atau scheduled re-enforcement.
5. **`become: true` tanpa `become_method` explicit.** Default `sudo` bisa macet di distro yang disable `sudo`. Set `ansible_become_method=su` untuk fallback.

---

## Catatan Terkait

- [[linux-hardening-cis]] — Manual CIS baseline (precursor untuk automasi ini)
- [[homelab-security-architecture-synthesis]] — Contoh riset homelab yang bisa jadi target deployment
- [[podman-networking-ufw]] — Konteks networking host Fedora (control node)
- [[cicd-guide]] — Pattern CI/CD untuk enforcement hardening check
- [[observability-stack-prometheus-grafana]] — Observability stack pasca-hardening (auditd → Wazuh/Prometheus)
- [[hierarchy-it-domain]] — Atlas konteks Infrastructure domain
- [[obsidian-vault-padding|SOP Vault Padding]] — Pola penulisan catatan ringkas tapi dalam
