import 'package:flutter/foundation.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/api_client.dart';

class HomeProvider extends ChangeNotifier {
  List<EventModel> _upcomingEvents = [];
  int _totalEvents = 0;
  int _totalCommunities = 0;
  int _totalMembers = 0;
  bool _isLoading = false;

  List<EventModel> get upcomingEvents => _upcomingEvents;
  int get totalEvents => _totalEvents;
  int get totalCommunities => _totalCommunities;
  int get totalMembers => _totalMembers;
  bool get isLoading => _isLoading;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchEvents(),
      _fetchCommunityStats(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchEvents() async {
    try {
      final res = await ApiClient.instance.get(
        '/events',
        queryParameters: {'status': 'OPEN', 'limit': '8'},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      _totalEvents = data['total'] as int? ?? 0;
      _upcomingEvents = (data['events'] as List)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _fetchCommunityStats() async {
    try {
      final res = await ApiClient.instance.get(
        '/communities',
        queryParameters: {'limit': '100'},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      _totalCommunities = data['total'] as int? ?? 0;
      final communities = data['communities'] as List? ?? [];
      _totalMembers = communities.fold<int>(
        0,
        (sum, c) => sum + ((c['_count']?['members'] as int?) ?? 0),
      );
    } catch (_) {}
  }
}
