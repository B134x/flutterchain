import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';

/// The RPC URL and contract address saved from the Koneksi screen; they take priority over `.env`.
/// Kept in encrypted storage because a provider RPC URL contains an API key.
class ConnectionStore {
  static const _rpcSlot = 'rpc_url';
  static const _contractSlot = 'contract_address';
  final _storage = const FlutterSecureStorage();

  /// Null when nothing is saved, so the `.env` values apply.
  Future<({String rpcUrl, String contract})?> load() async {
    final rpc = await _storage.read(key: _rpcSlot);
    final contract = await _storage.read(key: _contractSlot);
    if (rpc == null || contract == null) return null;
    return (rpcUrl: rpc, contract: contract);
  }

  Future<void> save(Connection connection) async {
    await _storage.write(key: _rpcSlot, value: connection.rpcUrl);
    await _storage.write(key: _contractSlot, value: connection.contract.eip55With0x);
  }

  Future<void> clear() async {
    await _storage.delete(key: _rpcSlot);
    await _storage.delete(key: _contractSlot);
  }
}
