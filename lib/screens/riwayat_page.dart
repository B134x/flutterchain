import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../logbook_controller.dart';
import '../models.dart';
import '../util/format.dart';
import '../widgets/confirm.dart';

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
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final f in LoanFilter.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: c.filter == f,
                  onSelected: f == LoanFilter.milikSaya && !c.hasKey ? null : (_) => c.setFilter(f),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (loans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                c.loans.isEmpty ? 'Belum ada peminjaman.' : 'Tidak ada peminjaman untuk filter ini.',
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
      child: ListTile(
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
        trailing: canReturn
            ? FilledButton.tonal(
                onPressed: c.tx?.busy ?? false ? null : () => _giveBack(context, c, toolName),
                child: const Text('Kembalikan'),
              )
            : null,
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
