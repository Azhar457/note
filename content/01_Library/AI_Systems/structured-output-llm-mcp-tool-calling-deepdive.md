---
title: "🔌 Structured Output from LLMs — JSON Mode, Function Calling & MCP Tool Contracts: Schema-Constrained Decoding untuk Agent Communication yang Reliable"
tags:
  - structured-output
  - json-mode
  - function-calling
  - mcp
  - tool-calling
  - constrained-decoding
  - thoughtworks-radar-vol-34
  - library
aliases:
  - json-mode-function-calling-deepdive
created: 2026-07-19
updated: 2026-07-19
status: growing
cssclasses:
  - wide-table
---

# 🔌 Structured Output from LLMs — JSON Mode, Function Calling & MCP Tool Contracts

**Schema-Constrained Decoding untuk Agent Communication yang Reliable**

> LLM secara default menghasilkan text bebas — narasi, paragraf, kode prose. Tapi sistem downstream (tool executor, RAG pipeline, agent router) butuh payload yang predictable: JSON valid dgn field konsisten, tipe data benar, schema contracts jelas. **Structured output** adalah teknik yang mengkonstrain model untuk menghasilkan output yang conforming ke schema — paling sering JSON — sehingga parsing failure bisa dieliminasi. ThoughtWorks Radar Vol.34 (April 2026) memindahkan blip #5 "Structured output from LLMs" ke ring **Adopt** karena sudah dipakai production lintas tool-calling, agent communication, dan M2M pipelines. Catatan ini membedah tiga lapisan pendekatan: JSON mode, function calling, dan constrained decoding — plus pola implementasi untuk MCP tool contracts, error handling, dan integrasi Hermes/OmniRouter stack.

> [!info] Hubungan ke Vault
>
> - [[agentic-ai-mcp-architecture-deepdive]] — MCP adalah rentang utama structured output; tool definitions di MCP pake JSON Schema
> - [[unified-mcp-server]] — MCP server implementation skill draft punya tool inputSchema
> - [[context7-mcp-deepdive]] — MCP server production example
> - [[mcp-integration-guide]] — guide integrasi Hermes MCP multi-provider (OmniRouter, 9Router)
> - [[prompt-engineering-patterns]] — prompt patterns yang minta JSON output
> - [[rag-pipeline-end-to-end-guide]] — JSON extraction dari dokumen RAG
> - [[rag-evaluation-framework]] — eval structured output sebagai agent contract test
> - [[ai-comm-protocol-deep-dive]] — protocol agent-to-agent yang structured
> - [[test-driven-development]] — JSON schema sebagai test contract
> - [[meta-agent-orchestration]] — agent router butuh structured message untuk routing

---

## Daftar Isi

