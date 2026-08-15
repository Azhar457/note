---
title: Orkestrasi Meta-Agen
tags:
- meta-agent
- orchestration
- multi-agent
- swarm
- delegation
aliases:
- Orkestrasi Meta-Agen
- Meta-Agent Orchestration
- Agent Swarm Manager
- Conductor
created: 2026-07-09
updated: 2026-08-14
status: pending
cssclasses:
  - wide-table
---

> [!abstract] Satu Agen adalah Alat, Banyak Agen adalah Sistem
> Di sinilah kita melangkah dari *tool use* ke *team management*. Meta-Agen bukanlah agen yang melakukan tugas. Ia adalah **orkestrator** yang memahami kapabilitas agen spesialis, mendelegasikan tugas, mengelola konflik, dan mensintesis hasil. Jika agen adalah karyawan, Meta-Agen adalah Manajer, Arsitek, dan Juri dalam satu paket.

---

## 🏛️ Mengapa Meta-Agen Diperlukan?

Agen tunggal punya keterbatasan mendasar:
1. **Context Window:** Satu agen tidak bisa menangani semua konteks sekaligus.
2. **Spesialisasi:** Model yang jago coding belum tentu jago security analysis.
3. **Resiliensi:** Jika satu agen gagal, seluruh tugas gagal. Dengan Meta-Agen, kegagalan bisa dialihkan.
4. **Skalabilitas:** Meta-Agen bisa menambahkan agen baru tanpa mengubah kode inti.

---

## 🏛️ Fungsi Inti Meta-Agen

### 1. Dynamic Capability Registry

Meta-Agen tidak boleh memiliki daftar agen yang di-hardcode. Agen spesialis harus bisa mendaftar dan keluar secara dinamis (plug-and-play).

**Self-Describing Agents:**

Setiap agen spesialis mendeskripsikan dirinya saat mendaftar:
```json
{
  "agent_id": "agent-code-reviewer-v2",
  "capabilities": ["code_review", "refactor", "lint"],
  "languages": ["Python", "JavaScript", "Rust"],
  "max_context": 10000,
  "cost_per_1k_tokens": 0.10,
  "status": "healthy"
}
```

**Semantic Discovery:**

Meta-Agen tidak mencari nama, tapi mencari **kemampuan**. "Saya butuh agen yang bisa `refactor_code` dan memahami `Rust`." Ia kemudian mencocokkan kebutuhan ini dengan registri menggunakan embedding similarity atau keyword matching.

**Health Probe:**

Setiap 5 menit, Meta-Agen mengirim ping ke semua agen terdaftar. Jika tidak ada respons dalam 30 detik, agen ditandai `UNHEALTHY` dan dikeluarkan dari pool tugas. Ini mencegah delegasi ke agen yang sudah mati.

### 2. Task Orchestration & Decomposition

**LLM-based Planner + DAG Validator:**

Meta-Agen menggunakan model penalaran kuat (o1-style) untuk membuat `ExecutionPlan`. Rencana ini adalah **DAG (Directed Acyclic Graph)** tugas, bukan daftar linear.

Contoh DAG untuk task "Audit Keamanan Server":

```
          ┌──────────────┐
          │ Port Scan    │
          └──────┬───────┘
                 │
          ┌──────▼───────┐
          │ Service      │
          │ Enumeration  │
          └──────┬───────┘
                 │
     ┌───────────┼───────────┐
     │           │           │
┌────▼───┐ ┌────▼───┐ ┌────▼───┐
│ CVE    │ │ Log    │ │ Config │
│ Check  │ │ Review │ │ Audit  │
└────┬───┘ └────┬───┘ └────┬───┘
     │          │          │
     └──────────┼──────────┘
                │
          ┌─────▼──────┐
          │ Synthesis  │
          │ Report     │
          └────────────┘
```

Keuntungan DAG: tugas paralel bisa dijalankan bersamaan, dan kegagalan satu cabang tidak menghentikan cabang lain.

**Dynamic Replanning — Empat Strategi:**

Jika `Agent-X` gagal mengerjakan `Task-B`, Meta-Agen tidak hanya menyerah. Ia memiliki empat strategi bertingkat:

1. **Retry:** "Agent-X, coba lagi dengan petunjuk baru." (1-2 retry, dengan prompt yang dimodifikasi)
2. **Reassign:** "Agent-Y, kamu juga bisa melakukan Task-B. Tolong ambil alih." (hanya jika ada agen alternatif dengan kapabilitas sama)
3. **Decompose Further:** "Task-B terlalu sulit. Mari kita pecah menjadi Task-B1 dan Task-B2." (gunakan LLM untuk memecah ulang)
4. **Escalate:** "Semua agen gagal. Task-B memerlukan input manusia." (Human-in-the-Loop — kirim notifikasi ke pengguna)

Prioritas: retry → reassign → decompose → escalate. Jangan pernah lompat ke escalate sebelum mencoba yang lain.

### 3. Synthesis & Conflict Resolution

Ketika banyak agen memberikan input, bagaimana Meta-Agen menghasilkan satu output yang koheren?

**Blackboard Integration (Papan Tulis Bersama):**

Semua agen menulis hasil mereka ke struktur data bersama (blackboard). Blackboard ini berisi:
- `shared_context`: fakta yang sudah diverifikasi oleh minimal satu agen.
- `disputed_facts`: klaim yang kontradiktif antar agen.
- `pending_verification`: klaim yang baru diajukan, belum diperiksa.

Meta-Agen membaca blackboard dan mensintesis jawaban akhir. Keuntungan: agen tidak perlu berkomunikasi langsung satu sama lain.

**Debate + Arbiter (Swarm Intelligence):**

