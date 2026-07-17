---
title: "Kernel Forensics — Memory Analysis of Compromised Systems"
tags:
  - forensics
  - kernel
  - memory-analysis
  - volatility
  - rootkit
aliases:
  - "kernel-forensics"
created: "2026-07-19"
updated: "2026-07-19"
status: seedling
---

> Analisis memory kernel untuk deteksi rootkit dan kernel-mode malware.

## Analysis Techniques

- System call table hooking detection
- IDT/GDT integrity checking
- Hidden processes detection (DKOM)
- Driver/module enumeration
- SSDT hook scanning (Windows)
- Kernel memory pool analysis

## Tools

| Tool         | Purpose                            |
| ------------ | ---------------------------------- |
| Volatility 3 | Linux/Windows/Mac memory forensics |
| LiME         | Linux memory acquisition           |
| FTK Imager   | Memory acquisition                 |
| WinDbg       | Windows kernel debugging           |
