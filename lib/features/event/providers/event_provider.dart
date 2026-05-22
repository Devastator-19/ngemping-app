import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/api_client.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  String? _category;   // null = semua
  bool _freeOnly = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const _limit = 15;

  List<EventModel> get events => _events;
  String? get category => _category;
  bool get freeOnly => _freeOnly;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> fetchEvents({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      _events = [];
      _isLoading = true;
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final params = <String, String>{
        'limit': '$_limit',
        'page': '$_page',
        'status': 'OPEN',
      };
      if (_category != null) params['category'] = _category!;

      final res = await ApiClient.instance.get('/events', queryParameters: params);
      final data = res.data['data'] as Map<String, dynamic>;
      final List raw = data['events'] as List? ?? [];

      var fetched = raw.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();

      if (_freeOnly) fetched = fetched.where((e) => e.price == 0).toList();

      _events = reset ? fetched : [..._events, ...fetched];
      _hasMore = fetched.length == _limit;
      _page++;
    } catch (_) {}

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMore() => fetchEvents(reset: false);

  Future<void> setCategory(String? cat) async {
    if (_category == cat) return;
    _category = cat;
    await fetchEvents(reset: true);
  }

  Future<void> toggleFree() async {
    _freeOnly = !_freeOnly;
    await fetchEvents(reset: true);
  }

  Future<void> refresh() => fetchEvents(reset: true);

  /// Returns a [RegistrationResult] on success, or throws [RegistrationError] on failure.
  Future<RegistrationResult> registerForEvent(
    String eventId, {
    required int participantCount,
    List<Map<String, String>> participants = const [],
    List<Map<String, dynamic>> selectedAdditionals = const [],
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/events/$eventId/register',
        data: {
          'participantCount': participantCount,
          if (participants.isNotEmpty) 'participants': participants,
          if (selectedAdditionals.isNotEmpty) 'selectedAdditionals': selectedAdditionals,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return RegistrationResult(
        isPaid: data['isPaid'] as bool? ?? false,
        snapUrl: data['snapUrl'] as String?,
        orderId: data['orderId'] as String?,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Terjadi kesalahan';
      throw RegistrationError(msg);
    } catch (_) {
      throw RegistrationError('Terjadi kesalahan');
    }
  }

  Future<void> submitPaymentProof(String eventId, String proofImageUrl) async {
    try {
      await ApiClient.instance.post(
        '/events/$eventId/proof',
        data: {'proofImageUrl': proofImageUrl},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Gagal mengirim bukti';
      throw RegistrationError(msg);
    }
  }
}

class RegistrationResult {
  final bool isPaid;
  final String? snapUrl;
  final String? orderId;
  const RegistrationResult({required this.isPaid, this.snapUrl, this.orderId});
}

class RegistrationError implements Exception {
  final String message;
  const RegistrationError(this.message);
}
