import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service using platform Keystore / Keychain / DPAPI
class TokenStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              wOptions: WindowsOptions(),
            );

  static const _keyAccessToken = 'gdrive_access_token';
  static const _keyRefreshToken = 'gdrive_refresh_token';
  static const _keyBackendUrl = 'backend_base_url';
  static const _keyDemoMode = 'cloud_demo_mode';
  static const _keyTargetFolder = 'gdrive_target_folder';

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    _memoryFallback[_keyAccessToken] = accessToken;
    if (refreshToken != null) _memoryFallback[_keyRefreshToken] = refreshToken;
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: _keyRefreshToken, value: refreshToken);
      }
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken) ?? _memoryFallback[_keyAccessToken];
    } catch (_) {
      return _memoryFallback[_keyAccessToken];
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken) ?? _memoryFallback[_keyRefreshToken];
    } catch (_) {
      return _memoryFallback[_keyRefreshToken];
    }
  }

  Future<void> setDemoMode(bool enabled) async {
    _memoryFallback[_keyDemoMode] = enabled ? 'true' : 'false';
    try {
      await _storage.write(key: _keyDemoMode, value: enabled ? 'true' : 'false');
    } catch (_) {}
  }

  Future<bool> isDemoMode() async {
    try {
      final val = await _storage.read(key: _keyDemoMode) ?? _memoryFallback[_keyDemoMode];
      return val == 'true';
    } catch (_) {
      return _memoryFallback[_keyDemoMode] == 'true';
    }
  }

  Future<bool> isConfigured() async {
    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) return true;
    return await isDemoMode();
  }

  Future<void> setBackendBaseUrl(String url) async {
    _memoryFallback[_keyBackendUrl] = url;
    try {
      await _storage.write(key: _keyBackendUrl, value: url);
    } catch (_) {}
  }

  Future<String> getBackendBaseUrl() async {
    try {
      final val = await _storage.read(key: _keyBackendUrl) ?? _memoryFallback[_keyBackendUrl];
      return val ?? 'http://127.0.0.1:4000';
    } catch (_) {
      return _memoryFallback[_keyBackendUrl] ?? 'http://127.0.0.1:4000';
    }
  }

  Future<void> setTargetFolderName(String folderName) async {
    _memoryFallback[_keyTargetFolder] = folderName;
    try {
      await _storage.write(key: _keyTargetFolder, value: folderName);
    } catch (_) {}
  }

  Future<String> getTargetFolderName() async {
    try {
      final val = await _storage.read(key: _keyTargetFolder) ?? _memoryFallback[_keyTargetFolder];
      return (val != null && val.trim().isNotEmpty) ? val.trim() : 'RDMS Documents';
    } catch (_) {
      final fallback = _memoryFallback[_keyTargetFolder];
      return (fallback != null && fallback.trim().isNotEmpty) ? fallback.trim() : 'RDMS Documents';
    }
  }

  Future<void> setCustomKey(String key, String value) async {
    _memoryFallback[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> getCustomKey(String key) async {
    try {
      return await _storage.read(key: key) ?? _memoryFallback[key];
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> clearAll() async {
    _memoryFallback.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
