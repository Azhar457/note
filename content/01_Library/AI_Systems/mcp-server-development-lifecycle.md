---
title: '🔄 MCP Server Development Lifecycle (MCP-SDLC) — Deep Dive: Dari Ide sampai Production'
tags:
- mcp
- model-context-protocol
- sdlc
- mcpdlc
- lifecycle
- devops
- cicd
- testing
- deployment
- security
aliases:
- MCP SDLC
- MCP Development Lifecycle
- MCP Server Lifecycle
- MCP DLC
created: 2026-07-08
updated: 2026-07-08
status: pending
cssclasses:
  - wide-table
---

# 🔄 MCP Server Development Lifecycle (MCP-SDLC) — Deep Dive: Dari Ide sampai Production

> Ringkasan satu-paragraf menjelaskan bahwa MCP Server Development Lifecycle (MCP-SDLC) adalah kerangka kerja sistematis untuk membangun, menguji, mendeploy, dan memelihara MCP server dari tahap perencanaan hingga operasional production. Berbeda dengan SDLC perangkat lunak konvensional, MCP-SDLC menekankan capability negotiation, schema versioning, transport selection, human-in-the-loop approval, dan continuous context synchronization antara AI host dan server eksternal.

> [!info] Hubungan ke Vault
> Nota ini terkait dengan [[skill-ai-mcp]] untuk aturan teknis spesifikasi MCP, [[threat-modeling-deepdive]] untuk security review tiap tahap, [[devops]] untuk pipeline CI/CD, serta [[system-design]] untuk arsitektur transport dan state management.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Apa Itu MCP-SDLC?

MCP-SDLC adalah adaptasi Software Development Lifecycle (SDLC) yang disesuaikan dengan karakteristik unik Model Context Protocol. Tidak seperti aplikasi web biasa yang berkomunikasi via REST API, MCP server harus menangani:

- **Capability negotiation** yang dinamis (tidak fixed endpoint)
- **Schema versioning** yang backward-compatible
- **Transport abstraction** (stdio vs Streamable HTTP)
- **Human-in-the-loop** approval untuk tool invocation
- **Real-time notifications** untuk list changes
- **Multi-tenant scoping** untuk enterprise deployment

### Perbedaan SDLC Konvensional vs MCP-SDLC

| Aspek | SDLC Konvensional | MCP-SDLC |
|-------|-------------------|----------|
| **Interface Contract** | OpenAPI/Swagger (static) | JSON Schema + Capability Negotiation (dynamic) |
| **Transport** | HTTP/REST (stateless) | JSON-RPC 2.0 over stdio/HTTP (stateful) |
| **Authentication** | API Key / OAuth / JWT | OAuth 2.1 + PKCE + Session ID |
| **Testing Focus** | Unit + Integration + E2E | Schema Validation + Transport + Capability + Security |
| **Deployment** | Container / Serverless | Subprocess (stdio) atau HTTP Endpoint |
| **Monitoring** | Logs / Metrics / Traces | JSON-RPC message inspection + Tool invocation audit |
| **Versioning** | Semantic Versioning | Protocol Version + Schema Version + Capability Version |
| **Rollback** | Blue/Green / Canary | Capability disable + Schema downgrade |

### Tahapan MCP-SDLC

MCP-SDLC terdiri dari 7 tahap yang saling terhubung dalam loop kontinu:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   1. PLAN   │───►│  2. DESIGN  │───►│ 3. SCAFFOLD │───►│  4. BUILD   │
│  (Ideation) │    │ (Protocol)  │    │  (Setup)    │    │ (Implement) │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       ▲                                                  │
       │                                                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 7. EVOLVE   │◄───│ 6. MONITOR  │◄───│ 5. DEPLOY   │◄───│   4. BUILD  │
│ (Iterate)   │    │ (Observe)   │    │ (Release)   │    │  (Implement)│
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

---

## Technical Deep-Dive

### Tahap 1: PLAN — Ideation & Requirements

**Tujuan:** Menentukan APA yang akan dibuat dan MENGAPA AI agent membutuhkannya.

#### 1.1 Define Context Gap

Identifikasi masalah yang ingin dipecahkan:

