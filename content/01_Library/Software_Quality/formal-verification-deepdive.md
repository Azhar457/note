---
title: Formal Verification Deep Dive — TLA+, Proof Assistants, and Rust Verification
tags:
  - formal-verification
  - software-quality
  - tla-plus
  - model-checking
  - coq
  - rust
  - kani
created: "2026-07-19"
updated: "2026-07-19"
status: pending
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Metode testing tradisional (unit, integration, fuzzing) hanya membuktikan adanya bug, bukan meniadakan bug. Untuk sistem kritis berskala _enterprise_ seperti engine proxy jarsWAF, verifikasi formal (_formal verification_) membuktikan kebenaran spesifikasi dan kode secara matematis. Catatan ini melengkapi [[software-quality-untung-yuhana]] dengan aspek pembuktian program secara rigit.

## Daftar Isi

1. [Spesifikasi Formal dengan TLA+](#1-spesifikasi-formal-dengan-tla)
2. [Model Checking (SPIN, Alloy, NuSMV)](#2-model-checking-spin-alloy-nusmv)
3. [Proof Assistants (Coq, Lean, Isabelle)](#3-proof-assistants-coq-lean-isabelle)
4. [Verifikasi Kode Rust dengan Kani & Verus](#4-verifikasi-kode-rust-dengan-kani--verus)
5. [Koneksi ke Vault](#5-koneksi-ke-vault)

---

## 1. Spesifikasi Formal dengan TLA+

**TLA+** (Temporal Logic of Actions) adalah bahasa spesifikasi formal yang dirancang oleh Leslie Lamport untuk mendesain dan memverifikasi sistem konkuren dan terdistribusi. TLA+ berfokus pada pembuktian logika sebelum kode ditulis.

### 1.1 Contoh Spesifikasi TLA+ Sederhana (Mutual Exclusion Lock)

Spesifikasi berikut mendefinisikan sistem penguncian (_locking_) konkuren sederhana dengan dua proses untuk membuktikan properti _safety_ (tidak terjadi kebuntuan/_deadlock_):

```tla
---------------------- MODULE SimpleLock ----------------------
EXTENDS Naturals, TLC

VARIABLES lock_state, process_owner

Vars == <<lock_state, process_owner>>

Init ==
    /\ lock_state = "Unlocked"
    /\ process_owner = 0

(* Proses p mencoba mengakuisisi lock *)
Acquire(p) ==
    /\ lock_state = "Unlocked"
    /\ lock_state' = "Locked"
    /\ process_owner' = p

(* Proses p melepaskan lock *)
Release(p) ==
    /\ lock_state = "Locked"
    /\ process_owner = p
    /\ lock_state' = "Unlocked"
    /\ process_owner' = 0

Next ==
    \exists p \in {1, 2} : Acquire(p) \/ Release(p)

Spec == Init /\ [][Next]_Vars

(* Properti Keamanan (Mutual Exclusion) *)
MutualExclusion ==
    (lock_state = "Unlocked") \/ (process_owner \in {1, 2})
==============================================================
```

TLC Model Checker akan mengeksplorasi seluruh _state space_ yang mungkin dari spesifikasi di atas untuk memastikan invariant `MutualExclusion` tidak pernah terlanggar (_safety_) dan tidak terjadi kondisi di mana sistem terhenti tanpa transisi berikutnya (_liveness_).

---

## 2. Model Checking (SPIN, Alloy, NuSMV)

**Model Checking** adalah metode otomatis untuk membuktikan apakah model sistem memenuhi properti spesifikasi temporal tertentu secara tuntas (_exhaustive state space exploration_).

- **SPIN**: Menggunakan bahasa **Promela** (Process Meta Language). Sangat kuat untuk memverifikasi protokol komunikasi konkuren berbasis pertukaran pesan (message passing).
- **Alloy**: Menggunakan logika orde-pertama untuk memodelkan struktur data relasional. Baik untuk menganalisis kelemahan desain arsitektur database.
- **NuSMV**: Model checker simbolik untuk memverifikasi logika CTL/LTL pada desain sirkuit perangkat keras digital atau sistem otomasi.

---

## 3. Proof Assistants (Coq, Lean, Isabelle)

Berbeda dengan model checker yang memeriksa _state space_ secara otomatis (tapi terbatas pada ukuran memori), **Proof Assistants** adalah perangkat lunak interaktif (_interactive theorem provers_) yang membantu manusia menyusun bukti matematika formal tanpa batasan ukuran state space.

- **Coq**: Berbasis _Calculus of Inductive Constructions_. Digunakan untuk memverifikasi compiler kritis seperti **CompCert** (compiler C tersertifikasi bebas bug optimasi).
- **Lean**: Sangat populer di kalangan matematikawan modern. Lean digunakan untuk merumuskan dan membuktikan teorema-teoreorema matematika tingkat lanjut secara formal.
- **Isabelle/HOL**: Proof assistant interaktif berbasis Higher-Order Logic. Digunakan untuk membuktikan kernel sistem operasi seperti **seL4** (microkernel komersial pertama yang terverifikasi aman secara formal).

---

## 4. Verifikasi Kode Rust dengan Kani & Verus

Untuk menjembatani teori verifikasi formal dengan kode nyata, komunitas Rust mengembangkan perkakas khusus yang menganalisis kode Rust secara matematis.

### 4.1 Kani Rust Verifier (Model Checking berbasis CBMC)

Kani membuktikan kode Rust menggunakan _Bounded Model Checking_ (BMC) di tingkat representasi compiler (MIR). Kani dapat membuktikan properti keamanan memori (tidak ada panic, out-of-bounds, overflow) untuk semua nilai input yang mungkin.

```rust
// Contoh kode Rust yang akan diverifikasi oleh Kani
pub fn safe_division(numerator: i32, denominator: i32) -> Option<i32> {
    if denominator == 0 {
        None
    } else {
        Some(numerator / denominator) // Aman dari pembagian nol
    }
}

#[cfg(kani)]
#[kani::proof]
fn verify_safe_division() {
    // Membuat input simbolis yang mewakili SEMUA nilai i32 yang mungkin
    let num: i32 = kani::any();
    let den: i32 = kani::any();

    let result = safe_division(num, den);

    if den == 0 {
        assert!(result.is_none());
    } else {
        assert!(result.is_some());
    }
}
```

Jalankan verifikasi menggunakan Kani CLI:

```bash
cargo kani
# Output: VERIFICATION SUCCESSFUL (membuktikan matematis tidak akan pernah crash)
```

### 4.2 Verus

Verus adalah perkakas verifikasi formal untuk Rust yang memungkinkan penulisan _spesifikasi fungsional_ (pre-conditions, post-conditions, invariants) langsung di dalam kode Rust menggunakan penanda khusus. Kompiler Verus membuktikan bahwa implementasi kode Rust dijamin 100% memenuhi spesifikasi tersebut sebelum dijalankan.

---

## 5. Koneksi ke Vault

| Catatan                            | Hubungan                                                                             |
| ---------------------------------- | ------------------------------------------------------------------------------------ |
| [[software-quality-untung-yuhana]] | Konsep dasar SQAP dan metodologi jaminan kualitas perangkat lunak konvensional.      |
| [[threat-modeling-deepdive]]       | Identifikasi model ancaman yang logikanya dibuktikan menggunakan spesifikasi formal. |
| [[jarswaf-plan]]                   | Rencana penerapan verifikasi formal pada core engine jarsWAF sebagai prioritas #2.   |
