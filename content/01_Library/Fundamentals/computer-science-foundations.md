---
tags:
  - os-internals
  - computer-architecture
  - kernel
  - cpu
  - memory
  - fondasi
aliases:
  - Fondasi CS
  - OS Internals
  - Computer Architecture
created: 2026-04-25
---

# 🖥️ FONDASI CS — OS Internals & Computer Architecture

> Dua lapisan yang menjelaskan SEMUA yang ada di atas mereka. Kenapa Ring 0 lebih powerful dari Ring 3? Kenapa Spectre bisa terjadi? Kenapa container lebih ringan dari VM? Semua jawabannya ada di sini.

> [!info] Cara Baca
> OS Internals = bagaimana software mengatur hardware. Computer Architecture = bagaimana hardware itu sendiri bekerja. Keduanya saling explain — baca paralel, bukan serial.

---

## Sheet 1 — OS Internals: Dari System Call sampai Kernel Exploit

| 🔧 Level & Konsep | ⚡ Cara Kerja & Sweet Spot | ☠️ Tembok Kematian | 🔗 Koneksi ke Topik Lain |
|---|---|---|---|
| **Level 0** — Process & Thread *(fork, exec, pthread, scheduler)* | Program = proses = address space isolated. Thread = unit eksekusi dalam proses, share memori. Scheduler OS (CFS di Linux) tentukan siapa jalan kapan via priority queue. `fork()` clone proses, `exec()` ganti image. | Race condition jika dua thread akses shared memory tanpa synchronization. Deadlock jika dua thread saling tunggu lock masing-masing. | Fondasi container isolation, fondasi malware process injection |
| **Level 1** — Memory Management *(virtual memory, paging, TLB, mmap)* | Setiap proses punya virtual address space sendiri — ilusi punya RAM penuh. MMU translate virtual → physical via page table. TLB: cache hasil translasi (flush TLB = performance hit). `mmap`: map file/device langsung ke address space. | Page fault handling overhead. TLB thrashing pada workload besar. Memory leak = proses makan RAM tanpa bebaskan. | Fondasi ASLR (security), fondasi VM hypervisor, fondasi buffer overflow exploit |
| **Level 2** — System Call Interface *(syscall, vDSO, seccomp, ptrace)* | Pintu resmi dari User Space (Ring 3) ke Kernel (Ring 0). `read()`, `write()`, `open()` semua akhirnya jadi syscall via interrupt/SYSCALL instruction. vDSO: syscall yang di-map ke user space untuk bypass overhead. seccomp: filter syscall yang boleh dipanggil proses (dipakai container). | Setiap syscall = context switch overhead. seccomp whitelist yang salah = aplikasi crash. ptrace (dipakai debugger) bisa diblokir via PR_SET_DUMPABLE. | Fondasi EDR (monitor syscall anomali), fondasi sandbox, fondasi strace/debugger |
| **Level 3** — File System *(VFS, inode, journaling, ext4, NTFS, btrfs)* | VFS (Virtual File System): abstraksi layer — semua FS terlihat sama dari atas. Inode: metadata file (permission, timestamp, pointer ke blok data) — bukan nama file. Journaling: catat transaksi sebelum commit, survive crash. | Inode habis = tidak bisa buat file baru meski disk masih ada space. Journaling overhead pada write-heavy workload. Fragmentation pada HDD (tidak relevan di SSD). | Koneksi ke Data Recovery (inode forensik), MFT di NTFS = target rootkit |
| **Level 4** — IPC & Synchronization *(pipe, socket, signal, mutex, semaphore, futex)* | Cara proses/thread komunikasi: pipe (unidirectional stream), socket (bidirectional, bisa network), signal (async notification), shared memory (tercepat tapi berbahaya). Mutex/semaphore: koordinasi akses shared resource. Futex: fast mutex yang hanya masuk kernel jika ada contention. | Signal handler yang tidak async-signal-safe = undefined behavior. Priority inversion: thread prioritas tinggi diblokir oleh thread prioritas rendah yang pegang lock. | Fondasi microservices communication, fondasi IPC-based malware (named pipe injection) |
| **Level 5** — Kernel Module & Driver *(LKM, DKMS, WDM, kernel panic)* | Kernel module: kode yang berjalan di Ring 0 tanpa restart. Linux: LKM (Loadable Kernel Module). Windows: WDM/WDF driver. Akses penuh ke semua hardware dan memori. Kernel panic/BSOD terjadi jika module crash karena tidak ada safety net di Ring 0. | Satu bug di kernel module = sistem crash atau security hole Ring 0. Windows DSE (Driver Signature Enforcement) paksa signature digital. Linux: kernel lockdown mode (Secure Boot enforced). | Koneksi ke Rootkit (kernel module jahat), EDR (kernel driver legitimasi), BYOVD attack |
| **Level 6** — Hypervisor & Virtualization *(KVM, Xen, Hyper-V, VMX/SVM instructions)* | Type-1 hypervisor (bare-metal): berjalan langsung di hardware, OS jadi guest. Type-2: berjalan di atas OS host. CPU support: Intel VMX / AMD SVM — hardware-assisted virtualization. VMCS/VMCB: struktur data yang simpan state guest. VM Exit: saat guest lakukan operasi privileged, control kembali ke hypervisor. | VM Exit overhead pada operasi I/O intensif. Spectre/Meltdown bisa bocorkan data antar VM. VM escape exploit: keluar dari guest ke host. | Koneksi ke Cloud (fondasi EC2/VM), Cheat Engine Level 4 (hypervisor cheat), Ring -1 security |
| ☠️ **Level 7** — Kernel Exploit & OS Security *(privilege escalation, SMEP, SMAP, CET, kASLR)* | Dari bug kernel → Ring 0 execution → full system compromise. Mitigasi: SMEP (cegah kernel execute user page), SMAP (cegah kernel baca user page tanpa izin), kASLR (randomize kernel address), CET (cegah ROP via shadow stack). Stack canary, RELRO, PIE di user space. | Modern kernel dengan semua mitigasi aktif sangat susah dieksploitasi — butuh chain multiple bug. Mitigasi baru (CET) butuh hardware support (Intel 11th gen+). | Koneksi ke RE Level 6 (kernel exploit), Endpoint Security (PatchGuard Windows), CVE research |