| Pertanyaan | Contoh Jawaban |
|------------|----------------|
| Apa yang AI tidak bisa lakukan tanpa server ini? | "AI tidak bisa mengakses vault Obsidian saya" |
| Data/context apa yang perlu disediakan? | "Catatan pribadi, backlink, frontmatter" |
| Aksi apa yang AI perlu eksekusi? | "Search, read, write, synthesize notes" |
| Siapa yang akan menggunakan ini? | "Saya pribadi / Tim / Enterprise customers" |

#### 1.2 Select Primitives

Gunakan decision tree untuk memilih primitif yang tepat:

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

#### 1.3 Threat Model Awal

Lakukan threat modeling sederhana sebelum coding:

| Ancaman | Likelihood | Impact | Mitigasi Awal |
|---------|------------|--------|---------------|
| Prompt Injection via tool args | Tinggi | Tinggi | Input validation strict |
| Data exfiltration via resources | Sedang | Tinggi | Path-based access control |
| Tool poisoning (malicious schema) | Rendah | Tinggi | Schema hash verification |
| Unauthorized tool invocation | Sedang | Tinggi | Human approval gate |
| Credential leak in config | Tinggi | Tinggi | Environment variables only |

#### 1.4 Output Tahap PLAN

- **MCP Server Charter:** 1-pager yang menjelaskan tujuan, primitif, dan scope
- **Primitive Registry:** Daftar tools/resources/prompts dengan deskripsi awal
- **Threat Model Summary:** Risiko utama dan mitigasi awal
- **Transport Decision:** stdio (local) atau Streamable HTTP (remote)

---

### Tahap 2: DESIGN — Protocol & Architecture

**Tujuan:** Merancang KONTRAK antara server dan client sebelum satu baris kode ditulis.

#### 2.1 Capability Design

Tentukan capabilities yang akan dideklarasikan saat initialize:

```json
{
  "capabilities": {
    "tools": {
      "listChanged": true
    },
    "resources": {
      "subscribe": true,
      "listChanged": true
    },
    "prompts": {
      "listChanged": false
    },
    "logging": {}
  }
}
```

**Aturan:**
- `listChanged: true` → HANYA jika tools/resources/prompts bisa berubah dinamis
- `subscribe: true` → HANYA untuk resources yang perlu real-time updates
- Jangan declare capability yang tidak diimplementasi

#### 2.2 Schema Design (JSON Schema)

Desain schema untuk setiap primitif sebelum coding:

**Tool Schema Example:**
```json
{
  "name": "search_vault",
  "title": "Semantic Vault Search",
  "description": "Search the Obsidian vault using BM25 or vector embeddings. Use this when the user asks about concepts, topics, or specific content across their knowledge base.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "query": {
        "type": "string",
        "minLength": 2,
        "description": "Search query in natural language"
      },
      "limit": {
        "type": "number",
        "default": 10,
        "description": "Maximum number of results to return"
      },
      "path_filter": {
        "type": "string",
        "description": "Optional folder path to narrow search scope"
      }
    },
    "required": ["query"],
    "additionalProperties": false
  },
  "outputSchema": {
    "type": "object",
    "properties": {
      "results": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "path": {"type": "string"},
            "score": {"type": "number"},
            "snippet": {"type": "string"}
          }
        }
      }
    }
  },
  "annotations": {
    "readOnlyHint": true,
    "destructiveHint": false,
    "openWorldHint": false
  }
}
```

**Resource Schema Example:**
```json
{
  "uri": "garden://stats",
  "name": "vault-stats",
  "title": "Vault Statistics",
  "description": "Real-time statistics about the Obsidian vault",
  "mimeType": "application/json",
  "annotations": {
    "audience": ["assistant"],
    "priority": 0.7
  }
}
```

#### 2.3 Transport Design Decision

| Kriteria | stdio | Streamable HTTP |
|----------|-------|-----------------|
| **Use Case** | Local, single-user | Remote, multi-tenant |
| **Security Model** | OS process isolation | OAuth 2.1 + PKCE |
| **Deployment** | npm package / binary | Cloud endpoint / serverless |
| **State Management** | Implicit (1:1) | Session ID (`Mcp-Session-Id`) |
| **Scalability** | Limited to single host | Horizontal scaling via load balancer |
| **Startup Time** | Instant (subprocess) | Network latency + TLS handshake |
| **Monitoring** | stderr logs | HTTP logs + structured metrics |

#### 2.4 Error Strategy Design

Tentukan error taxonomy sebelum implementasi:

