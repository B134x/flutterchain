import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logbook_controller.dart';
import '../util/format.dart';
import '../widgets/confirm.dart';

/// Test wallet setup. The key is never displayed again after entry.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _input = TextEditingController();
  String? _inputError;
  bool _working = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _working = true;
      _inputError = null;
    });
    try {
      await action();
      _input.clear();
    } on FormatException catch (e) {
      _inputError = e.message;
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // The warning matters while a key can be entered; once a wallet exists it is noise.
        if (!c.hasKey) ...[
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Hanya untuk wallet uji di Sepolia. Jangan pernah memasukkan kunci wallet pribadi '
                'atau wallet yang pernah berisi aset.',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (c.hasKey) ..._walletInfo(context, c) else ..._walletSetup(context, c),
      ],
    );
  }

  List<Widget> _walletInfo(BuildContext context, LogbookController c) {
    final address = c.myAddress!;
    final theme = Theme.of(context);
    return [
      Text('Alamat wallet uji', style: theme.textTheme.titleSmall),
      Row(
        children: [
          Expanded(child: SelectableText(address.eip55With0x)),
          IconButton(
            tooltip: 'Salin alamat',
            icon: const Icon(Icons.content_copy),
            onPressed: () => Clipboard.setData(ClipboardData(text: address.eip55With0x)),
          ),
        ],
      ),
      if (c.isAdmin) const Chip(avatar: Icon(Icons.verified_user_outlined), label: Text('Admin kontrak')),
      const SizedBox(height: 8),
      Text('Saldo: ${c.balance == null ? '-' : formatEth(c.balance!)}', style: theme.textTheme.titleMedium),
      if (c.balance?.getInWei == BigInt.zero)
        Text(
          'Isi saldo dengan Sepolia ETH dari faucet, atau kirim dari akun MetaMask uji ke alamat di atas.',
          style: theme.textTheme.bodySmall,
        ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => launchUrl(c.config.addressUrl(address), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Etherscan'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: () async {
              final ok = await confirmTransaction(
                context,
                title: 'Hapus kunci dari HP ini?',
                body: 'Kunci tidak bisa dipulihkan dari aplikasi. Saldo di alamat ini hanya bisa dipakai '
                    'lagi jika kunci yang sama diimpor kembali.',
                action: 'Hapus',
                destructive: true,
              );
              if (ok) await c.deleteKey();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus kunci'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text('Kunci tersimpan terenkripsi di HP ini dan tidak pernah ditampilkan.', style: theme.textTheme.bodySmall),
    ];
  }

  List<Widget> _walletSetup(BuildContext context, LogbookController c) {
    final theme = Theme.of(context);
    return [
      Text('Buat wallet uji di HP ini', style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      const Text('Kunci dibuat dan disimpan di HP, tidak pernah keluar. Setelah itu isi saldonya '
          'dengan mengirim Sepolia ETH dari MetaMask ke alamat yang muncul.'),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _working ? null : () => _run(c.createKey),
        icon: const Icon(Icons.add_moderator_outlined),
        label: const Text('Buat wallet uji'),
      ),
      const SizedBox(height: 24),
      Text('Atau impor private key akun uji MetaMask', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      TextField(
        controller: _input,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: 'Private key (64 karakter heks)',
          border: const OutlineInputBorder(),
          errorText: _inputError,
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.tonal(
        onPressed: _working ? null : () => _run(() => c.importKey(_input.text)),
        child: const Text('Simpan kunci'),
      ),
    ];
  }
}
