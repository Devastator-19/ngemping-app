import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/community_model.dart';
import '../../core/models/event_model.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../community/community_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  bool _loading = false;
  String _lastQuery = '';
  List<CommunityModel> _communities = [];
  List<EventModel> _events = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _communities = []; _events = []; _loading = false; _lastQuery = ''; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    _lastQuery = q;

    try {
      final results = await Future.wait([
        ApiClient.instance.get('/communities', queryParameters: {'search': q, 'limit': '10'}),
        ApiClient.instance.get('/events', queryParameters: {'search': q, 'limit': '10'}),
      ]);

      if (!mounted || _lastQuery != q) return;

      final commData = results[0].data['data']['communities'] as List? ?? [];
      final evtData  = results[1].data['data']['events']      as List? ?? [];

      setState(() {
        _communities = commData.map((e) => CommunityModel.fromJson(e as Map<String, dynamic>)).toList();
        _events      = evtData.map((e)  => EventModel.fromJson(e as Map<String, dynamic>)).toList();
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _communities.isNotEmpty || _events.isNotEmpty;
    final hasQuery = _ctrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _onChanged,
          style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Cari komunitas, event...',
            hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textLight),
                    onPressed: () {
                      _ctrl.clear();
                      _onChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          : !hasQuery
              ? _EmptySearch()
              : !hasResults
                  ? _NoResult(query: _ctrl.text.trim())
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (_communities.isNotEmpty) ...[
                          _SectionLabel(label: 'Komunitas', count: _communities.length),
                          ..._communities.map((c) => _CommunityTile(community: c)),
                        ],
                        if (_events.isNotEmpty) ...[
                          _SectionLabel(label: 'Event', count: _events.length),
                          ..._events.map((e) => _EventTile(event: e)),
                        ],
                      ],
                    ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 56, color: AppColors.primaryPastel),
          const SizedBox(height: 12),
          Text(
            'Cari komunitas atau event',
            style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  final String query;
  const _NoResult({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: AppColors.primaryPastel),
          const SizedBox(height: 12),
          Text(
            'Tidak ada hasil untuk "$query"',
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.comfortaa(
              fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.nunito(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Community tile ───────────────────────────────────────────────────────────

class _CommunityTile extends StatelessWidget {
  final CommunityModel community;
  const _CommunityTile({required this.community});

  @override
  Widget build(BuildContext context) {
    final initials = community.name.trim().isNotEmpty
        ? community.name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryPastel),
        ),
        clipBehavior: Clip.antiAlias,
        child: community.logoUrl != null
            ? Image.network(community.logoUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(initials, style: GoogleFonts.comfortaa(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ))
            : Center(
                child: Text(initials, style: GoogleFonts.comfortaa(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
      ),
      title: Text(
        community.name,
        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
      subtitle: community.location != null
          ? Text(
              community.location!,
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
            )
          : null,
      trailing: Text(
        '${community.memberCount} anggota',
        style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: community)),
      ),
    );
  }
}

// ─── Event tile ───────────────────────────────────────────────────────────────

class _EventTile extends StatelessWidget {
  final EventModel event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: event.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.event_rounded, color: event.accentColor, size: 22),
      ),
      title: Text(
        event.title,
        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${event.formattedDate}${event.location != null ? ' · ${event.location}' : ''}',
        style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: event.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          event.categoryLabel,
          style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: event.accentColor),
        ),
      ),
      onTap: () {}, // TODO: navigasi ke detail event saat sudah ada halamannya
    );
  }
}