| Error Code | Kategori | Contoh | Response Pattern |
|------------|----------|--------|------------------|
| `-32602` | Protocol | Invalid params, unknown tool | JSON-RPC error |
| `-32002` | Resource | File not found, URI invalid | JSON-RPC error |
| `-32603` | Internal | Server crash, unhandled exception | JSON-RPC error |
| `isError: true` | Business | API rate limit, auth failed | Tool result dengan error message |
| `notifications/progress` | Progress | Long-running operation | Progress update (0.0 - 1.0) |

#### 2.5 Output Tahap DESIGN

- **Capability Manifest:** JSON capabilities lengkap
- **Schema Registry:** Semua JSON Schema untuk tools/resources/prompts
- **Transport Decision Document:** stdio atau HTTP dengan justifikasi
- **Error Taxonomy:** Daftar error codes dan handling strategy
- **Sequence Diagrams:** Initialize → Discover → Execute flow

---

### Tahap 3: SCAFFOLD — Project Setup

**Tujuan:** Membuat fondasi project yang solid dan reproducible.

#### 3.1 Project Structure

```
garden-mcp/
├── src/
│   ├── index.ts              # Entry point, server initialization
│   ├── server.ts             # McpServer instance setup
│   ├── transport.ts          # Transport selection (stdio/HTTP)
│   ├── capabilities.ts       # Capability declarations
│   ├── tools/
│   │   ├── index.ts          # Tool registry & discovery
│   │   ├── search-vault.ts   # Individual tool implementations
│   │   ├── read-note.ts
│   │   └── write-note.ts
│   ├── resources/
│   │   ├── index.ts          # Resource registry
│   │   ├── vault-stats.ts
│   │   └── tag-index.ts
│   ├── prompts/
│   │   ├── index.ts          # Prompt registry
│   │   └── synthesize-research.ts
│   ├── handlers/             # Business logic (separated from protocol)
│   │   ├── search.ts
│   │   ├── read.ts
│   │   └── write.ts
│   ├── validators/           # Input validation utilities
│   │   └── schemas.ts
│   └── types/                # Shared TypeScript types
│       └── index.ts
├── tests/
│   ├── unit/                 # Unit tests untuk handlers
│   ├── integration/          # Integration tests dengan transport
│   ├── schema/               # JSON Schema validation tests
│   └── e2e/                  # End-to-end dengan mcp-inspector
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   └── publish.sh
├── .github/
│   └── workflows/
│       ├── ci.yml            # Build + Test + Lint
│       └── publish.yml       # npm publish on tag
├── claude_desktop_config.json  # Example config untuk users
├── cursor_mcp.json           # Example config untuk Cursor
├── package.json
├── tsconfig.json
├── README.md
└── LICENSE
```

#### 3.2 Dependencies

```json
{
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "@types/node": "^20.0.0",
    "tsx": "^4.0.0",
    "@modelcontextprotocol/inspector": "^1.0.0",
    "vitest": "^1.0.0",
    "@vitest/coverage-v8": "^1.0.0"
  }
}
```

#### 3.3 TypeScript Configuration

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

#### 3.4 Output Tahap SCAFFOLD

- **Repository:** Git repo dengan struktur folder di atas
- **package.json:** Dependencies lengkap dengan scripts
- **tsconfig.json:** Strict TypeScript config
- **CI/CD Pipeline:** GitHub Actions untuk build + test
- **Example Configs:** `claude_desktop_config.json`, `cursor_mcp.json`

---

### Tahap 4: BUILD — Implementation

**Tujuan:** Menulis kode yang sesuai spesifikasi, dengan fokus pada protocol compliance.

#### 4.1 Server Initialization (Skeleton)

```typescript
#!/usr/bin/env node
// src/index.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new McpServer(
  {
    name: "garden-mcp",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: { listChanged: true },
      resources: { subscribe: true, listChanged: true },
      prompts: { listChanged: false },
      logging: {},
    },
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("[garden-mcp] ready on stdio");
}

main().catch((err) => {
  console.error("Fatal:", err);
  process.exit(1);
});
```

#### 4.2 Tool Implementation Pattern

