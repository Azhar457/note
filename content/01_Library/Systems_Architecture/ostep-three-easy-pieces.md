---
title: "Operating Systems: Three Easy Pieces (OSTEP)"
tags:
  - library
  - systems-architecture
aliases:
  - "ostep-three-easy-pieces"
created: "2026-07-05"
updated: "2026-07-05"
status: active
---

# 🧵 Operating Systems: Three Easy Pieces

> Remzi H. Arpaci-Dusseau & Andrea C. Arpaci-Dusseau — 2018

**Tesis:** OS dibagi 3 pilar — **Virtualization** (CPU+memory), **Concurrency** (threads+locks), **Persistence** (file systems+disks). Dengan paham 3 ini, kamu paham gimana komputer kerja dari OS perspective.

**Akses:** Free online → https://pages.cs.wisc.edu/~remzi/OSTEP/

## 📌 Kenapa Penting

- OS textbook yang readable — gak kaya textboook kebanyakan
- Paham OS = paham _kenapa_ code kamu lambat, crash, atau kehabisan memory
- Disk scheduling, FAT vs ext4 vs NTFS, RAID — langsung relevan buat system design
- Pemahaman OS sangat penting bagi developer dan sistem administrator untuk memahami bagaimana komputer bekerja dan bagaimana mengoptimalkan sistem.

## 🎯 Key Takeaways

### Part 1: Virtualization

**CPU Virtualization — Scheduling**

- Metrics: turnaround time, response time, fairness
- **FIFO** (simple, bad for short jobs)
- **SJF** (optimal turnaround, starvation)
- **Round Robin** (good response time, bad turnaround)
- **MLFQ** (blend — used in real OS) — multiple levels, priority boost, time slice
- Contoh kode implementasi MLFQ scheduler:

```c
// mlq_scheduler.c
#include <stdio.h>
#include <stdlib.h>

// Struktur untuk proses
typedef struct {
    int id;
    int burst_time;
} Process;

// Fungsi untuk menjalankan MLFQ scheduler
void mlfq_scheduler(Process* processes, int num_processes) {
    // Inisialisasi queue untuk setiap level
    Queue* queues[3];
    for (int i = 0; i < 3; i++) {
        queues[i] = create_queue();
    }

    // Menambahkan proses ke queue
    for (int i = 0; i < num_processes; i++) {
        add_process(queues[0], processes[i]);
    }

    // Menjalankan scheduler
    while (1) {
        // Mengambil proses dari queue
        Process* process = get_next_process(queues[0]);
        if (process == NULL) break;

        // Menjalankan proses
        run_process(process);

        // Memindahkan proses ke queue berikutnya
        add_process(queues[1], process);
    }
}

int main() {
    // Membuat proses
    Process processes[5];
    for (int i = 0; i < 5; i++) {
        processes[i].id = i;
        processes[i].burst_time = i * 10;
    }

    // Menjalankan MLFQ scheduler
    mlfq_scheduler(processes, 5);

    return 0;
}
```

**Memory Virtualization**

- Address translation: base & bounds → segmentation → paging
- **TLB** (Translation Lookaside Buffer) — performance critical
- Page tables: multi-level (saves memory for sparse address space)
- Swapping: eviction policies (LRU ≈ optimal, FIFO simplest, Clock algorithm ≈ LRU-like)
- Contoh kode implementasi page table:

```c
// page_table.c
#include <stdio.h>
#include <stdlib.h>

// Struktur untuk page table
typedef struct {
    int page_number;
    int frame_number;
} PageTable;

// Fungsi untuk membuat page table
PageTable* create_page_table(int num_pages) {
    PageTable* page_table = malloc(sizeof(PageTable) * num_pages);
    for (int i = 0; i < num_pages; i++) {
        page_table[i].page_number = i;
        page_table[i].frame_number = -1;
    }
    return page_table;
}

// Fungsi untuk menambahkan page ke page table
void add_page(PageTable* page_table, int page_number, int frame_number) {
    for (int i = 0; i < num_pages; i++) {
        if (page_table[i].page_number == page_number) {
            page_table[i].frame_number = frame_number;
            break;
        }
    }
}

int main() {
    // Membuat page table
    int num_pages = 10;
    PageTable* page_table = create_page_table(num_pages);

    // Menambahkan page ke page table
    add_page(page_table, 0, 0);
    add_page(page_table, 1, 1);

    return 0;
}
```

### Part 2: Concurrency

- **Thread vs Process** — shared address space vs isolated
- **Locks:** test-and-set, compare-and-swap, fetch-and-add
- **Spin locks** vs **Mutex** (sleeping locks)
- **Condition Variables** — signaling between threads
- **Semaphores** — generalization of locks + CVs (bounded buffer → producer-consumer)
- **Deadlock:** Coffman conditions (all 4 must hold) + prevention strategies
- Contoh kode implementasi producer-consumer menggunakan semaphores:

