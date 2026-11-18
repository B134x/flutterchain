import 'package:material_ui/material_ui.dart';

import '../logbook_controller.dart';
import '../widgets/tx_status_card.dart';
import 'alat_page.dart';
import 'koneksi_page.dart';
import 'pinjam_page.dart';
import 'riwayat_page.dart';
import 'wallet_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  int _eventsSeen = 0;
  LogbookController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = LogbookScope.read(context);
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_onChange);
      _controller = controller..addListener(_onChange);
      _eventsSeen = controller.eventCount;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChange);
    super.dispose();
  }

  /// Tells the user when the list updated itself because of a contract event.
  void _onChange() {
    final c = _controller!;
    if (c.eventCount == _eventsSeen) return;
    _eventsSeen = c.eventCount;
    final what = c.lastEvent;
    if (what == null || what.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Event baru dari kontrak: $what')));
  }

  void _openKoneksi() =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KoneksiPage()));

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final ready = c.status == LoadStatus.ready;
    // The Wallet tab works without a contract; the other two wait for a connection.
    final notConnected = _NotConnected(onOpenKoneksi: _openKoneksi);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook Alat Lab IoT'),
        actions: [
          if (ready)
            Tooltip(
              message: c.liveUpdates
                  ? 'Pembaruan otomatis aktif (event kontrak)'
                  : 'Pembaruan otomatis terhenti; tarik untuk memuat ulang',
              child: Icon(c.liveUpdates ? Icons.sensors : Icons.sensors_off),
            ),
          if (ready)
            IconButton(tooltip: 'Muat ulang', icon: const Icon(Icons.refresh), onPressed: c.refresh),
          IconButton(tooltip: 'Koneksi', icon: const Icon(Icons.link), onPressed: _openKoneksi),
        ],
      ),
      body: Column(
        children: [
          if (c.tx != null) TxStatusCard(status: c.tx!, config: c.config, onClose: c.dismissTx),
          if (ready && c.error != null) _ErrorStrip(message: c.error!),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                ready ? const RiwayatPage() : notConnected,
                ready ? const AlatPage() : notConnected,
                const WalletPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ready && _tab < 2
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Pinjam alat'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PinjamPage()),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.handyman_outlined), label: 'Alat'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
        ],
      ),
    );
  }
}

/// Riwayat and Alat while there is no working contract connection: loading, not set up, or failed.
class _NotConnected extends StatelessWidget {
  const _NotConnected({required this.onOpenKoneksi});
  final VoidCallback onOpenKoneksi;

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final theme = Theme.of(context);

    if (c.status == LoadStatus.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menghubungkan ke Sepolia...'),
          ],
        ),
      );
    }

    final setup = c.status == LoadStatus.needsSetup;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Icon(setup ? Icons.link_off : Icons.cloud_off, size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          setup ? 'Belum terhubung ke kontrak' : 'Gagal terhubung',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          setup
              ? 'Masukkan alamat kontrak LogbookAlat di halaman Koneksi. Wallet uji sudah bisa diatur di tab Wallet.'
              : c.error ?? 'Penyebabnya tidak diketahui.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            if (!setup) FilledButton.icon(onPressed: c.start, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
            setup
                ? FilledButton.icon(onPressed: onOpenKoneksi, icon: const Icon(Icons.link), label: const Text('Atur koneksi'))
                : OutlinedButton.icon(onPressed: onOpenKoneksi, icon: const Icon(Icons.link), label: const Text('Atur koneksi')),
          ],
        ),
      ],
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  const _ErrorStrip({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
    );
  }
}
