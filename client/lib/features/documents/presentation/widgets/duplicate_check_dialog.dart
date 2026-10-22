import 'package:flutter/material.dart';

enum DuplicateChoice { cancel, keepSeparate }

/// Phase 4.5 duplicate detection dialog:
/// A hash hit requires an explicit user choice. Never auto-merge, never auto-delete.
Future<DuplicateChoice?> showDuplicateCheckDialog({
  required BuildContext context,
  required int matchCount,
  required String sampleTitle,
}) {
  return showDialog<DuplicateChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Konten Identik Ditemukan'),
      content: Text(
        'Berkas ini identik dengan $matchCount dokumen tersimpan, '
        'mis. "$sampleTitle". '
        'Buat catatan terpisah atau batalkan impornya?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, DuplicateChoice.cancel),
          child: const Text('Batal'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(ctx, DuplicateChoice.keepSeparate),
          child: const Text('Buat Catatan Terpisah'),
        ),
      ],
    ),
  );
}
