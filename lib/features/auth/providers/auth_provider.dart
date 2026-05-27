import 'package:flutter/foundation.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/notification_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

enum PhoneAuthStep { idle, sendingOtp, otpSent, verifying }

class AppAuthProvider extends ChangeNotifier {
  UserModel? _user;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  String? _error;
  PhoneAuthStep _phoneStep = PhoneAuthStep.idle;
  DateTime? _deletionRequestedAt;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get error => _error;
  PhoneAuthStep get phoneStep => _phoneStep;
  DateTime? get deletionRequestedAt => _deletionRequestedAt;

  AppAuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await ApiClient.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    await _fetchBackendProfile();
  }

  Future<void> _fetchBackendProfile() async {
    try {
      await NotificationService.instance.registerToken();
      final res = await ApiClient.instance.get('/users/me');
      final data = res.data['data'] as Map<String, dynamic>;

      final raw = data['deletionRequestedAt'];
      _deletionRequestedAt = raw != null ? DateTime.parse(raw as String) : null;

      final dob = data['dateOfBirth'] as String?;
      _user = UserModel(
        uid: data['id'] as String,
        displayName: data['displayName'] as String?,
        phoneNumber: data['phoneNumber'] as String?,
        photoURL: data['photoUrl'] as String?,
        alamat: data['address'] as String?,
        gender: data['gender'] as String?,
        provinsi: data['province'] as String?,
        district: data['district'] as String?,
        nickName: data['nickName'] as String?,
        placeOfBirth: data['placeOfBirth'] as String?,
        dateOfBirth: dob != null ? DateTime.tryParse(dob) : null,
      );
      _status = AuthStatus.authenticated;
    } catch (_) {
      await ApiClient.clearToken();
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Phone OTP — Step 1: kirim OTP
  // ---------------------------------------------------------------------------

  Future<void> sendOtp({
    required String phoneNumber,
    required VoidCallback onCodeSent,
    required void Function(String msg) onError,
  }) async {
    _phoneStep = PhoneAuthStep.sendingOtp;
    _setError(null);
    notifyListeners();

    try {
      await ApiClient.instance.post('/auth/send-otp', data: {'phoneNumber': phoneNumber});
      _phoneStep = PhoneAuthStep.otpSent;
      notifyListeners();
      onCodeSent();
    } catch (e) {
      _phoneStep = PhoneAuthStep.idle;
      final msg = _extractError(e);
      _setError(msg);
      onError(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP — Step 2: verifikasi OTP
  // ---------------------------------------------------------------------------

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _phoneStep = PhoneAuthStep.verifying;
    _setLoading(true);
    notifyListeners();

    try {
      final res = await ApiClient.instance.post('/auth/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'code': otp,
      });

      final data = res.data['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await ApiClient.saveToken(token);

      _phoneStep = PhoneAuthStep.idle;
      _setLoading(false);

      await _fetchBackendProfile();
      return true;
    } catch (e) {
      _phoneStep = PhoneAuthStep.otpSent;
      _setError(_extractError(e));
      _setLoading(false);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Update profile
  // ---------------------------------------------------------------------------

  Future<bool> updateProfile({
    String? displayName,
    String? nickName,
    String? placeOfBirth,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? alamat,
    String? gender,
    String? provinsi,
    String? district,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiClient.instance.patch('/users/me', data: {
        'displayName': displayName,
        'nickName': nickName,
        'placeOfBirth': placeOfBirth,
        'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
        'phoneNumber': phoneNumber,
        'address': alamat,
        'gender': gender,
        'province': provinsi,
        'district': district,
      });

      _user = _user?.copyWith(
        displayName: displayName,
        nickName: nickName,
        placeOfBirth: placeOfBirth,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
        alamat: alamat,
        gender: gender,
        provinsi: provinsi,
        district: district,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (_) {
      _setError('Gagal menyimpan profil. Coba lagi.');
      _setLoading(false);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Account deletion
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
    await ApiClient.clearToken();
    _user = null;
    _deletionRequestedAt = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() => _fetchBackendProfile();

  void resetPhoneStep() {
    _phoneStep = PhoneAuthStep.idle;
    _setError(null);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['message'] != null) return data['message'] as String;
    } catch (_) {}
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
