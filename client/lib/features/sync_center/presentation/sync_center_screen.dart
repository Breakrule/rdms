import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart' show SyncJob;
import '../../../../core/services/document_replica_repository.dart';
import '../../documents/presentation/providers/document_providers.dart';

/// Phase 2.8 Sync Center. Lists the open outbox, per-destination
/// rollups, and provides pause/resume/retry controls. Kept intentionally
/// minimal: the acceptance gate cares about behavior (jobs not stranded,
/// backend downtime not blocking Drive, no duplicates on retry), which
/// the pipeline enforces; this screen just surfaces it to the user.
class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(syncProgressStreamProvider).asData?.value;
    final rollups = ref.watch(replicaRollupsProvider);
    final openJobsAsync = ref.watch(openSyncJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Sinkronisasi'),
        actions: [
          IconButton(
            icon: Icon(progress?.isPaused == true
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded),
            tooltip: progress?.isPaused == true ? 'Lanjutkan' : 'Jeda',
            onPressed: () {
              final queue = ref.read(syncQueueServiceProvider);
              if (progress?.isPaused == true) {
                queue.resume();
                // Kick a worker now that we know the current binding.
                () async {
                  final binding = await ref.read(syncAccountBindingProvider.future);
                  await queue.processQueue(accountBinding: binding);
                }();
              } else {
                queue.pause();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Coba lagi job yang gagal',
            onPressed: () async {
              final binding = await ref.read(syncAccountBindingProvider.future);
              await ref.read(syncQueueServiceProvider).processQueue(accountBinding: binding);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (progress != null && progress.isRunning)
            LinearProgressIndicator(value: progress.percentage),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Antrean: ${progress?.total ?? 0} total, '
                  '${progress?.inProgress ?? 0} berjalan, '
                  '${progress?.completed ?? 0} selesai, '
                  '${progress?.failed ?? 0} gagal.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                rollups.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat rollup: $e'),
                  data: (r) => Row(
                    children: [
                      Expanded(child: _RollupCard('Google Drive', r.$1)),
                      const SizedBox(width: 12),
                      Expanded(child: _RollupCard('Backend', r.$2)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Job Terbuka',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                openJobsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat job: $e'),
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Tidak ada job terbuka.'),
                      );
                    }
                    return Column(
                      children: [
                        for (final job in jobs)
                          Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _colorForJob(job.status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _iconForJob(job.status),
                                  color: _colorForJob(job.status),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${job.destination} • ${job.kind}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Percobaan ke-${job.attempts} • ${_statusLabel(job.status)}'
                                '${job.errorRedacted == null ? '' : '\n${job.errorRedacted}'}',
                              ),
                              trailing: job.status == 'blocked'
                                  ? FilledButton.tonal(
                                      onPressed: () async {
                                        await ref
                                            .read(syncJobRepositoryProvider)
                                            .retry(job.id);
                                        final binding = await ref
                                            .read(syncAccountBindingProvider.future);
                                        await ref
                                            .read(syncQueueServiceProvider)
                                            .processQueue(accountBinding: binding);
                                      },
                                      child: const Text('Coba Lagi'),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForJob(String status) {
    switch (status) {
      case 'leased':
        return Icons.autorenew_rounded;
      case 'blocked':
        return Icons.error_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _colorForJob(String status) {
    switch (status) {
      case 'leased':
        return Colors.blue.shade700;
      case 'blocked':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'leased':
        return 'Sedang Berjalan';
      case 'blocked':
        return 'Terblokir / Perlu Ditinjau';
      case 'pending':
        return 'Menunggu Antrean';
      default:
        return status;
    }
  }
}

class _RollupCard extends StatelessWidget {
  final String title;
  final ReplicaRollup rollup;

  const _RollupCard(this.title, this.rollup);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDrive = title.contains('Drive');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (isDrive ? Colors.blue : Colors.purple)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isDrive ? Icons.cloud_outlined : Icons.dns_rounded,
                    size: 16,
                    color: isDrive ? Colors.blue.shade700 : Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _metricRow('Tersinkron', '${rollup.current}', Colors.teal),
            _metricRow('Dalam Antrean', '${rollup.pending}', Colors.blue),
            _metricRow('Gagal Sementara', '${rollup.failed}', Colors.orange),
            _metricRow('Diblokir', '${rollup.blocked}', Colors.red),
            _metricRow('Konflik', '${rollup.conflict}', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, Color indicatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live view of open (pending or leased) sync jobs; blocked jobs are
/// included so the user can retry them from the Sync Center.
final openSyncJobsProvider = FutureProvider<List<SyncJob>>((ref) async {
  final repo = ref.watch(syncJobRepositoryProvider);
  final binding = await ref.watch(syncAccountBindingProvider.future);
  final open = await repo.listOpen(accountBinding: binding);
  final blocked = await repo.listBlocked();
  return [...open, ...blocked];
});
