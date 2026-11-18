# Aturan dan praktik baik: FlutterChain (Logbook Alat Lab IoT)

Dokumen ini memuat aturan kerja kelompok untuk tugas proyek "Aplikasi Flutter Terhubung Blockchain" (Pemrograman Mobile 2). Sumber utamanya adalah dokumen `Tugas Proyek blockchain.pdf`. Jika ada aturan yang bertentangan, yang berlaku adalah dokumen tugas.

Kelompok memilih studi kasus alternatif **Logbook peminjaman alat Lab IoT**. Kontraknya, `LogbookAlat.sol`, dikembangkan dari kerangka ChainTodo.

## 1. Target

### Fitur minimum (wajib)

Dokumen tugas merumuskan fitur minimum dengan istilah ChainTodo. Padanannya di *logbook* sebagai berikut:

| Fitur minimum (istilah ChainTodo) | Padanan di Logbook Alat |
|---|---|
| Kontrak ter-*deploy* di Sepolia dan terverifikasi di Etherscan | Sama |
| Halaman daftar membaca `jumlahTugas` dan `ambilTugas`; tugas selesai tampil berbeda | Halaman Riwayat membaca `jumlahPeminjaman` dan `ambilPeminjaman`; peminjaman yang sudah kembali dicoret dan dicentang |
| Halaman tambah: formulir judul yang mengirim `tambahTugas` | Halaman Pinjam: formulir pilih alat yang mengirim `pinjam` |
| Tombol tandai selesai yang mengirim `tandaiSelesai` | Tombol Kembalikan yang mengirim `kembalikan` |
| Indikator status transaksi (memproses, berhasil + *hash*, gagal + pesan) | Sama, ditambah biaya gas dan tautan Etherscan |
| Tombol *refresh* atau tarik layar untuk memuat ulang | Sama |
| Alamat kontrak, RPC URL, dan *chain ID* dalam satu berkas konfigurasi | `.env` (lihat bagian 4) |

### Fitur tambahan (maksimal +10)

1. Filter riwayat: semua, dipinjam, sudah kembali, atau milik *wallet* sendiri.
2. Pembaruan otomatis dari *event* `Dipinjam`, `Dikembalikan`, `AlatDitambah`, dan `AlatDiubah` agar daftar selalu mutakhir.
3. Fitur kontrak tambahan: katalog alat yang dikelola admin (`tambahAlat`, serta `ubahAlat` untuk mengganti nama atau menonaktifkan alat) dan aturan bahwa alat yang sedang dipinjam tidak bisa dipinjam lagi. Riwayat peminjaman sengaja tidak bisa dihapus karena *logbook* adalah catatan audit.
4. Koneksi *wallet* lewat WalletConnect/Reown sehingga *private key* tidak pernah ada di aplikasi.

### Luaran

| No. | Luaran | Oleh |
|---|---|---|
| 1 | Jurnal Tonton, PDF 1–2 halaman, bahasa Indonesia | Individu |
| 2 | Repositori GitHub (Flutter + `.sol`), akses dibuka untuk dosen | Kelompok |
| 3 | README: cara menjalankan, versi paket, alamat kontrak, tautan Etherscan, atribusi | Kelompok |
| 4 | APK hasil *build* | Kelompok |
| 5 | Video demo 3–5 menit: *deploy*, pembacaan data, penambahan data, dan pemeriksaan transaksi di Etherscan | Kelompok |
| 6 | Laporan maksimal 5 halaman: arsitektur, kendala, pembagian tugas | Kelompok |

Video demo harus memperlihatkan proses *deploy*; karena itu, **layar direkam saat *deploy* ke Sepolia**.

## 2. Jaringan dan aset

- **Hanya Sepolia *testnet*** (*chain ID* `11155111`). *Mainnet* dan jaringan lain dilarang.
- Batasan ini ditegakkan di dua tempat:
  - **Saat *deploy*:** sebelum menekan *Deploy* di Remix (*Injected Provider - MetaMask*), pastikan Remix dan MetaMask sama-sama menunjukkan Sepolia.
  - **Di aplikasi:** aplikasi memeriksa `eth_chainId` saat mulai dan setiap kali koneksi diganti, lalu menolak berjalan jika hasilnya bukan `11155111`. Setiap transaksi menyertakan `chainId: 11155111`.
- **Tidak ada pembelian kripto** dalam bentuk apa pun: tidak membeli, menukar (*swap*), atau mem-*bridge* aset.
- Sepolia ETH hanya diambil dari *faucet*. *Faucet* yang mensyaratkan saldo ETH di *mainnet* dilewati, bukan dipenuhi dengan membeli ETH.

## 3. *Wallet* (MetaMask)

