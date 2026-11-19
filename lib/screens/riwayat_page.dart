import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../logbook_controller.dart';
import '../models.dart';
import '../util/format.dart';
import '../widgets/confirm.dart';
import '../widgets/filter_row.dart';

/// Loan history; returned loans are struck through.
class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final loans = c.filteredLoans;
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          FilterRow<LoanFilter>(
            values: LoanFilter.values,
            selected: c.filter,
            labelOf: (f) => f.label,
            onSelected: c.setFilter,
            enabled: (f) => f != LoanFilter.milikSaya || c.hasKey,
          ),
          if (!c.hasKey) ...[
            const SizedBox(height: 4),
            Text(
              'Filter Milik saya aktif setelah wallet uji dibuat di tab Wallet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: 8),
          if (loans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                c.loans.isEmpty
                    ? 'Belum ada peminjaman. Pinjam alat lewat tombol Pinjam alat di bawah atau dari tab Alat.'
                    : 'Tidak ada peminjaman untuk filter ini. Pilih Semua untuk melihat seluruh riwayat.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final loan in loans) _LoanCard(loan: loan),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});
  final Peminjaman loan;

  @override
  Widget build(BuildContext context) {
    final c = LogbookScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final overdue = loan.terlambat(c.config.loanLimit, now);
    final mine = loan.milik(c.myAddress);
    final canReturn = !loan.dikembalikan && (mine || c.isAdmin);
    final toolName = c.toolById(loan.alatId)?.nama ?? 'Alat #${loan.alatId}';

    final String state;
    if (loan.dikembalikan) {
      state = 'Kembali ${formatTime(loan.waktuKembali!)}';
    } else if (overdue) {
      state = 'Terlambat, sudah ${formatDuration(now.difference(loan.waktuPinjam))}';
    } else {
      state = 'Masih dipinjam (${formatDuration(now.difference(loan.waktuPinjam))})';
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(
              loan.dikembalikan ? Icons.check_circle : (overdue ? Icons.warning_amber : Icons.schedule),
              color: loan.dikembalikan ? scheme.primary : (overdue ? scheme.error : scheme.tertiary),
            ),
            title: Text(
              toolName,
              style: loan.dikembalikan
                  ? TextStyle(decoration: TextDecoration.lineThrough, color: scheme.onSurfaceVariant)
                  : null,
            ),
            subtitle: Text(
              'Peminjaman #${loan.id} · ${mine ? 'Anda' : shortAddress(loan.peminjam)}\n'
              'Dipinjam ${formatTime(loan.waktuPinjam)}\n$state',
            ),
            isThreeLine: true,
          ),
          // Below the text rather than beside it, so dates and status keep the full width.
          if (canReturn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: c.tx?.busy ?? false ? null : () => _giveBack(context, c, toolName),
                  child: const Text('Kembalikan'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _giveBack(BuildContext context, LogbookController c, String toolName) async {
    final ok = await confirmTransaction(
      context,
      title: 'Kembalikan $toolName?',
      body: 'Mengirim transaksi kembalikan(${loan.id}) ke Sepolia. Biaya gas dibayar dari wallet uji.',
    );
    if (ok) unawaited(c.giveBack(loan));
  }
}
