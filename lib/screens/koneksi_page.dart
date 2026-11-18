import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logbook_controller.dart';
import '../util/format.dart';

/// RPC URL and contract address, saved on this phone over the `.env` defaults.
/// The chain is fixed to Sepolia and cannot be changed here.
class KoneksiPage extends StatefulWidget {
  const KoneksiPage({super.key});

  @override
  State<KoneksiPage> createState() => _KoneksiPageState();
}

class _KoneksiPageState extends State<KoneksiPage> {
  final _rpc = TextEditingController();
  final _contract = TextEditingController();
  bool _filled = false;
  bool _showRpc = false;
  bool _working = false;
  String? _problem;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    final c = LogbookScope.read(context);
    _rpc.text = c.rpcUrl;
    _contract.text = c.contractText;
    _filled = true;
  }

  @override
  void dispose() {
    _rpc.dispose();
    _contract.dispose();
    super.dispose();
  }

  Future<void> _apply(Future<String?> Function() action, {required bool fillFromController}) async {
    setState(() {
      _working = true;
      _problem = null;
    });
    final c = LogbookScope.read(context);
    final problem = await action();
    if (!mounted) return;
    setState(() {
      _working = false;
      _problem = problem;
      if (fillFromController) {
        _rpc.text = c.rpcUrl;
        _contract.text = c.contractText;
      }
    });
    final address = c.contract;
    if (problem == null && address != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terhubung ke kontrak ${shortAddress(address)}')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final theme = Theme.of(context);
    final txBusy = c.tx?.busy ?? false;
    final locked = _working || txBusy;
    final address = c.contract;

    return Scaffold(
      appBar: AppBar(title: const Text('Koneksi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Jaringan', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Ethereum Sepolia · chain ID ${c.config.chainId}'),
          Text('Terkunci. Aplikasi hanya berjalan di testnet Sepolia.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          TextField(
            controller: _rpc,
            enabled: !locked,
            obscureText: !_showRpc,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'RPC URL',
              hintText: 'https://...',
              helperText: 'URL Alchemy atau Infura berisi API key. Disimpan terenkripsi di HP ini.',
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _showRpc ? 'Sembunyikan RPC URL' : 'Tampilkan RPC URL',
                icon: Icon(_showRpc ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _showRpc = !_showRpc),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contract,
            enabled: !locked,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Alamat kontrak LogbookAlat',
              hintText: '0x...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.usingSavedConnection ? 'Sumber: disimpan di aplikasi' : 'Sumber: .env',
            style: theme.textTheme.bodySmall,
          ),
          if (_problem != null) ...[
            const SizedBox(height: 16),
            _Problem(message: _problem!),
          ],
          if (txBusy) ...[
            const SizedBox(height: 16),
            const Text('Tunggu transaksi yang sedang berjalan selesai sebelum mengganti koneksi.'),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: locked
                ? null
                : () => _apply(() => c.saveConnection(_rpc.text, _contract.text), fillFromController: false),
            child: _working
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Memeriksa kontrak...'),
                    ],
                  )
                : const Text('Simpan dan sambungkan'),
          ),
          if (c.usingSavedConnection) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: locked ? null : () => _apply(c.useEnvConnection, fillFromController: true),
              child: const Text('Kembali ke nilai .env'),
            ),
          ],
          if (address != null && c.status == LoadStatus.ready) ...[
            const Divider(height: 40),
            Text('Terhubung', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(address.eip55With0x),
            if (c.admin != null) Text('Admin: ${shortAddress(c.admin!)}', style: theme.textTheme.bodySmall),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => launchUrl(c.config.addressUrl(address), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Lihat kontrak di Etherscan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer))),
        ],
      ),
    );
  }
}
