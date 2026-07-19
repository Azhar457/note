---
title: "MCP (Model Context Protocol) Integration Guide — JSON-RPC and Custom Tools"
tags:
  - mcp
  - model-context-protocol
  - integration
  - ai-tools
  - software-engineering
aliases:
  - "mcp-integration-guide"
created: "2026-07-19"
updated: "2026-07-19"
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Model Context Protocol (MCP) adalah protokol terbuka yang distandarisasi untuk menghubungkan kecerdasan buatan (AI Agents) dengan sistem data dan perkakas eksternal (seperti filesystem, database, dan API). Catatan ini melengkapi pembahasan arsitektur agen otonom di [[agentic-ai-mcp-architecture-deepdive]] dan protokol komunikasi AI di [[ai-comm-protocol-deep-dive]].

## Daftar Isi

1. [Arsitektur Komunikasi MCP](#1-arsitektur-komunikasi-mcp)
2. [Spesifikasi Payload JSON-RPC Protocol](#2-spesifikasi-payload-json-rpc-protocol)
3. [Perbandingan Transport: STDIO vs SSE (Server-Sent Events)](#3-perbandingan-transport-stdio-vs-sse-server-sent-events)
4. [Tiga Pilar Kapabilitas MCP (Tools, Resources, Prompts)](#4-tiga-pilar-kapabilitas-mcp-tools-resources-prompts)
5. [Contoh Implementasi Custom MCP Server (Python SDK)](#5-contoh-implementasi-custom-mcp-server-python-sdk)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Arsitektur Komunikasi MCP

Protokol ini berjalan menggunakan model hubungan Client-Server. AI Agent bertindak sebagai host yang memuat **MCP Client**, sedangkan perkakas eksternal bertindak sebagai **MCP Server**.

```
┌─────────────────────────────────┐
│        Host (AI Agent)          │
│  - Membaca prompt pengguna      │
│  - Mengelola context window     │
│  ┌───────────────────────────┐  │
│  │        MCP Client         │  │
│  └─────────────┬─────────────┘  │
└────────────────┼────────────────┘
                 │
                 │ JSON-RPC over STDIO / WebSockets
                 │
┌────────────────┼────────────────┐
│  ┌─────────────▼─────────────┐  │
│  │        MCP Server         │  │
│  └─────────────┬─────────────┘  │
│                │                │
│                ▼                │
│       Perkakas Eksternal        │
│   (Filesystem, Database, API)   │
└─────────────────────────────────┘
```

---

## 2. Spesifikasi Payload JSON-RPC Protocol

Seluruh pertukaran pesan di dalam MCP menggunakan standar format **JSON-RPC 2.0**.

### 2.1 Request Listing Tools (`tools/list`)

Client mengirimkan perintah ini saat mendeteksi server baru untuk mengetahui daftar tool yang tersedia:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "params": {},
  "id": 1
}
```

### 2.2 Response Listing Tools

Server mengembalikan daftar spesifikasi skema input parameter dari tool menggunakan format JSON Schema:

```json
{
  "jsonrpc": "2.0",
  "result": {
    "tools": [
      {
        "name": "calculate_hash",
        "description": "Menghitung nilai SHA-256 hash dari data teks",
        "inputSchema": {
          "type": "object",
          "properties": {
            "text": {
              "type": "string",
              "description": "Teks mentah yang akan di-hash"
            }
          },
          "required": ["text"]
        }
      }
    ]
  },
  "id": 1
}
```

### 2.3 Request Eksekusi Tool (`tools/call`)

Client memanggil fungsi tertentu berdasarkan skema yang telah dilaporkan:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "calculate_hash",
    "arguments": {
      "text": "jarsWAF-Secure"
    }
  },
  "id": 2
}
```

---

## 3. Perbandingan Transport: STDIO vs SSE (Server-Sent Events)

MCP mendukung dua jenis saluran pengiriman data (_transports_):

| Kategori         | STDIO Transport                                                      | SSE (Server-Sent Events) Transport                                             |
| ---------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Koneksi**      | Jalur pipa input/output proses lokal                                 | Koneksi HTTP stream (Remote)                                                   |
| **Kelebihan**    | Keamanan sangat tinggi, nihil konfigurasi jaringan, latensi minimal. | Mendukung arsitektur multi-node, server di-host secara terpusat di cloud.      |
| **Kelemahannya** | Server harus berjalan di mesin yang sama dengan client.              | Lebih rentan terhadap ancaman intersepsi jaringan, perlu SSL/TLS + Auth token. |
| **Gaya**         | `stdin` dan `stdout`                                                 | HTTP POST (untuk client → server) & EventSource (server → client)              |

---

## 4. Tiga Pilar Kapabilitas MCP (Tools, Resources, Prompts)

Server MCP dapat menyediakan tiga jenis aset informasi ke client:

1. **Tools**: Fungsi asinkron yang dapat dieksekusi oleh AI Agent untuk merubah state atau mendapatkan informasi (misal: jalankan perintah bash, edit berkas).
2. **Resources**: Data statis/dinamis berdimensi baca-saja (_read-only_) yang dapat dimasukkan langsung ke context window AI (misal: log file, schema database, API docs).
3. **Prompts**: Kumpulan template perintah yang telah dirancang sebelumnya untuk membantu pengguna merumuskan instruksi spesifik (misal: template "audit-code", "refactoring-helper").

---

## 5. Contoh Implementasi Custom MCP Server (Python SDK)

Berikut adalah contoh praktis pembuatan server MCP menggunakan Python SDK resmi untuk mengekspos tool hash MD5/SHA-256.

### 5.1 Prasyarat Pustaka

Instal SDK resmi menggunakan uv/pip:

```bash
pip install mcp
```

### 5.2 Kode Server (`mcp_hash_server.py`)

```python
import hashlib
from mcp.server.fastmcp import FastMCP

# Inisialisasi server dengan nama "HashHelper"
mcp = FastMCP("HashHelper")

# Deklarasikan tool dengan dekorator mcp.tool()
@mcp.tool()
def compute_hash(data: str, algorithm: str = "sha256") -> str:
    """
    Menghitung hash dari string input menggunakan algoritma tertentu.

    Args:
        data: String teks mentah.
        algorithm: Pilihan algoritma: 'sha256', 'md5', atau 'sha1'.
    """
    algo = algorithm.lower()
    raw_bytes = data.encode('utf-8')

    if algo == "sha256":
        return hashlib.sha256(raw_bytes).hexdigest()
    elif algo == "md5":
        return hashlib.md5(raw_bytes).hexdigest()
    elif algo == "sha1":
        return hashlib.sha1(raw_bytes).hexdigest()
    else:
        return f"Error: Algoritma '{algorithm}' tidak didukung."

if __name__ == "__main__":
    # Jalankan server menggunakan transport STDIO default
    mcp.run()
```

Jalankan server melalui konfigurasi host AI Agent (misal: Claude Desktop Config):

```json
{
  "mcpServers": {
    "hash-helper": {
      "command": "python3",
      "args": ["/absolute/path/to/mcp_hash_server.py"]
    }
  }
}
```

---

## 6. Koneksi ke Vault

| Catatan                                  | Hubungan                                                                  |
| ---------------------------------------- | ------------------------------------------------------------------------- |
| [[agentic-ai-mcp-architecture-deepdive]] | Kerangka kerja dasar multi-agent otonom yang mengkonsumsi server MCP ini. |
| [[ai-comm-protocol-deep-dive]]           | Penjelasan format protokol dan performa serialisasi antar agen.           |
| [[ai-assisted-dev-workflow]]             | Penggunaan perkakas MCP untuk otomatisasi penulisan kode siber.           |
