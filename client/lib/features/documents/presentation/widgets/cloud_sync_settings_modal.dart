import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/custom_toast.dart';
import '../providers/document_providers.dart';

/// Modal dialog allowing users to configure Google Drive cloud backup,
/// destination folder, offline mode, and optional network settings.
class CloudSyncSettingsModal extends ConsumerStatefulWidget {
  final bool promptForUpload;

  const CloudSyncSettingsModal({super.key, this.promptForUpload = false});

  @override
  ConsumerState<CloudSyncSettingsModal> createState() =>
      _CloudSyncSettingsModalState();
}

class _CloudSyncSettingsModalState
    extends ConsumerState<CloudSyncSettingsModal> {
  final _tokenController = TextEditingController();
  final _backendUrlController = TextEditingController();
  final _folderController = TextEditingController();

  bool _isDemoMode = false;
  bool _isLoading = false;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _backendUrlController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final tokenStorage = ref.read(tokenStorageServiceProvider);
    final token = await tokenStorage.getAccessToken() ?? '';
    final isDemo = await tokenStorage.isDemoMode();
    final backendUrl = await tokenStorage.getBackendBaseUrl();
    final folder = await tokenStorage.getTargetFolderName();

    if (mounted) {
      setState(() {
        _tokenController.text = token;
        _isDemoMode = isDemo;
        _backendUrlController.text = backendUrl;
        _folderController.text = folder;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings({bool closeWithSuccess = true}) async {
    final tokenStorage = ref.read(tokenStorageServiceProvider);
    await tokenStorage.setDemoMode(_isDemoMode);
    if (_tokenController.text.trim().isNotEmpty) {
      await tokenStorage.saveTokens(accessToken: _tokenController.text.trim());
    }

    if (_folderController.text.trim().isNotEmpty) {
      await tokenStorage.setTargetFolderName(_folderController.text.trim());
    }

    if (_backendUrlController.text.trim().isNotEmpty) {
      await tokenStorage.setBackendBaseUrl(_backendUrlController.text.trim());
    }

    ref.invalidate(cloudConfigurationProvider);

    if (mounted) {
      CustomToast.show(
        context,
        title: 'Pengaturan Disimpan',
        message: _isDemoMode
            ? 'Penyimpanan lokal aktif. Dokumen tersimpan aman di perangkat.'
            : 'Pengaturan Google Drive berhasil disimpan.',
        type: ToastType.success,
      );
      if (closeWithSuccess) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat pengaturan cloud...'),
            ],
          ),
        ),
      );
    }

    final googleUser = ref.watch(googleAuthServiceProvider).currentUser;
    final isConnected =
        googleUser != null || _tokenController.text.trim().isNotEmpty;

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomInset =
        math.max(20.0, viewPadding.bottom + 12.0 + viewInsets.bottom);
    final topInset = math.max(20.0, viewPadding.top + 8.0);

    return Dialog(
      insetPadding: EdgeInsets.fromLTRB(16, topInset, 16, bottomInset),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F52BA).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: Color(0xFF0F52BA),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.promptForUpload
                              ? 'Konfigurasi Google Drive'
                              : 'Pengaturan Cloud & Google Drive',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.promptForUpload
                              ? 'Hubungkan akun Google Drive untuk mencadangkan dokumen Anda'
                              : 'Kelola pencadangan dan sinkronisasi dokumen ke Google Drive',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Production-ready Status Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF059669).withValues(alpha: 0.08)
                      : (_isDemoMode
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                          : const Color(0xFFD97706).withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isConnected
                        ? const Color(0xFF059669).withValues(alpha: 0.25)
                        : (_isDemoMode
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.25)
                            : const Color(0xFFD97706).withValues(alpha: 0.25)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected
                          ? Icons.cloud_done_rounded
                          : (_isDemoMode
                              ? Icons.cloud_queue_rounded
                              : Icons.cloud_off_rounded),
                      size: 22,
                      color: isConnected
                          ? const Color(0xFF059669)
                          : (_isDemoMode
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? 'Google Drive Terhubung'
                                : (_isDemoMode
                                    ? 'Penyimpanan Lokal Aktif'
                                    : 'Penyimpanan Cloud Belum Terhubung'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isConnected
                                  ? const Color(0xFF065F46)
                                  : (_isDemoMode
                                      ? const Color(0xFF1E40AF)
                                      : const Color(0xFF92400E)),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            isConnected
                                ? 'Salinan dokumen Anda tersimpan aman dan siap disinkronkan ke cloud.'
                                : (_isDemoMode
                                    ? 'Dokumen disimpan aman di perangkat ini tanpa sinkronisasi internet.'
                                    : 'Hubungkan akun Google Drive Anda untuk mulai mencadangkan dokumen.'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isConnected
                                  ? const Color(0xFF047857)
                                  : (_isDemoMode
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Google Account Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F52BA).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.account_circle_rounded,
                              color: Color(0xFF0F52BA),
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                googleUser != null
                                    ? 'Akun Google Terhubung'
                                    : 'Akun Google Drive',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                googleUser != null
                                    ? googleUser.email
                                    : 'Hubungkan akun pribadi agar berkas tersimpan rapi di Google Drive Anda',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (googleUser == null)
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.login_rounded,
                          size: 18,
                          color: Color(0xFF0F52BA),
                        ),
                        label: const Text(
                          'Hubungkan Akun Google Saya',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F52BA),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(color: Color(0xFF0F52BA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            final authService = ref.read(
                              googleAuthServiceProvider,
                            );
                            final account = await authService.signIn();
                            if (account != null) {
                              final token =
                                  await ref
                                      .read(tokenStorageServiceProvider)
                                      .getAccessToken() ??
                                  '';
                              ref.invalidate(cloudConfigurationProvider);
                              if (context.mounted) {
                                setState(() {
                                  _tokenController.text = token;
                                  _isDemoMode = false;
                                });
                                CustomToast.show(
                                  context,
                                  title: 'Google Drive Terhubung',
                                  message:
                                      'Berhasil menghubungkan akun ${account.email}',
                                  type: ToastType.success,
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              CustomToast.show(
                                context,
                                title: 'Gagal Menghubungkan Akun',
                                message:
                                    'Tidak dapat menghubungkan akun Google. Pastikan perangkat terhubung ke internet.',
                                type: ToastType.error,
                              );
                            }
                          }
                        },
                      )
                    else
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Putuskan Akun',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(googleAuthServiceProvider)
                              .signOut();
                          ref.invalidate(cloudConfigurationProvider);
                          if (context.mounted) {
                            setState(() {
                              _tokenController.clear();
                              _isDemoMode = true;
                            });
                            CustomToast.show(
                              context,
                              title: 'Koneksi Diputus',
                              message: 'Akun Google berhasil diputuskan.',
                              type: ToastType.info,
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Target Google Drive Folder Section
              const Text(
                'Folder Tujuan di Google Drive',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Folder tempat berkas dokumen Anda akan disimpan rapi di Google Drive.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _folderController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.create_new_folder_outlined,
                    size: 20,
                    color: Color(0xFF0F52BA),
                  ),
                  hintText: 'Nama Folder (cth: RDMS Documents / Arsip Kantor)',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
              const SizedBox(height: 16),

              // Offline / Local Simulation Mode Switch Tile
              Material(
                color: _isDemoMode
                    ? const Color(0xFF0F52BA).withValues(alpha: 0.04)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: _isDemoMode
                        ? const Color(0xFF0F52BA).withValues(alpha: 0.4)
                        : theme.dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Mode Simulasi / Demo Cloud',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Simulasikan penyimpanan cloud tanpa memerlukan koneksi internet aktif.',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  value: _isDemoMode,
                  activeThumbColor: const Color(0xFF0F52BA),
                  onChanged: (val) {
                    setState(() => _isDemoMode = val);
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Technical & Advanced Settings (Collapsed by default for clean UX)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                    childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    leading: const Icon(Icons.tune_rounded, size: 20),
                    title: const Text(
                      'Pengaturan Teknis & Server (Opsional)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Token manual dan alamat server jaringan lokal',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    children: [
                      // Manual Token Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Token Akses Google Drive (Opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.paste_rounded, size: 14),
                            label: const Text(
                              'Tempel',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            onPressed: () async {
                              final data = await Clipboard.getData(
                                Clipboard.kTextPlain,
                              );
                              if (data?.text != null) {
                                _tokenController.text = data!.text!.trim();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _tokenController,
                        obscureText: _obscureToken,
                        decoration: InputDecoration(
                          hintText: 'Masukkan token akses manual jika diperlukan',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureToken
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _obscureToken = !_obscureToken),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Server Address Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Alamat Server Jaringan (Opsional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _backendUrlController,
                        decoration: InputDecoration(
                          hintText: 'http://127.0.0.1:4000',
                          hintStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.dns_outlined, size: 18),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Alamat server cadangan jika menggunakan jaringan kantor atau server lokal.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      widget.promptForUpload
                          ? 'Simpan & Lanjutkan Upload'
                          : 'Simpan Pengaturan',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F52BA),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _saveSettings(closeWithSuccess: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
