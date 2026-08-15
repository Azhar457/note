---
title: 'Desktop Application Security — Deep Dive: Electron Security, Win32 Reverse
  Engineering, .NET Analysis, Binary Patching'
tags:
- desktop-security
- electron
- win32
- reverse-engineering
- binary-analysis
- dotnet
created: '2026-07-18'
updated: '2026-07-18'
status: pending
cssclasses:
  - wide-table
  - callout

---

# 🖥️ Desktop Application Security — Deep Dive: Electron Security, Win32 Reverse Engineering, .NET Analysis, Binary Patching

> Panduan komprehensif keamanan aplikasi desktop — dari Electron app (asar unpack, Node.js integration, contextIsolation, IPC security) sampai Win32 native (PE analysis, API hooking, DLL injection, process injection, anti-debug bypass). Mencakup Electron security model (Chromium sandbox, contextIsolation, preload scripts, nodeIntegration), .NET reverse engineering (dnSpy, de4dot, obfuscation bypass), Win32 reversing (x64dbg, IDA, Ghidra, ScyllaHide), binary patching & cracking, dan desktop-specific attack surface (local file access, named pipes, COM objects, registry). Vault udah punya [[browser-security-exploitation-deepdive]] (browser web) dan [[web-hacking-exploitation]] (web app) — catatan ini melengkapi dari sisi **desktop native app**.

> [!info] Posisi di Vault
> Catatan ini melengkapi [[browser-security-exploitation-deepdive]] (browser — Electron pake Chromium), [[web-hacking-exploitation]] (web app — sebagian Electron app adalah web app dalam shell native), [[malware-analysis-reverse-engineering-playbook]] (malware RE — tekniknya overlap), [[exploit-development]] (Win32 exploit — buffer overflow di desktop app), [[hardware-hacking-re]] (firmware RE — teknik reversing berbeda), dan [[endpoint-detection-playbook]] (detection — desktop app adalah endpoint utama).

---

## Daftar Isi

