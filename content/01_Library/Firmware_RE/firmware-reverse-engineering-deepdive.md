---
title: Firmware Reverse Engineering Deepdive
tags:
- firmware-re
- library
created: '2026-07-02'
updated: '2026-07-02'
status: pending
cssclasses: ''
---

# 🔧 FIRMWARE REVERSE ENGINEERING — Deep Dive: Dari Dump Flash Sampai Remote Code Execution

> Firmware adalah **lapisan kepercayaan paling dalam** — berjalan sebelum OS, kontrol hardware langsung, sering luput dari perhatian. Satu backdoor di firmware memberikan persist melewati factory reset. Dokumen ini membedah **setiap aspek firmware RE**: ekstraksi firmware mentah dari chip fisik, filesystem extraction, reversing ARM/MIPS/RISC-V, vulnerability discovery, emulation, sampai exploit untuk sistem embedded.

> [!info] Hubungan ke Vault
> Firmware RE menghubungkan [[hardware-hacking-re|Hardware Hacking]] (akuisisi fisik), [[embedded-systems|Embedded Systems]] (arsitektur target), [[web-hacking-exploitation|Web Hacking]] (exploit chain dari firmware), [[military-sigint-deepdive|Military SIGINT]] (CNA implant), dan [[comprehensive-threat-directory|Threat Directory]] (APT penarget firmware).

---

## Daftar Isi

