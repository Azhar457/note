---
title: Bonus Books – Refactoring Legacy Code, YDKJS & Knuth
tags:
- library
- software-engineering
created: '2026-07-05'
updated: '2026-07-05'
status: pending
---

# 📚 Bonus Books Overview

| Book | Why It Belongs in This Vault | Core Theme |
|------|-----------------------------|------------|
| **Working Effectively with Legacy Code** (Michael Feathers) | Practical tactics for safely changing untested codebases. | *Add characterization tests; break dependencies; use seams.* |
| **You Don't Know JS** (Kyle Simpson) | Deep dive into JavaScript’s often misunderstood mechanisms. | *Scope, closures, async (Promises, Generators), this binding.* |
| **The Art of Computer Programming** (Donald Knuth) | Classical algorithmic foundations & problem‑solving mindset. | *Algorithmic thinking, rigor, mathematical proof of correctness.* |

### 1️⃣ Working Effectively with Legacy Code – Michael Feathers

#### 🎯 Thesis
> Anda dapat **mengubah kode dengan aman** yang tidak memiliki tes atau dokumentasi dengan **mengisolasi perubahan** dan **menambahkan verifikasi** sebelum menyentuh logika asli.

#### 🔑 Key Takeaways
- **Konsep seam** – sebuah seam adalah tempat di mana perilaku dapat diubah tanpa memecahkan perilaku yang ada.  
- **Tambahkan tes** – tulis tes karakterisasi yang menangkap perilaku saat ini sebelum melakukan refactoring.  
- **Pecahkan ketergantungan** – gunakan kelas wrapper, injeksi ketergantungan, atau pola adapter untuk memperkenalkan seam.  
- **Polah Strangler Fig** – ganti secara bertahap modul legacy dengan implementasi baru yang sudah diuji.

#### 📋 Daftar Periksa yang Dapat Diambil Tindakan
- [ ] Tulis **tes karakterisasi** untuk fungsi yang berisiko (jalankan, tangkap output, komit).  
- [ ] Identifikasi **seam** di dalam metode (titik masuk, parameter yang dapat dikonfigurasi, callback).  
- [ ] Tambahkan **wrapper** atau **antarmuka** untuk memperkenalkan sebuah seam.  
- [ ] Lakukan refactoring kode asli *setelah* tes telah berjalan dengan sukses.  
- [ ] Jalankan suite tes penuh (atau lari kecil untuk memastikan tidak ada yang rusak).

### Contoh Implementasi
```javascript
// tes karakterisasi untuk fungsi yang berisiko
describe('fungsi yang berisiko', () => {
  it('menangkap perilaku saat ini', () => {
    const hasil = fungsiYangBerisiko();
    expect(hasil).toEqual('hasil yang diharapkan');
  });
});

// menambahkan wrapper untuk memperkenalkan sebuah seam
class WrapperFungsiYangBerisiko {
  constructor(fungsiYangBerisiko) {
    this.fungsiYangBerisiko = fungsiYangBerisiko;
  }

  jalankan() {
    return this.fungsiYangBerisiko();
  }
}

const wrapper = new WrapperFungsiYangBerisiko(fungsiYangBerisiko);
const hasil = wrapper.jalankan();

// contoh skenario troubleshooting
// misalnya, fungsi yang berisiko memiliki ketergantungan pada modul lain
// yang tidak dapat diubah, maka kita dapat menggunakan pola adapter
// untuk memperkenalkan sebuah seam
class AdapterModul {
  constructor(modul) {
    this.modul = modul;
  }

  jalankan() {
    return this.modul.jalankan();
  }
}

const adapter = new AdapterModul(modul);
const hasil = adapter.jalankan();
```

## 2️⃣ You Don't Know JS – Kyle Simpson

### 🎯 Thesis
> Kekuatan JavaScript terletak pada **ruang lingkup, closure, dan model asinkron**; penguasaan konsep-konsep tersebut membuka *kode yang dapat diprediksi* dan menghilangkan bug tersembunyi.

