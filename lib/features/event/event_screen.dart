import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/models/event_model.dart';
import '../../core/theme/app_colors.dart';
import 'event_detail_screen.dart';
import 'providers/event_provider.dart';

// ─── Filter config ────────────────────────────────────────────────────────────

const _kCategories = [
  (key: null,         label: 'Semua'),
  (key: 'CAMPING',    label: 'Camping'),
  (key: 'HIKING',     label: 'Hiking'),
  (key: 'TREKKING',   label: 'Trekking'),
  (key: 'FAMILY',     label: 'Family'),
  (key: 'OTHER',      label: 'Lainnya'),
];

// ─── EventScreen ──────────────────────────────────────────────────────────────

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents(reset: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<EventProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Event',
                style: GoogleFonts.comfortaa(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Consumer<EventProvider>(
                builder: (_, p, __) => Text(
                  'Event outdoor yang bisa kamu ikuti',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter chips ─────────────────────────────────────────────────
            _FilterRow(),
            const SizedBox(height: 12),

            // ── Event list ───────────────────────────────────────────────────
            Expanded(
              child: Consumer<EventProvider>(
                builder: (_, provider, __) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    );
                  }

                  if (provider.events.isEmpty) {
                    return _EmptyState(freeOnly: provider.freeOnly, category: provider.category);
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: provider.refresh,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: provider.events.length + (provider.isLoadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == provider.events.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          );
                        }
                        return _EventCard(event: provider.events[i]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Category chips
          ..._kCategories.map((cat) {
            final selected = provider.category == cat.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: cat.label,
                selected: selected,
                onTap: () => provider.setCategory(cat.key),
              ),
            );
          }),

          // Divider
          Container(width: 1, height: 20, color: AppColors.divider, margin: const EdgeInsets.only(right: 8)),

          // Free toggle
          _Chip(
            label: 'Gratis',
            selected: provider.freeOnly,
            selectedColor: AppColors.secondary,
            selectedBg: AppColors.secondarySurface,
            icon: Icons.local_offer_rounded,
            onTap: provider.toggleFree,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedBg;
  final IconData? icon;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    this.selectedColor = AppColors.primary,
    this.selectedBg = AppColors.primarySurface,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? selectedColor : AppColors.textLight),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? selectedColor : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFull = event.status == 'FULL';
    final fillPercent = event.maxParticipants != null && event.maxParticipants! > 0
        ? (event.registrationCount / event.maxParticipants!).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (cover image atau warna) ──────────────────────────────
          _CardHeader(event: event, isFull: isFull),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: GoogleFonts.comfortaa(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Info row
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: event.formattedDate,
                    ),
                    if (event.location != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.location_on_outlined,
                          label: event.location!,
                          expand: true,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Participants + price row
                Row(
                  children: [
                    // Progress bar + count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.maxParticipants != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fillPercent,
                                minHeight: 4,
                                backgroundColor: AppColors.divider,
                                valueColor: AlwaysStoppedAnimation(
                                  isFull ? AppColors.error : event.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            event.maxParticipants != null
                                ? '${event.registrationCount} / ${event.maxParticipants} peserta'
                                : '${event.registrationCount} peserta',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: event.price == 0
                            ? AppColors.primarySurface
                            : AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.price == 0
                            ? 'Gratis'
                            : 'Rp ${_fmtPrice(event.price)}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: event.price == 0 ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ), // Container
    ); // GestureDetector
  }

  static String _fmtPrice(double price) {
    final n = price.toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}jt';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 0)}rb';
    return '$n';
  }
}

class _CardHeader extends StatelessWidget {
  final EventModel event;
  final bool isFull;
  const _CardHeader({required this.event, required this.isFull});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: cover image atau gradient warna kategori
          event.coverImageUrl != null
              ? Image.network(
                  event.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ColorBg(event: event),
                )
              : _ColorBg(event: event),

          // Overlay gradient bawah agar teks terbaca
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
                stops: const [0.4, 1.0],
              ),
            ),
          ),

          // Chips (kiri atas: kategori | kanan atas: status)
          Positioned(
            top: 10, left: 12, right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderChip(label: event.categoryLabel, color: event.accentColor),
                if (isFull)
                  _HeaderChip(label: 'Penuh', color: AppColors.error),
              ],
            ),
          ),

          // Tanggal di kiri bawah
          Positioned(
            bottom: 10, left: 12,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  event.formattedDate,
                  style: GoogleFonts.nunito(
                    fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorBg extends StatelessWidget {
  final EventModel event;
  const _ColorBg({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            event.accentColor.withValues(alpha: 0.85),
            event.accentColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Icon(
            _categoryIcon(event.category),
            size: 56,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'CAMPING':  return Icons.cabin_rounded;
      case 'HIKING':   return Icons.terrain_rounded;
      case 'TREKKING': return Icons.hiking_rounded;
      case 'FAMILY':   return Icons.family_restroom_rounded;
      default:         return Icons.event_rounded;
    }
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expand;
  const _InfoChip({required this.icon, required this.label, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMedium),
      overflow: expand ? TextOverflow.ellipsis : null,
      maxLines: expand ? 1 : null,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 4),
        expand ? Flexible(child: text) : text,
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool freeOnly;
  final String? category;
  const _EmptyState({required this.freeOnly, required this.category});

  @override
  Widget build(BuildContext context) {
    final hasFilter = freeOnly || category != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.filter_list_off_rounded : Icons.event_busy_rounded,
              size: 56,
              color: AppColors.primaryPastel,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilter ? 'Tidak ada event dengan filter ini' : 'Belum ada event yang dibuka',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15, color: AppColors.textMedium, fontWeight: FontWeight.w600,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 6),
              Text(
                'Coba ubah filter untuk melihat event lainnya',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