```typescript
// src/tools/search-vault.ts
import { z } from "zod";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

const searchVaultSchema = z.object({
  query: z.string().min(2).describe("Search query in natural language"),
  limit: z.number().optional().default(10),
  path_filter: z.string().optional(),
});

export function registerSearchVaultTool(server: McpServer) {
  server.tool(
    "search_vault",
    "Search the Obsidian vault semantically. Use this when the user asks about " +
      "concepts, topics, or specific content across their knowledge base.",
    searchVaultSchema.shape,
    async ({ query, limit, path_filter }) => {
      try {
        const results = await searchVault(query, { limit, path_filter });
        return {
          content: [{
            type: "text" as const,
            text: JSON.stringify(results, null, 2),
          }],
        };
      } catch (err) {
        return {
          content: [{
            type: "text" as const,
            text: `Search failed: ${(err as Error).message}`,
          }],
          isError: true,
        };
      }
    }
  );
}
```

#### 4.3 Resource Implementation Pattern

```typescript
// src/resources/vault-stats.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

export function registerVaultStatsResource(server: McpServer) {
  server.resource(
    "vault-stats",
    "garden://stats",
    async (uri) => {
      const stats = await getVaultStats();
      return {
        contents: [{
          uri: uri.href,
          mimeType: "application/json",
          text: JSON.stringify(stats, null, 2),
        }],
      };
    }
  );
}
```

#### 4.4 Prompt Implementation Pattern

```typescript
// src/prompts/synthesize-research.ts
import { z } from "zod";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";

export function registerSynthesizePrompt(server: McpServer) {
  server.prompt(
    "synthesize_research",
    "Generate a synthesis note from multiple source notes.",
    {
      topic: z.string().describe("Synthesis topic or question"),
      source_paths: z.array(z.string()).describe("List of note paths"),
    },
    async ({ topic, source_paths }) => {
      const sources = await Promise.all(source_paths.map(readNote));
      return {
        messages: [{
          role: "user" as const,
          content: {
            type: "text" as const,
            text: `Synthesize the following notes on "${topic}":\n\n${
              sources.map(s => `--- ${s.path} ---\n${s.content}`).join("\n\n")
            }`,
          },
        }],
      };
    }
  );
}
```

#### 4.5 Dynamic Capabilities (Advanced)

```typescript
// Enable/disable tools based on auth state
const putMessageTool = server.tool("putMessage", ...);
putMessageTool.disable(); // Initially disabled

// After auth upgrade:
putMessageTool.enable(); // Auto-sends listChanged notification

// Update tool schema dynamically:
putMessageTool.update({ paramSchema: newSchema }); // Auto-notifies client

// Remove tool entirely:
putMessageTool.remove(); // Auto-sends listChanged notification
```

#### 4.6 Output Tahap BUILD

- **Source Code:** Semua tools, resources, prompts terimplementasi
- **Input Validation:** Zod schemas dengan `.strict()`
- **Error Handling:** Structured errors dengan `isError: true`
- **Logging:** Semua log ke `stderr`, tidak ada output ke `stdout`
- **Type Safety:** 100% TypeScript coverage, no `any`

---

### Tahap 5: DEPLOY — Release & Distribution

**Tujuan:** Men-deploy server ke environment target dengan aman dan terukur.

#### 5.1 Testing Pyramid untuk MCP

```
        ┌─────────────┐
        │   E2E Test  │  ← mcp-inspector + Claude Desktop
        │  (Slowest)  │     Validate full user journey
        └──────┬──────┘
               │
        ┌──────┴──────┐
        │ Integration │  ← Transport + Protocol + Handler
        │    Test     │     Validate JSON-RPC message flow
        └──────┬──────┘
               │
        ┌──────┴──────┐
        │  Schema Test│  ← JSON Schema validation
        │   (Fast)    │     Validate input/output contracts
        └──────┬──────┘
               │
        ┌──────┴──────┐
        │  Unit Test  │  ← Business logic isolation
        │  (Fastest)  │     Validate handler behavior
        └─────────────┘
```

#### 5.2 Testing Strategy

**Unit Tests (Vitest):**
```typescript
// tests/unit/search-vault.test.ts
import { describe, it, expect } from "vitest";
import { searchVault } from "../../src/handlers/search";

describe("searchVault", () => {
  it("should return results for valid query", async () => {
    const results = await searchVault("AI agents", { limit: 5 });
    expect(results).toHaveLength.greaterThan(0);
    expect(results[0]).toHaveProperty("path");
    expect(results[0]).toHaveProperty("score");
  });

  it("should throw for empty query", async () => {
    await expect(searchVault("", { limit: 5 }))
      .rejects.toThrow("Query must be at least 2 characters");
  });
});
```

