# SKILL AI: MCP Server Development — Strict Compliance Guide

> **Versi:** 2025-06-18 (latest stable) | **Sumber:** modelcontextprotocol.io/docs | **Status:** OPERATIONAL
> 
> Panduan ini adalah aturan keras (hard rules) yang HARUS diikuti setiap kali membangun, mereview, atau mendokumentasikan MCP Server. Tidak ada pengecualian tanpa justifikasi teknis tertulis.

---

## 1. ARSITEKTUR — Hubungan Entitas

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   MCP HOST      │◄───────►│   MCP CLIENT    │◄───────►│   MCP SERVER    │
│ (Claude Desktop,│ 1-to-N  │ (1 per server)  │ 1-to-1  │ (Context Provider)│
│  Cursor, VSCode)│         │                 │         │                 │
└─────────────────┘         └─────────────────┘         └─────────────────┘
        │                           │                           │
        │                           │                           │
        ▼                           ▼                           ▼
   AI Application              JSON-RPC 2.0              Tools/Resources/
   (orchestrator)              stdio / HTTP                 Prompts
```

**ATURAN #1:** Satu MCP Host dapat memiliki BANYAK MCP Client. Satu MCP Client hanya terhubung ke SATU MCP Server.

**ATURAN #2:** MCP Server BUKAN server dalam arti tradisional (network daemon). Itu adalah "program that serves context data" — bisa berupa local subprocess (stdio) atau remote HTTP endpoint.

**ATURAN #3:** Transport adalah concern TERPISAH dari Data Layer. Jangan campuradukkan logic transport dengan logic primitif.

---

## 2. LAYERS — Dua Lapisan yang Tidak Bisa Dilewati

### Data Layer (Inner)
- JSON-RPC 2.0 message format
- Lifecycle: initialize → negotiate capabilities → ready
- Primitif: tools, resources, prompts, notifications
- Client features: sampling, elicitation, logging
- Utility: progress tracking, tasks (experimental)

### Transport Layer (Outer)
- Connection establishment & message framing
- Authentication & authorization
- Stdio: single-tenant, local only, zero network overhead
- Streamable HTTP: multi-client, remote, OAuth 2.1 + PKCE

**ATURAN #4:** Data Layer TIDAK BOLEH mengasumsikan transport spesifik. Code yang sama harus bekerja di stdio maupun HTTP.

---

## 3. LIFECYCLE — Sequence yang Sakral

```
Client                           Server
  │                                │
  │─── 1. initialize ─────────────►│  protocolVersion + capabilities + clientInfo
  │                                │
  │◄── 2. InitializeResult ────────│  capabilities + serverInfo
  │                                │
  │─── 3. notifications/initialized►│  (no response expected)
  │                                │
  │◄──► 4. Discovery: tools/list   │  Dynamic listing
  │◄──►    resources/list          │  Pagination via cursor
  │◄──►    prompts/list            │
  │                                │
  │◄──► 5. Operations: */get,     │  Actual work
  │◄──►    */call, */subscribe    │
  │                                │
  │◄─── 6. notifications/*        │  Real-time updates (optional)
```

**ATURAN #5:** Capability negotiation adalah MANDATORY. Server HARUS declare `capabilities` di `InitializeResult`. Client HARUS reject operasi yang tidak didukung.

**ATURAN #6:** `protocolVersion` (e.g., "2025-06-18") HARUS kompatibel. Jika tidak, connection TERMINATED.

**ATURAN #7:** `notifications/initialized` dari client adalah SIGNAL, bukan request. Tidak ada response.

---

## 4. TIGA PRIMITIF SERVER — Pilih dengan Benar

### 4.1 TOOLS — Model-Controlled, Aksi/Eksekusi

**Kapan digunakan:**
- Query database, call API, file operations, computation
- Apapun yang mengubah state atau melakukan aksi

**Kontrol:** Model (LLM) memutuskan KAPAN dan APA yang dipanggil. Tapi HUMAN harus bisa deny.

**Struktur wajib:**
```json
{
  "name": "unique_tool_name",           // Kebab-case, unik dalam namespace server
  "title": "Human Readable Title",      // Optional, untuk UI
  "description": "When to use this...", // KRITIS: ini yang dibaca model
  "inputSchema": {                       // JSON Schema, VALIDATED
    "type": "object",
    "properties": {...},
    "required": [...]
  },
  "outputSchema": {                      // Optional tapi SANGAT dianjurkan
    "type": "object",
    "properties": {...}
  },
  "annotations": {                       // Behavioral hints (UNTRUSTED)
    "readOnlyHint": false,
    "destructiveHint": true,
    "openWorldHint": false
  }
}
```

**ATURAN #8:** `description` adalah CONTRACT dengan model. Vague description = model tidak akan invoke tool. Tulis untuk MODEL, bukan untuk human developer.

**ATURAN #9:** `inputSchema` HARUS `additionalProperties: false` atau setara (Zod `.strict()`). Jangan biarkan model mengirim field yang tidak diharapkan.

**ATURAN #10:** Tool result HARUS return `content` array. Error HARUS menggunakan `isError: true`, BUKAN throw exception ke client.

**ATURAN #11:** `annotations` dianggap UNTRUSTED kecuali dari trusted server. Jangan rely pada `readOnlyHint` untuk security decisions.

### 4.2 RESOURCES — Application-Driven, Data Read-Only

**Kapan digunakan:**
- File contents, database schemas, API responses, config files
- Apapun yang memberikan konteks tanpa mengubah state

**Kontrol:** Aplikasi (host) memutuskan CARA dan KAPAN data di-include dalam context.

**Struktur wajib:**
```json
{
  "uri": "scheme://path",              // Unique identifier, RFC 3986 compliant
  "name": "display_name",              // Human-readable
  "title": "Optional Title",           // UI display
  "description": "What this contains",   // Optional
  "mimeType": "text/markdown",         // Optional tapi dianjurkan
  "size": 1024,                        // Optional, bytes
  "annotations": {
    "audience": ["user", "assistant"], // Siapa yang butuh ini
    "priority": 0.8,                     // 0.0-1.0, 1 = most important
    "lastModified": "2025-01-12T15:00:58Z"
  }
}
```

**ATURAN #12:** Resources adalah READ-ONLY. Jika butuh write, itu adalah TOOL, bukan resource.

**ATURAN #13:** URI scheme HARUS konsisten. `file:///` untuk filesystem-like, `https://` hanya jika client bisa fetch langsung, custom scheme untuk domain-specific.

**ATURAN #14:** Resource templates (`file:///{path}`) memungkinkan parameterized access. Implement completion API untuk auto-complete arguments.

### 4.3 PROMPTS — User-Controlled, Template Reusable

**Kapan digunakan:**
- System prompts, few-shot examples, structured interaction patterns
- Template yang user pilih secara eksplisit (slash commands)

**Kontrol:** USER memutuskan KAPAN prompt digunakan. Bukan model, bukan aplikasi.

**Struktur wajib:**
```json
{
  "name": "prompt_name",               // Unique identifier
  "title": "Human Readable",           // UI display
  "description": "When to use...",       // Discovery text
  "arguments": [                        // Optional parameters
    {
      "name": "arg_name",
      "description": "What this arg means",
      "required": true
    }
  ]
}
```

**ATURAN #15:** Prompt messages HARUS berupa array dengan `role` ("user" | "assistant") dan `content` (text | image | audio | resource).

**ATURAN #16:** Prompts BUKAN untuk menyembunyikan system instructions dari user. User HARUS bisa melihat dan memahami apa yang diprompt.

---

## 5. TRANSPORT — Stdio vs Streamable HTTP

### 5.1 stdio (DEFAULT, RECOMMENDED for local)

```
Client (Host)                    Server (Subprocess)
   │                                  │
   │─── fork/exec server binary ───►│
   │                                  │
   │◄── stdin (JSON-RPC requests) ────│
   │─── stdout (JSON-RPC responses) ─►│
   │◄── stderr (logs, debug) ─────────│
```

**ATURAN #17:** Server HARUS membaca dari `stdin`, menulis ke `stdout`. `stderr` untuk logging SAJA.

**ATURAN #18:** Setiap message adalah SATU baris JSON (newline-delimited). TIDAK BOLEH ada embedded newlines.

**ATURAN #19:** Server TIDAK BOLEH menulis APAPUN ke `stdout` selain valid JSON-RPC messages. Satu `console.log` yang lupa = protocol corruption.

### 5.2 Streamable HTTP (Remote, multi-client)

```
POST /mcp  ──►  JSON-RPC request  ──►  Server
             ◄── 202 Accepted (notification/response)
             ◄── SSE stream (text/event-stream)

GET /mcp   ──►  SSE subscription  ──►  Server-initiated messages
```

**ATURAN #20:** Server HARUS validate `Origin` header untuk mencegah DNS rebinding attacks.

**ATURAN #21:** Local servers HARUS bind ke `127.0.0.1`, BUKAN `0.0.0.0`.

**ATURAN #22:** Session ID (`Mcp-Session-Id`) HARUS cryptographically secure (UUID/JWT) dan globally unique.

**ATURAN #23:** HTTP+SSE transport (spec 2024-11-05) adalah DEPRECATED. Gunakan Streamable HTTP (2025-03-26+).

---

## 6. SAMPLING — Server Meminta LLM Completion ke Client

**Kapan digunakan:**
- Server butuh AI capability tapi tidak mau hard-code model dependency
- Nested LLM calls dalam tool execution

**Flow:**
```
Server ──► sampling/createMessage ──► Client ──► Host LLM ──► Response ──► Server
```

**ATURAN #24:** Server TIDAK BOLEH memiliki API keys LLM. Semua sampling melalui client.

**ATURAN #25:** Gunakan `modelPreferences` dengan `hints` (substring matching), BUKAN hard-coded model names. Priorities: `costPriority`, `speedPriority`, `intelligencePriority` (0-1).

**ATURAN #26:** Client HARUS implement user approval controls untuk sampling requests.

---

## 7. ERROR HANDLING — Dua Kategori

### 7.1 Protocol Errors (JSON-RPC level)
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params"
  }
}
```
- `-32602`: Invalid params (unknown tool, missing args)
- `-32603`: Internal error
- `-32002`: Resource not found

### 7.2 Tool Execution Errors (Application level)
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [{"type": "text", "text": "Error message"}],
    "isError": true
  }
}
```

**ATURAN #27:** Jangan pernah throw exception ke client. Selalu return structured error dengan `isError: true`.

**ATURAN #28:** Error message HARUS actionable. "Failed" tidak cukup. "Failed: API rate limit exceeded, retry after 60s" adalah yang benar.

---

## 8. SECURITY — Non-Negotiable

| Layer | MUST | SHOULD | MUST NOT |
|-------|------|--------|----------|
| **Auth** | Validate credentials | OAuth 2.0 + PKCE | Hard-code API keys in server |
| **Input** | JSON Schema validation | Zod `.strict()` | Accept unknown properties |
| **Path** | URI validation | Prefix-based gates | Allow directory traversal |
| **Output** | Sanitize before return | Content-type headers | Return raw exceptions |
| **Network** | Origin validation | Bind localhost only | Listen on 0.0.0.0 tanpa auth |
| **Rate** | Rate limit per client | Exponential backoff | Unlimited tool invocations |
| **Audit** | Log tool calls | Structured logging | Skip logging sensitive ops |

**ATURAN #29:** Selalu ada HUMAN IN THE LOOP untuk operasi destructive atau yang mengakses data sensitif.

**ATURAN #30:** Tool invocation HARUS visible di UI dengan clear indicator. User HARUS bisa melihat apa yang dipanggil dan dengan argumen apa.

---

## 9. DECISION TREE — Primitif Selection

```
                    START
                      │
                      ▼
    ┌─────────────────────────────────────┐
    │  Apakah ini aksi/eksekusi            │
    │  yang mengubah state?                │
    └─────────────────────────────────────┘
           │                    │
           ▼ YES               ▼ NO
      ┌─────────┐      ┌─────────────────────┐
      │  TOOL   │      │  Data read-only?     │
      │         │      └─────────────────────┘
      │ Model-  │           │           │
      │controlled│           ▼ YES      ▼ NO
      │ Human   │      ┌─────────┐  ┌─────────────┐
      │approval │      │RESOURCE │  │ Template    │
      └─────────┘      │         │  │ reusable?   │
                       │ App-    │  └─────────────┘
                       │ driven  │       │
                       └─────────┘       ▼ YES
                                    ┌─────────┐
                                    │ PROMPT  │
                                    │         │
                                    │ User-   │
                                    │controlled│
                                    └─────────┘
```

---

## 10. ANTI-PATTERNS — Yang Harus Dihindari

| Anti-Pattern | Mengapa Salah | Solusi |
|--------------|---------------|--------|
| **Mixing transport logic with business logic** | Tidak reusable, sulit test | Pisah layer: transport → protocol → handler |
| **Hard-coding model names** | Client mungkin tidak punya model tersebut | Gunakan `modelPreferences.hints` |
| **Returning exceptions as text** | Client tidak bisa parse | Return `isError: true` dengan structured message |
| **Trusting tool annotations** | Annotations bisa spoofed | Implement own access controls |
| **Skipping capability negotiation** | Incompatible features crash | Selalu declare dan check capabilities |
| **Using stdout for logging** | Corrupts JSON-RPC stream | Gunakan stderr atau proper logging framework |
| **No input validation** | Injection attacks | JSON Schema strict + runtime validation |
| **Synchronous I/O in handlers** | Blocks entire server | Async/await + timeout + AbortController |
| **No pagination for large lists** | Memory issues, slow response | Implement `cursor` + `nextCursor` |
| **Ignoring notification support** | Client tidak tahu update | Implement `listChanged` jika dynamic |

---

## 11. REFERENSI SPESIFIKASI

| Dokumen | URL | Kapan Dibaca |
|---------|-----|--------------|
| Architecture Overview | modelcontextprotocol.io/docs/concepts/architecture | Saat design awal |
| Tools | modelcontextprotocol.io/docs/concepts/tools | Saat implement tools |
| Resources | modelcontextprotocol.io/docs/concepts/resources | Saat implement resources |
| Prompts | modelcontextprotocol.io/docs/concepts/prompts | Saat implement prompts |
| Sampling | modelcontextprotocol.io/docs/concepts/sampling | Saat butuh nested LLM calls |
| Transports | modelcontextprotocol.io/docs/concepts/transports | Saat pilih stdio vs HTTP |
| Full Specification | modelcontextprotocol.io/specification | Saat debug edge cases |

---

> [!warning] PERINGATAN FINAL
> Setiap kali membuat MCP Server, PASTIKAN:
> 1. ✅ Capability negotiation di initialize
> 2. ✅ Input validation strict (additionalProperties: false)
> 3. ✅ Error handling structured (isError: true)
> 4. ✅ stdout bersih (hanya JSON-RPC)
> 5. ✅ Human-in-the-loop untuk operasi sensitif
> 6. ✅ Security: auth, path gates, sanitization, rate limiting
> 
> **Jika ada konflik antara keinginan dan spesifikasi — spesifikasi MENANG.**
