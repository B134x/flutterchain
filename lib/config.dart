import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wallet/wallet.dart';

/// Values from the single `.env` file (see `.env.example`). The RPC URL and contract address
/// are defaults that the Koneksi screen can override on the device.
class AppConfig {
  const AppConfig({
    required this.chainId,
    required this.loanLimit,
    required this.envRpcUrl,
    required this.envContract,
  });

  /// The only chain this app may talk to.
  static const sepoliaChainId = 11155111;
  static const etherscanBase = 'https://sepolia.etherscan.io';
  static const abiAsset = 'assets/abi/LogbookAlat.json';

  final int chainId;

  /// A loan open longer than this is shown as overdue.
  final Duration loanLimit;

  /// Raw `.env` values; either may be empty, in which case the app asks on the Koneksi screen.
  final String envRpcUrl;
  final String envContract;

  /// Throws [ConfigError] if `.env` is missing or CHAIN_ID is not Sepolia.
  static Future<AppConfig> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      throw const ConfigError('.env tidak ditemukan atau kosong. Salin .env.example menjadi .env lalu build ulang.');
    }

    final chainId = int.tryParse(dotenv.maybeGet('CHAIN_ID')?.trim() ?? '');
    if (chainId != sepoliaChainId) {
      throw const ConfigError('CHAIN_ID di .env harus 11155111 (Sepolia). Jaringan lain tidak diizinkan.');
    }

    final hours = int.tryParse(dotenv.maybeGet('LOAN_LIMIT_HOURS')?.trim() ?? '') ?? 24;

    return AppConfig(
      chainId: chainId!,
      loanLimit: Duration(hours: hours),
      envRpcUrl: dotenv.maybeGet('RPC_URL')?.trim() ?? '',
      envContract: dotenv.maybeGet('CONTRACT_ADDRESS')?.trim() ?? '',
    );
  }

  Uri txUrl(String hash) => Uri.parse('$etherscanBase/tx/$hash');
  Uri addressUrl(EthereumAddress address) => Uri.parse('$etherscanBase/address/${address.eip55With0x}');
}

/// An RPC endpoint and the LogbookAlat contract reached through it.
class Connection {
  const Connection(this.rpcUrl, this.contract);

  final String rpcUrl;
  final EthereumAddress contract;

  /// Throws [FormatException] with a readable message for a malformed URL or address.
  static Connection parse(String rpcUrl, String address) {
    final rpc = rpcUrl.trim();
    final uri = Uri.tryParse(rpc);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('RPC URL harus berupa alamat https://');
    }
    final EthereumAddress contract;
    try {
      contract = EthereumAddress.fromHex(address.trim());
    } catch (_) {
      throw const FormatException('Alamat kontrak harus 0x diikuti 40 karakter heksadesimal.');
    }
    return Connection(rpc, contract);
  }
}

class ConfigError implements Exception {
  const ConfigError(this.message);
  final String message;

  @override
  String toString() => message;
}
