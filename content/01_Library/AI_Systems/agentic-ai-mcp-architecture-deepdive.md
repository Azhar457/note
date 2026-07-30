---
tags:
  - agentic-ai
  - mcp
  - tool-use
  - react
  - memory
  - multi-agent
  - orchestration
aliases:
  - Agentic AI Roadmap
  - MCP Deep Dive
  - AI Agent Architecture
created: 2026-07-09
status: pending
cssclasses:
  - wide-table
---

# 🤖 AGENTIC AI & MCP — Arsitektur Otonomi Kognitif

**Dari Prompt ke Swarm: Sebuah Deep Dive Arsitektural**

> [!abstract] Filosofi Fundamental
> Transisi dari LLM statis ke Agentic AI adalah transisi dari **mesin inferensi** ke **mesin otonomi**. Sebuah LLM hanya menghasilkan teks. Sebuah Agen menghasilkan **aksi**. Ia tidak hanya "berpikir", ia "berpikir tentang bagaimana berpikir, lalu bertindak, lalu mengamati hasil tindakannya, dan memperbaiki diri." Dokumen ini adalah cetak biru arsitektur kognitif untuk agen AI: dari loop fundamental hingga orkestrasi multi-agen.

---

## 🧬 First Principles: Dari Token ke Tindakan

Untuk membangun agen yang tangguh, kita harus memahami transisi fundamental ini:

1.  **Inferensi Statis (LLM Murni):** `Input Tokens → Model → Output Tokens`. Tidak ada status, tidak ada memori, tidak ada efek samping.
2.  **Inferensi Terstruktur:** `Input + Schema → Model → JSON Valid`. Model dipaksa menghasilkan output yang bisa diparsing mesin. Ini adalah fondasi _tool use_.
3.  **Eksekusi (Agen Sederhana):** `Input + Schema → JSON → Action(JSON)`. Output JSON berisi nama fungsi dan argumen yang dieksekusi oleh _runtime_ (Python/JS).
4.  **Siklus Kognitif (Agen Otonom):** `Observe → Plan → Act → Observe → ...`. Agen menghasilkan aksi, menjalankannya, menerima umpan balik, dan memasukkannya kembali ke konteks untuk keputusan berikutnya. Ini adalah **ReAct Loop** — jantung agen modern.

---

## 🏗️ Arsitektur Kognitif Agen

Setiap agen otonom memiliki empat komponen inti yang membentuk _"otak digital"_:

| Komponen                         | Fungsi Kognitif                                           | Implementasi Teknis                                                         |
| -------------------------------- | --------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Model (Otak)**                 | Penalaran, Perencanaan, Kreativitas                       | LLM (GPT-4, Llama 3, DeepSeek) via API atau lokal                           |
| **Tools (Tangan)**               | Eksekusi aksi di dunia nyata/digital                      | Fungsi Python, API Eksternal, MCP Server, Browser                           |
| **Memory (Hipokampus)**          | Penyimpanan dan pengambilan informasi                     | Working Memory (Context Window), Short-Term (Buffer), Long-Term (Vector DB) |
| **Planner (Korteks Prefrontal)** | Dekomposisi tugas, alokasi sumber daya, koreksi kesalahan | Prompting (CoT, ToT), Task Graph, Finite State Machine                      |

### Siklus OODA Agen (ReAct)

Agen beroperasi dalam siklus _Observe-Orient-Decide-Act_ yang kontinu. Dalam konteks AI, ini diterjemahkan menjadi **ReAct (Reasoning + Acting)**:

1.  **Observe (Observasi):** Agen menerima input (perintah pengguna, hasil tool sebelumnya, pesan dari agen lain). Ini adalah _umpan balik lingkungan_.
2.  **Reason (Orientasi + Analisis):** Model memproses observasi dalam konteks memori dan tujuannya. Ia menghasilkan _Thought_ (pemikiran) — analisis situasi dan kebutuhan.
3.  **Act (Keputusan + Eksekusi):** Berdasarkan penalaran, model menghasilkan _Action_ (tindakan). Ini bisa berupa:
    - `Tool Call`: Memanggil fungsi eksternal (hitung, cari, kirim).
    - `Ask User`: Meminta klarifikasi ke pengguna (Human-in-the-Loop).
    - `Finish`: Menyelesaikan tugas dan mengembalikan hasil akhir.