1. [[#Foundation]]
2. [[#Technical Deep-Dive]]
3. [[#Advanced]]
4. [[#Case Studies]]
5. [[#Koneksi ke Vault]]
6. [[#Referensi]]
7. [[#Bottom Line]]

---

## Foundation

"Structured output" suara sederhana: minta model menghasilkan JSON, bukan text bebas. Tapi implementasinya punya tiga lapisan distinct yang sering di-conflate:

| Layer                    | Apa yang dikonstrain             | Dimana enforcement                        | Cost                    | Reliability                                                                                             |
| ------------------------ | -------------------------------- | ----------------------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------- |
| **JSON mode**            | Output must be valid JSON        | Server-side parsing (post-hoc validation) | Rendah (prompt hint)    | Moderate — model bisa generate syntactically valid tapi semantically invalid (field Salah, tipe Hilang) |
| **Function calling**     | Output must match tool signature | Provider API (server-side grammar)        | Sedang                  | Tinggi — provider validasi tool call payload dgn schema                                                 |
| **Constrained decoding** | Output must match BNF/grammar    | Token-level logit mask (di decoder)       | Tinggi (~10-20% slower) | Sangat tinggi — model tidak bisa menghasilkan token yang melanggar grammar                              |

Analogi: bayangkan REST API.

- **JSON mode** = "katanya dia POST JSON, server validate."
- **Function calling** = "ada OpenAPI spec, server parse pakai SDK yang tahu contract."
- **Constrained decoding** = "ada protobuf compile-time check, field hilang langkah compile gagal."

ThoughtWorks menempatkan structured output di **Adopt** karena seluruh ekosistem tool-calling (Anthropic tool_use, OpenAI function calling, Gemini function calling, MCP input schema) sudah matang. Tapi pilihan antara **mode** vs **constrained decoding** masih relevan untuk open-model deployment.

---

## Technical Deep-Dive

### JSON Mode vs Function Calling vs Constrained Decoding

```
USER PROMPT
    │
    ▼
┌────────────────────┐
│   LLM INFERENCE    │
└────────────────────┘
    │
    ▼
┌────────────────────────────────────────┐
│  Strategy A: JSON Mode (OpenAI)        │  ←─────────────────────┐
│  - Prompt: "Respond with valid JSON..."│                       │
│  - API param: response_format=json     │                       │
│  - Post-hoc: parse & validate          │                       │
│  - Risk: syntactically valid, semantic │                       │
│    drift                               │                       │
└────────────────┬───────────────────────┘                       │
                 │                                               │
                 ▼                                               │
┌────────────────────────────────────────┐                       │
│  Strategy B: Function Calling (Provider)│                      │
│  - Tool list passed to API             │                       │
│  - Model selects tool + args           │                       │
│  - Provider ensures args match schema  │                       │
│  - Risk: tool mismatch, missing args   │                       │
└────────────────┬───────────────────────┘                       │
                 │                                               │
                 ▼                                               │
┌────────────────────────────────────────┐                       │
│  Strategy C: Constrained Decoding      │                       │
│  - BNF/GBNF grammar defined            │                       │
│  - Logit mask rejects invalid tokens   │                       │
│  - Output guaranteed to match grammar  │                       │
│  - Risk: slower, needs grammar         │                       │
└────────────────────────────────────────┘
                                                              Retry loop
                                                              (send error back)
```

**Tabel komparasi provider:**

| Provider               | JSON mode                                                          | Function calling        | Constrained decoding                | API                              |
| ---------------------- | ------------------------------------------------------------------ | ----------------------- | ----------------------------------- | -------------------------------- |
| OpenAI (GPT-4o)        | `response_format: {type: "json_object"}` / `{type: "json_schema"}` | `tools` + `tool_choice` | Tidak native                        | `/v1/chat/completions`           |
| Anthropic (Claude 4.x) | `(if text + "respond with JSON")`                                  | `tools` API             | Tidak native                        | `/v1/messages`                   |
| Google (Gemini)        | `responseMimeType: "application/json"` + `responseSchema`          | `functionDeclarations`  | Tidak native                        | `/v1beta/models:generateContent` |
| vLLM + Outlines        | Tidak native                                                       | Tidak native            | Native BNF/JSON schema              | `/v1/completions`                |
| llama.cpp              | Tidak native                                                       | Tidak native            | GBNF grammar file                   | `/v1/chat/completions`           |
| Hermes (via provider)  | Inherit provider                                                   | Inherit provider        | Via Outlines adapter (lagi develop) | Wrapper                          |

### Schema Definition Patterns

Tiga pendekatan populer buat define schema:

**1. JSON Schema (Spec RFC)** — pervasive, language-agnostic. Di pakai MCP.

```json
{
  "type": "object",
  "properties": {
    "file_path": { "type": "string" },
    "content": { "type": "string" },
    "create_dirs": { "type": "boolean", "default": true }
  },
  "required": ["file_path", "content"]
}
```

**2. Pydantic (Python)** — type-safe, runtime-validated, auto-convert ke JSON Schema:

```python
from pydantic import BaseModel, Field

class WriteFileArgs(BaseModel):
    file_path: str = Field(..., description="Path to file. Will be created if doesn't exist.")
    content: str = Field(..., description="Full content to write.")
    create_dirs: bool = Field(default=True, description="Create parent dirs if missing.")

# Auto-generate JSON Schema untuk MCP tool definition
schema = WriteFileArgs.model_json_schema()
```

**3. Zod (TypeScript)** — runtime + static type in one:

```typescript
import { z } from "zod"

const writeArgsSchema = z.object({
  file_path: z.string().describe("Path to file"),
  content: z.string().describe("Content"),
  create_dirs: z.boolean().default(true),
})

type WriteArgs = z.infer<typeof writeArgsSchema>
```

| Format               | Bahasa | Runtime check                      | Integrasi MCP                            | Use case                                           |
| -------------------- | ------ | ---------------------------------- | ---------------------------------------- | -------------------------------------------------- |
| **JSON Schema**      | Any    | Manual validator (ajv, jsonschema) | First-class (`inputSchema` field di MCP) | Cross-language APIs, MCP servers, contract testing |
| **Pydantic v2**      | Python | Automatic                          | Auto-convert via `.model_json_schema()`  | FastAPI, LangChain tools, Python MCP servers       |
| **Zod**              | TS/JS  | Automatic                          | Manual pipe via `toJSONSchema()`         | Next.js, Deno, Bun MCP servers                     |
| **TypeScript types** | TS     | Compile-time only                  | Tidak cukup (need runtime check)         | Internal boundaries, non-network                   |

**Pilihan utama untuk MCP server author:** Pydantic (Python) atau Zod (TS), otomatis convert ke JSON Schema untuk `inputSchema`. Hindari hand-rolled JSON Schema kecuali sangat spesifik.

### MCP Tool Contracts — Structured Output in Practice

MCP `tools/list` response = beberapa tool definitions, masing-masing punya `inputSchema`:

```json
{
  "tools": [
    {
      "name": "write_file",
      "description": "Write content to a file, replacing existing content",
      "inputSchema": {
        "type": "object",
        "properties": {
          "file_path": { "type": "string", "description": "Absolute path target" },
          "content": { "type": "string" },
          "create_dirs": { "type": "boolean", "default": true }
        },
        "required": ["file_path", "content"]
      }
    },
    {
      "name": "search_files",
      "description": "Search file contents using regex",
      "inputSchema": {
        "type": "object",
        "properties": {
          "pattern": { "type": "string" },
          "path": { "type": "string", "default": "." },
          "output_mode": { "enum": ["content", "files_only", "count"], "default": "content" }
        },
        "required": ["pattern"]
      }
    }
  ]
}
```

Agent (Claude, GPT, atau Hermes via OmniRouter) mendaftar tools kemudian invoke:

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "write_file",
    "arguments": {
      "file_path": "/tmp/test.md",
      "content": "Hello from structured output",
      "create_dirs": true
    }
  }
}
```

**Sensor mutlak di server side:** MCP server wajib re-validate arguments terhadap `inputSchema` karena agent (atau provider lapis middleware) bisa passing payload slightly wrong. Pakai `jsonschema.validate()`.

### Error Handling & Retry Patterns

Saat model output tidak matching schema, pola yang recommended:

1. **Validate** — parse output, validate terhadap schema
2. **If fail, craft repair prompt** —
   ```python
   try:
       result = WriteFileArgs.model_validate_json(raw_output)
   except ValidationError as e:
       error_msg = f"Model output failed schema validation:\n{json.dumps(e.errors(), indent=2)}\n\nPlease retry with valid JSON matching this schema:\n{schema_json}"
       messages.append({"role": "user", "content": error_msg})
       response = client.messages.create(messages=messages, tools=tools)
   ```
3. **Set retry budget** (max 3 attempts) untuk prevent infinite loop
4. **Log for telemetry** — schema validation failure rate adalah metrics penting

**Pitfall:** kalau agent stable provider (Anthropic, OpenAI) jarang gagal schema, tapi kalau routing via free proxy providers (9Router through OmniRouter), siap-siap 20-30% output kena broken JSON. Di sanalah retry strategy penting.

#### Code Example: Production Retry with Schema Validation

```python
import json
from pydantic import BaseModel, ValidationError, Field
from typing import List, Dict, Optional, Any
import httpx

class WriteFileArgs(BaseModel):
    file_path: str = Field(..., description="Path to file")
    content: str = Field(..., description="Content")
    create_dirs: bool = True

class HermesToolClient:
    def __init__(self, base_url: str, api_key: str, model: str):
        self.base_url = base_url
        self.headers = {"Authorization": f"Bearer {api_key}"}
        self.model = model

    def invoke_with_validation(self, prompt: str, max_retries: int = 3) -> WriteFileArgs:
        messages = [{"role": "user", "content": prompt}]
        schema_json = json.dumps(WriteFileArgs.model_json_schema(), indent=2)
        instructions = f"""You are a structured-output tool. Respond with JSON matching this schema:\n\n{schema_json}\n\nOutput JSON only, no markdown, no prose."""

        for attempt in range(max_retries):
            response = httpx.post(
                f"{self.base_url}/v1/chat/completions",
                headers=self.headers,
                json={
                    "model": self.model,
                    "messages": messages,
                    "response_format": {"type": "json_object"},
                    "temperature": 0.2 + attempt * 0.1,  # nudge on retries
                },
                timeout=60
            )
            raw = response.json()["choices"][0]["message"]["content"]
            try:
                return WriteFileArgs.model_validate_json(raw)
            except ValidationError as e:
                if attempt == max_retries - 1:
                    raise
                error_feedback = f"Attempt {attempt+1} failed schema validation:\n{e.json(indent=2)}\n\nOriginal output:\n{raw}\n\nPlease retry with valid JSON matching the schema exactly. Output JSON only."
                messages.append({"role": "assistant", "content": raw})
                messages.append({"role": "user", "content": error_feedback})
        raise RuntimeError("Max retries exceeded")

# Usage
client = HermesToolClient("http://localhost:20128", "sk-...", "anthropic/claude-3-5-sonnet")
result = client.invoke_with_validation("Write hello world to /tmp/test.md")
print(result.file_path, result.content[:50])
```

---

## Advanced

### BNF/GBNF Grammars untuk llama.cpp

llama.cpp support grammar-based constrained decoding via `.gbnf` file:

```
# example.gbnf - grammar untuk WriteFileArgs
root ::= "{" ws "\"file_path\":" ws string "," ws "\"content\":" ws string ("," ws "\"create_dirs\":" ws boolean)? ws "}"
string ::= "\"" ([^"\\] | "\\" .)* "\""
boolean ::= "true" | "false"
ws ::= [ \t\n]*
```

Invoke dengan `extra_body: {grammar: grammar_str}`. Output dijamin cocok grammar karena token yang melanggar langsung di-reject oleh logit mask.

### Outlines / lm-format-enforcer

Untuk vLLM dan text-generation-inference, library dominan:

- **Outlines** — Python library, support JSON schema, Pydantic, regex, choice. Compatible dengan transformers, vLLM, llama.cpp.
- **lm-format-enforcer** — lebih ketat performant tapi limited grammar.

Pakai Outlines di vLLM:

```python
# Start vLLM dgn Outlines integration
# Then make request dengan --guided-json-schema arg:
POST /v1/chat/completions
{
  "model": "meta-llama/Meta-Llama-3-8B",
  "messages": [...],
  "guided_json_schema": {schema_json}
}
```

### Token-Level Constrained Decoding Logit Bias

Untuk implementasi custom: in inference time, sebelum sampllng, mask logit sesuai grammar state machine. Grammar state: "sedang di expect bool" → set logit `false` atau `true` jadi top-k pilihan, lainnya jadi -inf.

**Pitfall:** grammar yang terlalu ketat (misal: exact-string expects) bisa "trap" model di dead-end state → paradox loops. Always test grammar with diverse inputs.

### Hallucination Mitigation via Schema

Schema bukan cuma format enforcement — bisa juga semantik validator:

- `enum` untuk konstrain ke valid values
- `pattern` regex (JSON Schema) → force format email, UUID, IP
- `minimum`/`maximum` → konstrain range numerik
- `oneOf` → model harus pilih salah satu dari banyak skema (polymorphic payloads)

ThoughtWorks Radar Vol.34 themes bicara soal **codebase cognitive debt** (#36, Caution). Schema strict = salah satu mitigasi. Kalau model generate field yang tak terduga, skema reject, recap ke agent → agent forced to reflect.

---

## Case Studies

| Studi Kasus                          | Konteks                                                                                                    | Temuan Kunci                                                                                                                            | Mitigasi Diimplementasi                                                                                                             |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Anthropic Claude tool_use production | Provider Anthropic menambah native `tools` API. Claude tetap bisa hallucinate field yang tak ada di schema | Provider validate sebelum return; downstream MCP server tetap harus re-validate karena agent bisa invoke external system via OmniRouter | Hermes MCP server pattern: validate ulang dgn `jsonschema.validate()` sebelum execute. Log error + fallback kalau validation gagal  |
| OpenAI function calling scale issues | Production deployments with 50+ tools; prompt overhead too large                                           | Embedding-based tool retrieval — dapatkan top-k tools relevan dengan prompt sebelum attach ke context                                   | Hermes skill_router (lihat [[unified-mcp-server]] pattern) — router MCP server untuk dynamic skill discovery                        |
| Hermes MCP tool contract pattern     | Hermes tools `write_file`, `search_files` exposed via /api/mcp/sse                                         | OpenAPI-generated tools sering ambigu: `path` vs `file_path` vs `uri`                                                                   | Konsisten naming convention di MCP server; require `file_path` absolute path; `pattern` regex; dokumentasi di `description` panjang |
| Cursor agent structured output       | Cursor IDE menghasilkan structured plan, file edits sebagai JSON patch                                     | Output patch harus valid `diff` format, bukan text bebas                                                                                | Retry loop with JSON Schema contract; fallback ke prompt user manual copy paste kalau agent stuck                                   |
| RAG JSON extraction dari PDF         | Pipeline untuk extract metadata dari paper (title, authors, abstract, keywords)                            | Free-form extraction → field tak konsisten (title ada abstrak masuk abstract, keywords jadi comma string)                               | Strict JSON Schema: `authors: list[str]`, `abstract: string`, `keywords: list[str]`. Retry dengan parser fail-loud                  |

---

## Koneksi ke Vault

- [[agentic-ai-mcp-architecture-deepdive]] — fondasi MCP, tools/list + tools/call JSON RPC, structured output sebagai bagian native
- [[unified-mcp-server]] — skill draft unified MCP server dengan inputSchema pada tiap tool
- [[context7-mcp-deepdive]] — MCP server real; integrasi Hermes dengan documentation retrieval
- [[mcp-integration-guide]] — guide integrasi Hermes MCP multi-provider (OmniRouter, 9Router)
- [[agentic-ai-mcp-roadmap]] — roadmap menggunakan MCP sebagai layer abstraksi tool
- [[prompt-engineering-patterns]] — prompt patterns yang minta JSON, examples structured output
- [[rag-pipeline-end-to-end-guide]] — JSON extraction pada akhir LLM step untuk metadata RAG
- [[rag-evaluation-framework]] — eval JSON schema sebagai test contract untuk rag pipeline
- [[ai-comm-protocol-deep-dive]] — agent-to-agent protocol yang wajib structured
- [[meta-agent-orchestration]] — agent router butuh structured message untuk routing decisions
- [[document-parsing-for-rag]] — Docling dan library parser → structured output intermediate
- [[test-driven-development]] — schema sebagai test contract untuk structure validation

---

## Referensi

1. ThoughtWorks Technology Radar Vol.34 (April 2026) blip #5 Structured output from LLMs (Adopt). https://www.thoughtworks.com/radar/techniques/structured-output-from-llms
2. ThoughtWorks Radar PDF (April 2026). https://www.thoughtworks.com/content/dam/thoughtworks/documents/radar/2026/04/tr_technology_radar_vol_34_en.pdf
3. OpenAI Function Calling Documentation. https://platform.openai.com/docs/guides/function-calling
4. OpenAI JSON Mode. https://platform.openai.com/docs/guides/structured-outputs
5. Anthropic Tool Use Documentation. https://docs.anthropic.com/en/docs/build-with-claude/tool-use
6. Google Gemini Function Calling. https://ai.google.dev/gemini-api/docs/function-calling
7. Model Context Protocol specification. https://modelcontextprotocol.io/specification
8. MCP Tools API. https://modelcontextprotocol.io/docs/concepts/tools
9. JSON Schema Specification. https://json-schema.org/
10. Pydantic v2 documentation. https://docs.pydantic.dev/latest/
11. Zod documentation. https://zod.dev/
12. Outlines library (Python). https://github.com/outlines-dev/outlines
13. lm-format-enforcer. https://github.com/noamgat/lm-format-enforcer
14. llama.cpp GBNF grammar. https://github.com/ggerganov/llama.cpp/blob/master/grammars/README.md
15. Hermes Agent skill spec. https://hermes-agent.nousresearch.com/docs/skills
16. OmniRouter OpenAI-compatible API. https://docs.omnirouter.ai/
17. vLLM structured output docs. https://docs.vllm.ai/latest/features/structured_outputs.html
18. ajv JSON Schema validator (JavaScript). https://ajv.js.org/
19. jsonschema library (Python). https://github.com/python-jsonschema/jsonschema
20. Anthropic Engineering Blog — "Forcing Structured JSON Output". https://www.anthropic.com/news/claude-3-5-sonnet
21. LangChain Structured Output. https://python.langchain.com/docs/how_to/structured_output/
22. Instructor library (Pydantic extraction). https://github.com/jxnl/instructor
23. Hermes `write_file` tool inputSchema. `~/.hermes/tools/filesystem.py`
24. Jina AI JSON API via 9Router — structured output example. https://jina.ai/api-response-extraction-endpoints
25. Spec-Kit — schema-first development. https://github.com/github/spec-kit

---

> [!tip] Bottom Line
> Structured output dari LLMs bukan fitur "JSON mode" semata — empat parameter distinct: JSON mode (post-hoc parse), function calling (provider-enforced), constrained decoding (token-level logit masking), dan schema-strict validation (runtime + retry). Untuk adopt di production saat ini: gunakan **function calling** via provider yang di-support (Anthropic, OpenAI, Gemini), define schema via Pydantic atau Zod (auto-convert ke JSON Schema), dan di MCP server side **tetap re-validate** argumen karena agent bisa melalui middleware (OmniRouter proxy, custom adapter). Untuk open-model deployment, invest di Outlines bisa naik ke tier constrained decoding → ~100% reliability tanpa retry. Skill Hermes — tunggal definisi inputSchema per tool adalah contract yang sama; paksain itu, jangan biar tool "flexible" (itu artinya "kacau"). Pokoknya: schema bukan dokumentasi, schema adalah executable contract.