---

## Sheet 2 — Computer Architecture: Dari Transistor sampai Spectre

| ⚡ Level & Konsep | 🔬 Cara Kerja & Sweet Spot | ☠️ Implikasi Security | 🔗 Koneksi ke Topik Lain |
|---|---|---|---|
| **Level 0** — Logic Gates & Digital Circuit *(AND, OR, NOT, XOR, flip-flop, clock)* | Transistor = switch elektronik. Kombinasi transistor → logic gate. Kombinasi gate → adder, mux, register. Clock signal sinkronisasi semua operasi. Flip-flop: simpan 1 bit state. Ini fondasi SEMUA yang di atasnya. | Hardware backdoor bisa diimplementasi di gate level — tidak terdeteksi software apapun (Intel ME concern). | Fondasi Hardware Hacking Level 7 (silicon RE), fondasi FPGA (DMA card cheat) |
| **Level 1** — CPU Pipeline *(fetch, decode, execute, writeback, hazard)* | Instruksi diproses dalam stage paralel seperti assembly line. Pipeline hazard: data hazard (instruksi butuh hasil instruksi sebelumnya yang belum selesai), control hazard (branch — tidak tahu instruksi mana yang jalan berikutnya). Solusi: forwarding, stalling, branch prediction. | Pipeline yang stall bisa jadi timing side-channel. Instruksi sequence tertentu bisa trigger microarchitectural behavior yang tidak terdokumentasi. | Fondasi timing attack di kriptografi, fondasi Spectre/Meltdown |
| **Level 2** — Cache Hierarchy *(L1/L2/L3, cache line, coherency, MESI protocol)* | L1 (per-core, ~32KB, ~4 cycle): tercepat. L2 (per-core, ~256KB): medium. L3 (shared antar core, ~8-32MB): terlambat. Cache line: unit transfer 64 byte. Cache miss = fetch dari RAM (~100 cycle penalty). MESI protocol: koordinasi cache antar core. | **Cache timing attack**: ukur waktu akses memori untuk inferensi data di cache. Flush+Reload, Prime+Probe adalah teknik nyata yang dipakai Spectre/Meltdown. | Fondasi Spectre/Meltdown, fondasi side-channel attack di Hardware Hacking |
| **Level 3** — Branch Prediction & Speculative Execution *(BTB, RSB, PHT, speculative store bypass)* | CPU spekulatif execute instruksi di jalur branch yang diprediksi — sebelum tahu apakah prediksi benar. Jika salah: hasil di-rollback, tapi **efek samping di cache tidak di-rollback**. Branch Target Buffer (BTB): tabel prediksi target jump. Return Stack Buffer (RSB): prediksi return address. | **Spectre (2018)**: manipulasi branch predictor → CPU spekulatif akses memori forbidden → bocor via cache side-channel. Tidak bisa fix sempurna tanpa performance hit. Retpoline: mitigasi dengan overhead. | Koneksi langsung ke Spectre/Meltdown CVE, fondasi semua CPU side-channel attack modern |
| **Level 4** — Memory Subsystem *(DRAM, row hammer, ECC, NUMA, memory controller)* | DRAM: kapasitor yang leak charge — butuh refresh. Row hammer: akses baris DRAM berulang cepat → induksi bit flip di baris tetangga secara fisik. ECC (Error Correcting Code): deteksi dan koreksi bit flip 1-bit. NUMA: multi-socket CPU, akses RAM lokal lebih cepat dari remote. | **Rowhammer**: bit flip di DRAM tanpa akses langsung ke memori target. Bisa flip page table entry → privilege escalation. ECC tidak 100% aman dari Rowhammer bertarget. | Koneksi ke Hardware Hacking (physical memory attack), fondasi DRAM forensik |
| **Level 5** — I/O & Peripheral *(PCIe, DMA, IOMMU, interrupt, MMIO)* | PCIe: bus serial berkecepatan tinggi untuk GPU, NVMe, NIC. DMA (Direct Memory Access): peripheral baca/tulis RAM langsung tanpa lewat CPU. IOMMU: unit yang batasi akses DMA peripheral ke region memori tertentu (Intel VT-d, AMD-Vi). MMIO: peripheral di-map ke address space CPU. | **DMA Attack**: peripheral PCIe jahat bisa baca seluruh RAM tanpa izin jika IOMMU tidak aktif/dikonfigurasi. Ini basis DMA cheat (Level 5 Cheat Engine) dan teknik forensik PC-3000. | Koneksi ke DMA Card cheat, koneksi ke PC-3000 forensik, fondasi IOMMU security |
| ☠️ **Level 6** — Microcode & CPU Firmware *(microcode update, undocumented instruction, Intel ME, AMD PSP)* | Instruksi x86 ditranslasikan ke micro-operation internal oleh microcode. Microcode bisa di-update via OS (Intel/AMD rilis patch untuk Spectre dll). Instruksi x86 undocumented: ada di silicon tapi tidak di dokumentasi resmi. Intel ME / AMD PSP: prosesor terpisah di dalam CPU, Ring -3, selalu ON. | Microcode update bisa di-intercept atau diganti (butuh signed update — mitigasi ada). Instruksi undocumented: Christopher Domas menemukan instruksi x86 tersembunyi yang bisa escalate privilege (DEF CON 2018). Intel ME: attack surface yang hampir tidak bisa diaudit. | Koneksi ke Ring -3 Endpoint Security, koneksi ke Eclypsium firmware scanner |

