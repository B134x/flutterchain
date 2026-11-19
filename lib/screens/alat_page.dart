import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../logbook_controller.dart';
import '../models.dart';
import '../widgets/confirm.dart';
import '../widgets/filter_row.dart';

class AlatPage extends StatelessWidget {
  const AlatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final tools = c.filteredTools;
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // Hints only when they explain something on screen: the admin's tools, or a disabled Pinjam button.
          if (c.isAdmin || !c.hasKey) ...[
            Text(
              c.isAdmin
                  ? 'Anda admin kontrak ini. Tambah atau ubah alat lewat Remix atau tab Write Contract '
                      'di Etherscan (tambahAlat, ubahAlat).'
                  : 'Tombol Pinjam aktif setelah wallet uji dibuat di tab Wallet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
          ],
          FilterRow<ToolFilter>(
            values: ToolFilter.values,
            selected: c.toolFilter,
            labelOf: (f) => f.label,
            onSelected: c.setToolFilter,
          ),
          const SizedBox(height: 8),
          if (tools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                c.tools.isEmpty
                    ? 'Belum ada alat. Admin menambahkannya lewat Remix atau Etherscan.'
                    : 'Tidak ada alat untuk filter ini. Pilih Semua untuk melihat seluruh katalog.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final tool in tools) _ToolCard(tool: tool),
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
    final canBorrow = tool.bisaDipinjam && c.hasKey && !(c.tx?.busy ?? false);

    return Card(
      child: ListTile(
        leading: Icon(Icons.memory, color: color),
        title: Text(tool.nama),
        subtitle: Text('#${tool.id} · $label', style: TextStyle(color: color)),
        // Always present, greyed out when the tool cannot be borrowed, so every row keeps the same shape.
        trailing: FilledButton(
          onPressed: canBorrow ? () => _borrow(context, c) : null,
          child: const Text('Pinjam'),
        ),
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