**Schema Tests:**
```typescript
// tests/schema/tool-schemas.test.ts
import { describe, it, expect } from "vitest";
import { z } from "zod";
import { searchVaultSchema } from "../../src/validators/schemas";

describe("Tool Schemas", () => {
  it("should reject additional properties", () => {
    const result = searchVaultSchema.safeParse({
      query: "test",
      extraField: "should fail",
    });
    expect(result.success).toBe(false);
  });

  it("should validate required fields", () => {
    const result = searchVaultSchema.safeParse({});
    expect(result.success).toBe(false);
  });
});
```

**Integration Tests:**
```typescript
// tests/integration/transport.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

describe("MCP Transport", () => {
  let client: Client;
  let transport: StdioClientTransport;

  beforeAll(async () => {
    transport = new StdioClientTransport({
      command: "node",
      args: ["./dist/index.js"],
    });
    client = new Client({ name: "test-client", version: "1.0.0" });
    await client.connect(transport);
  });

  it("should initialize successfully", async () => {
    const result = await client.initialize();
    expect(result.protocolVersion).toBe("2025-06-18");
    expect(result.capabilities.tools).toBeDefined();
  });

  it("should list tools", async () => {
    const tools = await client.listTools();
    expect(tools.tools).toHaveLength.greaterThan(0);
  });

  afterAll(async () => {
    await client.close();
  });
});
```

**E2E Tests dengan mcp-inspector:**
```bash
# Run inspector
npm run inspector

# Manual test checklist:
# 1. Initialize berhasil (protocol version match)
# 2. tools/list menampilkan semua tools
# 3. resources/list menampilkan semua resources
# 4. prompts/list menampilkan semua prompts
# 5. tools/call dengan valid args → success
# 6. tools/call dengan invalid args → validation error
# 7. resources/read → content valid
# 8. notifications/list_changed → diterima saat dynamic update
```

#### 5.3 CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: MCP Server CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run test:unit -- --coverage
      - run: npm run test:schema
      - run: npm run test:integration
      - run: npm run build

  publish:
    needs: test
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          registry-url: "https://registry.npmjs.org"
      - run: npm ci
      - run: npm run build
      - run: npm publish --access public
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

#### 5.4 Deployment Patterns

**Pattern A: Local stdio (Personal Use)**
```json
// claude_desktop_config.json
{
  "mcpServers": {
    "digital-garden": {
      "command": "npx",
      "args": ["-y", "@your-scope/garden-mcp"],
      "env": {
        "VAULT_PATH": "/Users/you/Obsidian/Vault"
      }
    }
  }
}
```

**Pattern B: Remote Streamable HTTP (Enterprise)**
```yaml
# docker-compose.yml
version: "3.8"
services:
  garden-mcp:
    image: your-registry/garden-mcp:latest
    ports:
      - "3000:3000"
    environment:
      - MCP_AUTH_MODE=oauth
      - OAUTH_ISSUER=https://auth.yourcompany.com
      - VAULT_PATH=/data/vault
    volumes:
      - /host/vault:/data/vault:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**Pattern C: Serverless (Cloud Functions)**
```typescript
// src/serverless.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamable-http.js";

export default async function handler(req: Request, res: Response) {
  const server = new McpServer({ name: "garden-mcp", version: "1.0.0" });
  // ... register tools/resources/prompts

  const transport = new StreamableHTTPServerTransport();
  await server.connect(transport);
  await transport.handleRequest(req, res);
}
```

#### 5.5 Output Tahap DEPLOY

- **Test Suite:** Unit + Schema + Integration + E2E tests
- **CI/CD Pipeline:** Automated build, test, publish
- **Deployment Config:** `claude_desktop_config.json`, `docker-compose.yml`, atau serverless handler
- **Health Check Endpoint:** `/health` untuk monitoring
- **Rollback Plan:** Version pinning + capability disable

---

### Tahap 6: MONITOR — Observability & Audit

**Tujuan:** Memastikan server berjalan dengan baik, aman, dan terukur di production.

#### 6.1 Metrics yang Harus Di-track

| Metric | Kategori | Threshold Alert |
|--------|----------|-----------------|
| Tool invocation rate | Performance | > 100/min |
| Average tool execution time | Performance | > 5s |
| Error rate (isError: true) | Reliability | > 1% |
| Protocol error rate | Reliability | > 0.1% |
| Active sessions (HTTP) | Scale | > 1000 |
| Memory usage | Resource | > 80% |
| Credential refresh failures | Security | > 0 |
| Unauthorized access attempts | Security | > 0 |

#### 6.2 Logging Strategy

```typescript
// Structured logging untuk audit
interface MCPLogEntry {
  timestamp: string;
  level: "info" | "warn" | "error";
  event: "tool_call" | "resource_read" | "prompt_get" | "error" | "auth";
  sessionId?: string;
  toolName?: string;
  resourceUri?: string;
  promptName?: string;
  durationMs?: number;
  success: boolean;
  errorMessage?: string;
  userId?: string;
  clientName?: string;
}