---

## Peta Posisi — Hubungan OS dan Architecture

```
HARDWARE LAYER (Computer Architecture)
│
├── Transistor → Gate → Circuit → CPU
├── Pipeline → Cache → Branch Predictor  ← Spectre ada di sini
├── DRAM → Row Hammer                    ← Rowhammer ada di sini
├── PCIe → DMA → IOMMU                  ← DMA attack ada di sini
└── Microcode → Intel ME                ← Ring -3 ada di sini
│
▼
OS LAYER (OS Internals)
│
├── Kernel (Ring 0)  ← Rootkit, driver exploit ada di sini
├── Syscall interface ← EDR monitoring ada di sini
├── Virtual Memory   ← ASLR, buffer overflow ada di sini
├── File System      ← Forensik, MFT rootkit ada di sini
└── Hypervisor       ← VM escape, Ring -1 ada di sini
│
▼
USER SPACE (Ring 3)
│
└── Aplikasi, malware, antivirus biasa
```

> [!tip] Entry Point untuk Mahasiswa IT
> **Linux Kernel:** baca `Understanding the Linux Kernel` (Bovet & Cesati) atau mulai dari `xv6` — OS sederhana 15.000 baris yang diajarkan MIT, sempurna untuk memahami semua konsep tanpa drowning di kompleksitas kernel production.
> **Architecture:** `Computer Organization and Design` (Patterson & Hennessy) — buku wajib hampir semua CS program di dunia.

> [!warning] Kenapa Ini Wajib Dikuasai
> Semua yang ada di vault ini — rootkit, EDR, container, VM, DMA cheat, Spectre, side-channel attack — tidak akan benar-benar dipahami tanpa fondasi ini. Ini bukan opsional untuk insinyur yang ingin memahami sistem secara mendalam.

---

## 🔗 Lihat Juga

- [[index|Master Index]]
- [[network-security|Network Security]]
- [[hardware-hacking-re|Hardware Hacking]]
- [[cloud-infrastructure|Infrastruktur Cloud]]

---

*Fondasi CS | OS Internals + Computer Architecture · Dari Transistor sampai Kernel Exploit*
