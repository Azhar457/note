---
title: Skill AI MCP
tags: [ai, mcp, tools]
aliases: [skill-ai-mcp]
---
# AI & MCP (Model Context Protocol)

Model Context Protocol (MCP) adalah protokol open-source (Anthropic, 2024) untuk menghubungkan LLM ke tools/data eksternal secara standar. MCP memisahkan "model" dari "integrasi": satu server MCP = banyak klien (Claude Desktop, Cursor, IDE agents, aplikasi custom) bisa pakai tool yang sama. Di vault ini, skill AI mencakup: penggunaan MCP, agentic workflow, dan integrasi LLM dengan sistem internal.

## Arsitektur MCP

```
┌─────────────┐    JSON-RPC 2.0    ┌─────────────┐
│ MCP Client  │ ◄───────────────► │ MCP Server  │
│ (app/agent) │   stdio / SSE /    │ (tools,     │
│             │   HTTP+SSE         │ resources,  │
└─────────────┘                    │ prompts)    │
                                   └──────┬──────┘
                                          │
                                    [External System]
                                    (DB, API, FS, web)
```

- **Transports**: stdio (lokal), Streamable HTTP (remote), SSE (legacy).
- **Primitives**: tools (fungsi yang bisa dipanggil model), resources (data yang bisa dibaca: files, API results), prompts (template reusable).
- **Discovery**: server mengumumkan capabilities (list of tools) — klien menampilkan ke model dalam konteks.

## Alur Kerja Integrasi (Praktis)

1. **Tentukan use case**: apa yang perlu model lakukan? (query DB, jalankan script, baca file, kontrol CI).
2. **Pilih/build server MCP**: pakai yang sudah ada (filesystem, github, database, playwright) atau tulis custom (Python: `mcp` SDK; TypeScript: `@modelcontextprotocol/sdk`).
3. **Config di klien** (Contoh Claude Desktop `claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
    },
    "custom-db": {
      "command": "python",
      "args": ["/path/mcp_server_db.py"],
      "env": { "DB_URL": "postgresql://..." }
    }
  }
}
```
4. **Test**: pastikan tools muncul di klien, panggil dengan sample.
5. **Security hardening**: lihat bagian di bawah.

## Keamanan MCP (Kritis!)

MCP memberi model kemampuan EKSEKUSI — ini permukaan serangan besar:

| Risiko | Contoh | Mitigasi |
|--------|--------|----------|
| Tool abuse | Model memanggil tool dengan argumen jahat (path traversal, SQL injection via prompt) | Validasi input di server; whitelist parameter |
| Prompt injection via resource | Dokumen/file yang dibaca berisi instruksi jahat (lihat [[prompt-injection-defense]]) | Scan content; sandbox; output filter |
| Over-permission | Server punya akses terlalu luas (FS root, DB prod) | Least privilege: scope path/DB read-only |
| Secret exposure | Server menerima API keys, model bisa output | Jangan expose secret di tool schema; redact |
| SSRF via HTTP tool | Model mem-fetch URL internal | Allowlist URL; block private IP |
| Supply chain | Package server MCP berbahaya | Audit package; pin version; self-host |

### Checklist Deploy MCP Aman
1. Server jalan sebagai user terbatas (non-root, container).
2. Tools read-only kecuali dibutuhkan write.
3. Input validation di tiap tool (bukan cuma di model).
4. Logging semua tool calls (audit trail).
5. Rate limit per tool; cost control (LLM + eksekusi).
6. Test prompt injection terhadap server (red team) sebelum produksi.

## MCP Ecosystem (Tools Populer)

- **Filesystem** — baca/tulis file lokal (scope terbatas).
- **GitHub** — repo, issues, PR (token scoped).
- **Database** — Postgres/MySQL/MongoDB query (read-only disarankan).
- **Playwright/Puppeteer** — browser automation.
- **Fetch/HTTP** — request web.
- **Context7 / JINA Reader** — dokumentasi & web content (cocok riset).
- **Slack/Teams** — messaging.
- **Custom** — sesuaikan kebutuhan organisasi (script, API internal).

## Agentic Workflow (Di Luar MCP)

- **Tool calling (function calling)** — native LLM API (OpenAI, Anthropic) — JSON schema tools.
- **Agent loop**: LLM → pilih tool → eksekusi → observasi → lanjut (ReAct pattern).
- **Frameworks**: LangChain, LlamaIndex (orchestration), AutoGen (multi-agent), CrewAI.
- **Guardrails**: output validation, human-in-the-loop untuk aksi berdampak, budget/token limits.
- **Evaluation**: eval set per task (sukses/fail), cost per task, latency.

## Kaitan dengan Vault

- [[prompt-injection-defense]] — MCP tool = target injection.
- 01_Library/attacker — red team: uji MCP server (tool abuse, injection via resource).
- 02_SOPs — SOP penggunaan AI di lingkungan kerja (data residency).



## Contoh Implementasi Server MCP Custom (Python)

```python
# mcp_server_example.py — server MCP minimal dengan 2 tools
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("demo")

@mcp.tool()
def read_snippet(path: str) -> str:
    """Baca file (hanya dalam /data)."""
    safe = os.path.realpath(os.path.join("/data", path))
    if not safe.startswith("/data/"):
        return "ERROR: path di luar scope"
    with open(safe) as f:
        return f.read()[:4000]

@mcp.tool()
def search_index(query: str) -> list:
    """Cari di index lokal (read-only)."""
    ...

if __name__ == "__main__":
    mcp.run()  # stdio transport
```
Poin keamanan di contoh: path validated (traversal blocked), output dibatasi, read-only.

## Evaluasi Kualitas Integrasi AI

1. **Accuracy** — apakah tool menghasilkan output yang benar (eval set).
2. **Latency** — waktu per tool call; agent loop bisa lambat — cache & batasi depth.
3. **Cost** — token per task; tool descriptor besar = mahal; ringkas schema.
4. **Safety** — test injection, tool abuse, output poisoning (lihat checklist di atas).
5. **Maintainability** — server MCP = kode normal: versioning, CI, testing.

## MCP vs REST API (Kapan Mana)

| Aspek | MCP | REST API |
|-------|-----|----------|
| Konsumen | LLM agents | Aplikasi apa pun |
| Discovery | Otomatis (list tools) | Dokumentasi manual |
| Kontrak | JSON-RPC tools | OpenAPI spec |
| Ecosystem | Klien AI (Claude, Cursor) | Semua |
| Jika model perlu tools | Ya | Bisa (function calling manual) |

Untuk internal: MCP jika tim AI memakai agent; REST tetap untuk integrasi aplikasi biasa — bisa keduanya (MCP server wrap REST).

## Terminologi Penting

- **Tool schema** — deskripsi JSON dari parameter tool (model butuh ini untuk memilih argumen).
- **Context window** — ruang input model; tool output besar bisa memenuhi — ringkas output di server.
- **Human-in-the-loop** — approval manusia untuk tool berdampak (write, delete, deploy).
- **Sandboxing** — jalankan tool dalam container/VM terisolasi.

---

  audited
---