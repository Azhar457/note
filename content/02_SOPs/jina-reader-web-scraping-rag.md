---
title: 'SOP: Otomatisasi Web Scraping & Ingest Dokumentasi ke Vault RAG via Jina Reader'
tags:
- sop
- web-scraping
- jina-reader
- rag
- obsidian
- automation
aliases:
- SOP Jina Reader Web Scraping
- Jina Reader Web Scraping RAG
- Automated Content Ingestion
created: 2026-07-21
updated: 2026-07-21
status: pending
cssclasses:
  - wide-table
  
---
# SOP: Otomatisasi Web Scraping & Ingest Dokumentasi ke Vault RAG via Jina Reader

> [!tip] Standard Operating Procedure (SOP) ini menjelaskan langkah-langkah otomatisasi pengambilan artikel web, riset ilmiah, dan dokumentasi teknis menggunakan **Jina Reader API (`r.jina.ai`)** atau **9Router Web Fetch Gateway**, mengubahnya menjadi format Markdown murni yang bersih, serta menyuntikkannya secara otomatis ke Obsidian Vault & Indeks RAG.

---

## 1. Tujuan & Scope SOP

### Purpose
Menghilangkan proses manual *copy-paste* artikel teknis yang sering terkontaminasi oleh elemen UI (header, footer, iklan, popup cookie, dan script JavaScript), serta memastikan setiap dokumen yang di-ingest ke Vault memiliki **metadata standar (Frontmatter YAML, Timestamp, Source URL, dan Tags)**.

### Scope
- Ekstraksi artikel tunggal atau dokumentasi teknis via Jina Reader API (`https://r.jina.ai/`).
- Integrasi otomatis dengan Gateway **9Router (`/v1/web/fetch`)**.
- Sanitasi teks otomatis (penghapusan komensasi HTML, perbaikan relative links).
- Ingesti otomatis ke direktori Vault (`01_Library/` atau `03_Resources/`) dan pemicuan re-indexing `vault-rag`.

---

## 2. Prasyarat & Arsitektur Alur Kerja

```
[ Target URL ] ──> [ Jina Reader API / 9Router ] ──> [ Sanitizer & Formatter ] ──> [ Obsidian Vault ] ──> [ Vault RAG Re-index ]
```

### Prasyarat System
1. **Python 3.10+** dengan library `requests`, `pyyaml`.
2. **9Router Gateway** aktif di `http://localhost:20128` (Opsional untuk fallback).
3. **Jina API Key** (Opsional untuk mendapatkan rate limit tinggi hingga 200 request/menit).

---

## 3. Detail Parameter Header Jina Reader

Jina Reader mendukung konfigurasi perilaku ekstraksi melalui HTTP Headers berikut:

| HTTP Header | Nilai | Fungsi |
|---|---|---|
| `X-Respond-With` | `markdown` (Default) / `text` / `html` | Menentukan format output hasil ekstraksi. |
| `X-With-Generated-Alt` | `true` | Membuat alt-text deskriptif otomatis untuk gambar menggunakan AI Vision. |
| `X-With-Images-Summary` | `true` | Menambahkan daftar ringkasan seluruh URL gambar di akhir dokumen. |
| `X-With-Links-Summary` | `true` | Menambahkan daftar tautan/hyperlink terestrak di akhir dokumen. |
| `X-Target-Selector` | `article, main, .content` | Menentukan CSS Selector spesifik yang ingin diekstrak. |
| `X-Remove-Selector` | `.nav, .footer, .sidebar, .ad` | Menghapus elemen web yang tidak diinginkan. |

---

## 4. Skrip Automasi Python CLI: `jina_vault_ingest.py`

Simpan skrip berikut di `/mnt/data_d/Projects/vault-rag/scripts/jina_vault_ingest.py`:

