import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart'
    show Collection, SavedView, Tag;
import '../../../../core/theme/app_theme.dart';
import '../providers/document_providers.dart';

class SidebarOrganizationSection extends ConsumerWidget {
  final bool isDrawer;

  const SidebarOrganizationSection({
    super.key,
    this.isDrawer = false,
  });

  void _closeDrawer(BuildContext context) {
    if (isDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _confirm(BuildContext context, String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: body.isEmpty ? null : Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptNewCollection(
    BuildContext context,
    WidgetRef ref, {
    bool isCollection = true,
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCollection ? 'Koleksi Baru' : 'Tag Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: isCollection ? 120 : 60,
          decoration: InputDecoration(
            labelText: isCollection ? 'Nama koleksi' : 'Nama tag',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (confirmed != true || name.isEmpty || !context.mounted) return;
    final org = ref.read(organizationRepositoryProvider);
    if (isCollection) {
      await org.createCollection(name);
    } else {
      final docs = ref.read(selectedDocumentsProvider);
      if (docs.isNotEmpty) {
        await org.addTagToDocuments(name, docs.map((d) => d.id).toList());
      }
    }
  }

  Future<void> _saveCurrentView(
    BuildContext context,
    WidgetRef ref,
    DocumentFilterState current,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Tampilan Saat Ini'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nama tampilan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (confirmed != true || name.isEmpty) return;
    await ref
        .read(organizationRepositoryProvider)
        .saveView(name, jsonEncode(current.toJson()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(documentFilterProvider);
    final tags = ref.watch(tagsListProvider).value ?? const <Tag>[];
    final collections =
        ref.watch(collectionsListProvider).value ?? const <Collection>[];
    final savedViews =
        ref.watch(savedViewsProvider).value ?? const <SavedView>[];
    final favoriteCount = ref.watch(favoriteCountProvider).value ?? 0;

    Widget header(String label, {VoidCallback? onAdd}) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onAdd != null)
                IconButton(
                  tooltip: 'Tambah',
                  iconSize: 16,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: onAdd,
                ),
            ],
          ),
        );

    Widget row({
      required IconData icon,
      required String title,
      required bool active,
      String? trailing,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
    }) =>
        ListTile(
          dense: true,
          tileColor: active ? theme.colorScheme.primaryContainer : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          ),
          leading: Icon(
            icon,
            size: 16,
            color: active ? theme.colorScheme.primary : null,
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 12.5),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailing == null
              ? null
              : Text(trailing, style: const TextStyle(fontSize: 11)),
          onTap: onTap,
          onLongPress: onLongPress,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header('TAYANGAN'),
        row(
          icon: filterState.favoriteOnly
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          title: 'Favorit',
          trailing: '$favoriteCount',
          active: filterState.favoriteOnly,
          onTap: () {
            ref
                .read(documentFilterProvider.notifier)
                .setFavoriteOnly(!filterState.favoriteOnly);
            _closeDrawer(context);
          },
        ),
        if (tags.isNotEmpty) ...[
          header('TAG'),
          for (final tag in tags)
            row(
              icon: Icons.label_outline_rounded,
              title: tag.name,
              active: filterState.tag == tag.name,
              onTap: () {
                ref
                    .read(documentFilterProvider.notifier)
                    .setTag(filterState.tag == tag.name ? null : tag.name);
                _closeDrawer(context);
              },
              onLongPress: () async {
                final yes = await _confirm(
                  context,
                  'Hapus tag "${tag.name}"?',
                  'Tag dilepas dari semua dokumen; berkas tidak terhapus.',
                );
                if (yes == true) {
                  await ref
                      .read(organizationRepositoryProvider)
                      .deleteTag(tag.id);
                }
              },
            ),
        ],
        if (collections.isNotEmpty) ...[
          header('KOLEKSI', onAdd: () => _promptNewCollection(context, ref)),
          for (final c in collections)
            row(
              icon: Icons.folder_copy_outlined,
              title: c.name,
              active: filterState.collectionId == c.id,
              onTap: () {
                ref.read(documentFilterProvider.notifier).setCollection(
                      filterState.collectionId == c.id ? null : c.id,
                    );
                _closeDrawer(context);
              },
              onLongPress: () async {
                final yes = await _confirm(
                  context,
                  'Hapus koleksi "${c.name}"?',
                  'Dokumen anggotanya tetap ada di library.',
                );
                if (yes == true) {
                  await ref
                      .read(organizationRepositoryProvider)
                      .deleteCollection(c.id);
                }
              },
            ),
        ],
        if (savedViews.isNotEmpty)
          header(
            'TAYANGAN TERSIMPAN',
            onAdd: () => _saveCurrentView(context, ref, filterState),
          ),
        for (final v in savedViews)
          row(
            icon: Icons.bookmark_outline_rounded,
            title: v.name,
            active: false,
            onTap: () {
              final state = DocumentFilterState.fromJson(
                jsonDecode(v.stateJson) as Map<String, dynamic>,
              );
              ref.read(documentFilterProvider.notifier).replaceAll(state);
              _closeDrawer(context);
            },
            onLongPress: () async {
              final yes =
                  await _confirm(context, 'Hapus tampilan "${v.name}"?', '');
              if (yes == true) {
                await ref
                    .read(organizationRepositoryProvider)
                    .deleteSavedView(v.id);
              }
            },
          ),
      ],
    );
  }
}
