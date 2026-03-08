import 'package:flutter/foundation.dart';
import '../../../core/models/community_model.dart';
import '../../../core/services/api_client.dart';

class CommunityDetailProvider extends ChangeNotifier {
  final String communityId;

  CommunityDetailProvider({required this.communityId});

  // Detail
  CommunityModel? _community;
  bool _loadingDetail = false;
  String? _detailError;

  // Members
  List<CommunityMemberModel> _members = [];
  bool _loadingMembers = false;
  bool _hasMoreMembers = true;
  int _membersPage = 1;

  // Events
  List<CommunityEventModel> _events = [];
  bool _loadingEvents = false;
  bool _hasMoreEvents = true;
  int _eventsPage = 1;

  // Join/leave state
  bool _isJoining = false;

  // Getters
  CommunityModel? get community => _community;
  bool get loadingDetail => _loadingDetail;
  String? get detailError => _detailError;

  List<CommunityMemberModel> get members => _members;
  bool get loadingMembers => _loadingMembers;
  bool get hasMoreMembers => _hasMoreMembers;

  List<CommunityEventModel> get events => _events;
  bool get loadingEvents => _loadingEvents;
  bool get hasMoreEvents => _hasMoreEvents;

  bool get isJoining => _isJoining;

  List<CommunityMemberModel> get owners =>
      _members.where((m) => m.role == 'OWNER').toList();
  List<CommunityMemberModel> get admins =>
      _members.where((m) => m.role == 'ADMIN').toList();
  List<CommunityMemberModel> get regularMembers =>
      _members.where((m) => m.role == 'MEMBER').toList();

  Future<void> fetchDetail() async {
    _loadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get('/communities/$communityId');
      _community = CommunityModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (_) {
      _detailError = 'Gagal memuat detail komunitas.';
    }

    _loadingDetail = false;
    notifyListeners();
  }

  Future<void> fetchMembers({bool reset = false}) async {
    if (_loadingMembers) return;
    if (!reset && !_hasMoreMembers) return;

    if (reset) {
      _membersPage = 1;
      _members = [];
      _hasMoreMembers = true;
    }

    _loadingMembers = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get(
        '/communities/$communityId/members',
        queryParameters: {'page': _membersPage, 'limit': 50},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final list = (data['members'] as List)
          .map((e) => CommunityMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _members = reset ? list : [..._members, ...list];
      _hasMoreMembers = _membersPage < (data['totalPages'] as int? ?? 1);
      _membersPage++;
    } catch (_) {}

    _loadingMembers = false;
    notifyListeners();
  }

  Future<void> fetchEvents({bool reset = false}) async {
    if (_loadingEvents) return;
    if (!reset && !_hasMoreEvents) return;

    if (reset) {
      _eventsPage = 1;
      _events = [];
      _hasMoreEvents = true;
    }

    _loadingEvents = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get(
        '/communities/$communityId/events',
        queryParameters: {'page': _eventsPage, 'limit': 20},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      final list = (data['events'] as List)
          .map((e) => CommunityEventModel.fromJson(e as Map<String, dynamic>))
          .toList();

      _events = reset ? list : [..._events, ...list];
      _hasMoreEvents = _eventsPage < (data['totalPages'] as int? ?? 1);
      _eventsPage++;
    } catch (_) {}

    _loadingEvents = false;
    notifyListeners();
  }

  Future<void> fetchAll() async {
    await Future.wait([
      fetchDetail(),
      fetchMembers(reset: true),
      fetchEvents(reset: true),
    ]);
  }

  Future<String?> joinCommunity() async {
    _isJoining = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post('/communities/$communityId/join');
      final status = res.data['data']['status'] as String;
      if (_community != null) {
        _community = CommunityModel(
          id: _community!.id,
          name: _community!.name,
          slug: _community!.slug,
          description: _community!.description,
          logoUrl: _community!.logoUrl,
          bannerUrl: _community!.bannerUrl,
          location: _community!.location,
          isPublic: _community!.isPublic,
          memberCount: _community!.memberCount + (status == 'ACTIVE' ? 1 : 0),
          membershipStatus: status,
        );
      }
      _isJoining = false;
      notifyListeners();
      return res.data['message'] as String;
    } catch (_) {
      _isJoining = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> leaveCommunity() async {
    _isJoining = true;
    notifyListeners();

    try {
      await ApiClient.instance.delete('/communities/$communityId/join');
      if (_community != null) {
        _community = CommunityModel(
          id: _community!.id,
          name: _community!.name,
          slug: _community!.slug,
          description: _community!.description,
          logoUrl: _community!.logoUrl,
          bannerUrl: _community!.bannerUrl,
          location: _community!.location,
          isPublic: _community!.isPublic,
          memberCount: _community!.memberCount > 0 ? _community!.memberCount - 1 : 0,
          membershipStatus: null,
        );
      }
      // Refresh members after leave
      await fetchMembers(reset: true);
    } catch (_) {}

    _isJoining = false;
    notifyListeners();
  }
}
