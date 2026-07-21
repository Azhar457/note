---
title: Unified MCP Server — 10 Services in One
tags:
- cyber-security
- library
- web-security
created: '2026-07-02'
updated: '2026-07-02'
status: operational
cssclasses: ''
---

# 🧩 Unified MCP Server – Dokumentasi Lengkap

Hubungan ke Vault: Unified MCP server adalah implementasi yang terinspirasi dari [[cloudflare-ruleset-engine-phases]] (modular service architecture). Tools yang dibungkus termasuk web search ([[dns-tunneling-deepdive]]), browser automation, dan doc lookup ([[identity-and-access-management]]).

## 1. Konsep Dasar & Arsitektur

### 1.1 Apa itu Unified MCP Server?

Unified MCP Server adalah implementasi _multi-service_ dalam satu proses Python yang menggabungkan 10 MCP (Model Context Protocol) services terbaik. Setiap service aktif secara dinamis hanya jika API key yang sesuai terdeteksi di file `.env`. Prinsipnya: satu server, banyak tools, tanpa overhead deployment terpisah.

Tujuan arsitektur ini:
- **Efisiensi operasional** – tidak perlu menjalankan 10 server berbeda.
- **Konfigurasi minimal** – cukup satu file `.env`.
- **Ekstensibilitas** – menambah service baru cukup dengan satu modul Python dan satu baris konfigurasi.

### 1.2 Alur Kerja MCP

MCP adalah protokol client-server yang memungkinkan AI assistant (seperti Claude, Hermes, Cursor) untuk menjalankan tindakan di dunia nyata melalui _tools_. Berikut alurnya:

```
AI Client (Hermes) 
    │  (MCP Request: nama tool + parameter)
    ▼
Unified MCP Server 
    │  (validasi, autentikasi, eksekusi)
    ▼
API Eksternal / Local Engine
    │  (hasil)
    ▼
Unified MCP Server 
    │  (response terstruktur)
    ▼
AI Client (Hermes) – interpretasi hasil
```

Server kami menggunakan **FastMCP**, library Python ringan yang mengimplementasikan MCP spec secara penuh. FastMCP menangani transport layer (stdio atau SSE) dan serialisasi pesan JSON-RPC.

### 1.3 Dynamic Tool Registration

Salah satu fitur kunci adalah registrasi tools secara dinamis saat startup. Setiap modul di `unified_mcp/tools/` mengekspos fungsi yang didekorasi `@tool`. Pada `tools/__init__.py`, kita melakukan eager import dan memeriksa ketersediaan API key:

```python
# tools/__init__.py

import os
import importlib
from pathlib import Path

TOOL_MODULES = {
    "firecrawl": "FIRECRAWL_API_KEY",
    "brave_search": "BRAVE_API_KEY",
    "figma": "FIGMA_ACCESS_TOKEN",
    "code_sandbox": "E2B_API_KEY",
    "composio": "COMPOSIO_API_KEY",
    "vercel": "VERCEL_API_TOKEN",
    "linear": "LINEAR_API_KEY",
    "sentry": "SENTRY_AUTH_TOKEN",
    "playwright_browser": None,  # tidak perlu API key
    "context7": None,            # gratis
}

def register_tools(server):
    for module_name, env_var in TOOL_MODULES.items():
        if env_var and not os.getenv(env_var):
            continue  # skip jika key tidak ada
        try:
            mod = importlib.import_module(f".{module_name}", package="unified_mcp.tools")
            server.add_tool(getattr(mod, module_name))
        except (ImportError, AttributeError) as e:
            print(f"WARNING: gagal load {module_name} - {e}")
```

Pendekatan ini memungkinkan **graceful degradation**: service yang tidak dikonfigurasi tidak akan muncul di daftar tools, menghindari error saat runtime.

## 2. Implementasi Detail Setiap Service

### 2.1 Firecrawl – Web Scraping & Crawling

Firecrawl menyediakan endpoint `scrape`, `search`, `crawl`, dan `extract`. Contoh implementasi:

```python
# tools/firecrawl.py

import os
import requests
from fastmcp import tool

@tool("firecrawl_search")
def firecrawl_search(query: str, limit: int = 5) -> list:
    """Cari konten web menggunakan Firecrawl."""
    api_key = os.environ["FIRECRAWL_API_KEY"]
    headers = {"Authorization": f"Bearer {api_key}"}
    params = {"q": query, "limit": limit}
    resp = requests.get("https://api.firecrawl.dev/v1/search", params=params, headers=headers, timeout=30)
    resp.raise_for_status()
    return resp.json()["results"]
```

