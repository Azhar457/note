---
title: "Lynis Hardening Tracker Rocky Linux 9"
tags:
  - original
aliases:
  - "lynis-hardening-tracker-rocky-linux-9"
created: "2026-06-06"
updated: "2026-07-01"
status: Ongoing — Day 2 Complete
---

# 🔒 Lynis Hardening Tracker — Rocky Linux 9

## Host Profile

| Item          | Value                       |
| ------------- | --------------------------- |
| Host          | rocky (192.168.130.129)     |
| OS            | Rocky Linux 9 (RHEL family) |
| Kernel        | `(isi dari uname -r)`       |
| Baseline Scan | 2026-06-06 20:00            |
| Current Scan  | 2026-06-06 21:37            |
| Target Score  | 90+                         |

---

## 📊 Score Progression

| Phase        | Date       | Score | Delta | Notes                                         |
| ------------ | ---------- | ----- | ----- | --------------------------------------------- |
| **Baseline** | 2026-06-06 | 67    | —     | Fresh install, minimal hardening              |
| **Day 1**    | 2026-06-06 | 69    | +2    | SSH lockdown, fail2ban, PAM policy            |
| **Day 2**    | 2026-06-06 | 74    | +5    | AIDE, rkhunter, auditd, kernel sysctl         |
| **Day 3**    | (planned)  | 80+   | +6    | SSH fine-tune, login.defs, umask, banners     |
| **Day 4**    | (planned)  | 85+   | +5    | Protocol disable, service cleanup, partitions |
| **Day 5**    | (planned)  | 90+   | +5    | External logging, final polish                |

---

## ✅ Completed Actions

### Day 1 — SSH Fortress + Intrusion Detection

- [x] SSH: `PermitRootLogin no`, `PasswordAuthentication no`, `AllowUsers rocky`
- [x] SSH: `MaxAuthTries 3`, `ClientAliveInterval 300`, `ClientAliveCountMax 2`
- [x] fail2ban: installed, sshd jail enabled, bantime 3600, maxretry 3
- [x] PAM: authselect sssd + faillock + pwhistory
- [x] PAM: pwquality `minlen=12`, `minclass=3`, `maxrepeat=2`

### Day 2 — Audit Trail + Kernel + File Integrity

- [x] AIDE: installed, database initialized, daily cron check
- [x] rkhunter: installed, updated, propupd, checked
- [x] auditd: installed, custom CIS rules loaded via `augenrules`
- [x] Kernel sysctl: `rp_filter`, `accept_redirects`, `send_redirects`, `log_martians`
- [x] Kernel sysctl: `kptr_restrict=2`, `dmesg_restrict=1`, `ptrace_scope=1`
- [x] Kernel sysctl: TCP hardening (`syncookies`, `syn_backlog`, `syn_retries`)

---

## 🎯 Remaining Suggestions (Prioritized)

### 🔴 High Impact — Easy Fix (Day 3 Target)

| Suggestion                        | File/Command                | Fix                                   |
| --------------------------------- | --------------------------- | ------------------------------------- |
| SSH `AllowTcpForwarding` → NO     | `/etc/ssh/sshd_config`      | `AllowTcpForwarding no`               |
| SSH `ClientAliveCountMax` 3→2     | `/etc/ssh/sshd_config`      | `ClientAliveCountMax 2`               |
| SSH `LogLevel` INFO→VERBOSE       | `/etc/ssh/sshd_config`      | `LogLevel VERBOSE`                    |
| SSH `MaxSessions` 10→2            | `/etc/ssh/sshd_config`      | `MaxSessions 2`                       |
| SSH `TCPKeepAlive` YES→NO         | `/etc/ssh/sshd_config`      | `TCPKeepAlive no`                     |
| SSH `X11Forwarding` YES→NO        | `/etc/ssh/sshd_config`      | `X11Forwarding no`                    |
| SSH `AllowAgentForwarding` YES→NO | `/etc/ssh/sshd_config`      | `AllowAgentForwarding no`             |
| Core dump disable                 | `/etc/security/limits.conf` | `* hard core 0`                       |
| Password age min/max              | `/etc/login.defs`           | `PASS_MIN_DAYS 1`, `PASS_MAX_DAYS 90` |
| Default umask strict              | `/etc/login.defs`           | `UMASK 027`                           |
| Legal banner `/etc/issue`         | `/etc/issue`                | Add warning text                      |
| Legal banner `/etc/issue.net`     | `/etc/issue.net`            | Add warning text                      |

