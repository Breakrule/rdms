import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'token_storage_service.dart';

/// Service managing Google Account Sign-In with scoped Google Drive file permissions
class GoogleAuthService {
  final TokenStorageService _tokenStorage;
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({
    TokenStorageService? tokenStorage,
    GoogleSignIn? googleSignIn,
  })  : _tokenStorage = tokenStorage ?? TokenStorageService(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const [
                'email',
                'https://www.googleapis.com/auth/drive.file',
              ],
            );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Initiates interactive Google OAuth 2.0 Sign-In flow
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // User cancelled

      final auth = await account.authentication;
      if (auth.accessToken != null) {
        await _tokenStorage.saveTokens(accessToken: auth.accessToken!);
        await _tokenStorage.setDemoMode(false);
      }
      return account;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Silently restores existing session if available
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _tokenStorage.saveTokens(accessToken: auth.accessToken!);
        }
      }
      return account;
    } catch (_) {
      return null;
    }
  }

  /// Returns fresh access token, attempting silent refresh if available
  Future<String?> getValidAccessToken() async {
    try {
      final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.accessToken != null && auth.accessToken!.isNotEmpty) {
          await _tokenStorage.saveTokens(accessToken: auth.accessToken!);
          return auth.accessToken;
        }
      }
    } catch (_) {}
    return await _tokenStorage.getAccessToken();
  }

  /// Signs out of Google account and cleans saved credentials
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _tokenStorage.clearAll();
  }
}
