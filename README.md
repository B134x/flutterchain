# FlutterChain: Logbook Alat Lab IoT

Aplikasi Flutter (Android) untuk mencatat peminjaman alat Lab IoT di *smart contract* Ethereum **Sepolia *testnet***. Proyek ini dikerjakan untuk mata kuliah Pemrograman Mobile 2 di Politeknik Negeri Samarinda.

Aplikasi hanya berjalan di *testnet*: aplikasi menolak *chain* selain Sepolia (*chain ID* `11155111`), dan semua *wallet* yang dipakai adalah *wallet* uji tanpa aset bernilai.

<!-- Repositori ini publik. Isi tabel anggota sesuai permintaan dosen; NIM boleh dipindah ke laporan saja. -->

| Anggota | Peran |
|---|---|
| [Nama anggota 1] | [peran] |
| [Nama anggota 2] | [peran] |

## Fitur

Fitur minimum, disesuaikan dengan istilah *logbook*:

- **Riwayat peminjaman** membaca `jumlahPeminjaman` dan `ambilPeminjaman`. Peminjaman yang sudah kembali dicoret dan dicentang.
- **Formulir pinjam** untuk memilih alat yang tersedia dan mengirim `pinjam`.
- **Tombol Kembalikan** yang mengirim `kembalikan`.
- **Status transaksi**: mengirim, menunggu blok, berhasil (*hash*, biaya gas, tautan Etherscan), atau gagal (alasan penolakan kontrak dalam pesan yang mudah dipahami).
- **Muat ulang** lewat tombol atau dengan menarik layar ke bawah.
- **Satu berkas konfigurasi** `.env` berisi RPC URL, alamat kontrak, dan *chain ID*.

Fitur tambahan:

- **Filter riwayat**: semua, dipinjam, sudah kembali, atau milik *wallet* sendiri.
- **Pembaruan otomatis dari *event* kontrak** (`Dipinjam`, `Dikembalikan`, `AlatDitambah`, `AlatDiubah`) yang dibaca dengan `eth_getLogs` setiap 6 detik.
- **Fitur kontrak tambahan**: katalog alat yang dikelola admin, aturan bahwa alat yang sedang dipinjam tidak bisa dipinjam lagi, serta penggantian nama dan penonaktifan alat. Riwayat sengaja tidak bisa dihapus karena *logbook* adalah catatan audit.
- **Penanda terlambat** untuk peminjaman yang belum dikembalikan lebih lama daripada batas `LOAN_LIMIT_HOURS`.
- **Halaman Koneksi** untuk mengganti RPC URL dan alamat kontrak tanpa *build* ulang. Nilai `.env` menjadi nilai bawaan. Isian baru diperiksa terlebih dahulu (*chain* harus Sepolia dan alamat harus berisi kontrak LogbookAlat) sebelum disimpan terenkripsi di ponsel. *Chain ID* tidak bisa diubah.

## Kontrak