**Troubleshooting Firecrawl**:
- **Error 401**: API key salah atau kadaluarsa. Verifikasi di panel Firecrawl.
- **Error 429**: Rate limit terlampaui. Tambahkan `time.sleep(1)` antar panggilan atau upgrade plan.
- **Timeout 30 detik**: Tidak cukup untuk crawl besar. Naikkan parameter `timeout` atau batasi depth.

### 2.2 Brave Search – Web & News

```python
# tools/brave_search.py

@tool("brave_web_search")
def brave_web_search(query: str, count: int = 10):
    api_key = os.environ["BRAVE_API_KEY"]
    url = "https://api.search.brave.com/res/v1/web/search"
    headers = {"X-Subscription-Token": api_key}
    params = {"q": query, "count": count}
    resp = requests.get(url, headers=headers, params=params, timeout=10)
    resp.raise_for_status()
    return resp.json()["web"]["results"]
```

**Perbedaan dengan Firecrawl**: Brave lebih fokus pada hasil pencarian langsung, sementara Firecrawl mendukung crawling halaman. Brave gratis hingga 2000 request/bulan.

### 2.3 Figma – Design Tokens

```python
# tools/figma.py

@tool("figma_get_file")
def figma_get_file(file_key: str) -> dict:
    token = os.environ["FIGMA_ACCESS_TOKEN"]
    headers = {"X-Figma-Token": token}
    resp = requests.get(f"https://api.figma.com/v1/files/{file_key}", headers=headers)
    resp.raise_for_status()
    return resp.json()  # document tree besar, perlu filter
```

Figma API mengembalikan full document tree. Untuk asisten AI, sebaiknya filter hanya komponen atau style yang dibutuhkan. Contoh:

```python
# tambahkan parameter nodes untuk ambil subtree tertentu
resp = requests.get(f"https://api.figma.com/v1/files/{file_key}/nodes?ids={node_id}", headers=headers)
```

### 2.4 E2B – Code Sandbox (Opsional)

E2B membutuhkan dependency `e2b` dan API key. Modul akan ter-skip jika keduanya tidak ada.

```python
# tools/code_sandbox.py (hanya jika e2b terinstall)

from e2b import Sandbox

@tool("code_execute")
def code_execute(code: str, language: str = "python") -> str:
    sb = Sandbox(api_key=os.environ["E2B_API_KEY"])
    result = sb.run_code(code, language=language)
    return result.text
```

**Catatan**: Sandbox terlindungi – kode berjalan di lingkungan terisolasi.

### 2.5 Composio – 250+ Integrasi

Composio menyediakan API untuk aplikasi seperti Slack, Google Sheets, dll. Implementasi:

```python
# tools/composio.py

@tool("composio_execute_action")
def composio_execute_action(app: str, action: str, params: dict) -> dict:
    api_key = os.environ["COMPOSIO_API_KEY"]
    url = f"https://backend.composio.dev/api/v1/actions/{app}/{action}/execute"
    headers = {"x-api-key": api_key, "Content-Type": "application/json"}
    resp = requests.post(url, json=params, headers=headers)
    return resp.json()
```

### 2.6 Vercel – Deployment Management

Tool ini memungkinkan deploy, list deployments, dan manage environment variables:

```python
# tools/vercel.py

@tool("vercel_list_deployments")
def vercel_list_deployments(project_id: str, limit: int = 10):
    token = os.environ["VERCEL_API_TOKEN"]
    headers = {"Authorization": f"Bearer {token}"}
    params = {"projectId": project_id, "limit": limit}
    resp = requests.get("https://api.vercel.com/v6/deployments", headers=headers, params=params)
    resp.raise_for_status()
    return resp.json()["deployments"]
```

**Troubleshooting**:
- **403 Forbidden**: Token tidak punya akses ke project. Scope token di Vercel dashboard.
- **404**: Project ID salah. Pastikan menggunakan `projectId` (bukan nama).

### 2.7 Linear – Issue Tracking

```python
# tools/linear.py

@tool("linear_create_issue")
def linear_create_issue(team_id: str, title: str, description: str = ""):
    api_key = os.environ["LINEAR_API_KEY"]
    headers = {"Authorization": api_key, "Content-Type": "application/json"}
    query = """
    mutation CreateIssue($teamId: String!, $title: String!, $desc: String) {
        issueCreate(input: {teamId: $teamId, title: $title, description: $desc}) {
            success issue { id }
        }
    }"""
    resp = requests.post("https://api.linear.app/graphql",
        json={"query": query, "variables": {"teamId": team_id, "title": title, "desc": description}},
        headers=headers)
    resp.raise_for_status()
    return resp.json()["data"]["issueCreate"]
```

