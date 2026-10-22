import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/presentation/providers/auth_providers.dart';
import 'metrics_providers.dart';

/// Ringkasan Produktivitas — the local self-view required by Rev. 2 P0.4.
///
/// Three design rules, all of which come from the plan rather than taste:
///
/// 1. **Unknown is shown as unknown.** A metric with no data renders
///    "Belum cukup data", never `0`. Zero would tell the user they are slow;
///    the truth is that nothing has been measured yet.
/// 2. **The limits are on the screen, not just in a doc.** Two of the PRD's
///    four metrics are not producible by this architecture (see
///    docs/METRICS.md §1 and §2 M1/M4), and that is stated here where a user
///    would otherwise assume the numbers above are the whole story.
/// 3. **Nothing is transmitted.** The opt-in switch below persists a
///    preference; no reporting endpoint exists in P0–P6, and the UI says so.
class ProductivitySummaryScreen extends ConsumerStatefulWidget {
  const ProductivitySummaryScreen({super.key});

  @override
  ConsumerState<ProductivitySummaryScreen> createState() =>
      _ProductivitySummaryScreenState();
}

class _ProductivitySummaryScreenState
    extends ConsumerState<ProductivitySummaryScreen> {
  /// Default-off, matching the documented semantics: no stored value means
  /// disabled. Corrected by [_loadReportingPreference] a microtask later.
  ///
  /// This is deliberately NOT a nullable with an indeterminate progress
  /// indicator. Reading one key from the platform keystore is not a waitable
  /// operation from the user's point of view, and a `LinearProgressIndicator`
  /// here animates forever — which is also what made this screen untestable
  /// with `pumpAndSettle`.
  bool _reportingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadReportingPreference();
  }

  Future<void> _loadReportingPreference() async {
    final enabled = await ref
        .read(tokenStorageServiceProvider)
        .isUsageReportingEnabled();
    if (!mounted || enabled == _reportingEnabled) return;
    setState(() => _reportingEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(productivitySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ringkasan Produktivitas')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorNotice(onRetry: () => ref.invalidate(productivitySummaryProvider)),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _IntroCard(),
            const SizedBox(height: 16),
            Text('Kecepatan menemukan dokumen',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MetricTile(
              label: 'Median waktu dari pencarian ke membuka',
              value: data.medianTimeToOpenMs == null
                  ? _unknown
                  : '${data.medianTimeToOpenMs} ms',
              helper: 'Sinyal utama untuk target PRD "kurangi waktu cari 50 %".',
            ),
            _MetricTile(
              label: 'Median waktu proses pencarian',
              value: data.medianSearchLatencyMs == null
                  ? _unknown
                  : '${data.medianSearchLatencyMs} ms',
              helper: 'Diukur dari filter diterapkan sampai halaman pertama tampil.',
            ),
            _MetricTile(
              label: 'Pencarian yang berujung membuka dokumen',
              value: data.searchSuccessRate == null
                  ? _unknown
                  : '${(data.searchSuccessRate! * 100).toStringAsFixed(0)} %',
              helper: 'Lebih jujur daripada kecepatan murni: pencarian yang diabaikan berarti hasilnya tidak berguna.',
            ),
            const SizedBox(height: 16),
            Text('Kesalahan pengelolaan dokumen',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MetricTile(
              label: 'Konten identik terdeteksi',
              value: '${data.duplicatesDetected}',
              helper: 'Pemeriksaan hash Phase 4.5. Setiap keputusan dicatat, termasuk membatalkan.',
            ),
            _MetricTile(
              label: 'Temuan integritas berkas',
              value: '${data.integrityFindings}',
              helper: 'Berkas hilang atau isinya berubah di luar aplikasi.',
            ),
            _MetricTile(
              label: 'Koreksi metadata',
              value: '${data.metadataEdits}',
              helper: 'Koreksi kategori dalam 7 hari sejak impor dihitung sebagai salah simpan.',
            ),
            const SizedBox(height: 16),
            Text('Aktivitas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MetricTile(
              label: 'Hari aktif (30 hari)',
              value: '${data.daysActive}',
              helper: 'Hanya untuk Anda sendiri. Ini BUKAN angka adopsi organisasi.',
            ),
            _MetricTile(
              label: 'Dokumen dibuka',
              value: '${data.openedDocuments}',
            ),
            const SizedBox(height: 24),
            const _WhatIsNotMeasuredCard(),
            const SizedBox(height: 16),
            _PrivacyCard(
              rowsStored: data.rowsStored,
              pendingReportRows: data.pendingReportRows,
              reportingEnabled: _reportingEnabled,
              onToggle: (value) => _setReporting(value),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(productivitySummaryProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setReporting(bool enabled) async {
    await ref.read(tokenStorageServiceProvider).setUsageReportingEnabled(enabled);
    // Keep the live service honest so a flag set here is reflected in rows
    // written after this point.
    ref.read(metricsServiceProvider).reportingEnabled = enabled;
    if (!mounted) return;
    setState(() => _reportingEnabled = enabled);
  }
}

const String _unknown = 'Belum cukup data';

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Angka di layar ini hanya ada di perangkat ini',
                    style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RDMS Ultimate adalah perpustakaan dokumen pribadi. Perhitungan '
            'dibuat lokal dari 30 hari terakhir dan tidak dikirim ke mana pun. '
            'Isi dokumen Anda tidak pernah ikut tercatat.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Honesty requirement (plan §0.1 commitment 7): the metrics this architecture
/// cannot produce are named here instead of being quietly absent.
class _WhatIsNotMeasuredCard extends StatelessWidget {
  const _WhatIsNotMeasuredCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      tone: _CardTone.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Yang TIDAK bisa diukur aplikasi ini',
                    style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Adopsi 80 % pegawai — tidak terukur. Tidak ada pelaporan '
            'terpusat, jadi angka organisasi tidak dapat dihasilkan dari '
            'sini dan tidak akan pernah ditampilkan seolah-olah bisa.\n'
            '• Kepuasan 4,5/5 — survei kuartalan adalah proses operasional, '
            'bukan fitur aplikasi. Aplikasi hanya menyediakan alat pencatat.\n'
            '• Batas 2 detik pada ponsel — belum diverifikasi pada perangkat '
            'keras; lihat docs/METRICS.md §3.1.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final int rowsStored;
  final int pendingReportRows;
  final bool reportingEnabled;
  final ValueChanged<bool> onToggle;

  const _PrivacyCard({
    required this.rowsStored,
    required this.pendingReportRows,
    required this.reportingEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Penyimpanan & pelaporan', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            rowsStored == 1
                ? '1 catatan penggunaan tersimpan di perangkat ini.'
                : '$rowsStored catatan penggunaan tersimpan di perangkat ini.',
            style: theme.textTheme.bodySmall,
          ),
          if (pendingReportRows > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$pendingReportRows baris ditandai siap dilaporkan.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Laporkan ringkasan penggunaan'),
            subtitle: const Text(
              'Belum aktif: tidak ada layanan penerimanya di versi ini. '
              'Menyalakan hanya menyimpan pilihan Anda.',
            ),
            value: reportingEnabled,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;

  const _MetricTile({required this.label, required this.value, this.helper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnknown = value == _unknown;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: isUnknown ? theme.colorScheme.outline : null,
              ),
            ),
            if (helper != null) ...[
              const SizedBox(height: 4),
              Text(helper!, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              )),
            ],
          ],
        ),
      ),
    );
  }
}

enum _CardTone { surface, warning }

class _Card extends StatelessWidget {
  final Widget child;
  final _CardTone tone;

  const _Card({required this.child, this.tone = _CardTone.surface});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = tone == _CardTone.warning
        ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    // Material, not Container+BoxDecoration: this card hosts a SwitchListTile,
    // and a decorated box between an ink-bearing widget and its nearest
    // Material ancestor makes the ink and splash invisible. Flutter asserts on
    // exactly that arrangement, so the mistake is both visible and caught at
    // runtime rather than shipped.
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorNotice({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Ringkasan gagal dimuat'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