- [[#Mengapa Firmware RE]]
- [[#Tipe-Tipe Firmware]]
- [[#Arsitektur CPU Embedded]]
- [[#Akuisisi Firmware — SPI, JTAG, Chip-Off]]
- [[#Identifikasi Format & Entropy]]
- [[#Filesystem Extraction]]
- [[#Static Analysis & String Hunting]]
- [[#Hardcoded Credentials & Backdoor]]
- [[#Vulnerability Discovery — Buffer Overflow]]
- [[#Heap Exploitation Embedded]]
- [[#Emulation — QEMU, Firmadyne, Fuzzware]]
- [[#Secure Boot Chain & Bypass]]
- [[#Encrypted Firmware — Key Extraction]]
- [[#OTA Update — Attack Surface]]
- [[#WiFi NIC Firmware — Reversing]]
- [[#UEFI Firmware Analysis]]
- [[#BMC — Baseboard Management Controller]]
- [[#Real-World Case Studies]]
- [[#IoT Botnets — Mirai Sampai Downfall]]
- [[#Firmware Hardening & Defense]]
- [[#Toolkit Checklist]]
- [[#Koneksi ke Vault]]

---

## Mengapa Firmware RE

```text
STACK: Aplikasi → OS → Hypervisor → Firmware → Hardware
Setiap lapisan bawah bisa mengkompromi lapisan di atas
```

**Mengapa firmware target empuk:**

| Faktor | Dampak |
|--------|--------|
| **Update jarang** | Vulnerability bertahun-tahun tidak ditambal |
| **Hardcoded secret** | Root creds, API key, token di binary |
| **Legacy code** | Fork codebase 10-20 tahun — pola tidak aman |
| **Debug interface terbuka** | UART, JTAG tidak dilindungi di produksi |
| **Boot rentan** | BootROM bug (silicon), verified boot bisa dilewati |
| **Supply chain opaque** | Blob pihak ketiga tanpa audit |
| **Memory protection minim** | Stack canary, ASLR, NX jarang diaktifkan |

**Siapa yang menarget firmware:**
- **APT groups** — Vault 7 (CIA), Equation Group, LiGhT — implant persisten
- **Peneliti IoT** — CVE massal di router, kamera, smart home
- **Hardware hackers** — custom firmware (OpenWRT, DD-WRT)
- **Bug bounty hunters** — Synacktiv, Atredis Partners
- **Forensic analysts** — recovery data dari device rusak

---

## Tipe-Tipe Firmware

Setiap tipe punya **karakteristik, toolchain, dan attack surface** berbeda.

### 1. UEFI / BIOS Modern

| Atribut | Detail |
|---------|--------|
| Format | Firmware Volume (FV), FFS, PEI/DXE/SMM modules |
| CPU | x86-64 utama, ARM untuk server |
| Tools | CHIPSEC, UEFITool, Ghidra UEFI plugin |
| Storage | SPI flash 8-32 MB |
| Boot | SEC → PEI → DXE → BDS → TSL → RT |
| Attack | SMM injection, NVRAM exploit, BootGuard bypass |

### 2. BMC (Baseboard Management Controller)

| Atribut | Detail |
|---------|--------|
| Contoh | ASpeed AST2500/AST2600, AMI MegaRAC, HPE iLO |
| OS | OpenBMC atau proprietary Linux |
| CPU | ARM Cortex-A, kadang x86 |
| Storage | SPI NOR 32-64 MB |
| Attack | Web RCE, IPMI RMCP+, serial-over-LAN, default creds |

### 3. Embedded RTOS Firmware

| Atribut | Detail |
|---------|--------|
| Contoh | FreeRTOS, VxWorks, ThreadX, Zephyr, μC/OS |
| Struktur | Single binary, linked statis, tanpa filesystem |
| CPU | ARM Cortex-M, RISC-V, Xtensa, ColdFire, SuperH |
| Storage | Flash internal MCU (256KB-2MB), readout protection |
| Attack | Overflow dari input sensor, UART shell, debug interface |

### 4. SoC Boot ROM

| Atribut | Detail |
|---------|--------|
| Ukuran | 4-64 KB, mask ROM — **tidak bisa diubah** (silicon bug) |
| Peran | Inisialisasi hardware, load bootloader dari flash/NAND |
| Attack | USB download mode overflow, header parsing bug |
| Kasus | Broadcom BCM2835, Qualcomm Sahara, Mediatek preloader |

### 5. WiFi NIC Firmware

| Atribut | Detail |
|---------|--------|
| Contoh | Broadcom BCM43xx, Atheros AR9xxx, Intel AXxxx |
| CPU | Xtensa, MIPS, ARC — independent processor di chip WiFi |
| Host interface | PCIe/SDIO/USB + DMA ke host memory |
| Attack | Firmware load intercept, ioctl overflow, DMA host compromise |

---

## Arsitektur CPU Embedded

**ARM:** R0-R15 (32-bit), X0-X30 (64-bit). Little-endian. Thumb/Thumb-2 campuran 16/32-bit. Calling conv R0-R3 arg, R0 ret. IT block di Thumb-2. Link register (LR) untuk return address — kritis untuk ROP.

```asm
; ARM ROP — pop {r0, r3, pc}
0x0001234:   ldmia.w sp!, {r0, r1, pc}
; ARM64 gadget
0x0045678:   ldp x0, x19, [sp], #0x20
0x004567c:   ret
```

**MIPS:** $0-$31 + HI/LO. Big/little endian. **Delay slot** — instruksi setelah branch/jump tetap dieksekusi. $zero = 0 selalu. GP (global pointer) untuk data access. Return via `jr $ra`. ROP lebih sulit tanpa pop-multiple.

```asm
; MIPS gadget
00401234:   lw   $ra, 0x1c($sp)      ; load return addr
00401238:   lw   $s0, 0x18($sp)
0040123c:   jr   $ra                  ; jump ke gadget
00401240:   addiu $sp, $sp, 0x20     ; delay slot tetap dieksekusi
```

**RISC-V:** RV32I/RV64I. x0=zero (seperti MIPS). Tidak ada delay slot. C extension = compressed 16-bit. Calling conv: x10-x17 (a0-a7), x10 return. Linker relaxation bisa ubah encoding instruksi. Penggunaan: ESP32-C3, Bouffalo Lab BL602.

```asm
; RISC-V function
func:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      a0, 8(sp)
    call    process
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret
```

**Xtensa:** Semi-custom — vendor konfigurasi instruksi sendiri. ESP8266 (LX106), ESP32 (LX6). Ghidra plugin. Set instruksi bervariasi antar implementasi.

**ColdFire:** Varisi M68k CISC. Register D0-D7, A0-A7, SR, PC. Printer, industrial, legacy aerospace.

---

## Akuisisi Firmware — SPI, JTAG, Chip-Off

### Level 0 — Software Dump
```bash
# Dari shell device
cat /dev/mtd0 > /tmp/fw.bin; cat /proc/mtd
# U-Boot: sf probe; sf read 0x82000000 0x0 0x100000
# flashrom: flashrom -p internal -r backup.bin
```

### Level 1 — SPI Flash SOIC-8 Clip
**Tools:** CH341A ($3), FTDI FT2232H ($15-25), Bus Pirate ($30-50), DediProg SF100 ($100-200)

**Pinout SOIC-8:**
| Pin | Signal | Ke Programmer |
|-----|--------|---------------|
| 1 | CS# | CS |
| 2 | DO (MISO) | MISO |
| 5 | DI (MOSI) | MOSI |
| 6 | CLK | SCK |
| 7 | VCC | 3.3V (JANGAN 5V) |
| 8 | VCC (opsional) | 3.3V |
| 4 | GND | GND |
| 3/7 | WP#/HOLD# | Pull-up 3.3V |

```bash
flashrom -p ch341a_spi -r fw.bin
md5sum fw.bin; flashrom -p ch341a_spi -r fw2.bin; md5sum fw2.bin
```

### Level 2 — JTAG / SWD
| Interface | Pins | Max Freq |
|-----------|------|----------|
| JTAG | TMS, TCK, TDI, TDO | 10-100 MHz |
| SWD | SWDIO, SWCLK | 100 MHz+ |

**Tools:** OpenOCD (free), Segger J-Link ($400-700), Black Magic Probe ($50)
```bash
openocd -f interface/ftdi/ft2232h.cfg -f target/stm32f4x.cfg \
  -c "init" -c "flash read_bank 0 dump.bin 0x08000000 0x100000" -c "shutdown"
```

### Level 3 — Chip-Off (BGA)
**Destructive — langkah terakhir.** Hot air reflow (Quick 861DW) → reball → reader.

**Readout Protection Bypass:**
| Proteksi | Bypass |
|----------|--------|
| STM32 RDP1 | Debugger read — mass erase enable = data hilang |
| STM32 RDP2 | Permanent lock — chip-off + voltage glitch |
| ATECC508A/608A | Voltage/clock glitching |
| i.MX HAB | Known vuln per versi (e.g. HAB 4.1.0) |

---

## Identifikasi Format & Entropy

### Magic Bytes Kunci
```text
1F 8F          → gzip          42 5A 68       → bzip2
5D 00 00 40    → LZMA          7F 45 4C 46    → ELF
48 53 51 53    → SquashFS LE   73 71 71 73    → SquashFS BE
59 41 46 46 53 → YAFFS         55 42 49 2E 23 → UBI# (UBIFS)
52 53 44 53... → UEFI FV       1F 9D / 1F A0  → LZSS (Broadcom)
EB 48 90       → FAT16/32      55 2D 42 6F 6F 74 → U-Boot legacy
```

### Analisis Awal
```bash
# 1. Strings
strings fw.bin | head -100
# 2. Entropy
binwalk -E fw.bin
# 3. Signature scan
binwalk fw.bin
# 4. Extract
binwalk -Me fw.bin
# 5. Cek hasil
ls _fw.bin.extracted/
file _fw.bin.extracted/* | grep -v ASCII | grep -v empty
```

**Entropy (0-8 bits/byte):** 0-3 = uncomp/strings/padding, 3-6 = mixed/base64, 6-8 = compressed/encrypted.
Pola khas firmware: low (header) → high (kernel LZMA) → low (SquashFS magic) → high (filesystem data).

---

## Filesystem Extraction

**SquashFS — paling umum untuk router Linux:**
```bash
unsquashfs rootfs.squashfs       # standard
sasquashfs firmware-squashfs.bin # vendor-variant (Broadcom, Huawei)
```
Superblock: magic hsqs (LE) / qsqs (BE), ukuran blok (default 131072), kompresi: 1=gzip, 2=lzma, 3=lzo, 4=xz, 5=lz4, 6=zstd.

**JFFS2:**
```bash
jefferson rootfs.jffs2
# Alternatif via kernel module: modprobe jffs2; mount -t jffs2 /dev/mtdblock0 /mnt
```

**YAFFS:** `unyaffs firmware.yaffs2` atau `python3 yaffshiv.py`.

**UBI/UBIFS:**
```bash
ubireader_extract_images firmware.ubi
ubireader_dump_info firmware.ubi
# Via mtd-utils: ubiformat → ubiattach → mount -t ubifs ubi0:rootfs /mnt
```

**CPIO (initramfs):** `dd if=fw.bin bs=1 skip=OFFSET | zcat | cpio -idmv` (magic "070701"/"070702").

---

## Static Analysis & String Hunting

### Approach
```text
1. Identifikasi arsitektur — readelf -h, entry point
2. Strings recon — path, IP, keyword security
3. Function scanning — system, execve, memcpy, sprintf, gets
4. Cross-reference — dari string "password" → XREF ke fungsi pembanding
```

### String Hunting
```bash
# Hardcoded credentials
strings fw.bin | grep -iE '(password|passwd|pwd|secret|key|token|auth)' | grep -v '%s'
# Hardcoded IP/URL (C2, update server)
strings fw.bin | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]+'
strings fw.bin | grep -E 'https?://'
# Path interesting
strings fw.bin | grep -E '(/etc/|/var/|/tmp/|/dev/|/proc/|/factory/)'
# Default credentials
strings fw.bin | grep -iE '(admin|root|default|debug|backdoor|guest|support)'
# Format string vuln
strings fw.bin | grep -E '%.*[sdnx]' | grep -v '"%'
```

### Vulnerability Pattern
| Pattern di Binary | Potensi CVE |
|-------------------|-------------|
| sprintf(buf, user_input) | Stack buffer overflow |
| gets(buf) | Classic stack overflow |
| system("cmd %s", input) | Command injection |
| memcpy(buf, src, user_len) | Heap overflow |
| strcmp(password, "backdoor") | Backdoor account |
| hardcoded AES key | Firmware decryption |

### Ghidra Workflow
1. Cari string "login", "password", "admin" → XREF
2. Trace ke handler (httpd, loginHandler)
3. Cek recv/read/gets — bandingkan length vs buffer size
4. Cek format string: printf(buf) vs printf("%s", buf)
5. Cek stack canary (__stack_chk_fail): tidak ada → exploit tanpa ROP
6. Hitung offset via pattern cyclic → ROP chain (system / mknod+telnetd)

---

## Hardcoded Credentials & Backdoor

**Backdoor Umum per Vendor:**
| Vendor | Credential |
|--------|------------|
| Linksys | admin:admin, root:admin |
| D-Link | admin:airlive, super:super |
| TP-Link | admin:admin, root:1234 |
| Netgear | admin:password |
| ZTE | root:Zte521 |
| Huawei | admin:admin, root:admin |
| IPCamera | admin:123456, root:xc3511 |
| SuperMicro BMC | root:admin |
| Cisco | cisco:cisco, enable:cisco |
| ASUS | admin:admin |

### Auto-Scan Script
```bash
for f in $(find _extracted -type f -executable 2>/dev/null); do
  strings "$f" | grep -qiE '(system|popen|execve|fork|exec[lv]p?\()' && echo "[+] $f"
  strings "$f" | grep -qiE '(/bin/sh|bash -i|nc -e|mknod|telnetd)' && echo "[!] Backdoor: $f"
done
```

### Case — D-Link DIR-890L (CVE-2017-7410)
Hardcoded telnet credential `admin:1234567890` ditemukan via strings. Remote attacker login via WAN-side telnet.

### Case — TP-Link WDR4300 (CVE-2017-13772)
Parameter "exe" di ping process bisa di-inject command. Tidak ada otentikasi fungsi diagnostik. RCE tanpa auth.

---

### Format String & Integer Overflow

**Format string** lebih berbahaya di embedded karena ASLR jarang:
```c
// Vulnerable
snprintf(buf, 256, msg);  // msg dari user → format string vuln
// Safe
snprintf(buf, 256, "%s", msg);
```
- `%n` specifier → write arbitrary memory (GOT overwrite)
- `%x`/`%p` → leak stack (canary, libc base, return address)

**Integer overflow** sering terjadi karena tipe 16/32-bit mapping ke register:
```c
uint32_t calc_size(uint16_t w, uint16_t h, uint8_t bpp) {
    return w * h * bpp;  // overflow jika w*h > 0xFFFFFFFF
}
// w=0x10001, h=0x10001 → small allocation → loop copy dengan size asli → overflow
```

## Vulnerability Discovery — Buffer Overflow

**Karakteristik embedded vs desktop:**

| Aspek | Embedded |
|-------|----------|
| Stack canary | Sering tidak ada (-fno-stack-protector) |
| ASLR | Jarang diaktifkan — offset tetap |
| NX | Tidak selalu — heap/stack executable |
| PIE | Jarang — base address fixed |
| RelRO | Sering tidak ada — GOT overwrite feasible |
| Memory | Heap kecil (4KB-1MB), malloc rawan |

**Contoh decompile dari Ghidra:**
```c
void login_handler(int sock) {
    char username[64];
    char password[64];
    char response[256];
    recv(sock, username, 0x100, 0);  // BUG: 256 byte → 64 byte buffer
    recv(sock, password, 0x100, 0);  // BUG: sama
    sprintf(response, "Login: %s", username); // Format string vuln juga
    send(sock, response, strlen(response), 0);
}
```

**Menghitung Offset:**
```bash
pattern create 2000 > /tmp/pattern.txt
# Kirim ke proses → crash → GDB: info registers pc
pattern offset 0x6161616c  # → "pattern found at offset 140"
# → 140 bytes padding + 4 byte ra + ROP chain
```

### Format String di Embedded
```c
// Vulnerable
snprintf(buf, 256, msg);  // msg dari user = format string vuln
// Safe
snprintf(buf, 256, "%s", msg);
```
Impact: read arbitrary memory (leak canary/libc), write via %n (GOT overwrite). Lebih berbahaya di embedded karena ASLR jarang.

---

## Heap Exploitation Embedded

**Allocator:** dlmalloc (uClibc), newlib, musl, FreeRTOS heap. Ukuran 4KB-1MB. Metadata inline tidak diproteksi.

| Teknik | Cara |
|--------|------|
| **Heap overflow** | Overflow ke metadata → ubah size → arbitrary write |
| **Use-after-free** | Free tanpa null → reuse corrupted object |
| **Double free** | Free 2× → corrupt freelist → arbitrary alloc |
| **Tcache poisoning** | (uClibc-ng 1.0.36+) → arbitrary address allocation |
| **House of Force** | Top chunk overflow → alokasi besar → GOT overwrite |
| **Unsorted bin attack** | Ubah bk pointer → arbitrary write global |

```text
dlmalloc chunk: [prev_size(4B)][size(4B)|flags(3b)][data...]
flags: PREV_INUSE=0x1, IS_MMAPPED=0x2, NON_MAIN_ARENA=0x4

Overflow A→B: ubah size B, set PREV_INUSE=0 → free(B) backward consolidation
→ Fake prev_size → consolidate dengan chunk palsu → overlap → arbitrary write
```

---

## Emulation — QEMU, Firmadyne, Fuzzware

### QEMU User Mode
```bash
# Ekstrak filesystem dulu
binwalk -Me fw.bin; cd _fw.bin.extracted/squashfs-root
qemu-arm -L . ./bin/sh          # ARM LE
qemu-mips -L . ./bin/sh         # MIPS BE
qemu-mipsel -L . ./bin/sh       # MIPS LE
qemu-arm -g 1234 -L . ./bin/httpd  # debug via GDB
```

### QEMU System Mode
```bash
qemu-system-arm -M virt \
  -kernel vmlinuz -initrd rootfs.squashfs \
  -append "console=ttyAMA0 root=/dev/ram rdinit=/sbin/init" -nographic
```

### FirmAE
```bash
git clone https://github.com/pr0v3rbs/FirmAE
./run.sh -c <brand> firmware.bin   # infer + boot
./run.sh -r <brand> firmware.bin   # debug shell
```
**Limitasi:** Hanya Linux kernel, sering gagal (kernel modules proprietary), tidak support RTOS.

### Fuzzware
```bash
pip install fuzzware
fuzzware init firmware.bin    # analisis + generate konfigurasi
fuzzware run                  # coverage-guided fuzzing
```
User-mode QEMU + symbolic execution + peripheral MMIO modeling. Hasil di `crashes/`.

---

## Secure Boot Chain & Bypass

### Boot Flow
```text
BootROM (mask ROM) → signed bootloader (RSA/ECDSA) → verified kernel → dm-verity fs
```

**BootROM bug — tidak bisa di-patch (silicon):**

| CVE | Device | Bug |
|-----|--------|-----|
| CVE-2021-27886 | MediaTek MT7622 | USB header buffer overflow |
| CVE-2018-3639 | Qualcomm Snapdragon | USB download mode bypass |
| BCM2835 | Raspberry Pi | GPIO boot mode → boot tanpa signature |
| CVE-2019-14192 | Qualcomm WLAN | BootROM NVRAM parsing overflow |

### TrustZone (ARM)
```text
Normal World (Linux/Android) ──SMC──→ Secure World (OPTEE/Trusty)
  Secure boot, DRM (Widevine L1), key management, secure storage (RPMB)
```
**Attack surface:** SMC handler overflow, key leakage (side-channel power/EM), TZASC misconfig (secure DRAM accessible), OPTEE kernel CVEs.

### Verified Boot Bypass
| Metode | Syarat | Detail |
|--------|--------|--------|
| BootHole (CVE-2020-10713) | GRUB2 menu | Overflow di shim |
| BlackLotus (CVE-2023-24932) | Physical/admin | UEFI bootkit persist di NVRAM |
| Golden key leak | SBK leaked | Sign arbitrary bootloader |
| Setup mode | Physical | Import custom key |
| CMOS clear | Physical | Reset Secure Boot state |

---

## Encrypted Firmware — Key Extraction

### Sumber AES Key
```text
1. HARDCODED DI BINARY — strings atau hex search di bootloader/SPL/driver
2. EFUSE/OTP — glitching saat boot untuk bypass read protection
3. DERIVED DARI CHIP UID — SHA256(chip_id || vendor_salt)
4. KEY FILE — /etc/key, /factory/enc_key, /mfg/keys
5. ON-THE-FLY — AES key di eFuse, decrypt saat boot
```

```bash
# Cari key
strings fw.bin | grep -E '^[0-9a-fA-F]{32}$'   # 128-bit hex
strings fw.bin | grep -E '^[0-9a-fA-F]{64}$'   # 256-bit hex

# Decrypt
openssl enc -d -aes-128-cbc -K "$KEY" -iv "$IV" -in enc.bin -out dec.bin
openssl enc -d -aes-256-cbc -K "$KEY" -iv "$IV" -in enc.bin -out dec.bin
```

### RSA Key Recovery
- Private key leak dari GitHub/source dump
- Side-channel (timing analysis RSA)
- Fault injection (glitching → skip signature check → logic error output)
- 512-bit key factoring (CADO-NFS)
- Shared key antar produk vendor
- Extract dari ATECC608A via I2C probing

---

## OTA Update — Attack Surface

**Flow:** Device → check version → download → verify signature → write flash → reboot.

**Attack Vectors:**

| Vector | Detail | Contoh |
|--------|--------|--------|
| **Downgrade** | Server tidak enforce min version | Rollback ke FW dengan CVE lama |
| **MITM** | Update via HTTP — intercept + ganti binary | CVE-2019-12512 (Netgear) |
| **Signature bypass** | Tidak ada signature check atau public key hardcoded | Berbagai IoT |
| **Malicious server** | DNS spoofing → serve FW attacker | VPNFilter |
| **Partial update** | Update hanya sebagian flash | Inject backdoor ke bootloader |
| **Unsigned failsafe** | Recovery mode tanpa signature check | Xiaomi IoT |

```bash
# Sniff OTA
tcpdump -i eth0 host update-server.com -w ota.pcap
tshark -r ota.pcap -Y "http.response" -T fields -e http.file_data

# Cek header OTA: X-Firmware-Version, X-Signature, Content-MD5
hexdump -C downloaded_fw.bin | head -40
```

---

## WiFi NIC Firmware — Reversing

**Arsitektur:**
```text
Host (Linux) ──PCIe/SDIO──→ WiFi CPU (Xtensa/MIPS/ARC) → MAC/BB → RF
```
WiFi chip punya CPU independent + DMA ke host memory via bus mastering.

**Attack Surface:**

| Vector | Mekanisme | Dampak |
|--------|-----------|--------|
| Host→firmware RCE | Overflow di ioctl parsing | Code exec di chip WiFi |
| DMA via PCIe | WiFi chip baca/tulis host memory | Full host compromise |
| Frame injection | No source MAC validation | Kernel exploit via wireless |
| Firmware load intercept | Ganti FW binary saat host transfer | Backdoor permanen |
| Spectre-like | Branch prediction leak di chip WiFi | Cross-process data leak |

**Nexmon:** Open-source Broadcom firmware patching (BCM43xx). Monitor mode, frame injection, custom patches untuk chip yang tidak support.

---

## UEFI Firmware Analysis

**Boot phases:** SEC → PEI → DXE → BDS → TSL → RT.

| Tool | Fungsi |
|------|--------|
| UEFITool / UEFIExtract | Parse FV, extract FFS/PEI/DXE/SMM modules |
| CHIPSEC | Scan UEFI config, SMM handlers, SPI flash |
| IFRExtractor | Extract BIOS region dari Intel Flash Descriptor |
| VarCheck | Analisis NVRAM variable + Secure Boot policy |
| Binarly | AI-based UEFI vuln scanning (commercial) |

```bash
UEFIExtract BIOS.bin output_dir/
chipsec_main -m common.bios_wp     # BIOS write protect?
chipsec_main -m common.spi_desc    # SPI descriptor locked?
chipsec_main -m common.uefi_s3     # S3 boot script vuln?
```

**Common UEFI CVEs:** SMM callout (buffer dari OS tanpa validasi → overwrite SMRAM), NVRAM corruption, PEI injection, S3 boot script overflow.

---

## BMC — Baseboard Management Controller

**BMC = second computer:** ARM Cortex-A, 256MB-2GB RAM, 32-64MB SPI flash, dedicated NIC.
**Connections:** PCIe (DMA), LPC (flash access), I2C, serial (KVM), USB (virtual media), GPIO.

**Attack Vectors:**

| Vector | Detail | Contoh |
|--------|--------|--------|
| IPMI RMCP+ | Auth bypass/weak cipher | CVE-2013-4786 |
| Web UI RCE | CGI buffer overflow | CVE-2019-6260 |
| Default creds | root:admin — massal di Shodan | SuperMicro |
| DMA to host | Baca/tulis host memory via PCIe | - |
| KVM injection | Virtual keyboard → keystroke ke host | - |
| Virtual media | Mount ISO → boot OS attacker | - |
| PixieFail | RCE via PXE boot path | CVE-2024-0146 |

**BMC Firmware Extraction:**
```bash
binwalk -Me bmc_firmware.bin
unsquashfs _extracted/*rootfs*
ls squashfs-root/www/; ls squashfs-root/etc/; ls squashfs-root/usr/local/bin/
```

---

## Real-World Case Studies

### Jeep Cherokee 2014 (CVE-2015-6622, CVE-2015-6577)
```text
WiFi→D-Bus→infotainment→CAN bus→ECU: Remote control brake/steering/transmission.
KEY: Firmware OTA tanpa signature proper, CAN bus no auth, no network segmentation.
Source: Miller & Valasek, Black Hat 2015.
```

### VPNFilter (2018, APT28/GRU)
```text
Stage 1: Backdoor firmware router (Linksys, Netgear, MikroTik, TP-Link, ASUS)
Stage 2: C2 via Tor+SSL, packet sniffer, traffic redirection
Stage 3: Self-destruct — overwrite flash partition → device brick
KEY: Persist despite reboot dan factory reset. Deteksi via hash integrity check.
```

### Mirai Botnet (2016)
```text
Scan port 23/2323 → brute force 60 default credentials → download loader per arch
600K devices, 1.2 Tbps DDoS ke Dyn DNS — internet parsial down.
KEY: Bukan zero-day — semua dari credential default firmware.
Supported: ARM, ARM64, MIPS, MIPS64, x86, PowerPC, SPARC, m68k.
```

### Stuxnet (2010)
```text
PLC firmware reflash → display status normal ke HMI, real: destroy centrifuges.
KEY: Firmware-level rootkit pertama. OS dan HMI lihat operasi normal.
PLC tanpa integrity check untuk firmware yang di-load (2007).
```

### AMI MegaRAC — PixieFail (CVE-2024-0146)
```text
Multiple BMC vuln via PXE boot path — RCE tanpa auth.
100K+ server exposed via BMC management interface di Shodan.
BMC compromise = full host compromise (DMA access).
```

---

## IoT Botnets — Dari Mirai Sampai Downfall

### Botnet Evolution

Mirai (2016) membuka pintu dengan menunjukkan betapa massalnya perangkat IoT yang vulnerable karena default credentials. Source code dirilis publik — varian bermunculan: MiraiOk, Satori, OMG, MaskedBot.

Perubahan signifikan per generasi:
- 2016 (Mirai): Hanya brute force telnet dengan 60 credential 
- 2017-2019 (Satori, Mukashi): Fork Mirai + exploit CVE spesifik
- 2022+ (RapperBot): Hybrid botnet — IoT + cloud server untuk DDoS resilience
- 2024 (Downfall): Target firmware OTA mechanism, bukan credential

| Tahun | Botnet | Metode Masuk |
|-------|--------|--------------|
| 2016 | Mirai | Default credential telnet |
| 2017 | Hajime | P2P DHT decentralized |
| 2018 | VPNFilter | Firmware implant + CVE |
| 2022 | RapperBot | SSH brute force |
| 2023 | LuCI Lua Bot | RCE via Lua script injection |
| 2024 | Downfall | Firmware OTA abuse |

**Defense:** No default credentials, disable telnet, signed firmware + anti-rollback, IoT VLAN restricted egress, bug bounty program.

---

## Firmware Hardening & Defense

### Build-Time
| Mitigasi | Flag |
|----------|------|
| Stack canary | `-fstack-protector-strong` |
| PIE | `-fpie -pie` |
| RELRO | `-Wl,-z,relro -Wl,-z,now` |
| NX | `-Wl,-z,noexecstack` |
| Fortify | `-D_FORTIFY_SOURCE=2` |
| ASLR | `randomize_va_space=2` |
| CFI | `-fsanitize=cfi` (Clang) |

### Runtime
- Read-only SquashFS rootfs + dm-verity hash tree
- Separate encrypted data partition (UBIFS + dm-crypt)
- SELinux/AppArmor + seccomp syscall filter
- JTAG/SWD/UART disabled di production (efuse)
- /tmp with noexec,nosuid

### TPM Remote Attestation
```text
BootROM → measure boot → PCR[0]
Bootloader → measure kernel → PCR[1]
Kernel → measure rootfs → PCR[2]
Server: challenge signed PCR values via TPM
If mismatch → quarantine from network
```

---

## Toolkit Checklist

### Hardware
| Alat | Harga | Prioritas |
|------|-------|-----------|
| CH341A + SOIC clip | $5-15 | ⭐ Wajib (SPI flash) |
| FTDI FT2232H | $15-25 | ⭐ Wajib (JTAG) |
| USB UART 3.3V | $5-10 | ⭐ Wajib (console) |
| Bus Pirate v3.6 | $30-50 | ⭐⭐ Protocol debug |
| Logic Analyzer | $10-400 | ⭐⭐ I2C/SPI/UART |
| Hot Air Rework | $100-300 | ⭐⭐⭐ Chip-off |
| Oscilloscope | $150-400 | ⭐⭐ Signal analysis |
| Power supply var | $50-150 | ⭐⭐ Power injection |

### Software
**Wajib:** Ghidra, binwalk+unblob, QEMU, flashrom, OpenOCD, tcpdump/Wireshark, Python3 + FirmAE/angr.

**Nice-to-have:** IDA Pro, Saleae LA, ChipWhisperer, HackRF, JTAGulator.

---

## Koneksi ke Vault

| Skill | Hubungan |
|-------|----------|
| [[hardware-hacking-re\|Hardware Hacking]] | Akuisisi fisik — SPI, JTAG, chip-off, oscilloscope |
| [[embedded-systems\|Embedded Systems]] | Arsitektur target, RTOS, MMIO, peripheral |
| [[web-hacking-exploitation\|Web Hacking]] | Exploit chain firmware → web interface |
| [[military-sigint-deepdive\|Military SIGINT]] | TLE/CNA, firmware implant, supply chain interdiction |
| [[comprehensive-threat-directory\|Threat Directory]] | APT28 (VPNFilter), Equation (Stuxnet), CIA (Vault 7) |
| [[underground-knowledge\|Underground Knowledge]] | IoT botnet economy, firmware dumping services |

---
*Dokumen ini adalah living note — diperbarui seiring muncul teknik baru, CVE signifikan, dan perubahan landscape ancaman firmware.*