4.  **Evaluate (Evaluasi Diri):** Hasil tindakan (_Observation_) dimasukkan kembali ke konteks. Agen menilai apakah tindakannya membawanya lebih dekat ke tujuan atau justru menghasilkan kesalahan.

```
╔═══════════════════════════════════════════════════════╗
║                 The ReAct Cognitive Loop              ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║   ┌──────────┐      ┌──────────┐      ┌──────────┐   ║
║   │ OBSERVE  │─────►│  REASON  │─────►│   ACT    │   ║
║   └──────────┘      └──────────┘      └──────────┘   ║
║         ▲                                  │          ║
║         │                                  ▼          ║
║         │                             ┌──────────┐   ║
║         └─────────────────────────────│ EVALUATE │   ║
║                                       └──────────┘   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

---

## 🔩 Deep Dive 1: Anatomi Tool Use & Eksekusi yang Tangguh

_Tool Use_ adalah jembatan antara _language_ dan _action_. Tanpa eksekusi yang tangguh, agen hanyalah chatbot yang bisa berhalusinasi tentang tindakan.

### Definisi Tool yang Aman (Dengan Pydantic)

Setiap tool harus didefinisikan secara ketat. Ini bukan hanya untuk kenyamanan, tetapi untuk **keamanan**. Tanpa validasi, LLM bisa menyuntikkan parameter berbahaya.

```python
from pydantic import BaseModel, Field
from typing import Optional, Literal

class ExecuteCodeInput(BaseModel):
    """Input untuk tool eksekusi kode. HARUS divalidasi."""
    code: str = Field(description="Kode Python untuk dieksekusi. DILARANG: os.system, subprocess, eval.")
    timeout: int = Field(default=30, le=60, description="Timeout eksekusi maksimal (detik)")

    # Validator kustom untuk memblokir perintah berbahaya
    @field_validator('code')
    def block_dangerous_imports(cls, v):
        blocked_keywords = ['os.system', 'subprocess', 'eval(', 'exec(', 'import shutil']
        for keyword in blocked_keywords:
            if keyword in v:
                raise ValueError(f'Perintah berbahaya terdeteksi: {keyword}')
        return v
```

### Model Eksekusi yang Tak Lekang Waktu

Agen tidak boleh crash. Ia harus menangani setiap mode kegagalan dengan anggun.

```python
class RobustToolExecutor:
    def execute(self, tool_name: str, params: dict) -> dict:
        tool = self.tools.get(tool_name)
        if not tool: return {"error": "ToolNotFound", "message": f"'{tool_name}' tidak ada."}

        try:
            # 1. Validasi Input
            validated_params = tool.input_model(**params)

            # 2. Eksekusi
            result = tool.func(**validated_params.model_dump())

            # 3. Potong Output (Cegah Context Overflow)
            result_str = str(result)
            if len(result_str) > 10000:
                result_str = result_str[:10000] + "... [TRUNCATED]"

            return {"status": "success", "result": result_str}

        except Exception as e:
            # 4. Kembalikan Error Terstruktur, Bukan Traceback
            return {"status": "error", "type": type(e).__name__, "message": str(e)}
```

### Sirkuit Pemutus (Circuit Breaker)

Untuk mencegah _infinite loop_, agen harus memiliki _circuit breaker_.

```python
class AgentCircuitBreaker:
    MAX_CONSECUTIVE_FAILURES = 3

    def step(self, agent_state):
        if agent_state.consecutive_failures >= self.MAX_CONSECUTIVE_FAILURES:
            raise AgentStuckError("Agen terjebak dalam lingkaran kesalahan.")

        # ... eksekusi tool ...
