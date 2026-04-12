import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/community_model.dart';
import '../../../core/services/api_client.dart';

class CommunityProvider extends ChangeNotifier {
  List<CommunityModel> _communities = [];
  List<MyCommunityModel> _myCommunities = [];
  bool _isLoading = false;
  bool _isJoining = false;
  String? _error;
  String _searchQuery = '';
  Timer? _debounce;

  List<CommunityModel> get communities => _communities;
  List<MyCommunityModel> get myCommunities => _myCommunities;
  bool get isLoading => _isLoading;
  bool get isJoining => _isJoining;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> fetchCommunities({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      final q = search ?? _searchQuery;
      if (q.isNotEmpty) queryParams['search'] = q;

      final res = await ApiClient.instance.get(
        '/communities',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = res.data['data']['communities'] as List;
      _communities = data
          .map((e) => CommunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Gagal memuat komunitas.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      fetchCommunities(search: query);
    });
  }

  void clearSearch() {
    _searchQuery = '';
    _debounce?.cancel();
    fetchCommunities(search: '');
  }

  Future<void> fetchMyCommunities() async {
    try {
      final res = await ApiClient.instance.get('/communities/me');
      final data = res.data['data'] as List;
      _myCommunities = data
          .map((e) => MyCommunityModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> joinCommunity(String communityId,
      {Map<String, dynamic>? formData}) async {
    _isJoining = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.post(
        '/communities/$communityId/join',
        data: formData,
      );
      final status = res.data['data']['status'] as String;

      _communities = _communities.map((c) {
        if (c.id == communityId) {
          return CommunityModel(
            id: c.id,
            name: c.name,
            slug: c.slug,
            description: c.description,
            logoUrl: c.logoUrl,
            bannerUrl: c.bannerUrl,
            location: c.location,
            isPublic: c.isPublic,
            memberCount: c.memberCount + (status == 'ACTIVE' ? 1 : 0),
            membershipStatus: status,
          );
        }
        return c;
      }).toList();

      _isJoining = false;
      notifyListeners();
      return res.data['message'] as String;
    } catch (e) {
      _isJoining = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    try {
      await ApiClient.instance.delete('/communities/$communityId/join');
      _communities = _communities.map((c) {
        if (c.id == communityId) {
          return CommunityModel(
            id: c.id,
            name: c.name,
            slug: c.slug,
            description: c.description,
            logoUrl: c.logoUrl,
            bannerUrl: c.bannerUrl,
            location: c.location,
            isPublic: c.isPublic,
            memberCount: c.memberCount > 0 ? c.memberCount - 1 : 0,
            membershipStatus: null,
          );
        }
        return c;
      }).toList();
      await fetchMyCommunities();
      notifyListeners();
    } catch (_) {}
  }

  void reset() {
    _communities = [];
    _myCommunities = [];
    _searchQuery = '';
    _error = null;
    _debounce?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