### 🔑 Key Takeaways
- **Rantai Ruang Lingkup** – setiap pencarian variabel berjalan ke atas lingkungan leksikal; pahami pembuatan closure.  
- **`this` binding** – tergantung pada *tempat panggilan* (fungsi, metode, acara); gunakan pengikatan eksplisit (`call`, `apply`, `bind`) ketika diperlukan.  
- **Polah Asinkron** – Promises, Generators, dan `async/await` hanyalah *janji* nilai;perlakukan mereka sebagai entitas kelas pertama.  
- **Fitur ES6+** – let/const, modul, kelas, simbol — adalah gula sintaksis di atas mekanisme yang sama.

### 📋 Daftar Periksa yang Dapat Diambil Tindakan
- [ ] Pilih **fungsi** yang menggunakan callback; tulis ulang menggunakan **Promises** dan tes aliran asinkron.  
- [ ] Buat **demo closure**: sebuah pabrik yang mengembalikan sebuah penghitung; verifikasi bahwa setiap fungsi yang dikembalikan mempertahankan keadaannya sendiri.  
- [ ] Audit kode untuk **penggunaan implisit `this`**; refactor ke pengikatan eksplisit di mana konteks adalah ambigu.  
- [ ] Tambahkan **modul** (ESM) ke file yang saat ini menggunakan CommonJS; jalankan suite tes untuk memastikan tidak ada yang rusak.

### Contoh Implementasi
```javascript
// menulis ulang callback menggunakan Promises
function fungsiAsinkron() {
  return new Promise((resolve, reject) => {
    // kode asinkron di sini
    resolve('hasil yang diharapkan');
  });
}

// membuat demo closure
function pabrikPenghitung() {
  let hitungan = 0;
  return function() {
    hitungan++;
    return hitungan;
  };
}

const penghitung = pabrikPenghitung();
console.log(penghitung()); // 1
console.log(penghitung()); // 2

// contoh skenario troubleshooting
// misalnya, fungsi yang menggunakan callback memiliki ketergantungan
// pada modul lain yang tidak dapat diubah, maka kita dapat menggunakan
// pola adapter untuk memperkenalkan sebuah seam
class AdapterModul {
  constructor(modul) {
    this.modul = modul;
  }

  jalankan() {
    return this.modul.jalankan();
  }
}

const adapter = new AdapterModul(modul);
const hasil = adapter.jalankan();
```

## 3️⃣ The Art of Computer Programming – Donald Knuth

### 🎯 Thesis
> Pemrograman adalah **seni matematika**; analisis algoritma yang ketat, pembangkitan kombinatorial, dan teknik pembuktian kesalahan membentuk tulang punggung perangkat lunak yang andal.

### 🔑 Key Takeaways
- **Pemikiran Algoritmik** – pecahkan masalah menjadi *langkah-langkah yang tepat*; hindari heuristik ad-hoc.  
- **Analisis Kompleksitas** – gunakan notasi Big-O untuk memprediksi skalabilitas; pilih algoritma yang paling sederhana yang memenuhi konstrained kinerja.  
- **Koreksi oleh Konstruksi** – buktikan invarian loop, terminasi rekursi, dan pembangkitan kombinatorial kesalahan.  
- **Kombinatorial Generatif** – teknik seperti *Gray codes*, *permutasi*, dan *koefisien binomial* adalah blok bangunan yang dapat digunakan kembali.

### 📋 Daftar Periksa yang Dapat Diambil Tindakan
- [ ] Pilih **algoritma sederhana** dari Knuth (misalnya, pencarian biner) dan implementasikan *dengan unit tes penuh* yang mencakup kasus ujung.  
- [ ] Tulis **pseudocode bukti** kesalahan untuk rutinitas kecil (misalnya, “tukar dua elemen dalam array”).  
- [ ] Benchmark algoritma melawan baseline naïf; catat **waktu** dan **ruang** kompleksitas.  
- [ ] Dokumentasikan **kompleksitas** dan **trade-off** dalam markdown ADR untuk referensi di masa depan.

