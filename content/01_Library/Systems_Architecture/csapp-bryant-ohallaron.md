---
title: 'Computer Systems: A Programmer''s Perspective (CS:APP)'
tags:
- library
- systems-architecture
created: '2026-07-05'
updated: '2026-07-05'
status: pending
cssclasses:
  - wide-table
  - callout

---
# 🖥 Computer Systems: A Programmer's Perspective
> Randal E. Bryant & David R. O'Hallaron — 2003 (3rd ed 2015)

**Tesis:** Programmer yang paham *bagaimana kodenya jalan di mesin* → bikin code yang lebih cepat, lebih aman, lebih bisa di-debug. Bukan soal jadi expert arsitektur — soal *jembatani gap* antara high-level language dan hardware.

## 📌 Kenapa Penting

- Buku yang menjawab: "kenapa C code ini lambat padahal algoritma udah optimal?"
- Performance optimization bukan trik — ilmu tentang memori hierarchy, pipelining, branching
- Debugging segfault / buffer overflow → paham stack layout, calling convention
- Dalam pengembangan perangkat lunak, memahami sistem komputer sangat penting untuk meningkatkan kualitas kode yang dihasilkan.
- Mengetahui bagaimana kode berjalan di mesin juga membantu dalam memecahkan masalah yang sulit dan meningkatkan keamanan kode.

## 🎯 Key Takeaways

**1. Representasi Data — Bits, Bytes, Integers**
- Little Endian vs Big Endian — penting buat networking
- Two's complement — overflow behavior
- Floating point — IEEE 754 — kenapa 0.1 + 0.2 != 0.3
- Representasi data yang benar sangat penting dalam pengembangan perangkat lunak.
- Memahami little endian dan big endian dapat membantu dalam pengiriman data melalui jaringan.
- Two's complement digunakan untuk merepresentasikan bilangan negatif dalam biner.
- IEEE 754 adalah standar untuk representasi floating point yang digunakan dalam komputer modern.

**2. Machine-Level Code — Assembly (x86-64)**
- Register, stack, calling convention (System V ABI)
- **Paling berguna buat debugging:** baca disassembly waktu crash
- Control flow: conditional, loop, switch — gimana compiler optimize
- Assembly adalah bahasa pemrograman yang paling dekat dengan mesin.
- Memahami assembly dapat membantu dalam debugging kode yang kompleks.
- System V ABI adalah standar untuk calling convention dalam sistem operasi Unix-like.
- Compiler dapat mengoptimalkan kode dengan menggunakan control flow yang tepat.

**3. Memory Hierarchy**
- **CPU → L1 → L2 → L3 → RAM → Disk** — urutan kecepatan (1000x gap)
- **Cache Locality** — spatial + temporal — bedanya 10-100x performance
  - Loop order matters: row-major > column-major
- Cache miss = stall pipeline = CPU nganggur
- Memory hierarchy sangat penting dalam sistem komputer karena mempengaruhi kecepatan akses data.
- Cache locality dapat meningkatkan performa kode dengan mengurangi cache miss.
- Loop order yang tepat dapat mempengaruhi performa kode dengan mengurangi cache miss.

**4. Linking**
- Symbol resolution + relocation — kenapa linker errors
- Static vs dynamic linking — trade-off size, security, startup time
- Library interpositioning — LD_PRELOAD
- Linking adalah proses yang menghubungkan kode objek dengan library yang diperlukan.
- Symbol resolution dan relocation adalah proses yang dilakukan oleh linker untuk menghasilkan kode yang dapat dijalankan.
- Static linking dan dynamic linking memiliki trade-off yang berbeda dalam hal ukuran, keamanan, dan waktu startup.

**5. Exceptional Control Flow**
- Interrupt, trap, fault, abort — bedanya
- Context switch — proses scheduler preempt your code
- Signals — asynchronous handling
- Exceptional control flow adalah mekanisme yang digunakan oleh sistem operasi untuk menangani situasi yang tidak diharapkan.
- Interrupt, trap, fault, dan abort adalah jenis-jenis exceptional control flow yang berbeda.
- Context switch adalah proses yang dilakukan oleh proses scheduler untuk mengganti proses yang sedang berjalan.
- Signals adalah mekanisme yang digunakan untuk menangani peristiwa yang tidak diharapkan secara asynchronous.

**6. Virtual Memory**
- Page table — address translation via TLB
- **MMU mismatch = performance killer** — TLB miss
- mmap — memory-mapped files
- COW (Copy-On-Write) — fork() efficient
- Virtual memory adalah teknologi yang memungkinkan sistem komputer untuk menggunakan memori yang lebih besar daripada memori fisik yang tersedia.
- Page table adalah data struktur yang digunakan untuk menerjemahkan alamat virtual menjadi alamat fisik.
- MMU (Memory Management Unit) adalah komponen yang bertanggung jawab untuk menerjemahkan alamat virtual menjadi alamat fisik.
- TLB (Translation Lookaside Buffer) adalah cache yang digunakan untuk mempercepat proses penerjemahan alamat.

**7. System-Level I/O**
- Unix file descriptors, buffer management
- Non-blocking I/O, select, epoll
- System-level I/O adalah mekanisme yang digunakan untuk melakukan input/output pada level sistem operasi.
- Unix file descriptors adalah integer yang digunakan untuk mengidentifikasi file yang dibuka.
- Buffer management adalah proses yang digunakan untuk mengelola buffer yang digunakan untuk melakukan I/O.
- Non-blocking I/O adalah teknik yang digunakan untuk melakukan I/O tanpa memblokir proses yang sedang berjalan.

