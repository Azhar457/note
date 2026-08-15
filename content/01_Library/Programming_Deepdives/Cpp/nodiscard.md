---
title: Nodiscard (C++ [[nodiscard]])
tags: [programming, cpp, best-practice]
aliases: [nodiscard, cpp-nodiscard]
---
# C++ `[[nodiscard]]` — Praktik & Detail

`[[nodiscard]]` (C++17, diperluas C++20/23) memberi tahu compiler bahwa nilai return fungsi/tipe TIDAK BOLEH diabaikan. Jika hasil dibuang, compiler memunculkan warning (bukan error — tapi banyak tim treat warning as error) — menangkap bug kelas "saya lupa cek hasil".

## Dasar Penggunaan

```cpp
// Fungsi — hasil wajib dipakai
[[nodiscard]] int compute_checksum(const std::string& data);

// Tipe — semua fungsi yang return tipe ini
struct [[nodiscard]] Error { int code; std::string msg; };
Error open_file(const char* path);  // return Error dibuang = warning

// C++20: alasan (support compiler baru)
[[nodiscard("panggil free() pada resource")]] int alloc_handle();

// C++23: kondisi (evaluated only jika condition)
[[nodiscard(uses_non_default_allocator(allocator_type))]]
```

## Kata Kunci Sebelumnya (C++11/14: `__attribute__((warn_unused_result))` / `[[gnu::warn_unused_result]]`)

```cpp
// GNU/Clang — sebelum standard attribute
__attribute__((warn_unused_result)) int read(void*, size_t);
// MSVC — _Check_return_
_Check_return_ int send_data(...);
```
`[[nodiscard]]` adalah bentuk portabel; compiler tua butuh extension.

## Kapan Memakai

1. **Error-handling returns** — bool/Error/expected yang harus dicek: `bool try_lock()`, `Error validate()`.
2. **Resource-returning functions** — `FILE* fopen(..)`? (stdlib tidak ber-attribute — wrapper sendiri), handle/pointer yang harus di-free.
3. **Purely correct-by-construction** — hasil kalkulasi yang tidak boleh hilang: `std::unique_ptr` move (sudah), `std::string::find` (return pos).
4. **API design** — kontrak publik: "pemanggil wajib memakai hasil".
5. **move-only types** — sudah implied.

## Yang TIDAK Perlu

- Getter murni yang sering dipanggil tanpa hasil (mis. `is_empty()` sebagai pengecekan implisit di kondisi? — tetap cek).
- Fungsi yang dipanggil untuk side effect dan return sukses — justru harus nodiscard (hasilnya penting).
- API internal dengan hasil opsional — pertimbangkan `[[maybe_unused]]` untuk kasus sah membuang hasil.

## Interaksi dengan Standar Library

Stdlib modern banyak ber-`[[nodiscard]]`:
- `std::vector::empty()`, `std::string::empty()` — C++20 menambahkan nodiscard ke banyak query.
- `std::async` — hasil (future) wajib dipakai (kalau tidak: fire-and-forget? — future destructor block).
- `std::optional::value()` — throw jika kosong — hasil wajib.
- `std::unique_ptr::release()` — wajib dipakai (kalau tidak: leak).
- `std::lock_guard` — konstruksi via RAII bukan masalah.

**Bug class terkenal**: `if (vec.empty()); { ... }` — semicolon setelah kondisi; nodiscard tidak tangkap (hasil dipakai di kondisi) — tetap butuh review.

## Praktik di Tim

1. **Treat warnings as errors** di CI: `-Werror` (+ `-Wunused-result`) — nodiscard warning jadi error.
2. **Convention**: semua fungsi yang return error/bool-wajib-cek diberi `[[nodiscard]]` di header publik.
3. **RAII+Result pattern**: kembalikan `std::expected<T, E>` (C++23) yang inherently nodiscard-ish.
4. **Avoid silent ignore**: jangan casting `(void)result` tanpa komentar alasan.
5. **Code review rule**: jika ada `[[nodiscard]]` di overload baru — pastikan return-nya memang tidak bisa diabaikan.

## Contoh Nyata (Error Handling)

```cpp
// Sebelum: error diam-diam hilang
bool write_config(const std::string& path, const Config& c);
// write_config("/etc/app.conf", cfg);  // gagal? tidak tahu!

// Sesudah: compiler warning
[[nodiscard]] bool write_config(const std::string& path, const Config& c);
// write_config(...);  // warning: ignoring return value
```