### Contoh Implementasi
```javascript
// implementasi pencarian biner
function pencarianBiner(arr, target) {
  let kiri = 0;
  let kanan = arr.length - 1;
  while (kiri <= kanan) {
    const tengah = Math.floor((kiri + kanan) / 2);
    if (arr[tengah] === target) {
      return tengah;
    } else if (arr[tengah] < target) {
      kiri = tengah + 1;
    } else {
      kanan = tengah - 1;
    }
  }
  return -1;
}

// pseudocode bukti kesalahan
function tukarDuaElemen(arr, i, j) {
  const temp = arr[i];
  arr[i] = arr[j];
  arr[j] = temp;
}

// contoh skenario troubleshooting
// misalnya, algoritma yang dipilih memiliki ketergantungan pada
// struktur data yang tidak dapat diubah, maka kita dapat menggunakan
// pola adapter untuk memperkenalkan sebuah seam
class AdapterStrukturData {
  constructor(strukturData) {
    this.strukturData = strukturData;
  }

  jalankan() {
    return this.strukturData.jalankan();
  }
}

const adapter = new AdapterStrukturData(strukturData);
const hasil = adapter.jalankan();
```

## 🗂️ Bagaimana Buku-Buku Ini Terkait dengan Keputusan Arsitektur Kami

| Konsep | Buku Legacy Code | YDKJS | Knuth |
|---------|------------------|-------|-------|
| **Refactoring Aman** | Tes karakterisasi → memungkinkan kami mengganti mesin penyimpanan legacy tanpa memecahkan pipeline yang ada. | Pemahaman pola asinkron memungkinkan kami memodernisasi callback di layanan event-driven legacy. | Pembuktian kesalahan algoritmik memastikan logika pengarsipan atau replikasi baru berperilaku seperti yang diharapkan. |
| **Pelepasan Ketergantungan** | Gunakan seam dan adapter untuk mengisolasi modul legacy. | Gunakan modul (`import`) untuk memecahkan ketergantungan melingkar. | Desain ortogonal menggunakan algoritma dengan ketergantungan minimal. |
| **Portofolio Pengetahuan** | Pembelajaran terus-menerus (buku, ADR) menjaga kami tetap mutakhir dengan pola. | Menguasai semantik JS mencegah bug halus di kode event-driven. | Wawasan algoritmik yang mendalam membimbing pilihan struktur data (B-Tree vs LSM-Tree). |

## ✅ Rencana Aksi Cepat (Sprint Satu Minggu)

| Hari | Kegiatan |
|-----|----------|
| **Senin** | Tulis **tes karakterisasi** untuk fungsi akses database legacy. |
| **Selasa** | Lakukan refactoring fungsi menggunakan **seam** (injeksi ketergantungan). |
| **Rabu** | Konversi aliran asinkron berbasis callback ke **Promises**; tambahkan unit tes. |
| **Kamis** | Implementasikan **algoritma gaya Knuth** (misalnya, pencarian biner) dengan pemeriksaan kesalahan formal. |
| **Jumat** | Perbarui **log portofolio pengetahuan**; komit catatan singkat tentang apa yang dipelajari minggu ini. |

### Langkah Berikutnya?
- Ingin mendalami lebih dalam salah satu dari tiga buku?  
- Membutuhkan **templat ADR** yang menangkap trade-off yang dibahas?  
- Siap mengapply salah satu teknik tersebut ke repository riil di dalam vault?

Kita akan membantu Anda mengeksekusi langkah-langkah tersebut dan memberikan panduan yang lebih mendalam tentang cara mengimplementasikan prinsip-prinsip yang dibahas dalam buku-buku tersebut. Dengan memahami konsep-konsep yang dibahas dalam tiga buku ini, Anda dapat meningkatkan kemampuan Anda dalam mengembangkan perangkat lunak yang lebih baik, lebih efisien, dan lebih dapat diprediksi. Oleh karena itu, sangat penting untuk memahami konsep-konsep tersebut dan mengaplikasikannya dalam proyek-proyek Anda.