### 2.8 Sentry – Error Monitoring

```python
# tools/sentry.py

@tool("sentry_list_issues")
def sentry_list_issues(organization: str, project: str):
    token = os.environ["SENTRY_AUTH_TOKEN"]
    headers = {"Authorization": f"Bearer {token}"}
    params = {"organization": organization, "project": project}
    resp = requests.get(f"https://sentry.io/api/0/projects/{organization}/{project}/issues/", headers=headers)
    return resp.json()
```

**Catatan**: Sentry membutuhkan dua env vars: `SENTRY_AUTH_TOKEN` dan `SENTRY_ORG`. Project name bisa diberikan sebagai parameter.

### 2.9 Playwright – Browser Automation (Lokal, Tanpa API Key)

Playwright berjalan di mesin lokal. Modul ini tidak perlu API key, hanya dependency `playwright`.

```python
# tools/playwright_browser.py

from playwright.sync_api import sync_playwright

@tool("browser_navigate")
def browser_navigate(url: str) -> str:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url, timeout=30000)
        title = page.title()
        content = page.content()[:2000]  # batasi besar
        browser.close()
    return f"Title: {title}\nContent snippet: {content}"

@tool("browser_screenshot")
def browser_screenshot(url: str, full_page: bool = True) -> bytes:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url)
        screenshot = page.screenshot(full_page=full_page)
        browser.close()
    return screenshot  # return bytes untuk dikirim sebagai file
```

**Troubleshooting**:
- **Browser tidak launch**: Pastikan `playwright install chromium` sudah dijalankan.
- **Timeout**: Periksa koneksi internet atau naikkan parameter timeout.
- **Memory penuh**: Screenshot full page halaman besar bisa menghabiskan RAM. Batasi dengan `full_page=False` atau crop.

### 2.10 Context7 – Dokumentasi Version-Accurate

Context7 memberikan dokumentasi library yang sesuai versi. Gratis tanpa API key.

```python
# tools/context7.py

@tool("context7_resolve_library")
def context7_resolve_library(name: str, version: str = "latest") -> dict:
    url = f"https://api.context7.com/v1/resolve?name={name}&version={version}"
    resp = requests.get(url, timeout=10)
    resp.raise_for_status()
    return resp.json()  # berisi link doc, deskripsi, dll

@tool("context7_query_docs")
def context7_query_docs(library: str, query: str) -> str:
    url = "https://api.context7.com/v1/query"
    resp = requests.post(url, json={"library": library, "query": query})
    return resp.json()["answer"]
```

**Kasus Penggunaan**: Cocok untuk AI yang perlu menjawab pertanyaan tentang API framework tertentu dengan dokumentasi yang tepat versi.

## 3. Konfigurasi Lingkungan

### 3.1 File `.env.example`

```
# .env.example
FIRECRAWL_API_KEY=
BRAVE_API_KEY=
FIGMA_ACCESS_TOKEN=
E2B_API_KEY=
COMPOSIO_API_KEY=
VERCEL_API_TOKEN=
LINEAR_API_KEY=
SENTRY_AUTH_TOKEN=
SENTRY_ORG=my-org-slug
```

Jika variabel tidak diisi, service terkait tidak diaktifkan.

### 3.2 Optional Dependencies

Untuk mengurangi ukuran instalasi, dependencies opsional dipisah ke extras di `pyproject.toml`:

```toml
[project.optional-dependencies]
web = ["requests", "firecrawl-py", "brave-search-py"]
browser = ["playwright"]
sandbox = ["e2b"]
all = ["unified-mcp-server[web,browser,sandbox]"]
```

Cara install:
```bash
pip install unified-mcp-server[web]      # Firecrawl + Brave
pip install unified-mcp-server[browser]   # Playwright
pip install unified-mcp-server[all]       # semua
```

## 4. Integrasi dengan Hermes

### 4.1 Konfigurasi Hermes

File `~/.hermes/config.yaml`:

```yaml
mcp_servers:
  unified-mcp:
    command: python
    args: ["-m", "unified_mcp"]
    enabled: true
    workdir: /home/user/unified-mcp-server
```

Argumen tambahan dapat ditambahkan untuk memilih transport:

```yaml
args: ["-m", "unified_mcp", "--transport", "sse", "--port", "8282"]
```

### 4.2 Testing Koneksi

```bash
hermes mcp test unified-mcp
```

Output diharapkan menampilkan daftar tools yang aktif. Contoh:

```
Tools active: 2
- browser_navigate
- context7_resolve_library
```

