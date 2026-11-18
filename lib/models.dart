import 'package:wallet/wallet.dart';

/// A lab tool from the contract's catalog (`ambilAlat`).
class Alat {
  const Alat({
    required this.id,
    required this.nama,
    required this.tersedia,
    required this.aktif,
  });

  final int id;
  final String nama;

  /// False while the tool is lent out.
  final bool tersedia;

  /// False once the admin has retired the tool.
  final bool aktif;

  bool get bisaDipinjam => aktif && tersedia;
}

/// One loan record (`ambilPeminjaman`).
class Peminjaman {
  const Peminjaman({
    required this.id,
    required this.alatId,
    required this.peminjam,
    required this.waktuPinjam,
    this.waktuKembali,
  });

  final int id;
  final int alatId;
  final EthereumAddress peminjam;
  final DateTime waktuPinjam;

  /// Null while the tool has not been returned (the contract stores 0).
  final DateTime? waktuKembali;

  bool get dikembalikan => waktuKembali != null;

  bool terlambat(Duration batas, DateTime sekarang) =>
      !dikembalikan && sekarang.difference(waktuPinjam) > batas;

  bool milik(EthereumAddress? alamat) => alamat != null && peminjam == alamat;
}

/// Converts a Solidity `block.timestamp` (seconds since epoch) to local time.
DateTime dariTimestamp(BigInt detik) =>
    DateTime.fromMillisecondsSinceEpoch(detik.toInt() * 1000);