```

---

## 🧠 Deep Dive 2: Arsitektur Memori — Lebih dari Sekadar Konteks

Memori adalah jiwa agen. Ia membedakan agen yang "ingat" dari sekadar API call stateless.

### Hirarki Memori

| Jenis Memori                | Analogi Manusia                   | Implementasi                           | Fungsi                                                    |
| --------------------------- | --------------------------------- | -------------------------------------- | --------------------------------------------------------- |
| **Working Memory**          | Memori Jangka Pendek              | `Context Window` LLM                   | Informasi yang sedang diproses saat ini.                  |
| **Short-Term Memory (STM)** | Mengingat percakapan 5 menit lalu | List of Messages (Buffer)              | Menyimpan seluruh riwayat percakapan. Ringkas saat penuh. |
| **Long-Term Memory (LTM)**  | Mengingat proyek dari bulan lalu  | **Vector Database** (ChromaDB, Qdrant) | Menyimpan dan mencari fakta, konsep, dan entitas penting. |
| **Procedural Memory**       | Tahu _cara_ melakukan sesuatu     | Definisi Tool + System Prompt          | Pengetahuan yang sudah terprogram.                        |
| **Episodic Memory**         | Mengingat kejadian spesifik       | Log Aksi + Timeline                    | Riwayat lengkap tindakan dan hasilnya.                    |

### Strategi Retrieval yang Cerdas

Mengambil memori yang tepat adalah tantangan kunci.

```python
class IntelligentRetriever:
    def retrieve(self, query: str, context: AgentContext) -> List[Memory]:
        # 1. Semantic Search (berdasarkan makna)
        semantic_results = self.vector_db.similarity_search(query, k=5)

        # 2. Recency Boost (nilai memori baru lebih tinggi)
        for mem in semantic_results:
            mem.relevance_score *= (1 + mem.recency_factor)

        # 3. Importance Filter (hanya memori di atas ambang batas)
        important_memories = [mem for mem in semantic_results if mem.relevance_score > 0.7]

        return sorted(important_memories, key=lambda x: x.relevance_score, reverse=True)
```

---

## 🔌 Deep Dive 3: Model Context Protocol (MCP) — Tulang Punggung Interoperabilitas

MCP adalah standar terbuka yang memungkinkan agen untuk menemukan, memanggil, dan mengelola alat dari berbagai sumber secara seragam. Ini adalah "USB-C untuk Alat AI."

### Arsitektur Klien-Server MCP

MCP menggunakan arsitektur klien-server. _MCP Host_ (misalnya, aplikasi chat) menjalankan _MCP Client_, yang terhubung ke _MCP Server_. Server mengekspos _Resources_ (data), _Tools_ (fungsi), dan _Prompts_ (template).

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│    MCP Host     │      │    MCP Client    │      │   MCP Server    │
│ (Contoh: Chat)  │◄────►│ (Python Library) │◄────►│ (Custom Code)   │
│                 │      │                 │      │                 │
│ • User Interface│      │ • Server Manager │      │ • Tools:        │
│ • Auth           │      │ • Transport     │      │   - search_file │
│ • State Mgmt    │      │   Handler       │      │   - read_note   │
└─────────────────┘      └─────────────────┘      └─────────────────┘
```

### Fitur _Tool Self-Description_

Server MCP mendeskripsikan alatnya sendiri. Klien dapat menemukan alat baru tanpa konfigurasi manual.

```python
# Server MCP (Python) — self-describing tool
from mcp.server import Server
from mcp.types import Tool

server = Server("my-vault-server")

@server.tool(
    name="search_vault",
    description="Cari catatan di vault Obsidian berdasarkan query.",
    input_schema={
        "type": "object",
        "properties": {"query": {"type": "string", "description": "Kata kunci pencarian."}},
        "required": ["query"]
    }
)
async def search_vault(query: str) -> str:
    """Cari vault dan kembalikan hasil."""
    # ... logika pencarian ...
    return f"Ditemukan 3 catatan tentang '{query}'."
```

### Keamanan MCP: Prinsip Kepercayaan Nol (Zero Trust)

Setiap _tool call_ adalah ancaman potensial. MCP memungkinkan model keamanan berlapis:

- **Persetujuan Pengguna:** Klien dapat meminta konfirmasi pengguna sebelum menjalankan alat berisiko tinggi.
- **Isolasi Eksekusi:** Jalankan server MCP di lingkungan terisolasi (Docker, sandbox).
- **Validasi Input/Output:** Seperti yang dijelaskan sebelumnya, semua input ke alat dan output dari alat HARUS divalidasi.

