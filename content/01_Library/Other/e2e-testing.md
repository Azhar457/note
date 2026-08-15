---
title: E2E Testing
tags: [atlas, testing, e2e]
aliases: [e2e-testing]
---
# End-to-End (E2E) Testing

E2E testing memverifikasi seluruh alur aplikasi dari UI sampai backend/database — beda dengan unit/integration yang menguji komponen. Alat populer: Playwright (recommended — auto-wait, multi-browser, trace viewer), Cypress (mudah, tapi terbatas di node context), Selenium (legacy).

Praktik: (1) pilih user journey kritis (login, checkout, search, error paths); (2) test data terisolasi (bukan prod); (3) stabilkan selector — data-testid, bukan CSS class rapuh; (4) parallel execution di CI; (5) visual regression (snapshot) untuk UI; (6) trace & video untuk debug gagal; (7) jangan E2E untuk semua — 10-20% dari test pyramid (unit 70%, integration 20%, E2E 10%). Dalam red-team: E2E framework bisa disalahgunakan untuk automation attack (login brute, form abuse).
---

  audited
---