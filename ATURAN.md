# Aturan dan praktik baik: FlutterChain (ChainTodo)

Aturan kerja kelompok untuk tugas proyek "Aplikasi Flutter Terhubung Blockchain" (Pemrograman Mobile 2). Sumber utama: dokumen `Tugas Proyek blockchain.pdf`. Jika ada yang bertentangan, dokumen tugas yang berlaku.

## 1. Target

### Fitur minimum (wajib)

- Kontrak ter-*deploy* di Sepolia dan terverifikasi di Etherscan.
- Halaman daftar tugas membaca `jumlahTugas` dan `ambilTugas`; tugas selesai tampil berbeda (dicoret atau dicentang).
- Halaman tambah tugas: formulir judul yang mengirim transaksi `tambahTugas`.
- Tombol tandai selesai yang mengirim transaksi `tandaiSelesai`.
- Indikator status transaksi: memproses, berhasil (dengan *hash* transaksi), atau gagal (dengan pesan galat).
- Tombol *refresh* atau tarik-untuk-memuat-ulang.
- Alamat kontrak, RPC URL, dan chain ID dalam satu berkas konfigurasi (`.env`, lihat bagian 4).

### Fitur tambahan (maksimal +10)

Diurutkan dari yang paling murah:

1. Filter tugas: semua, belum selesai, selesai, atau milik wallet sendiri.
2. Mendengarkan *event* `TugasBaru` dan `TugasSelesai` agar daftar terbarui otomatis.
3. Edit judul atau hapus tugas oleh pembuatnya. Fitur ini mengubah kontrak, jadi **diputuskan sebelum *deploy* final**.
4. Koneksi wallet lewat WalletConnect/Reown, sehingga *private key* tidak pernah ada di aplikasi.

### Luaran

| No | Luaran | Oleh |
|---|---|---|
| 1 | Jurnal Tonton, PDF 1–2 halaman, bahasa Indonesia | Individu |
| 2 | Repositori GitHub (Flutter + `.sol`), akses dibuka untuk dosen | Kelompok |
| 3 | README: cara menjalankan, versi paket, alamat kontrak, link Etherscan, atribusi | Kelompok |
| 4 | APK hasil build | Kelompok |
| 5 | Video demo 3–5 menit: *deploy*, baca data, tambah data, cek transaksi di Etherscan | Kelompok |
| 6 | Laporan maksimal 5 halaman: arsitektur, kendala, pembagian tugas | Kelompok |

Video demo harus memperlihatkan *deploy*, jadi **layar direkam saat *deploy* ke Sepolia**.

## 2. Jaringan dan aset

- **Hanya Sepolia testnet** (chain ID `11155111`). Mainnet dan jaringan lain dilarang.
- Batasan ini ditegakkan di dua tempat:
  - **Saat *deploy*:** sebelum menekan *Deploy* di Remix (*Injected Provider - MetaMask*), pastikan Remix dan MetaMask sama-sama menunjukkan Sepolia.
  - **Di aplikasi:** aplikasi memeriksa `eth_chainId` saat mulai dan menolak berjalan jika hasilnya bukan `11155111`. Setiap transaksi menyertakan `chainId: 11155111`.
- **Tidak ada pembelian kripto** dalam bentuk apa pun: tidak membeli, menukar (*swap*), atau mem-*bridge* aset.
- Sepolia ETH hanya dari *faucet*. *Faucet* yang mensyaratkan saldo ETH di mainnet dilewati, bukan dipenuhi dengan membeli ETH.

## 3. Wallet (MetaMask)

- Akun MetaMask khusus tugas, **bukan wallet pribadi**, dan tidak pernah memegang aset bernilai.
- Gunakan *seed phrase* baru: profil peramban terpisah dengan instalasi MetaMask sendiri, bukan akun tambahan di wallet pribadi. Jika bocor, yang hilang hanya Sepolia ETH.
- *Seed phrase* hanya ditulis di kertas: tidak di file, tangkapan layar, catatan digital, *chat*, atau asisten AI.
- Setiap anggota boleh punya wallet uji sendiri. Dua wallet berguna untuk menunjukkan aturan "Bukan pembuat tugas" di kontrak.
- Alamat wallet bersifat publik dan boleh muncul di README, laporan, dan video.

## 4. Kunci dan konfigurasi

### Yang tidak boleh masuk repositori

- *Seed phrase* dan *private key*. Repositori yang memuatnya **dikurangi 20 poin**.
- URL RPC yang mengandung *API key* (Alchemy, Infura).
- File `.env`.

### Konfigurasi aplikasi

- Satu berkas `.env` berisi `RPC_URL`, `CONTRACT_ADDRESS`, dan `CHAIN_ID`. Berkas ini ada di `.gitignore`.
- Repositori hanya berisi `.env.example` (nama variabel, tanpa rahasia).
- Sebelum setiap commit, periksa `git status` dan `git diff --cached`.
- Di GitHub, aktifkan *secret scanning* dan *push protection*.

### *Private key* di aplikasi

- *Deploy* memakai Remix + MetaMask, sehingga **tidak ada berkas *private key* untuk *deploy***. Satu-satunya tempat kunci bisa berada adalah aplikasi Flutter.
- `.env` dimuat sebagai *asset* Flutter, jadi **isinya ikut terbungkus di APK**. APK adalah luaran yang dikumpulkan, sehingga kunci di `.env` akan terbawa ke dosen dan siapa pun yang memegang APK.
- Pilihan cara menyimpan kunci (diputuskan pada tahap fitur tulis):
  - **Dimasukkan saat aplikasi berjalan** dan disimpan dengan `flutter_secure_storage`. Kunci tidak pernah ada di berkas mana pun. Ini rekomendasi untuk fitur minimum.
  - **WalletConnect/Reown**: kunci tetap di MetaMask, tidak pernah di aplikasi. Ini sekaligus fitur tambahan.
  - **Kunci di `.env`**: diizinkan dokumen tugas selama `.env` di-*gitignore*, tetapi hanya untuk build pribadi. APK yang dikumpulkan tidak boleh berisi kunci.