---

## 🌐 Deep Dive 4: Orkestrasi Multi-Agen — Pola dan Jebakan

Ketika satu agen tidak cukup, kita membangun tim. Pola komunikasi adalah kunci untuk menghindari kekacauan.

### Pola Orkestrasi

1.  **Sequential Chain:** Agen A → Agen B → Agen C. Sederhana, untuk alur kerja linier.
2.  **Manager-Worker:** Agen Manajer mendelegasikan sub-tugas ke Agen Pekerja spesialis.
3.  **Debate (Peer-to-Peer):** Dua agen atau lebih berdebat untuk mencapai konsensus. Satu agen bertindak sebagai hakim.
4.  **Blackboard (Shared State):** Semua agen membaca dan menulis ke papan tulis pusat. Cocok untuk masalah kompleks yang membutuhkan kolaborasi longgar.

### Masalah Umum dalam Sistem Multi-Agen

- **Agent Drift:** Agen secara bertahap menyimpang dari tujuan awal. _Solusi_: Agen Manajer dengan pengecekan berkala.
- **Conversational Deadlock:** Agen saling menunggu atau mengulangi dialog. _Solusi_: `max_turns` yang ketat dan _circuit breaker_.
- **State Contamination:** Shared state yang kacau karena input yang tidak terduga. _Solusi_: Validasi ketat setiap kali menulis ke state.

---

## 👁️ Deep Dive 5: Observabilitas — Mata dan Telinga Arsitek Agen

Agen yang tidak terlihat adalah black box yang berbahaya. Observabilitas adalah kunci untuk debugging, optimasi, dan kepercayaan.

### Pilar Observabilitas Agen

1.  **Traces:** Catatan setiap langkah _ReAct_ (Thought, Action, Observation). Ini adalah "stack trace" untuk agen.
2.  **Metrics:** Token yang digunakan, latensi, tingkat keberhasilan alat, jumlah loop. Ini untuk monitoring kesehatan.
3.  **Logs:** Log terstruktur dari setiap peristiwa penting (tool call, error, human input).

### Debugging dengan Perspektif Agen

Saat terjadi kesalahan, jangan hanya melihat log. **Masuklah ke dalam pikiran agen.** Tanyakan pada diri sendiri:

- Konteks apa yang tersedia saat itu?
- Memori apa yang diambil?
- Apakah tool-nya berfungsi dengan benar?
- Apakah suhu model terlalu tinggi, menyebabkan halusinasi?

Implementasi yang baik akan memungkinkan Anda _memutar ulang_ sebuah sesi, langkah demi langkah, untuk melihat persis apa yang "dipikirkan" oleh agen.

---

## 💎 Kesimpulan: Matriks Kematangan Agen

| Level                 | Kognisi               | Memori                  | Tool Use               | Orkestrasi     | Observabilitas        |
| --------------------- | --------------------- | ----------------------- | ---------------------- | -------------- | --------------------- |
| **1. Script**         | Tidak ada             | Tidak ada               | Hardcoded              | Tidak ada      | Print statements      |
| **2. Tool User**      | Single LLM Call       | Context Window          | Function Calling       | N/A            | API Logs              |
| **3. ReAct Agent**    | Loop Pikir-Aksi       | Buffer + Summarizer     | Error Handling         | Single Agent   | Langfuse Traces       |
| **4. Memory Agent**   | Refleksi Diri         | Vector DB + Retrieval   | Failover Tools         | N/A            | Metrik Evaluasi       |
| **5. Multi-Agent**    | Perencana + Spesialis | Shared + Private Memory | MCP Orchestration      | Manager-Worker | Distributed Tracing   |
| **6. Autonomous Org** | Dekomposisi Tujuan    | Hirarki Memori Penuh    | Dynamic Tool Discovery | Swarm          | Full Telemetri + HITL |

Jalan dari _script_ ke _autonomous organization_ bukan tentang teknologi, melainkan tentang **membangun arsitektur kognitif yang mampu mengelola kompleksitas dan ketidakpastian.** Mulailah dari loop yang sederhana, dan tambahkan memori, tool, dan agen lain hanya ketika loop itu sudah sempurna.
