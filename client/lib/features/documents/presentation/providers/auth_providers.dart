import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/interfaces/i_auth_service.dart';
import '../../../../core/services/token_storage_service.dart';

/// Token storage service provider
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// Google Auth service provider
final googleAuthServiceProvider = Provider<IAuthService>((ref) {
  return GoogleAuthService(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
  );
});

/// Stable identifier of the account the current sync worker is bound
/// to (Phase 2.3). Signed-in Google users get `g:<userId>`; when no
/// account is connected the app falls back to `local-device`, which is
/// still persisted so jobs queued while offline are picked up by the
/// SAME worker on restart (and are NOT picked up if a different Google
/// account is signed in later).
final syncAccountBindingProvider = FutureProvider<String>((ref) async {
  final google = ref.watch(googleAuthServiceProvider);
  final user = google.currentUser;
  if (user != null) return 'g:${user.id}';
  // Silent-restore may reveal a user; try once.
  try {
    final restored = await google.signInSilently();
    if (restored != null) return 'g:${restored.id}';
  } catch (_) {
    // Ignore; fall through to local-device.
  }
  return 'local-device';
});
