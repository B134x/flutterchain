import 'dart:async';
import 'dart:convert';

import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

/// Turns RPC and network errors into a message a user can act on.
String errorMessage(Object error) {
  if (error is RPCError) {
    final reason = revertReason(error.message, error.data);
    if (reason != null) return 'Ditolak kontrak: $reason';
    final m = error.message.toLowerCase();
    if (m.contains('insufficient funds')) {
      return 'Saldo Sepolia ETH tidak cukup untuk biaya gas. Isi dari faucet atau MetaMask.';
    }
    if (m.contains('nonce too low') || m.contains('already known') || m.contains('underpriced')) {
      return 'Transaksi sebelumnya masih diproses. Tunggu sebentar lalu coba lagi.';
    }
    return 'RPC menolak permintaan: ${error.message}';
  }
  if (error is TimeoutException) {
    return 'Belum ada konfirmasi setelah 3 menit. Cek status transaksi di Etherscan.';
  }
  if (error is StateError) return error.message;
  if (error is FormatException) return error.message;
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException') || text.contains('Failed host lookup')) {
    return 'Tidak dapat menghubungi RPC. Periksa koneksi internet dan RPC_URL.';
  }
  return text;
}

/// The `require(...)` message, from the RPC error text or from the `Error(string)` data some nodes return.
String? revertReason(String message, Object? data) {
  final fromText = RegExp(r'execution reverted:?\s*(.*)$', caseSensitive: false).firstMatch(message);
  final text = fromText?.group(1)?.trim();
  if (text != null && text.isNotEmpty) return text;

  final hex = data is String ? data : (data is Map ? data['data'] : null);
  if (hex is String && hex.startsWith('0x08c379a0')) {
    final decoded = decodeErrorString(hex);
    if (decoded != null) return decoded;
  }
  return fromText != null ? 'transaksi akan gagal (revert)' : null;
}

/// Layout: 4-byte selector, 32-byte offset, 32-byte length, then the UTF-8 bytes.
String? decodeErrorString(String hex) {
  try {
    final body = hex.substring(10);
    final length = int.parse(body.substring(64, 128), radix: 16);
    return utf8.decode(hexToBytes(body.substring(128, 128 + length * 2)));
  } catch (_) {
    return null;
  }
}