```python
#!/usr/bin/env python3
import os
import sys
import re
import argparse
import requests
from datetime import datetime

VAULT_BASE_DIR = "/mnt/data_d/Documents/Wide Note/Note"
QUARTZ_MIRROR_DIR = "/mnt/data_d/Desktop/Domain Website/azhar457.github.io[note]/note/content"

def fetch_with_jina_reader(url: str, jina_key: str = None) -> dict:
    """
    Fetch webpage content via Jina Reader REST API.
    """
    jina_endpoint = f"https://r.jina.ai/{url}"
    headers = {
        "X-Respond-With": "markdown",
        "X-With-Generated-Alt": "true"
    }
    if jina_key:
        headers["Authorization"] = f"Bearer {jina_key}"

    print(f"[1/4] Scraping URL via Jina Reader: {url}...")
    response = requests.get(jina_endpoint, headers=headers, timeout=25)
    response.raise_for_status()
    
    raw_text = response.text
    
    # Extract Title if available
    title_match = re.search(r"^Title:\s*(.+)$", raw_text, re.MULTILINE)
    title = title_match.group(1).strip() if title_match else "Scraped Article"
    
    return {
        "title": title,
        "raw_text": raw_text,
        "url": url
    }

def sanitize_and_format_markdown(scraped_data: dict, category_tag: str) -> str:
    """
    Clean raw markdown and prepend standardized Frontmatter YAML.
    """
    print("[2/4] Membersihkan teks dan menyusun Frontmatter YAML...")
    raw_text = scraped_data["raw_text"]
    title = scraped_data["title"]
    url = scraped_data["url"]
    
    # Hapus header metadata standar dari Jina
    cleaned_text = re.sub(r"^Title:.*\n", "", raw_text)
    cleaned_text = re.sub(r"^URL Source:.*\n", "", cleaned_text)
    cleaned_text = re.sub(r"^Published Time:.*\n", "", cleaned_text)
    cleaned_text = re.sub(r"^Markdown Content:\n", "", cleaned_text)
    cleaned_text = cleaned_text.strip()
    
    # Buat slug nama file yang aman
    safe_title = re.sub(r"[^\w\s-]", "", title).strip().lower()
    slug_name = re.sub(r"[-\s]+", "-", safe_title)[:60]
    
    date_str = datetime.now().strftime("%Y-%m-%d")
    
    frontmatter = f"""---
tags:
  - web-clipping
  - {category_tag}
  - jina-reader
aliases:
  - "{title}"
status: seedling
created: {date_str}
updated: {date_str}
source_url: "{url}"
---

# {title}

> [!note] Artikel ini diekstrak secara otomatis dari [{url}]({url}) menggunakan Jina Reader API pada {date_str}.

---

{cleaned_text}
"""
    return frontmatter, slug_name

def save_to_vault(content: str, slug_name: str, subfolder: str):
    """
    Save markdown file to both Obsidian Vault & Quartz Mirror.
    """
    target_rel_path = os.path.join(subfolder, f"{slug_name}.md")
    vault_path = os.path.join(VAULT_BASE_DIR, target_rel_path)
    quartz_path = os.path.join(QUARTZ_MIRROR_DIR, target_rel_path)
    
    os.makedirs(os.path.dirname(vault_path), exist_ok=True)
    os.makedirs(os.path.dirname(quartz_path), exist_ok=True)
    
    print(f"[3/4] Menyimpan file ke Vault: {vault_path}...")
    with open(vault_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print(f"[4/4] Menyinkronkan ke Quartz Mirror: {quartz_path}...")
    with open(quartz_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print("✓ Sukses! File berhasil tersimpan dan siap di-index oleh vault-rag.")

def main():
    parser = argparse.ArgumentParser(description="Jina Reader Vault Ingestion Tool")
    parser.add_argument("url", help="Target Web URL to scrape")
    parser.add_argument("--subfolder", default="03_Resources/web-clippings", help="Subfolder destination in Vault")
    parser.add_argument("--tag", default="research", help="Category tag for frontmatter")
    args = parser.parse_args()
    
    jina_key = os.getenv("JINA_API_KEY")
    data = fetch_with_jina_reader(args.url, jina_key)
    formatted_md, slug = sanitize_and_format_markdown(data, args.tag)
    save_to_vault(formatted_md, slug, args.subfolder)

if __name__ == "__main__":
    main()
```

---

## 5. Troubleshooting & Handling Edge Cases

### A. Penanganan Cloudflare Anti-Bot (HTTP 403 / 503)
Jika target URL mengaktifkan Cloudflare Turnstile berat:
- **Solusi**: Gunakan `9Router Web Fetch Gateway` (`POST http://localhost:20128/v1/web/fetch`) dengan provider `jina-reader` karena 9Router memiliki rotasi user-agent dan retry backoff internal.

### B. Single Page Applications (SPA) / Heavy JavaScript
- **Solusi**: Jina Reader secara otomatis menjalankan *Headless Browser rendering* di backend-nya. Jika konten masih belum termuat sempurna, tambahkan header `X-Wait-For-Selector: .main-content` pada request Jina.

### C. Penanganan Rate Limit (HTTP 422 / 429)
- Free tier Jina Reader memiliki limit **20 RPM**.
- Jika terkena `HTTP 429 Too Many Requests`, tambahkan delay $3.0\text{ detik}$ antar-request dalam skrip otomasi.

---

## 🔗 Referensi & Catatan Terkait
- [[jina-reranker-v3-deepdive]] — Integrasi Jina Reranker v3 untuk Pencarian Presisi
- [[jina-embeddings-v5-mrl-adapters]] — Integrasi Vektor Embedding Matryoshka Jina v5
- [[unified-mcp-server]] — Integrasi Tooling MCP Server untuk Vault
---

audited
---
