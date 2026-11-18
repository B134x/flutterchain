import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'config.dart';
import 'models.dart';
import 'services/connection_store.dart';
import 'services/key_store.dart';
import 'services/logbook_service.dart';
import 'util/error_message.dart';

/// [needsSetup]: no RPC URL or contract address yet, so the app waits for the Koneksi screen.
enum LoadStatus { loading, ready, failed, needsSetup }

enum LoanFilter {
  semua('Semua'),
  dipinjam('Dipinjam'),
  kembali('Sudah kembali'),
  milikSaya('Milik saya');

  const LoanFilter(this.label);
  final String label;
}

enum TxStage { sending, waiting, success, failed }

/// The state of the latest transaction, shown by `TxStatusCard`.
class TxStatus {
  const TxStatus(this.stage, this.label, {this.hash, this.message, this.fee});

  final TxStage stage;

  /// What the transaction does, e.g. "Meminjam ESP32-S3 #1".
  final String label;
  final String? hash;
  final String? message;

  /// Gas actually paid: gasUsed × effectiveGasPrice from the receipt.
  final EtherAmount? fee;

  bool get busy => stage == TxStage.sending || stage == TxStage.waiting;
}

/// App state and actions. Screens read it through [LogbookScope].
class LogbookController extends ChangeNotifier {
  LogbookController(this.config);

  final AppConfig config;
  final _keys = KeyStore();
  final _connections = ConnectionStore();
  LogbookService? _service;

  LoadStatus status = LoadStatus.loading;
  String? error;

  /// The RPC URL and contract address in use or last tried, as typed; shown on the Koneksi screen.
  String rpcUrl = '';
  String contractText = '';

  /// True when the connection comes from the Koneksi screen instead of `.env`.
  bool usingSavedConnection = false;

  List<Alat> tools = const [];

  /// Newest first.
  List<Peminjaman> loans = const [];
  EthereumAddress? admin;
  EtherAmount? balance;
  TxStatus? tx;
  LoanFilter filter = LoanFilter.semua;

  /// True while event polling works; false if the RPC refuses log queries.
  bool liveUpdates = false;

  /// Increments whenever new contract events arrive; [lastEvent] describes them.
  int eventCount = 0;
  String? lastEvent;

  EthPrivateKey? _key;
  Timer? _eventTimer;
  bool _checkingEvents = false;
  bool _disposed = false;

  EthereumAddress? get contract => _service?.connection.contract;
  EthereumAddress? get myAddress => _key?.address;
  bool get hasKey => _key != null;
  bool get isAdmin => myAddress != null && myAddress == admin;
  List<Alat> get availableTools => tools.where((a) => a.bisaDipinjam).toList();

  Alat? toolById(int id) => id >= 0 && id < tools.length ? tools[id] : null;

  List<Peminjaman> get filteredLoans => switch (filter) {
        LoanFilter.semua => loans,
        LoanFilter.dipinjam => loans.where((p) => !p.dikembalikan).toList(),
        LoanFilter.kembali => loans.where((p) => p.dikembalikan).toList(),
        LoanFilter.milikSaya => loans.where((p) => p.milik(myAddress)).toList(),
      };

  void setFilter(LoanFilter value) {
    filter = value;
    _notify();
  }

  Future<void> start() async {
    status = LoadStatus.loading;
    error = null;
    _notify();
    try {
      _key = await _keys.load();
      final saved = await _connections.load();
      usingSavedConnection = saved != null;
      rpcUrl = saved?.rpcUrl ?? config.envRpcUrl;
      contractText = saved?.contract ?? config.envContract;
    } catch (e) {
      _fail(errorMessage(e));
      return;
    }
    if (rpcUrl.isEmpty || contractText.isEmpty) {
      status = LoadStatus.needsSetup;
      _notify();
      return;
    }
    final problem = await _connect(rpcUrl, contractText);
    if (problem != null) _fail(problem);
  }

  /// Checks the connection, saves it over `.env`, and switches to it.
  /// Returns a readable error, or null on success; on error the current connection stays.
  Future<String?> saveConnection(String rpc, String address) async {
    if (tx?.busy ?? false) return 'Tunggu transaksi yang sedang berjalan selesai dulu.';
    final problem = await _connect(rpc, address);
    if (problem != null) return problem;
    final connection = _service!.connection;
    rpcUrl = connection.rpcUrl;
    contractText = connection.contract.eip55With0x;
    try {
      await _connections.save(connection);
      usingSavedConnection = true;
    } catch (e) {
      return 'Terhubung, tetapi gagal menyimpan pengaturan: ${errorMessage(e)}';
    } finally {
      _notify();
    }
    return null;
  }

  /// Forgets the saved connection and reconnects with the `.env` values.
  Future<String?> useEnvConnection() async {
    if (tx?.busy ?? false) return 'Tunggu transaksi yang sedang berjalan selesai dulu.';
    await _connections.clear();
    usingSavedConnection = false;
    rpcUrl = config.envRpcUrl;
    contractText = config.envContract;
    if (rpcUrl.isEmpty || contractText.isEmpty) {
      await _disconnect();
      status = LoadStatus.needsSetup;
      _notify();
      return null;
    }
    final problem = await _connect(rpcUrl, contractText);
    if (problem != null) {
      await _disconnect();
      _fail(problem);
    }
    return problem;
  }