### Jika rahasia bocor

- Anggap sudah diketahui orang lain. Menghapus dari riwayat Git tidak cukup.
- Ganti *API key* RPC yang bocor.
- Tinggalkan wallet yang bocor, buat wallet baru, dan ambil Sepolia ETH baru.

### Dokumentasi

- Tangkapan layar, rekaman, dan video demo tidak boleh memperlihatkan *seed phrase*, *private key*, URL RPC lengkap, atau layar ekspor kunci MetaMask.

## 5. Data pribadi

- Data di blockchain bersifat **publik dan permanen**, termasuk argumen fungsi (*calldata*) dan *event* yang terlihat di Etherscan.
- **Judul tugas ChainTodo tersimpan publik selamanya.** Aplikasi mengingatkan pengguna agar tidak menulis nama, NIM, atau data pribadi di judul.
- Jika memakai alternatif yang mencatat NIM (misalnya presensi):
  - *Hash* dihitung di aplikasi, bukan di kontrak; memanggil `keccak256(nim)` di Solidity tetap membuka NIM di *calldata*.
  - `keccak256(NIM)` polos mudah ditebak balik karena NIM pendek dan berpola. Gunakan *hash* bergaram (`keccak256(salt + NIM)`, *salt* acak disimpan di luar rantai dan repositori) atau kode pengganti.

## 6. *Smart contract*

- Ditulis, diuji, dan di-*deploy* di **Remix IDE**. Berkas sumber disimpan di `contracts/ChainTodo.sol` di repositori.
- *Pragma* `^0.8.20`. Versi *compiler* yang dipakai di Remix dicatat persis (misalnya `0.8.20+commit...`), beserta pengaturan *optimizer*.
- Diuji di Remix VM sebelum *deploy*: judul kosong, id tidak ada, bukan pembuat, tugas sudah selesai.
- Fitur kontrak tambahan (edit/hapus) diputuskan sebelum *deploy* final. *Deploy* ulang berarti alamat baru, verifikasi ulang, dan README serta video yang harus diperbarui.
- Verifikasi di Etherscan memakai versi *compiler*, *optimizer*, dan lisensi yang sama persis dengan saat *deploy*.
- Dicatat di README: alamat kontrak, *hash* transaksi *deploy*, versi *compiler*, dan link Etherscan.
- ABI disalin dari Remix ke `assets/abi/ChainTodo.json`, tidak ditulis ulang manual.

## 7. Aplikasi Flutter

- Flutter stabil terbaru. `web3dart` dan `http` versi terbaru dari pub.dev; versinya dicatat di README.
- `web3dart` 3.x lebih baru dari yang dipakai video tutorial, sehingga kode dari video mungkin perlu disesuaikan.
- Koneksi melalui `Web3Client(rpcUrl, http.Client())`. Nilai konfigurasi hanya dibaca dari `.env` melalui satu berkas `lib/config.dart`.
- Pemeriksaan chain ID saat mulai (bagian 2).
- Fungsi baca memakai `call`. Fungsi tulis:
  - menyertakan `chainId: 11155111`;
  - menunggu *receipt*;
  - menampilkan *hash* transaksi dan tautan ke sepolia.etherscan.io.
- Galat ditampilkan dengan jelas: saldo tidak cukup, transaksi ditolak kontrak (*revert*), RPC tidak terjangkau, chain salah.
- Izin `INTERNET` dideklarasikan di `AndroidManifest.xml`. Tanpanya, aplikasi berjalan saat *debug* tetapi gagal di APK *release*.

## 8. Repositori dan GitHub

- Repositori di **GitHub**. Selama pengerjaan sebaiknya *private*; dosen diundang sebagai *collaborator* saat pengumpulan, atau repositori dibuat publik.
- Struktur:
  - aplikasi Flutter di akar repositori;
  - `contracts/ChainTodo.sol`;
  - `assets/abi/ChainTodo.json`;
  - `.env.example`, `README.md`, dan `ATURAN.md`.
- APK dikumpulkan sebagai berkas terpisah, tidak di-*commit*.

## 9. Bantuan dan atribusi

- Tutorial, dokumentasi, contoh kode, teman, dan asisten AI boleh dipakai sepenuhnya.
- Syaratnya:
  - **Setiap anggota mampu menjelaskan kode** yang dikumpulkan.
  - **Setiap kode yang diadaptasi disebut di README** pada bagian "Sumber dan atribusi": tautan, bagian yang diadaptasi, dan lisensinya. Bantuan asisten AI juga dicatat di sana.

## 10. Daftar periksa sebelum dikumpulkan

- [ ] Kontrak ter-*deploy* di Sepolia dan terverifikasi di Etherscan.
- [ ] Ketujuh fitur minimum berjalan di APK *release*.
- [ ] Aplikasi menolak chain selain Sepolia.
- [ ] Tidak ada *private key*, *seed phrase*, URL RPC ber-*API key*, atau `.env` di riwayat Git (`git log -p` diperiksa).
- [ ] APK yang dikumpulkan tidak berisi *private key*.
- [ ] Tidak ada data pribadi mentah di judul tugas, *event*, maupun *calldata* (diperiksa di Etherscan).
- [ ] README berisi versi paket, alamat kontrak, link Etherscan, dan atribusi.
- [ ] Video demo 3–5 menit tidak memperlihatkan rahasia.
- [ ] Jurnal Tonton masing-masing anggota dan laporan kelompok siap.