- Gunakan akun MetaMask khusus tugas, **bukan *wallet* pribadi**, yang tidak pernah memegang aset bernilai.
- Gunakan *seed phrase* baru: profil peramban terpisah dengan instalasi MetaMask sendiri, bukan akun tambahan di *wallet* pribadi. Jika bocor, yang hilang hanya Sepolia ETH.
- *Seed phrase* hanya ditulis di kertas, tidak di berkas, tangkapan layar, catatan digital, obrolan, atau asisten AI.
- Setiap anggota boleh memiliki *wallet* uji sendiri. Dua *wallet* berguna untuk menunjukkan aturan "Bukan peminjam" di kontrak.
- Alamat *wallet* bersifat publik dan boleh muncul di README, laporan, dan video.

## 4. Kunci dan konfigurasi

### Yang tidak boleh masuk repositori

- *Seed phrase* dan *private key*. Repositori yang memuatnya **dikurangi 20 poin**.
- URL RPC yang mengandung *API key* (Alchemy, Infura).
- Berkas `.env`.

### Konfigurasi aplikasi

- Satu berkas `.env` berisi `RPC_URL`, `CONTRACT_ADDRESS`, dan `CHAIN_ID`. Berkas ini tercantum di `.gitignore`.
- Repositori hanya berisi `.env.example` (nama variabel, tanpa rahasia).
- `RPC_URL` dan `CONTRACT_ADDRESS` di `.env` adalah nilai bawaan. Halaman Koneksi di aplikasi bisa menggantinya tanpa *build* ulang setelah memeriksa *chain* dan kontraknya. `CHAIN_ID` tetap terkunci ke 11155111.
- Sebelum setiap *commit*, periksa `git status` dan `git diff --cached`.
- Di GitHub, aktifkan *secret scanning* dan *push protection*.

### *Private key* di aplikasi

- *Deploy* memakai Remix dan MetaMask sehingga **tidak ada berkas *private key* untuk *deploy***. Satu-satunya tempat kunci bisa berada adalah aplikasi Flutter.
- `.env` dimuat sebagai aset Flutter sehingga **isinya ikut terbungkus di dalam APK**. Karena APK termasuk luaran yang dikumpulkan, kunci di `.env` akan terbawa ke dosen dan siapa pun yang memegang APK.
- Pilihan cara menyimpan kunci:
  - **Dimasukkan saat aplikasi berjalan** dan disimpan dengan `flutter_secure_storage`. Kunci tidak pernah ada di berkas mana pun. Cara ini yang dipakai aplikasi.
  - **WalletConnect/Reown**: kunci tetap di MetaMask dan tidak pernah ada di aplikasi. Cara ini sekaligus menjadi fitur tambahan.
  - **Kunci di `.env`**: diizinkan dokumen tugas selama `.env` dimasukkan ke `.gitignore`, tetapi hanya untuk *build* pribadi. APK yang dikumpulkan tidak boleh berisi kunci.

### Jika rahasia bocor

- Anggap rahasia itu sudah diketahui orang lain. Menghapusnya dari riwayat Git tidak cukup.
- Ganti *API key* RPC yang bocor.
- Tinggalkan *wallet* yang bocor, buat *wallet* baru, dan ambil Sepolia ETH baru.

### Dokumentasi

- Tangkapan layar, rekaman, dan video demo tidak boleh memperlihatkan *seed phrase*, *private key*, URL RPC lengkap, atau layar ekspor kunci MetaMask.

## 5. Data pribadi

- Data di *blockchain* bersifat **publik dan permanen**, termasuk argumen fungsi (*calldata*) dan *event* yang terlihat di Etherscan.
- **Peminjam hanya dikenali dari alamat *wallet*.** Kontrak tidak menyimpan nama atau NIM. Jika lab perlu mengetahui pemilik sebuah alamat, daftarnya disimpan di luar rantai, bukan di kontrak atau repositori.
- **Nama alat tersimpan secara publik dan permanen.** Admin hanya menulis nama dan nomor alat (misalnya `ESP32-S3 N16R8 #1`), bukan nama orang. Aplikasi tidak menerima teks bebas dari peminjam; alat dipilih dari daftar.
- Jika memakai alternatif yang mencatat NIM (misalnya presensi):
  - *Hash* dihitung di aplikasi, bukan di kontrak; memanggil `keccak256(nim)` di Solidity tetap membuka NIM di *calldata*.
  - `keccak256(NIM)` polos mudah ditebak balik karena NIM pendek dan berpola. Gunakan *hash* bergaram (`keccak256(salt + NIM)`, dengan *salt* acak yang disimpan di luar rantai dan repositori) atau kode pengganti.

## 6. *Smart contract*

