import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_client.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

enum PhoneAuthStep { idle, sendingOtp, otpSent, verifying }

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _user;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  String? _error;
  PhoneAuthStep _phoneStep = PhoneAuthStep.idle;
  String? _verificationId;
  DateTime? _deletionRequestedAt;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get error => _error;
  PhoneAuthStep get phoneStep => _phoneStep;
  DateTime? get deletionRequestedAt => _deletionRequestedAt;

  /// Provider IDs yang sudah terhubung ke akun ini
  List<String> get linkedProviders =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ?? [];
  bool get hasGoogle => linkedProviders.contains('google.com');
  bool get hasPhone => linkedProviders.contains('phone');

  AppAuthProvider() {
    if (kDebugMode) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _user = null;
      _deletionRequestedAt = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _user = UserModel.fromFirebaseUser(firebaseUser);
      _status = AuthStatus.authenticated;
      _syncAndFetchBackend();
    }
    notifyListeners();
  }

  Future<void> _syncAndFetchBackend() async {
    try {
      final syncRes = await ApiClient.instance.post('/users/sync');
      // 410 = account permanently deleted after 30 days
      if (syncRes.statusCode == 410) {
        await signOut();
        return;
      }
    } catch (_) {}
    // Fetch deletion status from backend
    try {
      final res = await ApiClient.instance.get('/users/me');
      final raw = res.data['data']['deletionRequestedAt'];
      _deletionRequestedAt = raw != null ? DateTime.parse(raw as String) : null;
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In / Link
  // Jika sudah login (misal via HP) → otomatis link Google ke akun yang ada
  // ---------------------------------------------------------------------------

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Sudah login → link Google ke akun yang ada
        await currentUser.linkWithCredential(credential);
        // Firebase tidak otomatis copy profile — update manual dari Google
        if (currentUser.displayName == null ||
            currentUser.displayName!.isEmpty) {
          await currentUser.updateDisplayName(googleUser.displayName);
        }
        if (currentUser.photoURL == null) {
          await currentUser.updatePhotoURL(googleUser.photoUrl);
        }
        await _auth.currentUser!.reload();
        _user = UserModel.fromFirebaseUser(_auth.currentUser!);
        notifyListeners();
      } else {
        // Belum login → sign in biasa
        await _auth.signInWithCredential(credential);
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Google account sudah terhubung ke akun lain → merge
        return await _mergeGoogleAccount(e);
      }
      _setError(_mapFirebaseError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Terjadi kesalahan. Coba lagi.');
      _setLoading(false);
      return false;
    }
  }

  /// Ketika Google credential sudah terhubung ke akun lain,
  /// login ke akun Google itu dan link data yang ada
  Future<bool> _mergeGoogleAccount(FirebaseAuthException e) async {
    try {
      final credential = e.credential;
      if (credential == null) {
        _setError('Gagal menghubungkan akun.');
        _setLoading(false);
        return false;
      }
      await _auth.signInWithCredential(credential);
      _setLoading(false);
      return true;
    } catch (_) {
      _setError('Gagal menghubungkan akun Google.');
      _setLoading(false);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Phone Sign-In — Step 1: kirim OTP
  // ---------------------------------------------------------------------------

  Future<void> sendOtp({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required void Function(String msg) onError,
  }) async {
    _phoneStep = PhoneAuthStep.sendingOtp;
    _setError(null);
    notifyListeners();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Auto-verify Android — link atau sign in
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null && !hasPhone) {
            await currentUser.linkWithCredential(credential);
          } else {
            await _auth.signInWithCredential(credential);
          }
        } catch (_) {}
      },
      verificationFailed: (e) {
        _phoneStep = PhoneAuthStep.idle;
        _setError(_mapFirebaseError(e.code));
        onError(_error ?? 'Verifikasi gagal.');
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _phoneStep = PhoneAuthStep.otpSent;
        notifyListeners();
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Phone Sign-In — Step 2: verifikasi OTP
  // Jika sudah login (misal via Google) → otomatis link HP ke akun yang ada
  // ---------------------------------------------------------------------------

  Future<bool> verifyOtp(String otp) async {
    if (_verificationId == null) {
      _setError('Sesi habis. Minta OTP lagi.');
      return false;
    }

    try {
      _phoneStep = PhoneAuthStep.verifying;
      _setLoading(true);
      notifyListeners();

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final currentUser = _auth.currentUser;
      if (currentUser != null && !hasPhone) {
        // Sudah login → link nomor HP ke akun yang ada
        await currentUser.linkWithCredential(credential);
      } else {
        // Belum login → sign in biasa dengan nomor HP
        await _auth.signInWithCredential(credential);
      }

      _phoneStep = PhoneAuthStep.idle;
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Nomor HP sudah terdaftar di akun lain → login ke akun itu
        return await _mergePhoneAccount(e);
      }
      _phoneStep = PhoneAuthStep.otpSent;
      _setError(_mapFirebaseError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _phoneStep = PhoneAuthStep.otpSent;
      _setError('Terjadi kesalahan. Coba lagi.');
      _setLoading(false);
      return false;
    }
  }

  /// Nomor HP sudah terdaftar di akun lain → sign in ke akun itu
  Future<bool> _mergePhoneAccount(FirebaseAuthException e) async {
    try {
      final credential = e.credential;
      if (credential == null) {
        _setError('Gagal menghubungkan akun.');
        _setLoading(false);
        return false;
      }
      await _auth.signInWithCredential(credential);
      _phoneStep = PhoneAuthStep.idle;
      _setLoading(false);
      return true;
    } catch (_) {
      _setError('Gagal menghubungkan akun HP.');
      _phoneStep = PhoneAuthStep.otpSent;
      _setLoading(false);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Unlink provider (dari Profile screen)
  // ---------------------------------------------------------------------------

  Future<bool> unlinkProvider(String providerId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Minimal harus ada 1 provider tersisa
      if (linkedProviders.length <= 1) {
        _setError('Tidak bisa menghapus satu-satunya metode login.');
        _setLoading(false);
        return false;
      }

      await _auth.currentUser!.unlink(providerId);
      // Refresh user model
      await _auth.currentUser!.reload();
      _user = UserModel.fromFirebaseUser(_auth.currentUser!);
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e.code));
      _setLoading(false);
      return false;
    }
  }

  void resetPhoneStep() {
    _phoneStep = PhoneAuthStep.idle;
    _verificationId = null;
    _setError(null);
  }

  // ---------------------------------------------------------------------------
  // Account deletion (soft delete — 30 day grace period)
  // ---------------------------------------------------------------------------

  Future<bool> requestDeletion() async {
    try {
      _setLoading(true);
      final res = await ApiClient.instance.post('/users/me/deletion-request');
      final raw = res.data['data']['deletionRequestedAt'];
      _deletionRequestedAt = raw != null ? DateTime.parse(raw as String) : DateTime.now();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (_) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> cancelDeletion() async {
    try {
      _setLoading(true);
      await ApiClient.instance.delete('/users/me/deletion-request');
      _deletionRequestedAt = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (_) {
      _setLoading(false);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Error mapping (Indonesian)
  // ---------------------------------------------------------------------------

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Nomor HP tidak valid.';
      case 'invalid-verification-code':
        return 'Kode OTP salah. Coba lagi.';
      case 'session-expired':
        return 'Sesi OTP habis. Minta kode baru.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Tunggu beberapa saat.';
      case 'user-disabled':
        return 'Akun dinonaktifkan. Hubungi admin.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'provider-already-linked':
        return 'Metode login ini sudah terhubung ke akun kamu.';
      case 'credential-already-in-use':
        return 'Akun ini sudah digunakan. Masuk menggunakan akun tersebut.';
      case 'requires-recent-login':
        return 'Sesi kadaluarsa. Masuk ulang lalu coba lagi.';
      case 'no-such-provider':
        return 'Metode login tidak ditemukan.';
      default:
        return 'Terjadi kesalahan ($code). Coba lagi.';
    }
  }
}
