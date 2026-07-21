---
title: About
tags:
  - atlas
created: "2026-06-04"
updated: "2026-07-01"
status: active
---

# 👋 Hai, Saya Azhar Muttaqien

Mahasiswa **INFORMATIKA** di **Pasundan**, Bandung — yang entah bagaimana malah jatuh tertarik ke dunia CS, security research, dan low-level systems.

Bukan dari seorang ahli. Tapi dari rasa penasaran yang tidak berhenti.

Perjalanan belajarnya dimulai dari pertanyaan:
_"Apa sih software paling bagus buat recovery data?, atau jangan2 ada pendekatan lain?"_

## Apa yang Aku Pelajari

Bukan kurikulum formal. Lebih ke **peta besar yang dibangun sendiri** — dari nol, dari rasa penasaran.

```
💾 Data Recovery          → dari software sampai fisika kuantum
🦠 Endpoint Security      → dari antivirus sampai Intel ME Ring -3
🌐 Network Security       → dari Layer 1 sampai Layer 8 (manusia)
🤖 AI & Machine Learning  → dari IF-THEN sampai Omega Point
🔬 Reverse Engineering    → dari strings sampai FIB silicon edit
📡 RF & SIGINT            → dari RTL-SDR sampai Echelon NSA
🔐 Kriptografi            → dari Caesar Cipher sampai Post-Quantum
☁️ Cloud Infrastructure   → dari shared hosting sampai Zero Trust
🖥️ OS & Architecture      → dari transistor sampai kernel exploit
🕵️ OSINT                  → dari Google sampai Palantir Gotham
☠️ Shadow Arsenal         → dari OSINT Level 0 sampai Nation-State SIGINT
🤖 Agentic AI & MLOps     → dari function calling sampai autonomous swarm
```

### Detail Topik

#### Data Recovery

Data recovery adalah proses mengembalikan data yang hilang atau rusak. Ada beberapa jenis data recovery, seperti:

- **Software-based recovery**: menggunakan software untuk mengembalikan data yang hilang atau rusak.
- **Hardware-based recovery**: menggunakan hardware untuk mengembalikan data yang hilang atau rusak.
- **Fisika kuantum**: menggunakan prinsip fisika kuantum untuk mengembalikan data yang hilang atau rusak.

Contoh kode untuk data recovery menggunakan Python:

```python
import os
import hashlib

def recover_data(file_path):
    # Membaca file yang rusak
    with open(file_path, 'rb') as file:
        data = file.read()

    # Menghitung checksum data
    checksum = hashlib.md5(data).hexdigest()

    # Mencari data yang hilang
    for i in range(len(data)):
        if data[i] != checksum[i % len(checksum)]:
            # Mengembalikan data yang hilang
            data[i] = checksum[i % len(checksum)]

    # Menulis data yang telah diperbaiki
    with open('recovered_data', 'wb') as file:
        file.write(data)

# Menggunakan fungsi recover_data
recover_data('rusak_data.txt')
```

#### Endpoint Security

Endpoint security adalah proses melindungi endpoint (seperti komputer, laptop, atau mobile) dari serangan malware, virus, dan lain-lain. Ada beberapa jenis endpoint security, seperti:

- **Antivirus**: menggunakan antivirus untuk melindungi endpoint dari serangan malware dan virus.
- **Intel ME Ring -3**: menggunakan Intel ME Ring -3 untuk melindungi endpoint dari serangan yang lebih advanced.

Contoh kode untuk endpoint security menggunakan Python:

```python
import os
import hashlib

def scan_malware(file_path):
    # Membaca file yang dicurigai
    with open(file_path, 'rb') as file:
        data = file.read()

    # Menghitung checksum data
    checksum = hashlib.md5(data).hexdigest()

    # Mencari malware
    if checksum in ['malware_checksum_1', 'malware_checksum_2']:
        # Menghapus file yang terinfeksi
        os.remove(file_path)
        print('File telah dihapus karena terdeteksi malware')
    else:
        print('File aman')

# Menggunakan fungsi scan_malware
scan_malware('dicurigai_malware.exe')
```

#### Network Security

Network security adalah proses melindungi jaringan dari serangan yang tidak diinginkan. Ada beberapa jenis network security, seperti:

- **Layer 1**: melindungi jaringan pada layer 1 (fisik).
- **Layer 8 (manusia)**: melindungi jaringan dari serangan yang dilakukan oleh manusia.

Contoh kode untuk network security menggunakan Python:

```python
import socket

def scan_port(host, port):
    # Membuat socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Mencoba menghubungkan ke port yang dicurigai
    try:
        sock.connect((host, port))
        print(f'Port {port} terbuka')
    except socket.error:
        print(f'Port {port} tertutup')

    # Menutup socket
    sock.close()

# Menggunakan fungsi scan_port
scan_port('localhost', 8080)
```

### Contoh Praktis

Berikut adalah contoh praktis dari topik yang dipelajari:

- **Menggunakan software recovery** untuk mengembalikan data yang hilang.
- **Menggunakan antivirus** untuk melindungi endpoint dari serangan malware dan virus.
- **Menggunakan firewall** untuk melindungi jaringan dari serangan yang tidak diinginkan.

## Cara Aku Belajar

**top-down** — peta besar dulu, detail belakangan.
hal yang ingin dipelajari harus dipahami dulu beberapa enviromentnya.
Tidak pernah puas dengan jawaban permukaan. Kalau ada sesuatu yang "dianggap rahasia" atau disembunyikan di balik konsensus — itu yang justru paling menarik untuk digali.

### Langkah-Langkah Belajar

Berikut adalah langkah-langkah belajar yang aku lakukan:

1. **Membuat peta besar**: membuat peta besar dari topik yang ingin dipelajari.
2. **Mempelajari environments**: mempelajari beberapa environment dari topik yang ingin dipelajari.
3. **Mencari jawaban**: mencari jawaban dari pertanyaan yang aku tanyakan.
4. **Menganalisis jawaban**: menganalisis jawaban yang aku dapatkan.
5. **Mengulangi proses**: mengulangi proses belajar jika masih ada pertanyaan yang belum terjawab.

## Tools & Stack Yang Pernah Di Coba

```
OS        : Windows, Ubuntu, Kali Linux, Rocky Linux, Ubuntu Server
IDE       : VSCode, Antigravity
Security  : Kali Linux (VM), Wireshark, Crowdsec, Safeline
Hardware  : ESP32, ESP2886
Vault     : Obsidian + Quartz + GitHub Pages
Scripting : Python, Bash
Homelab   : Proxmox VM (Rocky Linux) +Safeline + Nginx Proxmy Manager + Cloudflared+ Nextcloud+Uptime Kuma Semua di dalam Docker Container
```

### Contoh Penggunaan Tools

Berikut adalah contoh penggunaan tools yang aku coba:

- **Menggunakan Kali Linux (VM)** untuk melakukan penetration testing.
- **Menggunakan Wireshark** untuk menganalisis paket jaringan.
- **Menggunakan Crowdsec** untuk melindungi jaringan dari serangan yang tidak diinginkan.

## Saat Ini

- 🛠️ Bereksperimen dengan berbagai macam Hardsisk dan SSD Untuk Recorvery atau Repair
- 🛠️ Mencoba menggunakan Ansible untuk automasi dalam pengaturan berbagai VM
- 🛠️ Membaca, Memahami berbagai macam seputar tech terutama dibidang DevOps
- 🛠️ Memahami AI Engineering, Agentic AI stack (MCP, tool use), dan LLM Red Teaming
- 🛠️ Mengeksplorasi hierarki alat militer & intelijen (Shadow Arsenal) dalam konteks defensive
- 📝 Membangun vault ini sebagai knowledge base publik

### Rencana Masa Depan

Berikut adalah rencana masa depan yang aku punya:

- **Mengembangkan kemampuan** dalam bidang DevOps dan AI Engineering.
- **Membangun sistem keamanan** yang lebih advanced untuk melindungi jaringan dan data.
- **Mengembangkan vault ini** menjadi knowledge base yang lebih lengkap dan detail.

## Kontak

| Platform         | Link                                                                               |
| ---------------- | ---------------------------------------------------------------------------------- |
| 🐙 **GitHub**    | [github.com/Azhar457](https://github.com/Azhar457)                                 |
| 💼 **LinkedIn**  | [linkedin.com/in/Azhar457](https://www.linkedin.com/in/azhar-muttaqien-a74a69237/) |
| 📧 **Email**     | [azharsss457@gmail.com](mailto:azharsss457@gmail.com)                              |
| 🌐 **Portfolio** | [azharmtq.my.id](https://azharmtq.my.id)                                           |
| 📸 **Instagram** | [@azharmtq](https://www.instagram.com/azharmtq/)                                   |

### Tips Troubleshooting

Berikut adalah tips troubleshooting yang aku punya:

- **Menggunakan log** untuk menganalisis error yang terjadi.
- **Menggunakan debug** untuk menganalisis kode yang error.
- **Menggunakan dokumentasi** untuk memahami konsep yang tidak dipahami.

### Skenario Troubleshooting

Berikut adalah skenario troubleshooting yang aku punya:

1. **Menganalisis log error**: menganalisis log error untuk mengetahui penyebab error.
2. **Menggunakan debug**: menggunakan debug untuk menganalisis kode yang error.
3. **Menggunakan dokumentasi**: menggunakan dokumentasi untuk memahami konsep yang tidak dipahami.
4. **Mencari jawaban**: mencari jawaban dari pertanyaan yang aku tanyakan.
5. **Mengulangi proses**: mengulangi proses troubleshooting jika masih ada pertanyaan yang belum terjawab.

---

> _Vault ini adalah catatan perjalanan belajar yang sedang berjalan — bukan hasil akhir._
> _Kalau ada yang salah, ada yang lebih dalam, atau ada yang mau didiskusikan — reach out._

---

_Built with [Quartz v4](https://quartz.jzhao.xyz/) · Hosted on GitHub Pages_
