import 'package:material_ui/material_ui.dart';

/// Asks before anything that costs gas or cannot be undone. Dismissing counts as cancel.
Future<bool> confirmTransaction(
  BuildContext context, {
  required String title,
  required String body,
  String action = 'Kirim',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return result ?? false;
}
