---
title: AI Agent Readability & Writing Guide for this Vault
tags:
- vault
- note
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout

---

cssclasses:
  - wide-table
  - callout

# AI Agent Readability & Writing Guide for this Vault

Welcome, AI Agent. This document defines the strict engineering standards, conventions, and formatting guidelines for writing and modifying notes within this Obsidian/Quartz knowledge base. You MUST read and follow these rules unconditionally.

---

## 1. Metadata and Frontmatter Standards
Every markdown file (`*.md`) in the vault (excluding `_index.md` and this guide) MUST begin with a valid YAML frontmatter block enclosed in triple dashes (`---`). No blockquote metadata is allowed.

### Mandatory Frontmatter Schema:
```yaml
---
title: "Human Readable English Title"
tags:
  - domain-tag-1
  - domain-tag-2
aliases:
  - "alternative-kebab-case-name"
  - "Alternative Spaced Name"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
status: operational
---
```

### Metadata Fields Definition:
- **`title`**: The official display title of the document in title case (must be in English).
- **`tags`**: Lowercase list of tags for categorization (e.g. `machine-learning`, `cyber-security`, `reverse-engineering`).
- **`aliases`**: Array of alternative names. Always include the kebab-case version of the filename to aid AI agent link-resolution, along with any other common synonyms.
- **`status`**: Current note maturity:
  - `seedling`: Short stub notes with bullet points or basic definitions (<100 words).
  - `growing`: Expanding notes with structured headings but lacking fully elaborated examples.
  - `operational`: Deep, technical, well-structured notes with detailed code blocks, formulas, and diagrams.
  - `evergreen`: Master reference notes that are stable and highly polished.

---

## 2. File Naming & Language Protocol

### 2.1 File Names
- File names MUST be written in **English** using **kebab-case** (lowercase separated by hyphens).
- Do not use spaces, capital letters, or special characters in filenames (e.g. use `backpropagation-roadmap.md` instead of `Backpropagation Roadmap.md`).
- This prevents broken links and URL decoding issues when deploying the vault to public pages via Quartz.

### 2.2 Content Language
- All frontmatter fields (especially `title` and `aliases`) MUST be in English.
- The **body content** of the notes can be written in a **mixed Indonesian-English (ID-EN) language** according to the user's preference. Keep technical terms in their original English form (e.g., *key encapsulation*, *tiling*, *circuit breaker*).

---

## 3. Structural Design Patterns

### 3.1 Two-Doc Complementary Pattern
For complex technical topics, do not create single oversized notes. Instead, split them into two complementary documents linked via wikilinks:
1. **Roadmap (`*-roadmap.md`)**: Practical, step-by-step learning guide with ordered phases, hands-on tasks, required environment setup, and portfolio project suggestions.
2. **Deep Dive (`*-architecture-deepdive.md` or similar)**: Theoretical reference detailing first principles, math formulas, dynamic workflows, low-level mechanics, code snippets, and security/defense analysis.

### 3.2 Maps of Content (MOC)
- **`_index.md`**: Each main directory and sub-directory must contain an `_index.md` file. It serves as a Map of Content (MOC) and should be updated whenever notes are added or deleted.
- **Index Structure**: It must contain a category description paragraph, folder statistics (`> **Total:** N files | M subfolders`), subfolder list, and note list.
- **No Frontmatter**: `_index.md` files must NOT contain YAML frontmatter.

---

## 4. Markdown Formatting Compatibility

### 4.1 Pipe Tables
To ensure markdown engines (such as Obsidian, marked.js, and Quartz) render tables correctly:
- **Blank Line Rule**: You MUST insert at least one blank line between the preceding text paragraph/header and the start of a pipe table.
- **No backslash pipes**: Do not use backslashes inside wikilinks in tables (e.g. `[[file\|alias]]` is wrong; use `[[file\|alias]]` or simple `[[file]]` if target and display match).

### 4.2 Code Blocks and Math
- Use standard fenced code blocks with language specifiers for all code examples.
- For mathematical equations, use LaTeX delimiters:
  - Inline Math: `$...$` or `$...$`
  - Display Block Math: `$$...$$` or `$$...$$`

---

## 5. Verification Pipeline
After making any content edits, always:
1. Run the local audit script: `python3 scripts/vault-audit.py`.
2. Inspect `vault-audit-report.md` for warnings on **Broken Wikilinks**, **Missing Frontmatter**, or **Table Spacing Issues**.
3. Fix any true positives before ending your turn.