```cpp
// Pattern expected (C++23)
#include <expected>
[[nodiscard]] std::expected<int, std::error_code> parse_int(std::string_view s);
auto r = parse_int("42");
if (!r) { /* handle */ }   // wajib — kalau dibuang: warning
```

## Compiler Flags & Versi

| Compiler | Flag penting | Dukungan |
|----------|--------------|----------|
| GCC | `-Wunused-result` (aktif di -Wall), `-Werror` | C++17 penuh, reason C++20 |
| Clang | sama, `-Wunused-result` | penuh |
| MSVC | `/W4` + `C4834` (warning) | penuh |
| C++17 | attribute dasar + type-level | semua GPU? — modern ok |

`[[nodiscard("msg")]]` (C++20) memberi pesan kontekstual — sangat membantu di codebase besar (alasan kenapa wajib dipakai).

## Kaitan dengan Keamanan (Kenapa Penting di Vault Ini)

- **Crypto**: fungsi verify/sign return bool — abaikan = vuln (signature never verified). `[[nodiscard]] bool verify_signature(...)` mencegah.
- **File I/O**: write gagal diabaikan = data korup/kehilangan.
- **Memory**: allocator hasil dibuang = leak.
- **Network**: send/bind gagal diabaikan = masalah produksi.
- Dalam audit codebase: cari fungsi penting yang return dibuang tanpa cek (grep pattern `(void)` cast atau pemanggilan di statement) — potensi bug.

## Checklist

- [ ] Semua fungsi return-bool/Error diberi `[[nodiscard]]`.
- [ ] `-Werror` aktif sehingga warning memblokir CI.
- [ ] `(void)result` hanya dengan komentar alasan.
- [ ] Audit: tidak ada panggilan kritis (crypto, I/O) yang dibuang hasilnya.
- [ ] Tim paham konvensi (dokumentasi singkat di CONTRIBUTING).



## Interaksi dengan [[maybe_unused]] & Casting

```cpp
// Kasus sah membuang hasil: fungsi dipanggil untuk side-effect,
// hasil hanya info.
[[nodiscard]] int notify_admin(const std::string& msg);
// panggil di fire-and-forget path:
[[maybe_unused]] auto r = notify_admin("disk 90%");  // sengaja
// atau cast eksplisit:
(void)notify_admin("disk 90%");  // dokumentasikan alasan!
```

## Macro Portability (Codebase Multi-Compiler)

```cpp
// C++17 ke bawah / MSVC lama
#if defined(__has_cpp_attribute) && __has_cpp_attribute(nodiscard)
#  define NODISCARD [[nodiscard]]
#elif defined(_MSC_VER)
#  define NODISCARD _Check_return_
#else
#  define NODISCARD __attribute__((warn_unused_result))
#endif
```
Pakai `NODISCARD` di seluruh codebase — konsisten.

## Case Study: Crypto Library

```cpp
// OpenSSL-style C API dipakai dari C++:
// EVP_DigestVerifyFinal() return 1 = sukses
// kalau hasil dibuang → signature tidak pernah diverifikasi
NODISCARD bool verify_hmac(const unsigned char* key, size_t klen,
                           const unsigned char* data, size_t dlen);
```
Tanpa nodiscard: `verify_hmac(...);` — kompiler diam, attacker senang.
Dengan nodiscard: warning → CI error → bug ditangkap sebelum produksi.

## Tools & Detection

- `grep -n "([^)]*);" src/ | grep -v "="` — heuristik cari pemanggilan statement (return dibuang).
- clang-tidy: `bugprone-unused-return-value` — deteksi pemanggilan yang mengabaikan return (termasuk stdlib).
- Compiler `-Wunused-result` — aktif di -Wall untuk fungsi berattribute.

## FAQ

**Q: nodiscard mencegah bug?** — mencegah kelas "lupa cek"; bukan semua bug (semicolon, logic error tetap perlu review).
**Q: Bisakah dihapus saat release?** — TIDAK — ini kontrak API, bukan debug aid.
**Q: Node performance?** — zero runtime cost (compile-time only).
**Q: Berlaku untuk konstruktor?** — [[nodiscard]] pada constructor type-level (struct) berlaku untuk fungsi yang return type itu; constructor return objek — berlaku juga (C++20).

---

  audited
---