### 🟡 Medium Impact — Requires Config

| Suggestion                         | Notes                              |
| ---------------------------------- | ---------------------------------- |
| PAM rounds for password hashing    | Add `rounds=5000` to `pam_unix.so` |
| Expire dates for all accounts      | `chage -M 90 -m 1 username`        |
| Remove locked accounts             | `userdel` untuk akun locked        |
| Split resolving localhost/hostname | Edit `/etc/hosts`                  |

### 🟢 Low Impact / Infrastructure Limitation

| Suggestion                 | Notes                                                           | Status         |
| -------------------------- | --------------------------------------------------------------- | -------------- |
| Separate `/home` partition | Requires reinstall/repartition                                  | 🔒 Blocked     |
| Separate `/tmp` partition  | Requires reinstall/repartition                                  | 🔒 Blocked     |
| Separate `/var` partition  | Requires reinstall/repartition                                  | 🔒 Blocked     |
| Disable USB storage        | `modprobe -r usb_storage`                                       | ⏸️ Optional    |
| Disable firewire storage   | `modprobe -r firewire_ohci`                                     | ⏸️ Optional    |
| Disable DCCP protocol      | `echo "install dccp /bin/true" >> /etc/modprobe.d/disable.conf` | ⏸️ Optional    |
| Disable SCTP protocol      | `echo "install sctp /bin/true" >> /etc/modprobe.d/disable.conf` | ⏸️ Optional    |
| Disable RDS protocol       | `echo "install rds /bin/true" >> /etc/modprobe.d/disable.conf`  | ⏸️ Optional    |
| Disable TIPC protocol      | `echo "install tipc /bin/true" >> /etc/modprobe.d/disable.conf` | ⏸️ Optional    |
| External logging host      | Butuh server log terpisah (rsyslog/Vector)                      | ⏸️ Future      |
| Check deleted files in use | `lsof +L1` untuk investigasi                                    | ⏸️ Investigasi |

## 🛠️ Quick Fix Commands (Day 3)

### SSH Fine-Tune

```bash
sudo tee -a /etc/ssh/sshd_config << 'EOF'

# Lynis Day 3 Hardening
AllowTcpForwarding no
ClientAliveCountMax 2
LogLevel VERBOSE
MaxSessions 2
TCPKeepAlive no
X11Forwarding no
AllowAgentForwarding no
EOF

sudo systemctl restart sshd
```

### Core Dump Disable

```bash
sudo tee -a /etc/security/limits.conf << 'EOF'
* hard core 0
EOF
```

### Login.defs

```bash
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sudo sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
```

### Banners

```bash
sudo tee /etc/issue << 'EOF'
***************************************************************************
*                                                                         *
*  WARNING: Unauthorized access to this system is prohibited and may result *
*  in criminal prosecution. All activities are monitored and logged.        *
*                                                                         *
***************************************************************************
EOF

sudo cp /etc/issue /etc/issue.net
```

### Protocol Disable

```bash
sudo tee /etc/modprobe.d/disable-protocols.conf << 'EOF'
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF
```

## 📁 Evidence Files

Table

| File          | Location                             | Description                          |
| :------------ | :----------------------------------- | :----------------------------------- |
| Baseline log  | `~/lynis-before.log`                 | Pre-hardening scan                   |
| Day 1 after   | `~/lynis-day1-after.log`             | SSH + fail2ban + PAM                 |
| Day 2 after   | `~/lynis-day2-after.log`             | AIDE + rkhunter + auditd + kernel    |
| Day 3 after   | `~/lynis-day3-after.log`             | (pending) SSH fine-tune + login.defs |
| AIDE database | `/var/lib/aide/aide.db.gz`           | File integrity baseline              |
| audit rules   | `/etc/audit/rules.d/hardening.rules` | Custom audit rules                   |
| sysctl config | `/etc/sysctl.d/99-hardening.conf`    | Kernel hardening                     |
| SSH config    | `/etc/ssh/sshd_config`               | SSH hardening                        |
| fail2ban jail | `/etc/fail2ban/jail.local`           | Intrusion detection                  |
