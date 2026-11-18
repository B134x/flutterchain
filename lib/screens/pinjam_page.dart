import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../logbook_controller.dart';

/// Borrow form. Pops right after sending; progress shows on the home screen.
class PinjamPage extends StatefulWidget {
  const PinjamPage({super.key});

  @override
  State<PinjamPage> createState() => _PinjamPageState();
}

class _PinjamPageState extends State<PinjamPage> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final tools = c.availableTools;
    final busy = c.tx?.busy ?? false;
    final selected = tools.where((a) => a.id == _selected).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Pinjam alat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!c.hasKey)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Atur wallet uji dulu di tab Wallet sebelum mengirim transaksi.'),
              ),
            ),
          if (tools.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Tidak ada alat yang tersedia saat ini.'),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: selected?.id,
              decoration: const InputDecoration(labelText: 'Alat', border: OutlineInputBorder()),
              items: [
                for (final tool in tools) DropdownMenuItem(value: tool.id, child: Text(tool.nama)),
              ],
              onChanged: (id) => setState(() => _selected = id),
            ),
          const SizedBox(height: 16),
          Text(
            'Peminjaman dicatat permanen dan dapat dibaca siapa saja di Sepolia, bersama alamat wallet '
            'Anda. Aplikasi tidak menyimpan nama atau NIM di blockchain.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: selected == null || !c.hasKey || busy
                ? null
                : () {
                    unawaited(c.borrow(selected));
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.send),
            label: const Text('Kirim transaksi pinjam'),
          ),
        ],
      ),
    );
  }
}
