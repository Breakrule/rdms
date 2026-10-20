import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/custom_toast.dart';
import '../../command_palette/presentation/command_palette_modal.dart';
import '../../documents/domain/models/document_item.dart';
import '../../documents/presentation/providers/document_providers.dart';
import '../../documents/presentation/widgets/add_document_modal.dart';
import '../../documents/presentation/widgets/cloud_sync_settings_modal.dart';
import '../../documents/presentation/widgets/document_list_view.dart';
import '../../documents/presentation/widgets/document_preview_panel.dart';
import '../../documents/presentation/widgets/document_sidebar.dart';
import '../../documents/presentation/widgets/document_toolbar.dart';
import 'home_layout.dart';
import 'widgets/home_header.dart';
import 'widgets/home_status_bar.dart';
import 'widgets/home_summary.dart';

class DocumentExplorerScreen extends ConsumerStatefulWidget {
  const DocumentExplorerScreen({super.key});

  @override
  ConsumerState<DocumentExplorerScreen> createState() =>
      _DocumentExplorerScreenState();
}

class _DocumentExplorerScreenState
    extends ConsumerState<DocumentExplorerScreen> {
  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openCommandPalette() {
    showDialog(
      context: context,
      builder: (ctx) => CommandPaletteModal(
        onOpenAddDocument: _openAddDocument,
        onTriggerBulkSync: _triggerBulkSync,
        onSelectDocument: _activateDocument,
      ),
    );
  }

  void _openAddDocument() {
    showDialog(context: context, builder: (ctx) => const AddDocumentModal());
  }

  void _openCloudSettings() {
    showDialog(
      context: context,
      builder: (ctx) => const CloudSyncSettingsModal(),
    );
  }

  Future<void> _triggerBulkSync() async {
    final operationState = ref.read(homeOperationProvider);
    if (operationState.isAnyOperationActive) return;

    final cloudConfig = await ref.read(cloudConfigurationProvider.future);
    if (cloudConfig == CloudConfigurationStatus.unconfigured) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => const CloudSyncSettingsModal(promptForUpload: true),
        );
      }
      return;
    }
    if (cloudConfig == CloudConfigurationStatus.demo) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Penyimpanan Offline',
          message:
              'Hubungkan akun Google Drive di Pengaturan Cloud untuk mencadangkan berkas.',
          type: ToastType.info,
        );
      }
      return;
    }

    ref.read(homeOperationProvider.notifier).setBulkUploading(true);
    try {
      final binding = await ref.read(syncAccountBindingProvider.future);
      final queue = ref.read(syncQueueServiceProvider);
      final count = await queue.enqueueAllUnsynced(accountBinding: binding);

      if (count == 0) {
        if (mounted) {
          CustomToast.show(
            context,
            title: 'Status Sinkronisasi',
            message: 'Semua dokumen sudah tersinkronisasi atau sedang dalam antrean.',
            type: ToastType.info,
          );
        }
        return;
      }

      if (mounted) {
        CustomToast.show(
          context,
          title: 'Antrean Dimulai',
          message: '$count dokumen dimasukkan ke antrean sinkronisasi.',
          type: ToastType.success,
        );
      }

      unawaited(queue.processQueue(accountBinding: binding));
    } finally {
      ref.read(homeOperationProvider.notifier).setBulkUploading(false);
    }
  }

  void _activateDocument(DocumentItem doc) {
    ref.read(selectedDocumentProvider.notifier).select(doc);
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final showInline = HomeLayout.shouldShowInlineDetails(
      availableWidth: size.width,
      textScaleFactor: textScale,
      hasSelection: true,
    );

    if (!showInline) {
      final useFullScreen = HomeLayout.shouldUseFullScreenDetails(
        width: size.width,
        textScaleFactor: textScale,
      );

      if (useFullScreen) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => Scaffold(
              body: DocumentPreviewPanel(
                onClose: () {
                  ref.read(selectedDocumentProvider.notifier).clear();
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ),
        );
      } else {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Tutup Detail',
          barrierColor: Colors.black45,
          pageBuilder: (ctx, anim1, anim2) {
            return Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: HomeLayout.maxModalDetailWidth,
                height: double.infinity,
                child: Material(
                  child: DocumentPreviewPanel(
                    onClose: () {
                      ref.read(selectedDocumentProvider.notifier).clear();
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final layoutMode = HomeLayout.fromWidth(size.width);
    final hasSelection = ref.watch(selectedDocumentProvider) != null;
    final docsAsync = ref.watch(documentsListStreamProvider);
    final visibleCount = docsAsync.asData?.value.length ?? 0;

    final showInlineDetails = HomeLayout.shouldShowInlineDetails(
      availableWidth: size.width,
      textScaleFactor: textScale,
      hasSelection: hasSelection,
    );

    return Focus(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isControlOrCmd =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;

          if (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyK) {
            _openCommandPalette();
            return KeyEventResult.handled;
          }
          if (isControlOrCmd && event.logicalKey == LogicalKeyboardKey.keyF) {
            _searchFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (hasSelection) {
              ref.read(selectedDocumentProvider.notifier).clear();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: layoutMode.usesDrawer
            ? Drawer(
                child: DocumentSidebar(
                  onBulkSync: _triggerBulkSync,
                  onOpenCloudSettings: _openCloudSettings,
                  isDrawer: true,
                ),
              )
            : null,
        floatingActionButton: layoutMode.usesLabeledFab
            ? FloatingActionButton.extended(
                onPressed: _openAddDocument,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Dokumen'),
              )
            : null,
        body: Row(
          children: [
            // Permanent Sidebar on desktop & wide
            if (layoutMode.hasPermanentSidebar)
              DocumentSidebar(
                onBulkSync: _triggerBulkSync,
                onOpenCloudSettings: _openCloudSettings,
              ),

            // Main Collection Area
            Expanded(
              child: Column(
                children: [
                  // Workspace Header
                  HomeHeader(
                    onOpenAddDocument: _openAddDocument,
                    onTriggerBulkUpload: _triggerBulkSync,
                    onOpenCloudSettings: _openCloudSettings,
                    onOpenDrawer: layoutMode.usesDrawer
                        ? () => _scaffoldKey.currentState?.openDrawer()
                        : null,
                  ),

                  // Compact Summary Cards
                  const HomeSummary(),

                  // Operation / Progress Status Strip
                  const HomeStatusBar(),

                  // Search and Filter Toolbar
                  DocumentToolbar(
                    searchFocusNode: _searchFocusNode,
                    onOpenCommandPalette: _openCommandPalette,
                    visibleCount: visibleCount,
                  ),

                  // Document Collection List
                  Expanded(
                    child: DocumentListView(
                      onOpenAddDocument: _openAddDocument,
                      onOpenCommandPalette: _openCommandPalette,
                      onSelectDocument: _activateDocument,
                    ),
                  ),
                ],
              ),
            ),

            // Inline Detail Panel (Wide layout only)
            if (showInlineDetails)
              SizedBox(
                width: HomeLayout.inlineDetailWidth,
                child: DocumentPreviewPanel(
                  onClose: () {
                    ref.read(selectedDocumentProvider.notifier).clear();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
