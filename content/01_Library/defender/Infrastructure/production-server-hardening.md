---
title: Production Server Hardening
tags: [security, hardening, infrastructure]
aliases: [production-server-hardening]
---
# Production Server Hardening

Hardening = mengurangi permukaan serangan server produksi: konfigurasi aman, update terjadwal, akses minimal, monitoring. Berlaku untuk Linux server (bare metal/VM/cloud) yang melayani internet atau data sensitif.

## 1. OS & Update

- **Distro LTS dengan support jelas**: RHEL/Alma/Rocky (10 tahun), Debian (5+), Ubuntu LTS (5-12 tahun) — pilih satu, standarisasi.
- **Update terjadwal**: `dnf update`/`apt upgrade` rutin; critical (CISA KEV) ≤ 48 jam; high ≤ 7 hari; medium ≤ 30 hari; otomasi (unattended-upgrades untuk security saja — hati-hati; atau patch window).
- **Kernel**: ikuti kernel LTS/stable + security patches; jangan kernel "latest mainline" di produksi.
- **Firmware**: BIOS/UEFI update terjadwal (vendor advisory) — banyak CVE BMC/firmware (lihat Firmware_RE).

## 2. Akses & Authentication

- **SSH**:
  - `PermitRootLogin no`, `PasswordAuthentication no` (key-only).
  - Key ed25519 (4096 RSA legacy); passphrase + agent.
  - `AllowUsers`/`AllowGroups` whitelist; `MaxAuthTries 3`; `LoginGraceTime 30`.
  - Fail2ban (atau rate limit di proxy/firewall) untuk brute force.
  - `sshd_config`: `Protocol 2`, `X11Forwarding no`, `AllowTcpForwarding yes` (jika perlu, batasi), `ClientAliveInterval 300`.
- **MFA** untuk admin (TOTP/U2F) — akses SSH via jump host/bastion dengan MFA.
- **Sudo**: `NOPASSWD` hanya untuk user service tertentu; log semua sudo (auditd/rsyslog).

## 3. Firewall & Network

- **Default deny inbound**: hanya port yang dibutuhkan (80/443 via proxy; 22 dari admin IP).
- **Egress restrict**: DNS, NTP, package repo, monitoring; blokir lainnya (default allow = risk).
- **nftables/firewalld**: stateful rules; rate limit ICMP.
- **Port scan protection** (opsional): knock/port knocking? — hindari (kompleks); cukup firewall + fail2ban.
- Segmentation: DMZ untuk service publik; internal network terpisah; database/backup di segmen tertutup.
- **IPv6**: konfigurasi aman (jangan lupa — sering terlewat: firewall IPv6 default open).

## 4. File & Service Hardening

- **File permissions**: `/etc/shadow` 640 root; no world-writable dirs tanpa sticky bit; cek `find / -perm -002` sesekali.
- **umask 027** untuk service user.
- **Services**: matikan service tidak perlu (systemd enable list audit); container service di-restrict (lihat [[container-security-exploitation-deepdive]]).
- **Binary/service hardening**:
  - systemd unit: `NoNewPrivileges=true`, `ProtectSystem=strict`, `PrivateTmp=true`, `ProtectHome=true`, `ReadWritePaths` minimal, `CapabilityBoundingSet` minimal, `MemoryMax`/`LimitNOFILE`.
  - AppArmor/SELinux: enforce policy (jangan permissive forever).
  - Seccomp: default (systemd sudah), atau profile custom.
- **Kernel hardening** (sysctl):
```ini
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 2
kernel.unprivileged_bpf_disabled = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
```

## 5. Monitoring & Audit

- **Fleet**: inventory (semua server), version, patch status (spacewalk/foreman/ansible), drift detection.
- **Log**: central (rsyslog/syslog-ng → SIEM/ELK); logrotate retention (30-90 hari); auditd untuk sensitive files (shadow, sudoers, systemd).
- **Metrics**: node_exporter + Prometheus; alert (CPU, mem, disk, error rate, service down).
- **Uptime/health**: ping/ICMP + HTTP health (blackbox).
- **Intrusion detection**: file integrity (AIDE/tripwire) untuk binari & config kritis; host IDS (Wazuh/OSSEC) opsional; Falco (container).