- [[#Electron Security Model]]
- [[#Electron Pentesting]]
- [[#Win32 Reverse Engineering]]
- [[#.NET Application Analysis]]
- [[#Binary Patching]]
- [[#Anti-Debug & Anti-Tamper]]
- [[#Desktop Attack Surface]]
- [[#Toolchain]]
- [[#Koneksi ke Vault]]

---

## Electron Security Model

### Arsitektur Electron
```
┌────────────────────────────────────────┐
│              Main Process              │ ← Node.js, system access
│   (BrowserWindow, IPC, Menu, Tray)    │
└──────────┬─────────────────────────────┘
           │ IPC (send, on, invoke, handle)
           │
┌──────────▼─────────────────────────────┐
│           Renderer Process             │ ← Chromium, web content
│   (HTML, CSS, JS — isolated from OS)  │
│   preload.js → bridge (contextBridge)  │
└────────────────────────────────────────┘

┌────────────────────────────────────────┐
│          Utility Process               │ ← Node.js child process
│   (GPU, Network, Audio, etc)          │
└────────────────────────────────────────┘
```

### Security Best Practices (Electron Security Checklist)

#### Wajib (Non-negotiable)
```javascript
// ✅ AMAN — recommended for production
new BrowserWindow({
    webPreferences: {
        nodeIntegration: false,        // ❌ JANGAN true — renderer bisa require('child_process')
        contextIsolation: true,        // ✅ WAJIB — renderer isolated dari preload
        sandbox: true,                 // ✅ WAJIB — Chromium sandbox
        enableRemoteModule: false,     // ❌ JANGAN true — remote module RCE
        preload: path.join(__dirname, 'preload.js')  // ✅ preload = bridge
    }
});
```

#### ❌ Common Insecure Patterns
```javascript
// ❌ RCE via nodeIntegration
new BrowserWindow({ webPreferences: { nodeIntegration: true } })
// → renderer bisa: require('child_process').exec('rm -rf /')

// ❌ RCE via contextBridge yang salah
contextBridge.exposeInMainWorld('api', {
    exec: (cmd) => require('child_process').exec(cmd)
    // → renderer: window.api.exec('malicious command')
});

// ❌ Shell.openExternal tanpa validasi
shell.openExternal(userInput)  // → bisa diarahkan ke file:// atau protocol berbahaya

// ❌ webview tag tanpa restriction
<webview src="http://evil.com"></webview>  // → XSS di webview → RCE via IPC?
```

#### Secure IPC Pattern
```javascript
// ✅ preload.js — bridge minimal
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('appAPI', {
    getData: () => ipcRenderer.invoke('get-data'),
    saveFile: (data) => ipcRenderer.invoke('save-file', data)
    // JANGAN expose: exec, shell, fs, net
});

// ✅ main.js — validasi input dari renderer
ipcMain.handle('save-file', async (event, data) => {
    if (typeof data !== 'string') throw new Error('Invalid input');
    // Validasi path — prevent path traversal
    const safePath = path.resolve(baseDir, path.basename(data.filename));
    if (!safePath.startsWith(baseDir)) throw new Error('Path traversal detected');
});
```

## Electron Pentesting

### 1. ASAR Extraction
```bash
# Electron app = ASAR archive
npx asar extract app.asar extracted/
# Hasil: HTML, JS, CSS, Node modules

# Atau langsung
electron app.asar  # run tanpa extract
asar list app.asar  # list files in archive
```

### 2. Static Analysis
```bash
# Cari hardcoded API key, endpoint, secret
grep -r "api_key\|secret\|token" extracted/
grep -r "http:" extracted/  # HTTP non-HTTPS -> MITM
grep -r "nodeIntegration\|contextIsolation\|sandbox" extracted/

# Cek package.json — dependency dengan CVE
cat extracted/package.json | jq '.dependencies'
```

### 3. Runtime Analysis
```bash
# Open DevTools di Electron app
# Method 1: --auto-open-devtools-for-tabs
electron app.asar --auto-open-devtools-for-tabs

# Method 2: inject via preload + environment
# Method 3: Open console.log — lihat semua output

# Network interception
mitmproxy -p 8080  # Proxy
# Electron: set http_proxy=http://127.0.0.1:8080
```

### 4. Electron Attacks

| Attack | Prerequisite | Impact |
|--------|-------------|--------|
| **RCE via nodeIntegration** | nodeIntegration=true | Full system access |
| **RCE via IPC** | Vulnerable IPC handler | System command execution |
| **XSS -> RCE** | XSS + insecure IPC bridge | Remote code execution |
| **Context Isolation bypass** | contextIsolation=false + XSS | Access Node.js API |
| **ASAR integrity bypass** | Unsigned update | Malicious update injection |
| **Protocol handler hijack** | Custom protocol (myapp://) | Open app with malicious params |
| **DevTools persistence** | DevTools enabled in production | Debug access |

## Win32 Reverse Engineering

### PE (Portable Executable) Structure
```
┌─────────────────┐
│     DOS Header  │ ← "MZ" magic
├─────────────────┤
│   NT Headers    │ ← PE signature, COFF header, Optional header
├─────────────────┤
│  Section Table  │ ← .text, .data, .rdata, .reloc, .rsrc
├─────────────────┤
│  Section .text  │ ← Executable code
│  Section .data  │ ← Global/static variables
│  Section .rdata │ ← Read-only data (imports, strings)
│  Section .rsrc  │ ← Resources (icons, version, manifest)
└─────────────────┘
```

### Reverse Engineering Workflow

```bash
# 1. Information gathering
file target.exe
exiftool target.exe
strings target.exe | grep -i "http\|api\|secret\|key"

# 2. Static analysis (IDA/Ghidra/x64dbg)
# IDA: decompile to pseudo-C
# Ghidra: open source alternative
# Detect: packed? UPX/MPRESS/VMProtect?

# 3. Unpack if packed
upx -d target.exe -o target_unpacked.exe

# 4. Dynamic analysis (x64dbg)
# Set breakpoints
# API monitoring (API Monitor, Procmon)
# Trace execution

# 5. Import/Export analysis
dumpbin /imports target.exe
# API calls → determine app behavior
```

### Win32 Key APIs for Security Analysis

| API | Function | Use in Analysis |
|-----|----------|-----------------|
| `CreateFile` | File open | Cari file config, log, database |
| `RegOpenKeyEx` | Registry access | Cek registry persistence, config |
| `InternetOpen` | HTTP request | Network communication analysis |
| `CreateProcess` | Process creation | Deteksi child process, inject |
| `VirtualAllocEx` | Remote memory alloc | Code injection detection |
| `SetWindowsHookEx` | Keyboard/mouse hook | Keylogger detection |
| `CryptDecrypt` | Decryption | Cari decryption routine |
| `IsDebuggerPresent` | Anti-debug | Bypass anti-debug |
| `OutputDebugString` | Debug output | Debug message analysis |

### Anti-Debug Bypass

| Anti-Debug Technique | Bypass |
|---------------------|--------|
| `IsDebuggerPresent()` | Patch return value (0) |
| `NtQueryInformationProcess(ProcessDebugPort)` | ScyllaHide, TitanHide |
| `NtSetInformationThread(HideThreadFromDebugger)` | x64dbg + ScyllaHide plugin |
| `TLS Callbacks` | Set breakpoint BEFORE entry point |
| `Timing checks (rdtsc)` | Patch timing check or use VM |
| `INT3 / CC breakpoint detection` | Hardware breakpoint (DR0-DR3) |
| `PEB BeingDebugged` | ScyllaHide forces PEB->BeingDebugged=0 |

## .NET Application Analysis

### .NET vs Native
```
Native (C++):   .text → x86/x64 machine code → IDA/Ghidra
.NET (C#/VB):   .text → MSIL (CIL) → dnSpy/de4dot → C# source
```

### .NET Reversing Tools

| Tool | Fungsi | Harga |
|------|--------|-------|
| **dnSpy** | .NET debugger + decompiler | Free |
| **de4dot** | .NET obfuscation remover | Free |
| **ILSpy** | .NET decompiler | Free |
| **ConfuserEx** | .NET obfuscator (analisis) | Free |
| **DotPeek** | .NET decompiler (JetBrains) | Free |

### .NET Security Issues

| Issue | Source | Impact |
|-------|--------|--------|
| **Hardcoded connection string** | app.config / App.config | Database access leak |
| **Unprotected license check** | if-then-else in MSIL | Easy to patch (nop) |
| **Serialization vulnerability** | BinaryFormatter | RCE via deserialization |
| **Weak obfuscation** | ConfuserEx, Obfuscar | Reversible with de4dot |
| **Embedded resources** | .resources files | Secret extraction |
| **String encryption** | Custom XOR/Base64 | Reverse decryption function |

### .NET Deobfuscation
```bash
# 1. Detect obfuscator → de4dot auto-detect
de4dot target.exe -o target_cleaned.exe

# 2. Open in dnSpy
dnspy target_cleaned.exe

# 3. Set breakpoint, analyze, patch
# Right-click → Edit Method → Save Module
```

## Binary Patching

### Types of Patch
| Patch Type | Tool | Use Case |
|-----------|------|----------|
| **NOP patch** | x64dbg, HxD | Disable check (jump → NOP) |
| **JMP patch** | x64dbg, IDA | Redirect execution flow |
| **Hex edit** | HxD, 010 Editor | Change constant, string |
| **DLL proxy** | Custom DLL | Hook API calls |
| **Memory patch** | Cheat Engine | Runtime modification |
| **IL patch (dnSpy)** | dnSpy | .NET method body edit |

### Example: Bypass License Check
```
Original:  je 0x4010A0    (jump jika license valid → success)
Patch:     jmp 0x4010A0   (always jump → always success)
Atau:      nop; nop        (disable jump entirely)
```

## Desktop Attack Surface

| Surface | Teknik | Impact |
|---------|--------|--------|
| **Local file access** | Path traversal, symlink | Read/write arbitrary files |
| **Named pipes** | Pipe impersonation | Privilege escalation |
| **COM objects** | COM hijacking | Persistence, privilege escalation |
| **Registry** | Registry modification | Persistence, config manipulation |
| **DLL hijacking** | Missing DLL in PATH | Arbitrary code execution |
| **DLL injection** | CreateRemoteThread + LoadLibrary | Code execution in target process |
| **Process hollowing** | Replace process memory | Stealth execution |
| **DLL sideloading** | Legitimate EXE loads malicious DLL | Bypass app whitelist |
| **Local privilege escalation** | Named pipe, token manipulation | SYSTEM access |
| **Clipboard monitoring** | SetClipboardViewer | Password theft |

## Toolchain

| Tool | Platform | Fungsi | Harga |
|------|----------|--------|-------|
| **Electron** (asar, elect) | Cross | ASAR analysis | Free |
| **x64dbg** | Windows | Debugger (32/64 bit) | Free |
| **IDA Pro** | Windows | Disassembler + decompiler | $$$ |
| **Ghidra** | Cross | Open source reverse engineering | Free |
| **dnSpy** | Windows | .NET debugger + decompiler | Free |
| **de4dot** | Cross | .NET deobfuscator | Free |
| **HxD** | Windows | Hex editor | Free |
| **010 Editor** | Cross | Hex editor + templates | $ |
| **Process Monitor** | Windows | File, registry, process monitoring | Free |
| **API Monitor** | Windows | API call monitoring | Free |
| **ScyllaHide** | Windows | Anti-anti-debug plugin | Free |
| **Cheat Engine** | Windows | Memory scanning + patching | Free |
| **PeStudio** | Windows | PE analysis | Free |
| **Detect It Easy (DiE)** | Cross | Packer/compiler detection | Free |

---

## Koneksi ke Vault

- [[browser-security-exploitation-deepdive]] — Browser security — Electron pake Chromium
- [[web-hacking-exploitation]] — Web app — Electron app adalah web app dalam shell native
- [[malware-analysis-reverse-engineering-playbook]] — Malware reverse engineering — teknik RE overlap dengan desktop app reversing
- [[exploit-development]] — Win32 exploit development — buffer overflow, ROP di desktop app
- [[hardware-hacking-re]] — Firmware reverse engineering — teknik reversing berbeda (beda target)
- [[endpoint-detection-playbook]] — Endpoint detection — desktop app adalah endpoint utama
- [[side-channel-analysis]] — Side channel — bisa diterapkan di desktop app (timing, power)
- [[fuzzing-vulnerability-research]] — Fuzzing — fuzzing desktop app binary
---

audited
---