Untuk keputusan kritis, Meta-Agen bisa menjalankan protokol debat:

1. Meta-Agen memberi masalah yang sama ke `Agent-A` dan `Agent-B`.
2. Masing-masing memberikan solusi lengkap dengan reasoning.
3. Meta-Agen meminta `Agent-C` (Arbiter) untuk menilai dan memilih solusi terbaik — atau mensintesis elemen terbaik dari keduanya.
4. Arbiter menambahkan confidence score pada keputusan akhir.

**Deteksi Konflik Otomatis:**

Meta-Agen secara konstan memindai blackboard untuk kontradiksi: jika `Agent-A` mengatakan "Port 443 terbuka" dan `Agent-B` mengatakan "Port 443 tertutup (filtered)", Meta-Agen mendeteksi kontradiksi ini dan menginisiasi prosedur resolusi. Ini bisa berupa verifikasi ulang oleh agen ketiga, atau eksekusi tool verifikasi (misal: `nmap` langsung).

### 4. Agent Lifecycle Management

**Horizontal Scaling:**

Jika antrian tugas untuk "analisis sentimen" sedang panjang (antrian > 10 tugas), Meta-Agen bisa meminta sistem untuk *spawn* (menghidupkan) lebih banyak instance `Agent-Sentiment-Analyzer`. Ini adalah *auto-scaling* untuk agen — persis seperti Kubernetes menambah pod. Threshold scaling: antrian > N tugas selama > 60 detik.

**Health Monitoring:**

Meta-Agen memonitor tiga metrik utama setiap agen:
- **Latency:** Waktu respons rata-rata. Jika > 30 detik, tandai WARNING.
- **Error Rate:** Persentase tugas gagal. Jika > 10%, tandai UNHEALTHY.
- **Hallucination Rate:** (Diperiksa oleh Quality Gate) Jika skor faithfulness < 0.7, tandai UNHEALTHY.

Agen `UNHEALTHY` tidak lagi diberi tugas sampai pulih — dan penyebabnya dicatat untuk debugging.

---

## 🧠 Diagram: Arsitektur Orkestrasi

```
┌───────────────────────────────────────────────────────────────────────┐
│                    ORKESTRASI META-AGEN (Conductor)                     │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐   │
│  │ INPUT & TUJUAN   │   │ REGISTRI AGEN    │   │ KONTEKS GLOBAL   │   │
│  │ (Dari User/Goal) │   │ (Dynamic Registry)│   │ (Blackboard)     │   │
│  └────────┬─────────┘   └────────┬─────────┘   └────────┬──────────┘   │
│           │                      │                      │              │
│           ▼                      ▼                      ▼              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                PERENCANA (Planner & Decomposer)                  │   │
│  │ • Task DAG Generator  • Resource Estimator  • Dynamic Replanning │   │
│  └──────────────────────────────┬──────────────────────────────────┘   │
│                                 │                                      │
│                                 ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                EKSEKUTOR (Dispatcher & Monitor)                  │   │
│  │ • A2A Protocol  • Fault Recovery  • Auto-Scale                  │   │
│  └───────┬─────────────────┬─────────────────┬─────────────────────┘   │
│          │                 │                 │                         │
│          ▼                 ▼                 ▼                         │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐                      │
│  │ Agent    │      │ Agent    │      │ Agent    │  ... (Specialists)   │
│  │ Code     │      │ Research │      │ Security │                      │
│  └──────────┘      └──────────┘      └──────────┘                      │
│                                                                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                ARBITER (Synthesis & Conflict Resolution)         │   │
│  │ • Debate Manager  • Consensus Engine  • Quality Gate (Eval)      │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Koneksi ke Vault

| Konsep | Dokumen Pendukung |
| :--- | :--- |
| Multi-Agent Framework | [[agentic-ai-mcp-roadmap]] (Fase 5: Multi-Agent) |
| Agent Communication Protocol | [[ai-comm-protocol-deep-dive]] (A2A, Gibberlink) |
| Orchestration Pillar | [[cognitive-architecture-engineering]] (Pilar 1, 3) |
| Goal Management | [[autonomous-system-design]] (Goal Tree Manager) |
| ACO Agent Routing | [[aco-agent-routing-deepdive]] (pheromone dispatch) |
| Evaluator as First-Class | [[ai-evaluation-framework]], [[test-time-compute-system2]] (PRM) |
| Agent Security | [[llm-security-red-teaming-attack-surface-ai-layer]] (Tool Sandboxing) |
| MCP Integration | [[agentic-ai-mcp-architecture-deepdive]] (Tool Use, MCP) |

---

## 🎯 Contoh Skenario: Meta-Agen dalam Aksi

**Tugas:** "Audit keamanan server web produksi dan buat laporan."

1. **Input:** Meta-Agen menerima perintah dari user.
2. **Plan:** Buat DAG: Port Scan → Service Enumeration → (CVE Check || Log Review || Config Audit) → Synthesis.
3. **Dispatch:** Kirim `Port Scan` ke Agent-Security. Kirim `Log Review` ke Agent-Analytics. Jalankan paralel.
4. **Monitor:** Agent-Security selesai dalam 10 detik. Agent-Analytics masih berjalan. Meta-Agen menunggu.
5. **Conflict:** Agent-Security bilang "nginx 1.24" tapi Config Audit bilang "nginx 1.22". Meta-Agen deteksi konflik. Kirim verifikasi ke Agent-C.
6. **Synthesis:** Setelah semua selesai, Meta-Agen kumpulkan hasil, format laporan, dan kirim ke user.
7. **Log:** Semua langkah dicatat di Episodic Memory untuk pembelajaran berikutnya.

---

*Orkestrasi Meta-Agen — 2026-07-09*
---

audited
---