  /// Validates [rpc] and [address] on a fresh client before replacing the current one.
  Future<String?> _connect(String rpc, String address) async {
    final LogbookService next;
    try {
      next = LogbookService(Connection.parse(rpc, address), chainId: config.chainId);
    } on FormatException catch (e) {
      return e.message;
    }
    try {
      await next.init();
    } catch (e) {
      await next.dispose();
      return errorMessage(e);
    }
    await _service?.dispose();
    _service = next;
    _clearData();
    await refresh();
    _eventTimer ??= Timer.periodic(const Duration(seconds: 6), (_) => _checkEvents());
    return null;
  }

  Future<void> _disconnect() async {
    await _service?.dispose();
    _service = null;
    _clearData();
  }

  void _clearData() {
    admin = null;
    tools = const [];
    loans = const [];
    balance = null;
    liveUpdates = false;
  }

  void _fail(String message) {
    status = LoadStatus.failed;
    error = message;
    _notify();
  }

  /// On failure the old data stays visible.
  Future<void> refresh() async {
    final service = _service;
    if (service == null) {
      _notify();
      return;
    }
    try {
      final me = myAddress;
      final results = await Future.wait<Object>([
        service.admin(),
        service.allTools(),
        service.allLoans(),
        if (me != null) service.balance(me),
      ]);
      admin = results[0] as EthereumAddress;
      tools = results[1] as List<Alat>;
      loans = (results[2] as List<Peminjaman>).reversed.toList();
      balance = me != null ? results[3] as EtherAmount : null;
      status = LoadStatus.ready;
      error = null;
    } catch (e) {
      error = errorMessage(e);
      if (status != LoadStatus.ready) status = LoadStatus.failed;
    }
    _notify();
  }

  Future<void> borrow(Alat tool) => _send('pinjam', [BigInt.from(tool.id)], 'Meminjam ${tool.nama}');

  Future<void> giveBack(Peminjaman loan) => _send(
        'kembalikan',
        [BigInt.from(loan.id)],
        'Mengembalikan ${toolById(loan.alatId)?.nama ?? 'alat #${loan.alatId}'}',
      );

  Future<void> _send(String function, List<dynamic> params, String label) async {
    final key = _key;
    final service = _service;
    if (tx?.busy ?? false) return;
    if (key == null || service == null) {
      tx = TxStatus(TxStage.failed, label,
          message: key == null ? 'Atur wallet uji dulu di tab Wallet.' : 'Belum terhubung ke kontrak.');
      _notify();
      return;
    }

    tx = TxStatus(TxStage.sending, label);
    _notify();
    String? hash;
    try {
      hash = await service.send(key, function, params);
      tx = TxStatus(TxStage.waiting, label, hash: hash);
      _notify();

      final receipt = await service.waitForReceipt(hash);
      final gasUsed = receipt.gasUsed;
      final price = receipt.effectiveGasPrice;
      final fee = gasUsed != null && price != null ? EtherAmount.inWei(gasUsed * price.getInWei) : null;
      tx = receipt.status == false
          ? TxStatus(TxStage.failed, label,
              hash: hash, fee: fee, message: 'Transaksi masuk blok tetapi ditolak kontrak (revert).')
          : TxStatus(TxStage.success, label, hash: hash, fee: fee);
    } catch (e) {
      tx = TxStatus(TxStage.failed, label, hash: hash, message: errorMessage(e));
    }
    _notify();
    await refresh();
  }

  void dismissTx() {
    if (tx?.busy ?? false) return;
    tx = null;
    _notify();
  }

  /// Throws [FormatException] for a malformed key; the wallet screen shows it.
  Future<void> importKey(String input) async {
    _key = await _keys.import(input);
    await refresh();
  }

  Future<void> createKey() async {
    _key = await _keys.createNew();
    await refresh();
  }

  Future<void> deleteKey() async {
    await _keys.delete();
    _key = null;
    balance = null;
    _notify();
  }

  static const _eventNames = {
    'Dipinjam': 'peminjaman baru',
    'Dikembalikan': 'pengembalian',
    'AlatDitambah': 'alat baru',
    'AlatDiubah': 'perubahan alat',
  };

  Future<void> _checkEvents() async {
    final service = _service;
    if (service == null || _checkingEvents || status != LoadStatus.ready) return;
    _checkingEvents = true;
    try {
      final events = await service.newEvents();
      if (!liveUpdates) {
        liveUpdates = true;
        _notify();
      }
      if (events.isNotEmpty) {
        final counts = <String, int>{};
        for (final name in events) {
          counts[name] = (counts[name] ?? 0) + 1;
        }
        lastEvent = counts.entries
            .where((e) => _eventNames.containsKey(e.key))
            .map((e) => '${e.value} ${_eventNames[e.key]}')
            .join(', ');
        eventCount++;
        await refresh();
      }
    } catch (_) {
      // Retried on the next tick; the indicator shows updates are paused.
      if (liveUpdates) {
        liveUpdates = false;
        _notify();
      }
    } finally {
      _checkingEvents = false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _eventTimer?.cancel();
    _service?.dispose();
    super.dispose();
  }
}

/// Gives every screen (including pushed routes) access to the controller.
class LogbookScope extends InheritedNotifier<LogbookController> {
  const LogbookScope({super.key, required LogbookController controller, required super.child})
      : super(notifier: controller);

  /// Rebuilds the caller when the state changes.
  static LogbookController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LogbookScope>()!.notifier!;

  /// For callbacks: no rebuild dependency.
  static LogbookController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LogbookScope>()!.notifier!;
}
