import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../logbook_controller.dart';
import '../models.dart';
import '../widgets/confirm.dart';

class AlatPage extends StatelessWidget {
  const AlatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          Text(
            c.isAdmin
                ? 'Anda admin kontrak ini. Tambah atau ubah alat lewat Remix (tambahAlat, ubahAlat).'
                : 'Katalog alat dikelola admin lab. Pilih alat yang tersedia untuk dipinjam.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (c.tools.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text('Belum ada alat. Admin menambahkannya lewat Remix.', textAlign: TextAlign.center),
            ),
          for (final tool in c.tools) _ToolCard(tool: tool),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});
  final Alat tool;

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = !tool.aktif
        ? ('Nonaktif', scheme.outline)
        : tool.tersedia
            ? ('Tersedia', scheme.primary)
            : ('Sedang dipinjam', scheme.tertiary);

    return Card(
      child: ListTile(
        leading: Icon(Icons.memory, color: color),
        title: Text(tool.nama),
        subtitle: Text('#${tool.id} · $label', style: TextStyle(color: color)),
        trailing: tool.bisaDipinjam
            ? FilledButton(
                onPressed: !c.hasKey || (c.tx?.busy ?? false) ? null : () => _borrow(context, c),
                child: const Text('Pinjam'),
              )
            : null,
      ),
    );
  }

  Future<void> _borrow(BuildContext context, LogbookController c) async {
    final ok = await confirmTransaction(
      context,
      title: 'Pinjam ${tool.nama}?',
      body: 'Mengirim transaksi pinjam(${tool.id}) ke Sepolia. Peminjaman dicatat permanen dan publik '
          'bersama alamat wallet Anda. Biaya gas dibayar dari wallet uji.',
    );
    if (ok) unawaited(c.borrow(tool));
  }
}