```c
// producer_consumer.c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>

// Struktur untuk buffer
typedef struct {
    int data;
    sem_t empty;
    sem_t full;
    pthread_mutex_t mutex;
} Buffer;

// Fungsi untuk producer
void* producer(void* arg) {
    Buffer* buffer = (Buffer*) arg;
    for (int i = 0; i < 10; i++) {
        sem_wait(&buffer->empty);
        pthread_mutex_lock(&buffer->mutex);
        buffer->data = i;
        pthread_mutex_unlock(&buffer->mutex);
        sem_post(&buffer->full);
    }
    return NULL;
}

// Fungsi untuk consumer
void* consumer(void* arg) {
    Buffer* buffer = (Buffer*) arg;
    for (int i = 0; i < 10; i++) {
        sem_wait(&buffer->full);
        pthread_mutex_lock(&buffer->mutex);
        int data = buffer->data;
        pthread_mutex_unlock(&buffer->mutex);
        sem_post(&buffer->empty);
        printf("%d\n", data);
    }
    return NULL;
}

int main() {
    // Membuat buffer
    Buffer buffer;
    sem_init(&buffer.empty, 0, 1);
    sem_init(&buffer.full, 0, 0);
    pthread_mutex_init(&buffer.mutex, NULL);

    // Membuat thread
    pthread_t producer_thread;
    pthread_t consumer_thread;
    pthread_create(&producer_thread, NULL, producer, &buffer);
    pthread_create(&consumer_thread, NULL, consumer, &buffer);

    // Menunggu thread selesai
    pthread_join(producer_thread, NULL);
    pthread_join(consumer_thread, NULL);

    return 0;
}
```

### Part 3: Persistence

- **Disks:** seek + rotation + transfer — _I/O time dominated by seek_
- **RAID 0, 1, 4, 5, 6** — redundancy vs capacity vs performance trade-offs
- **File Systems:**
  - FFS (Unix Fast File System) — cylinder groups, block groups
  - ext2 → ext3 (journaling) → ext4 (extents)
  - **Journaling (WAL):** atomicity — write intent log first
  - **LFS (Log-structured FS):** treat disk as log — Netflix's approach
- Contoh kode implementasi file system:

```c
// file_system.c
#include <stdio.h>
#include <stdlib.h>

// Struktur untuk file system
typedef struct {
    int block_size;
    int num_blocks;
} FileSystem;

// Fungsi untuk membuat file system
FileSystem* create_file_system(int block_size, int num_blocks) {
    FileSystem* file_system = malloc(sizeof(FileSystem));
    file_system->block_size = block_size;
    file_system->num_blocks = num_blocks;
    return file_system;
}

// Fungsi untuk menulis data ke file system
void write_data(FileSystem* file_system, int block_number, char* data) {
    // Mencari block yang kosong
    for (int i = 0; i < file_system->num_blocks; i++) {
        if (i == block_number) {
            // Menulis data ke block
            printf("Menulis data ke block %d\n", i);
            break;
        }
    }
}

int main() {
    // Membuat file system
    int block_size = 1024;
    int num_blocks = 10;
    FileSystem* file_system = create_file_system(block_size, num_blocks);

    // Menulis data ke file system
    char* data = "Hello, World!";
    write_data(file_system, 0, data);

    return 0;
}
```

## 📖 Bab Penting

| Bab   | Judul                 | Mengapa                                   |
| ----- | --------------------- | ----------------------------------------- |
| 4-8   | CPU Scheduling        | MLFQ — bagaimana OS manage your processes |
| 13-16 | Memory Virtualization | Paging, TLB — **wajib**                   |
| 26-31 | Concurrency & Locks   | Threads, semaphore, deadlock — **wajib**  |
| 36-40 | File Systems          | ext3 journal, LFS, WAFL                   |
| 41    | Flash SSD             | —                                         |
| 47-51 | Distribution          | NFS, AFS — distributed filesystems        |

## ⚠️ Tantangan

- **Projects in C** — gak ada yang nyelametin dari pointer arithmetic
- Soal latihan butuh simulator Python yang disediain (beres)
- Cover to cover ≈ 500 hal — readable tapi tetap butuh waktu
- Pemahaman konsep dasar sangat penting sebelum memulai

## 🔗 Koneksi

- [[csapp-bryant-ohallaron]] — CS:APP = programmer perspective, OSTEP = OS designer perspective
- [[ddia-kleppmann]] — distributed systems butuh OS fundamentals
- [[sre-google]] — reliability juga soal OS level (OOM, I/O scheduling)

## ✅ Checklist

- [ ] Simulasi MLFQ scheduler — bandwidth pakenya?
- [ ] Paging simulation: multi-level page table savings
- [ ] Concurrency: solve producer-consumer + reader-writer pake semaphores
- [ ] Implementasi simple filesystem simulator (inode + data block)
- [ ] Baca soal RAID — kapan pilih RAID 0, 1, 5, 6, 10?

Dengan memahami konsep dasar operating system, kamu dapat memahami bagaimana komputer bekerja dan bagaimana mengoptimalkan sistem. Buku OSTEP sangat penting bagi developer dan sistem administrator yang ingin memahami bagaimana operating system bekerja. Dengan melakukan simulasi dan implementasi, kamu dapat memahami konsep dasar operating system dengan lebih baik.
