---
title: "MCP Integration Guide"
tags:
  - mcp
  - model-context-protocol
  - integration
  - ai-tools
aliases:
  - "mcp-integration-guide"
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> MCP (Model Context Protocol) adalah open protocol untuk menghubungkan AI agents dengan tools eksternal.

## Architecture

```
Host (AI Agent) <-> MCP Client <-> MCP Server <-> Tool/Data
```

## Components

- **MCP Client**: Library untuk AI agent (Python/TypeScript)
- **MCP Server**: Implementasi tool (filesystem, database, API)
- **Transports**: STDIO (local) atau WebSocket (remote)
- **Capabilities**: tools, resources, prompts

See also: ai-comm-protocol-deep-dive, ai-engineering-stack-roadmap
