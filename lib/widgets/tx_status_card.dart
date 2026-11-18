import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../logbook_controller.dart';
import '../util/format.dart';

class TxStatusCard extends StatelessWidget {
  const TxStatusCard({super.key, required this.status, required this.config, required this.onClose});

  final TxStatus status;
  final AppConfig config;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (title, background, foreground) = switch (status.stage) {
      TxStage.sending => ('Mengirim transaksi...', scheme.surfaceContainerHighest, scheme.onSurface),
      TxStage.waiting => ('Menunggu konfirmasi blok...', scheme.surfaceContainerHighest, scheme.onSurface),
      TxStage.success => ('Transaksi berhasil', scheme.primaryContainer, scheme.onPrimaryContainer),
      TxStage.failed => ('Transaksi gagal', scheme.errorContainer, scheme.onErrorContainer),
    };
    final hash = status.hash;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: switch (status.stage) {
                  TxStage.sending || TxStage.waiting =>
                    const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  TxStage.success => Icon(Icons.check_circle, color: foreground),
                  TxStage.failed => Icon(Icons.error_outline, color: foreground),
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(status.label),
                    if (status.message != null) ...[const SizedBox(height: 4), Text(status.message!)],
                    if (status.fee != null) Text('Biaya gas: ${formatEth(status.fee!, digits: 7)}'),
                    if (hash != null)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Hash: ${shortHash(hash)}'),
                          IconButton(
                            tooltip: 'Salin hash',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.content_copy, size: 18, color: foreground),
                            onPressed: () => Clipboard.setData(ClipboardData(text: hash)),
                          ),
                          TextButton(
                            onPressed: () => launchUrl(config.txUrl(hash), mode: LaunchMode.externalApplication),
                            child: const Text('Lihat di Etherscan'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!status.busy)
                IconButton(
                  tooltip: 'Tutup',
                  icon: Icon(Icons.close, color: foreground),
                  onPressed: onClose,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