| | |
|---|---|
| Jaringan | Ethereum Sepolia (*chain ID* `11155111`) |
| Alamat | `[CONTRACT_ADDRESS]` |
| Transaksi *deploy* | `[DEPLOY_TX_HASH]` |
| Etherscan | [sepolia.etherscan.io/address/[CONTRACT_ADDRESS]#code](https://sepolia.etherscan.io/address/[CONTRACT_ADDRESS]#code) |
| Admin | `[ADMIN_ADDRESS]` (*wallet* uji yang men-*deploy* kontrak) |
| Kompilator | solc `0.8.20+commit.a1b79de6`, *optimizer* nonaktif, EVM `shanghai` |
| Lisensi | MIT |
| Sumber | [`contracts/LogbookAlat.sol`](contracts/LogbookAlat.sol); masukan kompilator yang persis sama dengan saat *deploy*: [`contracts/LogbookAlat.input.json`](contracts/LogbookAlat.input.json) |

| Fungsi | Pemanggil | Keterangan |
|---|---|---|
| `tambahAlat(nama)` | admin | Menambah alat ke katalog |
| `ubahAlat(alatId, nama, aktif)` | admin | Mengganti nama, menonaktifkan, atau mengaktifkan kembali alat. Alat yang sedang dipinjam tidak bisa dinonaktifkan |
| `pinjam(alatId)` | siapa saja | Meminjam alat yang aktif dan tersedia |
| `kembalikan(id)` | peminjam atau admin | Mengembalikan alat; admin bisa mencatat pengembalian atas nama peminjam |
| `jumlahAlat`, `ambilAlat`, `jumlahPeminjaman`, `ambilPeminjaman` | siapa saja | Membaca data tanpa biaya gas |

Kontrak tidak memiliki fungsi `payable` sehingga tidak bisa menerima atau menyimpan ETH.

## Arsitektur

```
Aplikasi Flutter (Android)
  |  HTTPS JSON-RPC ke RPC_URL
  v
Node Ethereum Sepolia  -->  kontrak LogbookAlat

baca   : eth_call, gratis
tulis  : transaksi ditandatangani di ponsel dengan web3dart, lalu eth_sendRawTransaction
event  : eth_getLogs pada alamat kontrak
```

| Berkas | Isi |
|---|---|
| `lib/config.dart` | Membaca `.env`, menolak `CHAIN_ID` selain 11155111, dan memvalidasi isian RPC URL serta alamat kontrak |
| `lib/services/logbook_service.dart` | Semua akses *blockchain*: pemeriksaan *chain* dan kontrak, pembacaan data, pengiriman transaksi, penantian *receipt*, dan deteksi *event* |
| `lib/services/key_store.dart` | Menyimpan kunci *wallet* uji di penyimpanan terenkripsi Android |
| `lib/services/connection_store.dart` | Menyimpan RPC URL dan alamat kontrak dari halaman Koneksi |
| `lib/logbook_controller.dart` | *State* aplikasi dan aksinya (koneksi, peminjaman, pengembalian, filter, pembaruan otomatis) |
| `lib/screens/` | Halaman Riwayat, Alat, Pinjam, Wallet, dan Koneksi |
| `lib/widgets/` | Kartu status transaksi dan dialog konfirmasi |
| `lib/util/` | Pesan galat yang mudah dipahami dan format tampilan |
| `assets/abi/LogbookAlat.json` | ABI dari hasil kompilasi yang sama dengan kontrak yang di-*deploy* |

## Menjalankan aplikasi

Prasyarat: Flutter 3.50.0 (Dart 3.14.0), Android SDK, dan emulator atau ponsel Android.

1. *Clone* repositori, lalu salin `.env.example` menjadi `.env`:

   ```bash
   cp .env.example .env
   ```

2. Isi `.env`:

   ```
   RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
   CONTRACT_ADDRESS=[CONTRACT_ADDRESS]
   CHAIN_ID=11155111
   LOAN_LIMIT_HOURS=24
   ```

   `RPC_URL` boleh diganti URL Alchemy atau Infura milik sendiri. URL seperti itu memuat *API key* sehingga tidak boleh di-*commit*.

   `RPC_URL` dan `CONTRACT_ADDRESS` boleh dikosongkan. Aplikasi tetap terbuka dan meminta keduanya di halaman **Koneksi** (ikon tautan di kanan atas). Halaman yang sama dipakai untuk pindah ke kontrak LogbookAlat lain tanpa *build* ulang.

3. Pasang dependensi dan jalankan aplikasi:

   ```bash
   flutter pub get
   flutter run
   ```

4. Di aplikasi, buka tab **Wallet** dan pilih **Buat wallet uji** (atau impor *private key* akun uji MetaMask). Kirim sekitar 0,01 SepoliaETH dari MetaMask ke alamat yang muncul, lalu pinjam alat dari tab **Alat**.

Membuat APK:

```bash
flutter build apk --release
```

Berkas APK tersimpan di `build/app/outputs/flutter-apk/app-release.apk`.

## Versi

| Komponen | Versi |
|---|---|
| Flutter / Dart | 3.50.0 stable / 3.14.0 |
| web3dart | 3.0.3 |
| http | 1.6.0 |
| flutter_dotenv | 6.0.2 |
| flutter_secure_storage | 11.2.0 |
| url_launcher | 6.3.3 |
| wallet | 0.0.18 |
| material_ui | 1.11.1 |
| Solidity | 0.8.20 |
| Remix IDE | 2.6.15 |

## Keamanan dan privasi

- **Hanya Sepolia.** *Chain ID* diperiksa di tiga tempat: saat membaca `.env`, saat terhubung ke RPC (`eth_chainId`), dan saat menandatangani transaksi (`chainId: 11155111`). Pemeriksaan terakhir penting karena web3dart secara bawaan menandatangani transaksi untuk *chain ID* 1 (*mainnet*). *Chain ID* tidak bisa diubah dari aplikasi.
- **Alamat kontrak diperiksa sebelum dipakai.** Alamat itu harus berisi kode kontrak di Sepolia, dan kode tersebut harus memuat semua fungsi LogbookAlat.
- **Tidak ada *private key* di repositori, di `.env`, atau di APK.** Kontrak di-*deploy* lewat Remix dan MetaMask sehingga tidak ada berkas kunci untuk *deploy*. Kunci *wallet* uji di aplikasi dibuat atau diimpor saat aplikasi berjalan, lalu disimpan dengan `flutter_secure_storage`. Isi `.env` ikut terbungkus di dalam APK; karena itu, `.env` hanya berisi nilai publik.
- **Tidak ada data pribadi di *blockchain*.** Peminjam hanya dikenali dari alamat *wallet*; kontrak tidak menyimpan nama atau NIM. Nama alat ditulis sebagai jenis dan nomor unit (misalnya `ESP32-S3 DevKit #1`) karena data di *blockchain* bersifat publik dan permanen.
- `.env` tercantum di `.gitignore`; repositori hanya memuat `.env.example`.

## Pengujian

- **Kontrak** diuji di Remix VM sebelum *deploy*. Semua kasus berikut lulus dengan pesan yang sesuai:
  - admin menambah alat (berhasil);
  - admin menambah alat dengan nama kosong (`Nama alat kosong`);
  - akun bukan admin menambah alat (`Bukan admin`);
  - meminjam alat yang sedang dipinjam (`Alat sedang dipinjam`);
  - menonaktifkan alat yang sedang dipinjam (`Alat sedang dipinjam`);
  - memakai ID alat atau ID peminjaman yang tidak ada (`Alat tidak ada`, `Peminjaman tidak ada`);
  - mengembalikan peminjaman milik orang lain (`Bukan peminjam`);
  - mengembalikan alat dua kali (`Sudah dikembalikan`);
  - meminjam alat nonaktif (`Alat tidak aktif`).
- **Aplikasi** diuji dengan `flutter test`: *unit test* untuk pembacaan alasan *revert*, pesan galat, validasi isian Koneksi, penanda terlambat, kepemilikan peminjaman, dan format tampilan.

## Sumber dan atribusi

- **Kerangka kontrak ChainTodo** dari dokumen tugas Pemrograman Mobile 2 (Politeknik Negeri Samarinda). Pola `struct` dan *array*, fungsi `jumlah...`/`ambil...`, *event*, serta *modifier* diadaptasi ke dalam `LogbookAlat`.
- **[web3dart](https://pub.dev/packages/web3dart)** (lisensi MIT). Pola `Web3Client`, `DeployedContract`, `call`, dan `sendTransaction` mengikuti dokumentasi paket.
- **Templat `flutter create`** (lisensi BSD-3-Clause, The Flutter Authors) dipakai sebagai kerangka proyek Android.
- **Dokumentasi** Solidity, Remix IDE, MetaMask, dan Etherscan menjadi rujukan *deploy* dan verifikasi.
- **Bantuan AI**: Claude (Anthropic), lewat Claude Code, dipakai untuk merancang kontrak, menulis sebagian besar kode aplikasi dan pengujian, serta menyusun draf README ini. Kelompok meninjau, menjalankan, dan menguji seluruh kode; setiap anggota mampu menjelaskannya.
