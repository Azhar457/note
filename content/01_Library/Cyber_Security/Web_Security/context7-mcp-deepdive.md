---
title: Context7 MCP & Custom MCP Server Development
tags:
  - cyber-security
  - library
  - web-security
created: "2026-07-03"
updated: "2026-07-03"
status: pending
cssclasses: ""
---

# 🧠 Context7 MCP & Custom Server Development — Deep Dive

> Ringkasan satu-paragraf menjelaskan bahwa Context7 MCP adalah server Model Context Protocol (MCP) dari tim Upstash yang menyediakan dokumentasi kode _up-to-date_ dan _version-specific_ untuk LLM dan AI code editor. Panduan ini membahas cara membangun MCP server kustom untuk Digital Garden (Obsidian) dan mengadaptasi pola komponen seperti React Bits ke framework lain (Svelte) dengan memanfaatkan arsitektur MCP sebagai jembatan kontekstual antar ekosistem.

> [!info] Hubungan ke Vault
> Nota ini terkait dengan [[threat-modeling-deepdive]] untuk prinsip keamanan dalam arsitektur sistem, [[comprehensive-threat-directory]] untuk ancaman pada integrasi AI-agent, serta [[devops]] dan [[system-design]] untuk pipeline CI/CD dan arsitektur serverless.

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

### Apa Itu Context7 MCP?

Context7 adalah MCP server open-source yang dikembangkan oleh tim Upstash untuk mengatasi masalah fundamental LLM: _training data cutoff_ dan _hallucination_ pada API library yang sering berubah. Alih-alih mengandalkan pengetahuan statis model, Context7 menarik dokumentasi dan contoh kode _real-time_ langsung dari repositori sumber, membersihkannya, dan menyuntikkannya ke _context window_ LLM pada saat prompting.

**Masalah yang dipecahkan:**

| Tanpa Context7                                      | Dengan Context7                                 |
| --------------------------------------------------- | ----------------------------------------------- |
| Contoh kode outdated berdasarkan data latih tahunan | Dokumentasi _version-specific_ dan _up-to-date_ |
| API yang dihalusinasi (tidak ada di library)        | Snippet kode nyata dari sumber resmi            |
| Jawaban generik untuk versi lama                    | Informasi ringkas tanpa _filler_                |
| Copy-paste manual page-by-page                      | Integrasi otomatis via MCP atau CLI             |

Context7 beroperasi dalam dua mode: **CLI + Skills** (`ctx7` commands) dan **MCP** (native tool invocation). Server MCP-nya tersedia sebagai npm package `@upstash/context7-mcp` dengan endpoint `https://mcp.context7.com/mcp`.

### Apa Itu Model Context Protocol (MCP)?

MCP adalah standar open-source dari Anthropic (rilis November 2024) yang menstandardisasi koneksi antara aplikasi AI (_host_) dengan sistem eksternal (_server_). Analoginya seperti USB-C untuk AI: satu protokol universal untuk data, tools, dan workflows.

**Arsitektur dasar:**

```
┌─────────────┐     JSON-RPC 2.0      ┌─────────────┐
│  MCP Host   │ ◄──────────────────► │  MCP Server │
│ (Claude,    │   stdio / Streamable  │ (Tools,     │
│  Cursor,    │      HTTP             │  Resources, │
│  VS Code)   │                       │  Prompts)   │
└─────────────┘                       └─────────────┘
```

Tiga primitif utama yang diekspos server:

| Primitif      | Kontrol     | Fungsi                                       | Analogi REST    |
| ------------- | ----------- | -------------------------------------------- | --------------- |
| **Tools**     | Model (LLM) | Eksekusi aksi: query DB, call API, komputasi | POST/PUT/DELETE |
| **Resources** | Aplikasi    | Data read-only: file, record, config         | GET             |
| **Prompts**   | User        | Template reusable untuk interaksi optimal    | Template engine |

### Digital Garden & Knowledge Base

_Digital Garden_ adalah metode manajemen pengetahuan pribadi di mana catatan (notes) ditanam, dirawat, dan ditumbuhkan seiring waktu—berbeda dengan blog yang bersifat "publish once, done". Obsidian adalah platform paling populer untuk pendekatan ini, dengan fitur _backlink_, _graph view_, dan _local-first_ Markdown storage.