Jika jumlah tools sesuai harapan, server siap digunakan.

## 5. Troubleshooting Komprehensif

### 5.1 Service Tidak Muncul

**Penyebab**: API key tidak terdeteksi.

**Langkah**:
1. Pastikan file `.env` ada di `workdir` dan isinya benar.
2. Periksa ejaan variabel di `.env` dan `tools/__init__.py`.
3. Jalankan `python -c "import os; print('FIRECRAWL_API_KEY' in os.environ)"` dari `workdir`.
4. Load ulang konfigurasi Hermes: `hermes mcp restart unified-mcp`.

### 5.2 Error 401/403 saat Panggil Tool

**Penyebab**: API key tidak valid atau kadaluarsa.

**Solusi**: Generate ulang token dari dashboard masing-masing service. Untuk Sentry, pastikan token memiliki scope `org:read` dan `project:read`.

### 5.3 Dependency Tidak Terinstall

Jika tool membutuhkan ekstra dependencies, error `ModuleNotFoundError` akan muncul saat startup. Solusi: install extras seperti dijelaskan di bagian 3.2.

### 5.4 Playwright Runtime Error

- **"Executable doesn't exist"**: Jalankan `playwright install chromium`.
- **"Connection refused"**: Pastikan tidak ada firewall yang memblokir koneksi keluar.
- ** "Timeout "**: Halaman mungkin lambat. Ubah parameter `timeout` di kode.

### 5.5 Kinerja Lambat pada Banyak Tools

Setiap service melakukan inisialisasi sendiri. Untuk mengurangi overhead, implementasikan lazy loading:

```python
# tools/__init__.py – lazy decorator
def lazy_load(module_name):
    def decorator(func):
        def wrapper(*args, **kwargs):
            importlib.import_module(f".{module_name}", package="unified_mcp.tools")
            return func(*args, **kwargs)
        return wrapper
    return decorator
```

Namun untuk kesederhanaan, versi awal menggunakan eager import.

## 6. Skenario Penggunaan Nyata

### 6.1 AI Mencari Dokumentasi dan Menjalankan Browser

User bertanya: "Bagaimana cara deploy app ke Vercel dengan environment variable?"

Alur:
1. Context7 → cari dokumentasi Vercel.
2. Playwright → buka halaman dokumentasi.
3. Vercel tool → jalankan `add_env` di project.

```python
# pseudo sequence
docs = context7_resolve_library("vercel")
browser_navigate(docs["url"])
# AI baca halaman, lalu panggil vercel_add_env(project_id, key, value)
```

### 6.2 Debug Error dari Sentry

User: "Ada error 500 di production, apa yang terjadi?"

Alur:
1. Sentry list issues di project.
2. Ambil detail issue terbaru (screenshot via Playwright jika perlu).
3. Analisis AI dan berikan saran fix.

## 7. Catatan Arsitektural Lanjutan

### 7.1 Dynamic vs Static Registration

Pendekatan dynamic registration memungkinkan satu server melayani berbagai konfigurasi. Alternatif lain adalah static registration dengan file konfigurasi YAML, tetapi dynamic lebih mudah dipelihara karena konfigurasi tersentral di satu file `.env`.

### 7.2 Keamanan

- API key disimpan di file `.env` (tidak di code).
- Playwright berjalan di mesin lokal; pastikan akses hanya untuk user yang tepat.
- E2B sandbox menyediakan isolasi kode – aman untuk eksekusi tidak terpercaya.

### 7.3 Extensibility

Untuk menambah service baru:
1. Buat file `tools/new_service.py`.
2. Definisikan fungsi dengan dekorator `@tool`.
3. Tambahkan mapping di `TOOL_MODULES` dengan nama env var (None jika gratis).
4. Commit.

Tidak perlu mengubah arsitektur inti.

## 8. Referensi

- [Firecrawl — 10 Best MCP Servers](https://www.firecrawl.dev/blog/best-mcp-servers-for-developers)
- [FastMCP Python SDK](https://github.com/jlowin/fastmcp)
- [MCP Protocol Spec](https://modelcontextprotocol.io/)
- [[cloudflare-ruleset-engine-phases]] — inspirasi arsitektur modular
- [Playwright Python](https://playwright.dev/python/)
- [Context7](https://context7.com)

---

**Kesimpulan**: Unified MCP Server adalah solusi ringkas untuk menggabungkan banyak tools AI dalam satu proses. Dengan dynamic registration dan konfigurasi berbasis env, server ini siap digunakan tanpa setup rumit. Kode sumber terbuka dan dapat diperluas sesuai kebutuhan.