// Example log output (ke stderr)
console.error(JSON.stringify({
  timestamp: "2026-07-08T14:30:00Z",
  level: "info",
  event: "tool_call",
  sessionId: "sess_abc123",
  toolName: "search_vault",
  durationMs: 145,
  success: true,
  userId: "user_123",
  clientName: "claude-desktop",
}));
```

#### 6.3 Audit Trail

```typescript
// Audit middleware untuk semua tool calls
async function auditToolCall(
  toolName: string,
  args: unknown,
  result: unknown,
  metadata: { userId: string; sessionId: string }
) {
  await auditLog.write({
    type: "tool_invocation",
    toolName,
    arguments: sanitizeForAudit(args), // Strip sensitive data
    result: sanitizeForAudit(result),
    ...metadata,
    timestamp: new Date().toISOString(),
  });
}
```

#### 6.4 Health Check

```typescript
// src/health.ts
export async function healthCheck(): Promise<HealthStatus> {
  const checks = await Promise.all([
    checkVaultAccess(),
    checkSearchIndex(),
    checkMemoryUsage(),
  ]);

  const healthy = checks.every(c => c.status === "ok");

  return {
    status: healthy ? "healthy" : "degraded",
    version: process.env.npm_package_version || "unknown",
    uptime: process.uptime(),
    checks: checks.reduce((acc, c) => ({ ...acc, [c.name]: c }), {}),
  };
}
```

#### 6.5 Output Tahap MONITOR

- **Dashboard:** Grafana/CloudWatch dengan metrics di atas
- **Alert Rules:** PagerDuty/OpsGenie integration
- **Audit Logs:** Immutable log storage (S3/CloudWatch Logs)
- **Health Endpoint:** `/health` untuk load balancer health checks
- **Runbook:** Dokumen troubleshooting untuk on-call engineer

---

### Tahap 7: EVOLVE — Iteration & Improvement

**Tujuan:** Menumbuhkan server secara berkelanjutan berdasarkan feedback dan perubahan kebutuhan.

#### 7.1 Versioning Strategy

MCP menggunakan TIGA level versioning yang berbeda:

| Level | Format | Kapan Berubah | Contoh |
|-------|--------|---------------|--------|
| **Protocol Version** | `YYYY-MM-DD` | Spesifikasi MCP berubah | `2025-06-18` |
| **Server Version** | SemVer | Code changes | `1.2.3` |
| **Schema Version** | Incremental | Tool/resource schema berubah | `v2` |

**Aturan Versioning:**
- Protocol Version: HARUS compatible dengan client. Jika tidak, disconnect.
- Server Version (SemVer):
  - **Major:** Breaking change (tool dihapus, required field baru)
  - **Minor:** New capability (tool baru, optional field baru)
  - **Patch:** Bug fix, implementation-only change
- Schema Version: Gunakan dalam tool name atau parameter jika perlu (e.g., `search_vault_v2`)

#### 7.2 Backward Compatibility

```typescript
// Strategy: Dual-version tools selama migration period
server.tool("search_vault", /* old schema */, async (args) => {
  // Forward ke implementation baru dengan default values
  return searchVaultV2({ ...args, newParam: defaultValue });
});

server.tool("search_vault_v2", /* new schema */, async (args) => {
  return searchVaultV2(args);
});