Integrasi MCP dengan Digital Garden memungkinkan AI agent untuk:

- Membaca dan mencari vault secara semantik
- Membuat serta memperbarui catatan
- Menavigasi _knowledge graph_ via wiki-links
- Mensintesis ide dari beberapa catatan terhubung

### React Bits & Ekosistem Component Porting

React Bits adalah koleksi 130+ komponen React animasi yang berkembang pesat (37K+ stars, #2 JS Rising Stars 2025). Filosofinya: _copy-paste ready_, minimal dependencies, dan tidak memaksakan Framer Motion—menggunakan CSS animations untuk sebagian besar komponen. Setiap komponen tersedia dalam 4 varian: JS-CSS, JS-Tailwind, TS-CSS, TS-Tailwind.

**Porting ke Svelte:**

React Bits memiliki port oficial ke Svelte bernama **Svelte Bits** (sveltebits.xyz). Porting ini mempertahankan perilaku animasi, shader, dan konfigurasi spring asli, namun mengadaptasi ke pola reaktivitas Svelte ($state, $derived, $effect) dan menghilangkan runtime React.

| Aspek          | React Bits                       | Svelte Bits                                   |
| -------------- | -------------------------------- | --------------------------------------------- |
| Framework      | React 19                         | Svelte 5                                      |
| Reactivitas    | Hooks (useState, useEffect)      | Runes ($state, $effect)                       |
| Bundle         | ~42–45 KB (React runtime)        | ~2–5 KB (Svelte compiled)                     |
| RSC Compatible | Partial (CSS components)         | Native (compile-time)                         |
| Install        | `npx shadcn add @react-bits/...` | `npx jsrepo add https://sveltebits.xyz/r/...` |
| Dependencies   | Optional GSAP/Three.js           | Same optional deps                            |

---

## Technical Deep-Dive

### Langkah-Langkah Membangun MCP Server Kustom

Berikut adalah alur kerja lengkap untuk membangun MCP server untuk Digital Garden (Obsidian vault) dan cross-library documentation, mengikuti pola Context7:

#### 1. Menyiapkan Project Scaffold (TypeScript)

```bash
mkdir garden-mcp && cd garden-mcp
npm init -y
npm install @modelcontextprotocol/sdk zod
npm install -D typescript @types/node tsx @modelcontextprotocol/inspector
npx tsc --init
```

Konfigurasi `package.json` (ESM-only, bin executable):

```json
{
  "name": "@your-scope/garden-mcp",
  "version": "0.1.0",
  "type": "module",
  "bin": { "garden-mcp": "./dist/index.js" },
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/index.ts",
    "inspector": "npx @modelcontextprotocol/inspector tsx src/index.ts"
  }
}
```

> **Peringatan scaffold:** Jangan lewatkan `"type": "module"`. MCP SDK adalah ESM-only; CommonJS akan gagal dengan error `require() of ES module`.

#### 2. Membuat Server Skeleton

```typescript
#!/usr/bin/env node
// src/index.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js"
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js"

const server = new McpServer({
  name: "garden-mcp",
  version: "0.1.0",
})

async function main() {
  const transport = new StdioServerTransport()
  await server.connect(transport)
  // stdout adalah channel protokol — jangan tulis apa pun ke sana
  console.error("[garden-mcp] ready on stdio")
}

main().catch((err) => {
  console.error("Fatal:", err)
  process.exit(1)
})
```

**Aturan emas stdio:** Jangan pernah menulis ke `stdout` kecuali framed JSON-RPC. Gunakan `stderr` untuk logging.

#### 3. Mendaftarkan Tools untuk Digital Garden

**Pola Tool 1: Semantic Vault Search**

```typescript
import { z } from "zod"

server.tool(
  "search_vault",
  "Search the Obsidian vault semantically using BM25 or vector embeddings. " +
    "Use this when the user asks about concepts, topics, or specific content " +
    "across their knowledge base.",
  {
    query: z.string().min(2).describe("Search query in natural language"),
    limit: z.number().optional().default(10).describe("Max results to return"),
    path_filter: z.string().optional().describe("Optional folder path to narrow search"),
  },
  async ({ query, limit, path_filter }) => {
    // Implementasi: gunakan Obsidian CLI, Local REST API, atau file-system BM25
    const results = await searchVault(query, { limit, path_filter })
    return {
      content: [
        {
          type: "text",
          text: formatSearchResults(results),
        },
      ],
    }
  },
)
```

**Pola Tool 2: Read Note dengan Frontmatter Parsing**

```typescript
server.tool(
  "read_note",
  "Read a specific note from the vault, parsing YAML frontmatter, content, " +
    "and wikilinks. Use this when the user references a specific note title or path.",
  {
    path: z.string().describe("Relative path to note, e.g. 'Projects/AI-Research.md'"),
    include_backlinks: z.boolean().optional().default(false),
  },
  async ({ path, include_backlinks }) => {
    const note = await readNote(path)
    const backlinks = include_backlinks ? await getBacklinks(path) : []
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({ ...note, backlinks }, null, 2),
        },
      ],
    }
  },
)
```

**Pola Tool 3: Write / Append Note**

```typescript
server.tool(
  "write_note",
  "Create or append content to a note. Use for capturing insights, " +
    "synthesizing research, or updating project documentation.",
  {
    path: z.string().describe("Target note path"),
    content: z.string().describe("Markdown content to write"),
    mode: z.enum(["create", "append", "prepend"]).default("append"),
    frontmatter: z.record(z.any()).optional().describe("YAML frontmatter object"),
  },
  async ({ path, content, mode, frontmatter }) => {
    const result = await writeNote(path, content, { mode, frontmatter })
    return {
      content: [{ type: "text", text: `Note ${mode}ed: ${result.path}` }],
    }
  },
)
```

#### 4. Menambahkan Resources (Read-Only Data)

Resources berguna untuk menyediakan konteks statis yang sering diakses:

```typescript
server.resource("vault-stats", "garden://stats", async (uri) => {
  const stats = await getVaultStats()
  return {
    contents: [
      {
        uri: uri.href,
        mimeType: "application/json",
        text: JSON.stringify(stats, null, 2),
      },
    ],
  }
})

server.resource("tag-index", "garden://tags/{tag}", async (uri) => {
  const tag = uri.pathname.replace("//", "")
  const notes = await getNotesByTag(tag)
  return {
    contents: [
      {
        uri: uri.href,
        mimeType: "application/json",
        text: JSON.stringify(notes, null, 2),
      },
    ],
  }
})
```

#### 5. Menambahkan Prompts (Reusable Templates)

```typescript
server.prompt(
  "synthesize_research",
  "Generate a synthesis note from multiple source notes. " +
    "Use when the user wants to connect ideas across their knowledge graph.",
  {
    topic: z.string().describe("Synthesis topic or question"),
    source_paths: z.array(z.string()).describe("List of note paths to synthesize"),
  },
  async ({ topic, source_paths }) => {
    const sources = await Promise.all(source_paths.map(readNote))
    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `Synthesize the following notes on "${topic}":\n\n${sources
              .map((s) => `--- ${s.path} ---\n${s.content}`)
              .join("\n\n")}\n\nCreate a new note that connects these ideas with backlinks.`,
          },
        },
      ],
    }
  },
)
```

#### 6. Wire ke Claude Desktop / Cursor / VS Code

**Claude Desktop (`claude_desktop_config.json`):**

```json
{
  "mcpServers": {
    "digital-garden": {
      "command": "npx",
      "args": ["-y", "@your-scope/garden-mcp"],
      "env": {
        "VAULT_PATH": "/Users/you/Obsidian/Vault",
        "OBSIDIAN_API_KEY": "your-rest-api-key"
      }
    }
  }
}
```

**Cursor (`~/.cursor/mcp.json`):**

```json
{
  "mcpServers": {
    "digital-garden": {
      "command": "npx",
      "args": ["-y", "@your-scope/garden-mcp"],
      "env": { "VAULT_PATH": "/Users/you/Obsidian/Vault" }
    }
  }
}
```

### Contoh Artefak: Component Registry MCP untuk React Bits → Svelte

Berikut adalah konsep MCP server yang memetakan komponen React Bits ke Svelte Bits, memungkinkan AI agent untuk "mentranspilasi" komponen antar framework:

#### Component Mapping Register

| Component ID      | React Bits Path              | Svelte Bits Path             | Dependencies   | Complexity |
| ----------------- | ---------------------------- | ---------------------------- | -------------- | ---------- |
| `blur-text`       | `text-animations/BlurText`   | `text-animations/BlurText`   | None (CSS)     | Low        |
| `aurora-bg`       | `backgrounds/Aurora`         | `backgrounds/Aurora`         | None (CSS)     | Low        |
| `particles`       | `backgrounds/Particles`      | `backgrounds/Particles`      | `matter-js`    | Medium     |
| `grid-distortion` | `backgrounds/GridDistortion` | `backgrounds/GridDistortion` | `three`        | High       |
| `magnetic-button` | `components/MagneticButton`  | `components/MagneticButton`  | None (CSS)     | Low        |
| `tilt-card`       | `components/TiltCard`        | `components/TiltCard`        | `vanilla-tilt` | Low        |

#### Tool: `port_component`

```typescript
server.tool(
  "port_component",
  "Port a React Bits component to Svelte. Returns the Svelte equivalent " +
    "with reactivity patterns adapted (useState → $state, useEffect → $effect). " +
    "Use when the user wants to use a React Bits component in a Svelte project.",
  {
    component_id: z.string().describe("Component ID from the registry, e.g. 'blur-text'"),
    variant: z.enum(["css", "tailwind"]).default("tailwind"),
    typescript: z.boolean().default(true),
  },
  async ({ component_id, variant, typescript }) => {
    const mapping = await getComponentMapping(component_id)
    const svelteCode = await fetchSvelteVariant(mapping.sveltePath, variant, typescript)
    const reactCode = await fetchReactVariant(mapping.reactPath, variant, typescript)

    return {
      content: [
        {
          type: "text",
          text:
            `# ${mapping.name} — Svelte Port\n\n` +
            `## Install\n\`\`\`bash\n` +
            `npx jsrepo add https://sveltebits.xyz/r/${component_id}.json\n` +
            `\`\`\`\n\n` +
            `## Svelte Code (${variant}, ${typescript ? "TS" : "JS"})\n\`\`\`svelte\n${svelteCode}\n\`\`\`\n\n` +
            `## React Original (for reference)\n\`\`\`tsx\n${reactCode}\n\`\`\`\n\n` +
            `## Key Differences\n` +
            `- React: \`useState\`, \`useEffect\` → Svelte: \`$state\`, \`$effect\`\n` +
            `- React: Props via destructuring → Svelte: \`$props()\`\n` +
            `- React: \`children\` → Svelte: \`{@render children()}\`\n` +
            `- Bundle: ~${mapping.bundleDiff}KB smaller in Svelte\n`,
        },
      ],
    }
  },
)
```

---

## Advanced

### Toolchain dan Otomatisasi

| Alat              | Fungsi                                     | Integrasi           | Catatan                                        |
| ----------------- | ------------------------------------------ | ------------------- | ---------------------------------------------- |
| **mcp-inspector** | Debug server, test tools, inspect JSON-RPC | `npm run inspector` | UI browser untuk iterasi cepat                 |
| **ctx7 CLI**      | Setup Context7 tanpa MCP                   | `npx ctx7 setup`    | OAuth + auto-config untuk Cursor/Claude        |
| **PyTM**          | Threat modeling as code                    | Python/CLI          | Untuk security review MCP server               |
| **llms.txt**      | Routing layer untuk agentic web            | Root domain         | B2A infrastructure, diakses Cursor/Claude Code |
| **jsrepo**        | Install Svelte Bits components             | `jsrepo add <url>`  | Direct HTTPS registry, no npm package          |

### Mengintegrasikan MCP ke dalam Workflow Digital Garden

**Shift-Left Knowledge Capture:**

Gunakan MCP server untuk menangkap konteks _sebelum_ insight hilang:

1. **Hot Storage (Session Log):** Setiap sesi Claude dengan MCP server menulis ke `Daily Notes/YYYY-MM-DD.md`
2. **Warm Storage (Synthesis):** Akhir hari, agent merangkum session log menjadi decision records
3. **Cold Storage (Archive):** Catatan lama dipindahkan ke `Archive/` dengan backlink preserved

**Deduplication Loop:**

```typescript
server.tool(
  "capture_insight",
  "Capture an insight to the vault with deduplication check. " +
    "Searches existing notes before writing to prevent redundant entries.",
  {
    insight: z.string(),
    topic: z.string(),
    source_url: z.string().optional(),
  },
  async ({ insight, topic, source_url }) => {
    const existing = await semanticSearch(`${topic} ${insight}`, { limit: 5 })
    const similarity = await checkSimilarity(insight, existing)

    if (similarity.max > 0.85) {
      return {
        content: [
          {
            type: "text",
            text: `Similar note exists: ${similarity.bestMatch.path}. Appending instead.`,
          },
        ],
        isError: false,
      }
    }

    const path = `Inbox/${slugify(topic)}-${Date.now()}.md`
    await writeNote(
      path,
      `## ${topic}\n\n${insight}\n\n${source_url ? `Source: ${source_url}` : ""}`,
    )
    return { content: [{ type: "text", text: `Captured to ${path}` }] }
  },
)
```

### Security & Sandboxing MCP Server

Berdasarkan OWASP MCP Security Cheat Sheet:

| Layer                    | Kontrol                                           | Implementasi                                  |
| ------------------------ | ------------------------------------------------- | --------------------------------------------- |
| **Auth**                 | OAuth 2.0 + PKCE untuk remote                     | `MCP_AUTH_MODE=oauth`                         |
| **Sandboxing**           | Container/chroot untuk local                      | Docker, `fs` access scoped                    |
| **Input Validation**     | JSON Schema strict, `additionalProperties: false` | Zod schema dengan `.strict()`                 |
| **Path Policy**          | Prefix-based read/write gates                     | `OBSIDIAN_READ_PATHS`, `OBSIDIAN_WRITE_PATHS` |
| **Output Sanitization**  | Strip instruction-like patterns                   | Regex filter pada text content                |
| **Tool Poisoning Guard** | Hash schema definitions                           | Re-validate sebelum `tools/call`              |

---

## Case Studies

| Studi Kasus                                    | Konteks                                               | Metodologi                                    | Temuan Kunci                                                                                                                              | Mitigasi yang Diimplementasi                                                                                                       |
| ---------------------------------------------- | ----------------------------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Obsidian + Claude Desktop (2026)**           | Vault pribadi 5,000+ notes, MCP server via `mcpvault` | MCP (stdio) + BM25 search                     | 1. File-based access tanpa plugin dependency 2. Frontmatter corruption pada server lain 3. 70,000x token efficiency vs naive file reads   | 1. Gunakan `@bitbonsai/mcpvault` (zero deps) 2. AST-aware YAML preservation 3. Scoped path permissions                             |
| **React Bits → SvelteKit Landing Page (2026)** | Porting 12 komponen animasi ke Svelte untuk performa  | Component-by-component port + jsrepo registry | 1. Bundle berkurang ~38KB (React runtime dihapus) 2. RSC-compatible tanpa `"use client"` 3. Three.js peer deps tetap sama                 | 1. Gunakan Svelte Bits official port 2. `$state` untuk reactive props 3. `{@render}` untuk slot equivalent                         |
| **Context7 + Custom Docs (2025)**              | Internal design system docs, tidak publik di Context7 | PASTA + llms.txt generation                   | 1. Private docs tidak terindex Context7 2. Butuh versioning untuk setiap release 3. Token bloat pada HTML docs                            | 1. Generate `llms.txt` internal via CI 2. Tag-based versioning di registry 3. Markdown-first docs dengan `llms-full.txt` companion |
| **Project Synapse (2026)**                     | Neo4j + Obsidian wiki untuk research compounding      | TRIKE + Graph RAG                             | 1. Akses graph relationship lebih powerful dari flat search 2. Vector embeddings per node 3. Multi-hop traversal untuk hidden connections | 1. Neo4j 2026.x untuk graph storage 2. FAISS untuk vector index 3. `wiki_fetch_url` dengan defuddle untuk web clipping             |

---

## Koneksi ke Vault

- [[threat-modeling-deepdive]] — Prinsip STRIDE/PASTA untuk mengamankan surface area MCP server (spoofing, tampering, repudiation, information disclosure).
- [[comprehensive-threat-directory]] — Taksonomi ancaman spesifik untuk AI agent integrations (prompt injection, tool poisoning, context window attacks).
- [[network-security]] — Lapisan deteksi untuk MCP traffic anomaly (unusual tool invocation patterns, data exfiltration via resources).
- [[endpoint-security]] — Sandboxing dan isolation untuk MCP server processes (EDR, container escape detection).
- [[system-design]] — Arsitektur zero-trust untuk MCP: never trust, always verify antara host-client-server.
- [[devops]] — Integrasi MCP server ke CI/CD: automated testing dengan mcp-inspector, schema versioning, dan llms.txt generation pipeline.
- [[zero-trust-security]] — Konsep least-privilege untuk tool permissions: read-only default, scoped write paths, audit logging.

---

## Referensi

1. Upstash. _Context7 Platform — Up-to-date Code Docs For Any Prompt_. GitHub: upstash/context7. 2025. https://github.com/upstash/context7
2. Anthropic. _Introducing the Model Context Protocol_. 2024. https://www.anthropic.com/news/model-context-protocol
3. Model Context Protocol. _What is MCP?_ https://modelcontextprotocol.io/docs/getting-started/intro
4. Digital Applied. _Build an MCP Server in TypeScript: From Scratch 2026_. 2026. https://www.digitalapplied.com/blog/build-mcp-server-typescript-tutorial-from-scratch-2026
5. Joe FRANCOIS. _Supercharging Obsidian with AI using MCP_. Medium, 2026. https://joemugen.medium.com/supercharging-obsidian-with-ai-using-mcp-319679a36c97
6. DavidHDev. _React Bits — Animated UI Components_. GitHub, 2024. https://github.com/DavidHDev/react-bits
7. DavidHDev. _Svelte Bits — Svelte Port_. GitHub, 2025. https://github.com/DavidHDev/svelte-bits
8. Jeremy Howard / Answer.AI. _llms.txt Specification_. llmstxt.org, 2024. https://llmstxt.org/
9. Limy.ai. _LLMs.txt in 2026: The Full Guide_. 2026. https://limy.ai/blog/llms.txt-in-2026-the-full-guide
10. OWASP / WebFuse. _MCP Cheat Sheet: Security Best Practices_. 2026. https://www.webfuse.com/mcp-cheat-sheet
11. cyanheads. _Model Context Protocol Resources & Guides_. GitHub, 2024. https://github.com/cyanheads/model-context-protocol-resources
12. Build MVP Fast. _Obsidian + Claude AI Knowledge Management Setup 2026_. 2026. https://www.buildmvpfast.com/blog/obsidian-claude-ai-knowledge-management-system-2026
13. PkgPulse. _react-bits vs Aceternity UI vs Magic UI 2026_. 2026. https://www.pkgpulse.com/guides/react-bits-animated-components-2026
14. Tech Insider. _Svelte vs React 2026: 14x Bundle Gap [Tested]_. 2026. https://tech-insider.org/svelte-vs-react-2026-2/

> [!tip] Bottom Line
> Context7 MCP menunjukkan arsitektur masa depan: _context as a service_. Bangun MCP server kustom untuk Digital Garden Anda dengan pola yang sama—parse, enrich, vectorize, rerank, cache. Porting komponen seperti React Bits ke Svelte bukan sekadar translasi kode, tapi adaptasi filosofi reaktivitas. Gabungkan keduanya, dan Anda mendapatkan _knowledge system_ yang tidak hanya menyimpan informasi, tapi aktif berinteraksi dengan AI agent untuk mensintesis, menghubungkan, dan menumbuhkan pengetahuan secara otonom.
