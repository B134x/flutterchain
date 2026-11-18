import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../config.dart';
import '../models.dart';

/// All blockchain access for one connection: free reads via `eth_call`, signed writes that cost gas,
/// events via logs.
class LogbookService {
  LogbookService(this.connection, {required this.chainId})
      : _client = Web3Client(connection.rpcUrl, http.Client());

  final Connection connection;
  final int chainId;
  final Web3Client _client;
  DeployedContract? _deployed;
  int? _lastBlock;

  DeployedContract get _contract => _deployed!;

  /// Loads the ABI, then checks that the RPC is Sepolia and the address holds a LogbookAlat contract.
  Future<void> init() async {
    if (_deployed == null) {
      final abi = await rootBundle.loadString(AppConfig.abiAsset);
      _deployed = DeployedContract(ContractAbi.fromJson(abi, 'LogbookAlat'), connection.contract);
    }
    final actualChain = await _client.getChainId();
    if (actualChain != BigInt.from(chainId)) {
      throw StateError('RPC ini terhubung ke chain $actualChain, bukan Sepolia ($chainId). '
          'Aplikasi tidak mau berjalan di jaringan lain.');
    }
    final code = bytesToHex(await _client.getCode(connection.contract));
    if (code.isEmpty) {
      throw StateError('Tidak ada kontrak di alamat ini pada Sepolia.');
    }
    // Every function selector sits in the contract's dispatcher, so a missing one means another contract.
    final isLogbook = _contract.functions
        .where((f) => !f.isConstructor)
        .every((f) => code.contains(bytesToHex(f.selector)));
    if (!isLogbook) {
      throw StateError('Kontrak di alamat ini bukan LogbookAlat.');
    }
  }

  Future<List<dynamic>> _read(String function, [List<dynamic> params = const []]) =>
      _client.call(contract: _contract, function: _contract.function(function), params: params);

  Future<EthereumAddress> admin() async => (await _read('admin')).first as EthereumAddress;

  Future<List<Alat>> allTools() async {
    final count = ((await _read('jumlahAlat')).first as BigInt).toInt();
    return Future.wait(List.generate(count, (i) async {
      final r = await _read('ambilAlat', [BigInt.from(i)]);
      return Alat(id: i, nama: r[0] as String, tersedia: r[1] as bool, aktif: r[2] as bool);
    }));
  }

  Future<List<Peminjaman>> allLoans() async {
    final count = ((await _read('jumlahPeminjaman')).first as BigInt).toInt();
    return Future.wait(List.generate(count, (i) async {
      final r = await _read('ambilPeminjaman', [BigInt.from(i)]);
      final returnedAt = r[3] as BigInt;
      return Peminjaman(
        id: i,
        alatId: (r[0] as BigInt).toInt(),
        peminjam: r[1] as EthereumAddress,
        waktuPinjam: dariTimestamp(r[2] as BigInt),
        waktuKembali: returnedAt == BigInt.zero ? null : dariTimestamp(returnedAt),
      );
    }));
  }

  Future<EtherAmount> balance(EthereumAddress address) => _client.getBalance(address);

  /// Returns the transaction hash. The gas estimate simulates the call first,
  /// so a call the contract would reject fails here, before anything is paid.
  Future<String> send(Credentials key, String function, List<dynamic> params) =>
      _client.sendTransaction(
        key,
        Transaction.callContract(
          contract: _contract,
          function: _contract.function(function),
          parameters: params,
        ),
        // web3dart defaults to chainId 1 (mainnet); always sign for Sepolia.
        chainId: chainId,
      );

  /// Polls for the receipt until the transaction is mined (Sepolia: about 12 s per block).
  Future<TransactionReceipt> waitForReceipt(String hash, {Duration limit = const Duration(minutes: 3)}) async {
    final deadline = DateTime.now().add(limit);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final receipt = await _client.getTransactionReceipt(hash);
        if (receipt != null) return receipt;
      } catch (_) {
        // A dropped request while waiting is not a failed transaction; keep polling.
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    throw TimeoutException('Transaksi belum masuk blok', limit);
  }

  /// Names of contract events since the last call; the first call only records the block.
  /// Not web3dart's `events()`: its polling errors never reach the stream, so updates stop silently.
  Future<List<String>> newEvents() async {
    final latest = await _client.getBlockNumber();
    final from = _lastBlock;
    if (from == null || latest <= from) {
      _lastBlock = latest;
      return const [];
    }
    // Providers cap log ranges, so after a long pause skip the backlog and resync.
    if (latest - from > 500) {
      _lastBlock = latest;
      return const ['sinkron'];
    }
    final logs = await _client.getLogs(FilterOptions(
      address: _contract.address,
      fromBlock: BlockNum.exact(from + 1),
      toBlock: BlockNum.exact(latest),
    ));
    _lastBlock = latest; // only after a successful read, so a failed poll skips nothing
    return [
      for (final log in logs)
        for (final event in _contract.events)
          if (log.topics?.firstOrNull == bytesToHex(event.signature, include0x: true)) event.name,
    ];
  }

  Future<void> dispose() => _client.dispose();
}