- Kontrak ditulis, diuji, dan di-*deploy* di **Remix IDE**. Berkas sumbernya tersimpan di `contracts/LogbookAlat.sol`.
- Kontrak memakai *pragma* `^0.8.20` dan dikompilasi dengan **0.8.20+commit.a1b79de6**, *optimizer* nonaktif (bawaan Remix), dan EVM `shanghai`. Pengaturan ini dipakai lagi saat verifikasi.
- Pengujian di Remix VM sebelum *deploy* mencakup kasus berikut:
  - bukan admin menambah alat;
  - nama alat kosong;
  - meminjam alat yang sedang dipinjam atau nonaktif;
  - ID alat atau ID peminjaman tidak ada;
  - mengembalikan dua kali;
  - mengembalikan peminjaman orang lain;
  - menonaktifkan alat yang sedang dipinjam.
- Semua fitur kontrak tambahan sudah ada di versi ini sehingga cukup satu kali *deploy*. *Deploy* ulang berarti alamat baru, verifikasi ulang, serta README dan video yang harus diperbarui.
- Verifikasi di Etherscan memakai versi kompilator, *optimizer*, dan lisensi yang sama persis dengan saat *deploy*. Masukan kompilator dari Remix disimpan di `contracts/LogbookAlat.input.json` dan diunggah dengan metode *Standard JSON Input*.
- README mencatat alamat kontrak, *hash* transaksi *deploy*, versi kompilator, dan tautan Etherscan.
- ABI disimpan di `assets/abi/LogbookAlat.json` dari hasil kompilasi yang sama, bukan ditulis ulang secara manual.

## 7. Aplikasi Flutter

- Proyek memakai Flutter stabil terbaru serta `web3dart` dan `http` versi terbaru dari pub.dev; versi semuanya dicatat di README.
- `web3dart` 3.x lebih baru daripada versi di video tutorial sehingga kode dari video mungkin perlu disesuaikan.
- Aplikasi terhubung melalui `Web3Client(rpcUrl, http.Client())`. Nilai bawaan dibaca dari `.env` melalui satu berkas `lib/config.dart`; isian halaman Koneksi disimpan terenkripsi di ponsel.
- *Chain ID* diperiksa saat aplikasi mulai dan saat koneksi diganti (bagian 2).
- Fungsi baca memakai `call`. Fungsi tulis:
  - menyertakan `chainId: 11155111`;
  - menunggu *receipt*;
  - menampilkan *hash* transaksi dan tautan ke sepolia.etherscan.io.
- Galat ditampilkan dengan jelas: saldo tidak cukup, transaksi ditolak kontrak (*revert*), RPC tidak terjangkau, dan *chain* salah.
- Izin `INTERNET` dideklarasikan di `AndroidManifest.xml`. Tanpa izin itu, aplikasi berjalan saat *debug* tetapi gagal di APK *release*.
- `android/app/build.gradle.kts` mengatur filter aset agar `.env` ikut masuk APK. Tanpa pengaturan itu, Android Gradle Plugin membuang berkas yang namanya diawali titik.

## 8. Repositori dan GitHub

- Repositori disimpan di **GitHub** dan bersifat publik, dengan *secret scanning* dan *push protection* aktif. Karena siapa pun bisa membacanya, pemeriksaan sebelum *commit* (bagian 4) wajib dilakukan setiap kali.
- Struktur:
  - aplikasi Flutter di akar repositori;
  - `contracts/LogbookAlat.sol` dan `contracts/LogbookAlat.input.json`;
  - `assets/abi/LogbookAlat.json`;
  - `.env.example`, `README.md`, dan `ATURAN.md`.
- APK dikumpulkan sebagai berkas terpisah dan tidak di-*commit*.

## 9. Bantuan dan atribusi

- Tutorial, dokumentasi, contoh kode, teman, dan asisten AI boleh dipakai sepenuhnya.
- Syaratnya:
  - **Setiap anggota mampu menjelaskan kode** yang dikumpulkan.
  - **Setiap kode yang diadaptasi disebut di README** pada bagian "Sumber dan atribusi", lengkap dengan tautan, bagian yang diadaptasi, dan lisensinya. Bantuan asisten AI juga dicatat di sana.

## 10. Daftar periksa sebelum dikumpulkan

- [ ] Kontrak ter-*deploy* di Sepolia dan terverifikasi di Etherscan.
- [ ] Ketujuh fitur minimum berjalan di APK *release*.
- [ ] Aplikasi menolak *chain* selain Sepolia.
- [ ] Tidak ada *private key*, *seed phrase*, URL RPC ber-*API key*, atau `.env` di riwayat Git (`git log -p` diperiksa).
- [ ] APK yang dikumpulkan tidak berisi *private key*.
- [ ] Tidak ada data pribadi mentah di nama alat, *event*, atau *calldata* (diperiksa di Etherscan).
- [ ] README berisi versi paket, alamat kontrak, tautan Etherscan, dan atribusi.
- [ ] Video demo 3–5 menit tidak memperlihatkan rahasia.
- [ ] Jurnal Tonton masing-masing anggota dan laporan kelompok sudah siap.
