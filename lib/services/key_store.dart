import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';

/// Holds the course-only Sepolia test key in Android's encrypted storage.
/// Never in `.env`, assets or the APK, and never logged or shown (ATURAN.md section 4).
class KeyStore {
  static const _slot = 'sepolia_test_private_key';
  final _storage = const FlutterSecureStorage();

  Future<EthPrivateKey?> load() async {
    final hex = await _storage.read(key: _slot);
    return hex == null ? null : EthPrivateKey.fromHex(hex);
  }

  /// Imports a test account's key: 64 hex characters, with or without `0x`.
  Future<EthPrivateKey> import(String input) async {
    final hex = input.trim().replaceFirst(RegExp('^0x', caseSensitive: false), '');
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hex)) {
      throw const FormatException('Private key harus 64 karakter heksadesimal.');
    }
    final key = EthPrivateKey.fromHex(hex);
    await _storage.write(key: _slot, value: hex);
    return key;
  }

  /// Generates a new key on this phone; it never leaves the device.
  Future<EthPrivateKey> createNew() async {
    final key = EthPrivateKey.createRandom(Random.secure());
    final hex = bytesToHex(key.privateKey);
    // createRandom's bytes can be 33 long (sign byte) or shorter than 32; store exactly 32.
    await _storage.write(key: _slot, value: hex.length > 64 ? hex.substring(hex.length - 64) : hex.padLeft(64, '0'));
    return key;
  }

  Future<void> delete() => _storage.delete(key: _slot);
}