## 6. Backup & Recovery

- 3-2-1 (3 copies, 2 media, 1 offsite); backup DB + config; encrypted (age/gpg/KMS).
- Restore test BULANAN (bukan cuma "backup jalan").
- Documented RTO/RPO; DR drill tahunan.
- Backup terpisah dari produksi (network isolation — ransomware target backup).

## 7. Aplikasi & Runtime

- Aplikasi jalan non-root; service user dedicated.
- Web: TLS 1.2+ (lihat [[wiod-reverse-proxy-deepdive]] hardening headers), HSTS.
- DB: bind 127.0.0.1/internal (bukan 0.0.0.0), auth kuat, SSL, backup terjadwal.
- PHP/Node/Java: versi didukung (EOL = risk), runtime hardening (open_basedir, disable_functions? — sesuai kebutuhan).
- Application secrets: secret manager (lihat [[sealed-secrets-vs-vault]]) — bukan .env di disk sembarangan (atau enkripsi + perms 600).
- Log rotation jangan sampai mengisi disk (logrotate + alert disk 80%).

## 8. Physical & Cloud

- **Cloud**: IAM role (bukan long-term keys di server); security groups (default deny); IMDSv2 (AWS) — instance metadata protection; block public S3; VPC flow logs.
- **Bare metal**: BIOS password, secure boot, disable unused ports, BMC (iLO/iDRAC) — network tersendiri + MFA + patch (lihat [[security-economics-cost-of-breach]] untuk alasan biaya).

## Checklist Audit (CIS-aligned)

- [ ] SSH: no root, key-only, MFA via bastion
- [ ] Firewall default deny + egress restrict
- [ ] Systemd hardening: NoNewPrivileges, ProtectSystem, cap bounds
- [ ] SELinux/AppArmor enforce
- [ ] Sysctl hardening terpasang
- [ ] Update SLA jalan (critical 48h)
- [ ] Monitoring: metrics + logs centralized + alert
- [ ] Backup 3-2-1 + restore test terbaru
- [ ] Auditd/file integrity aktif
- [ ] Aplikasi non-root, TLS, DB internal
- [ ] Cloud: IAM role, IMDSv2, security group audit



## Contoh: systemd Service Hardening (Unit File)

```ini
[Service]
User=app
Group=app
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=true
LockPersonality=true
MemoryDenyWriteExecute=true
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
SystemCallFilter=@system-service
RestrictSUIDSGID=true
```
Test: `systemd-analyze security <unit>` — skor exposure turun drastis.

## Contoh: Audit Command (Quick Checks)

```bash
# open ports
ss -tlnp
# world-writable tanpa sticky
find / -xdev -type d -perm -0002 ! -perm -1000 -print 2>/dev/null
# SUID binaries (audit list)
find / -xdev -type f -perm -4000 -ls
# listening services & user
ss -tulpn
# recent auth failures
journalctl -u sshd --since today | grep -i failed | head
# cron jobs
ls -la /etc/cron* /var/spool/cron 2>/dev/null
# sudoers review
sudo -l -U <user>
# mounted filesystems (noexec options?)
mount | grep -E " /(home|tmp|var)"
```

## Pemulihan (Recovery) setelah Insiden

1. Isolasi host (network block) — jangan langsung reboot (forensik).
2. Snapshot memory/disk (jika forensik dibutuhkan — lihat Data_Forensics).
3. Verifikasi integritas: AIDE/package verify (`rpm -Va`/`dpkg -V`).
4. Cari backdoor: new SUID, sshd_config aneh, cron, systemd unit baru, LD_PRELOAD.
5. Restore dari backup terpercaya (bukan "bersihkan" manual) — rebuild lebih aman.
6. Rotate semua credential yang mungkin terpapar.
7. Postmortem + hardening gap analysis.

---

  audited
---