// Setelah migration period, hapus v1 dan kirim listChanged notification
```

#### 7.3 Feature Flags untuk Capabilities

```typescript
// src/capabilities.ts
const FEATURES = {
  ADVANCED_SEARCH: process.env.ENABLE_ADVANCED_SEARCH === "true",
  REAL_TIME_SYNC: process.env.ENABLE_REAL_TIME_SYNC === "true",
  MULTI_TENANT: process.env.ENABLE_MULTI_TENANT === "true",
};

export function getCapabilities() {
  return {
    tools: {
      listChanged: true,
    },
    resources: {
      subscribe: FEATURES.REAL_TIME_SYNC,
      listChanged: true,
    },
    prompts: {
      listChanged: false,
    },
    logging: {},
  };
}
```

#### 7.4 Feedback Loop

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   User      │────►│   AI Agent  │────►│  MCP Server │
│  Feedback   │     │  Analysis   │     │   Metrics   │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Backlog    │
                    │  (Priority) │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Sprint    │
                    │  Planning   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Implement  │
                    │   & Test    │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Deploy    │
                    │  (Canary)   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Monitor   │
                    │  (Metrics)  │
                    └─────────────┘
```

#### 7.5 Output Tahap EVOLVE

- **Release Notes:** Perubahan schema, breaking changes, migration guide
- **Deprecation Timeline:** Tanggal tool lama akan dihapus
- **Feature Flags:** Environment-based capability toggles
- **User Feedback:** Analytics tentang tool usage patterns
- **Roadmap:** Prioritas fitur berdasarkan demand dan technical debt

---

## Advanced

### Toolchain dan Otomatisasi per Tahap

| Tahap | Alat | Fungsi | Integrasi |
|-------|------|--------|-----------|
| **PLAN** | Miro/FigJam | Capability mapping | Workshop dengan stakeholders |
| **DESIGN** | JSON Schema Validator | Schema validation online | jsonschema.net |
| **SCAFFOLD** | `npm init`, `npx tsc --init` | Project bootstrap | One-command setup |
| **BUILD** | TypeScript, Zod, ESLint | Type safety + linting | Pre-commit hooks |
| **TEST** | Vitest, mcp-inspector | Unit + E2E testing | `npm test`, `npm run inspector` |
| **DEPLOY** | GitHub Actions, Docker | CI/CD + containerization | Push-to-deploy |
| **MONITOR** | Grafana, CloudWatch | Metrics + alerting | Dashboard + PagerDuty |
| **EVOLVE** | GitHub Issues, Linear | Backlog management | Sprint planning |

### Security Gates per Tahap

| Tahap | Security Gate | Checklist |
|-------|---------------|-----------|
| **PLAN** | Threat Model | Data classification, attack surface |
| **DESIGN** | Schema Review | `additionalProperties: false`, input bounds |
| **SCAFFOLD** | Secret Management | No hard-coded keys, env vars only |
| **BUILD** | SAST Scan | Semgrep, CodeQL untuk injection patterns |
| **TEST** | Penetration Test | Fuzzing input, auth bypass attempts |
| **DEPLOY** | Container Scan | Trivy/Snyk untuk image vulnerabilities |
| **MONITOR** | Audit Review | Log analysis untuk anomalous patterns |
| **EVOLVE** | Dependency Audit | `npm audit`, Dependabot alerts |

### MCP Server Maturity Model

| Level | Nama | Ciri-ciri |
|-------|------|-----------|
| **0** | Experiment | Local stdio, single tool, no tests |
| **1** | MVP | Multiple tools, basic validation, manual testing |
| **2** | Production-Ready | Full test suite, CI/CD, error handling, logging |
| **3** | Enterprise | Multi-tenant, OAuth, audit trail, rate limiting |
| **4** | Platform | Dynamic capabilities, feature flags, A/B testing, SLA |

---

## Case Studies

