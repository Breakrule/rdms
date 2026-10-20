import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../widgets/custom_toast.dart';

/// Cross-platform utility to open files with default viewer or system "Open With" dialog.
/// Supports Android, iOS, Windows, macOS, and Linux.
class FileOpenerService {
  /// Opens the file using the default associated application or system intent.
  static Future<bool> openFile(String filePath, BuildContext context) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Berkas Tidak Ditemukan',
          message: 'Berkas fisik tidak ditemukan di: $filePath',
          type: ToastType.warning,
        );
      }
      return false;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          if (context.mounted) {
            final msg = switch (result.type) {
              ResultType.noAppToOpen => 'Tidak ada aplikasi yang dapat membuka berkas jenis ini.',
              ResultType.permissionDenied => 'Izin akses penyimpanan ditolak.',
              ResultType.fileNotFound => 'Berkas tidak ditemukan di sistem.',
              _ => result.message.isNotEmpty ? result.message : 'Terjadi kesalahan saat membuka berkas.',
            };
            CustomToast.show(
              context,
              title: 'Gagal Membuka Dokumen',
              message: msg,
              type: ToastType.warning,
            );
          }
          return false;
        }
        return true;
      }

      final normalizedPath = Platform.isWindows ? filePath.replaceAll('/', '\\') : filePath;
      if (Platform.isWindows) {
        final result = await OpenFilex.open(normalizedPath);
        if (result.type != ResultType.done) {
          await Process.run('cmd.exe', ['/c', 'start', '', normalizedPath]);
        }
      } else if (Platform.isMacOS) {
        await Process.run('open', [normalizedPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [normalizedPath]);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Membuka Dokumen',
          message: 'Terjadi kesalahan saat membuka aplikasi penampil: $e',
          type: ToastType.error,
        );
      }
      return false;
    }
  }

  /// Opens the native system "Open With..." chooser dialog.
  static Future<bool> openWith(String filePath, BuildContext context) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Berkas Tidak Ditemukan',
          message: 'Berkas fisik tidak ditemukan di: $filePath',
          type: ToastType.warning,
        );
      }
      return false;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // On Android, OpenFilex launches an Intent with chooser
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          if (context.mounted) {
            final msg = switch (result.type) {
              ResultType.noAppToOpen => 'Tidak ada aplikasi penampil yang terpasang di perangkat.',
              ResultType.permissionDenied => 'Izin akses ditolak.',
              _ => result.message.isNotEmpty ? result.message : 'Gagal memanggil aplikasi penampil.',
            };
            CustomToast.show(
              context,
              title: 'Pilihan Aplikasi',
              message: msg,
              type: ToastType.warning,
            );
          }
          return false;
        }
        return true;
      }

      final normalizedPath = Platform.isWindows ? filePath.replaceAll('/', '\\') : filePath;
      if (Platform.isWindows) {
        // Windows native Shell32 OpenAs dialog
        await Process.run('rundll32.exe', ['shell32.dll,OpenAs_RunDLL', normalizedPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', normalizedPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [normalizedPath]);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Membuka Pilihan Aplikasi',
          message: 'Tidak dapat memanggil dialog Open With: $e',
          type: ToastType.error,
        );
      }
      return false;
    }
  }

  /// Opens the directory in file explorer with the file selected.
  static Future<bool> openFolder(String filePath, BuildContext context) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Berkas Tidak Ditemukan',
          message: 'Berkas fisik tidak ditemukan di: $filePath',
          type: ToastType.warning,
        );
      }
      return false;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (context.mounted) {
          CustomToast.show(
            context,
            title: 'Penyimpanan Berkas',
            message: filePath,
            type: ToastType.info,
          );
        }
        return true;
      }

      final normalizedPath = Platform.isWindows ? filePath.replaceAll('/', '\\') : filePath;
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', normalizedPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', normalizedPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.parent.path]);
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(
          context,
          title: 'Gagal Membuka Folder',
          message: '$e',
          type: ToastType.error,
        );
      }
      return false;
    }
  }
}