**8. Concurrency**
- Threads vs processes — sharing vs isolation
- Mutex, semaphore, deadlock
- Cache coherence — false sharing (performance killer)
- Concurrency adalah kemampuan sistem komputer untuk melakukan beberapa tugas secara bersamaan.
- Threads dan processes adalah dua jenis concurrency yang berbeda.
- Mutex dan semaphore adalah mekanisme yang digunakan untuk mengelola akses ke sumber daya yang dibagi.
- Deadlock adalah situasi yang terjadi ketika dua atau lebih proses tidak dapat melanjutkan karena mereka sedang menunggu sumber daya yang dibagi.

## 📖 Bab Penting

| Bab | Judul | Mengapa |
|-----|-------|---------|
| 3 | Machine-Level Programming | Assembly + debugging — **wajib** |
| 5 | Optimizing Program Performance | Loop optimization, branch prediction, cache |
| 6 | Memory Hierarchy | **Kunci performance** — cache matters |
| 9 | Virtual Memory | Soal kenapa RAM gak cukup → swap, mmap |
| 12 | Concurrent Programming | Threads, locks, deadlock |

## ⚠️ Tantangan

- **Butuh C knowledge** — contoh kode semuanya C
- Fokus x86-64 — gak cover ARM (tapi konsep transferable)
- Lab (Bomb Lab, Attack Lab, Shell Lab) — bagian paling bagus tapi butuh setup
- Buku ini memerlukan pengetahuan tentang bahasa C untuk memahami contoh kode yang disajikan.
- Buku ini fokus pada arsitektur x86-64, tetapi konsep yang disajikan dapat diterapkan pada arsitektur lain.
- Lab yang disajikan dalam buku ini sangat berguna untuk mempraktekan konsep yang dipelajari, tetapi memerlukan setup yang tepat.

## 🚦 Strategi Baca

1. **Ch 1-3**: bits, assembly, debugging — pain point immediate
2. **Ch 5-6**: performance optimization + cache — *biggest bang for buck*
3. **Ch 9**: virtual memory — paham kenapa proses terisolasi
4. **Ch 12**: concurrency
5. Lab resources di **csapp.cs.cmu.edu** — Bomb Lab highly recommended
- Baca bab 1-3 untuk memahami dasar-dasar sistem komputer.
- Baca bab 5-6 untuk memahami optimasi performa dan cache.
- Baca bab 9 untuk memahami virtual memory.
- Baca bab 12 untuk memahami concurrency.
- Gunakan sumber daya lab yang disediakan untuk mempraktekan konsep yang dipelajari.

## 🔗 Koneksi

- [[ostep-three-easy-pieces]] — OS bagian dari CS:APP, OSTEP cover lebih detail
- [[clrs-introduction-to-algorithms]] — algoritma *logical*, CS:APP *mechanical*
- [[clean-code-robert-martin]] — clean code gak cukup kalo gak paham hardware impact
- Buku ini terkait dengan Operating System (OS) dan dapat dipelajari bersama dengan OSTEP.
- Buku ini juga terkait dengan algoritma dan dapat dipelajari bersama dengan CLRS.
- Buku ini juga terkait dengan clean code dan dapat dipelajari bersama dengan Clean Code.

## ✅ Checklist

- [ ] Baca assembly output dari compiler — `objdump -d` atau Godbolt
- [ ] Profile 1 fungsi — cache misses, branch mispredictions (perf stat)
- [ ] Optimize 1 loop — transpose loop order, test speedup
- [ ] Debug 1 segfault — pake GDB + backtrace (paham stack frame)
- Baca assembly output dari compiler untuk memahami bagaimana kode berjalan di mesin.
- Profile 1 fungsi untuk memahami performa kode.
- Optimize 1 loop untuk meningkatkan performa kode.
- Debug 1 segfault untuk memahami bagaimana kode berjalan di mesin.

### Contoh Kode

Berikut adalah contoh kode yang dapat digunakan untuk memahami konsep yang dipelajari:
```c
#include <stdio.h>

int main() {
    // Contoh penggunaan pointer
    int x = 10;
    int* p = &x;
    printf("%d\n", *p);

    // Contoh penggunaan struct
    struct Person {
        int age;
        char name[20];
    };
    struct Person person;
    person.age = 25;
    strcpy(person.name, "John");
    printf("%d %s\n", person.age, person.name);

    return 0;
}
```
Contoh kode di atas dapat digunakan untuk memahami konsep pointer dan struct.

### Kesimpulan

Buku "Computer Systems: A Programmer's Perspective" adalah buku yang sangat penting untuk dipelajari oleh programmer karena membahas tentang sistem komputer dan bagaimana kode berjalan di mesin. Buku ini membahas tentang konsep-konsep dasar seperti bit, byte, dan integer, serta konsep-konsep lanjutan seperti optimasi performa, cache, dan concurrency. Dengan mempelajari buku ini, programmer dapat memahami bagaimana kode berjalan di mesin dan dapat meningkatkan performa kode dengan menggunakan teknik-teknik yang dipelajari.
---

audited
---