| Studi Kasus | Konteks | Tahapan | Temuan Kunci | Mitigasi |
|-------------|---------|---------|--------------|----------|
| **Obsidian MCP Vault (2026)** | Personal Digital Garden, 5K+ notes | PLAN → SCAFFOLD → BUILD → DEPLOY (stdio) | 1. Schema drift saat vault structure berubah 2. Token bloat pada large notes 3. Frontmatter corruption tanpa validation | 1. Schema versioning per note type 2. Chunking strategy untuk large content 3. YAML AST parsing, bukan regex |
| **Enterprise SaaS Connector (2026)** | Multi-tenant CRM integration, 500+ tenants | Full 7-tahap dengan emphasis pada MONITOR | 1. OAuth token race condition saat concurrent calls 2. Rate limit exhaustion oleh aggressive LLM 3. Flat namespace collision antar tenants | 1. Distributed locks untuk token refresh 2. Circuit breaker + exponential backoff 3. Tenant-scoped tool names (`salesforce_tenant123_search`) |
| **Context7 Custom Docs (2025)** | Internal design system, private registry | PLAN → DESIGN → BUILD → DEPLOY (HTTP) → EVOLVE | 1. Private docs tidak bisa di-index Context7 publik 2. Version mismatch antara docs dan implementation 3. llms.txt generation manual dan error-prone | 1. Private MCP server dengan internal index 2. Tag-based schema versioning di CI 3. Automated `llms.txt` generation via build pipeline |
| **Healthcare EMR Integration (2026)** | HIPAA-compliant patient data access | Full 7-tahap + Security Gates setiap tahap | 1. PHI exposure via tool logs 2. Unauthorized access via path traversal 3. Audit trail tidak lengkap untuk compliance | 1. Log sanitization: strip PHI sebelum write 2. Strict path validation dengan allowlist 3. Immutable audit logs dengan tamper-evident hashing |

---

## Koneksi ke Vault

- [[skill-ai-mcp]] — Aturan teknis spesifikasi MCP yang mengikat setiap tahap BUILD dan DEPLOY.
- [[threat-modeling-deepdive]] — Metodologi STRIDE/PASTA untuk security gates di tahap PLAN dan MONITOR.
- [[comprehensive-threat-directory]] — Taksonomi ancaman spesifik untuk AI agent integrations.
- [[network-security]] — Monitoring dan deteksi anomaly untuk MCP traffic.
- [[endpoint-security]] — Sandboxing dan isolation untuk MCP server processes.
- [[system-design]] — Arsitektur zero-trust dan transport design decisions.
- [[devops]] — CI/CD pipeline patterns dan infrastructure as code.
- [[zero-trust-security]] — Least-privilege principles untuk tool permissions dan tenant scoping.

---

## Referensi

1. Model Context Protocol. *Architecture Overview*. modelcontextprotocol.io/docs/concepts/architecture. 2025.
2. Model Context Protocol. *Server Lifecycle*. modelcontextprotocol.info/specification/draft/basic/lifecycle. 2024.
3. cyanheads. *MCP Server Development Guide*. GitHub, 2025. https://github.com/cyanheads/model-context-protocol-resources/blob/main/guides/mcp-server-development-guide.md
4. Truto.one. *What is an MCP Server? The 2026 Architecture Guide for SaaS PMs*. 2026. https://truto.one/blog/what-is-an-mcp-server-the-2026-architecture-guide-for-saas-pms/
5. WorkOS. *Everything your team needs to know about MCP in 2026*. 2026. https://workos.com/blog/everything-your-team-needs-to-know-about-mcp-in-2026
6. Model Context Protocol. *2026 Roadmap*. modelcontextprotocol.io/development/roadmap. 2026.
7. Palo Alto Networks. *Model Context Protocol (MCP): A Security Overview*. 2025. https://www.paloaltonetworks.com/blog/cloud-security/model-context-protocol-mcp-a-security-overview/
8. Digital Applied. *Build an MCP Server in TypeScript: From Scratch 2026*. 2026. https://www.digitalapplied.com/blog/build-mcp-server-typescript-tutorial-from-scratch-2026
9. Logto. *MCP Best Practices*. 2025. https://blog.logto.io/zh-HK/what-is-mcp
10. OWASP / WebFuse. *MCP Cheat Sheet: Security Best Practices*. 2026. https://www.webfuse.com/mcp-cheat-sheet

> [!tip] Bottom Line
> MCP-SDLC bukan sekadar template — ini adalah loop kontinu yang menghubungkan ide, implementasi, deployment, observability, dan evolusi. Setiap tahap memiliki deliverables yang jelas, security gates yang non-negotiable, dan feedback loop ke tahap berikutnya. Server yang matang tidak dibangun dalam satu sprint; mereka ditumbuhkan melalui iterasi yang terukur, teramankan, dan terus-menerus ditingkatkan. Ingat: spesifikasi MCP adalah fondasi, tapi production-readiness datang dari disiplin di setiap tahap lifecycle.
---

audited
---
