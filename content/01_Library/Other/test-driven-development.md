---
title: Test Driven Development
tags: [atlas, tdd, testing]
aliases: [test-driven-development]
---
# Test Driven Development (TDD)

TDD adalah siklus RED-GREEN-REFACTOR: (1) tulis test yang gagal (RED) — spesifikasi perilaku yang diinginkan; (2) buat implementasi minimal agar test lolos (GREEN); (3) refactor bersih tanpa mengubah perilaku (test tetap hijau). Manfaat: desain terdorong dari usage (API testable), regression safety net, dokumentasi perilaku langsung.

Praktik: unit test fokus (satu perilaku per test), jangan test implementation detail, gunakan AAA (Arrange-Act-Assert). Tools per bahasa: Jest/Vitest (JS), pytest (Python), go test (Go), JUnit (Java). Dalam konteks keamanan: TDD untuk parser/payload validation — tulis test dulu untuk boundary cases (null bytes, unicode, overflow).
---

  audited
---