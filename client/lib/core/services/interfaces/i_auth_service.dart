import 'package:google_sign_in/google_sign_in.dart';

abstract interface class IAuthService {
  GoogleSignInAccount? get currentUser;
  Future<GoogleSignInAccount?> signIn();
  Future<GoogleSignInAccount?> signInSilently();
  Future<String?> getValidAccessToken();
  Future<void> signOut();
}
