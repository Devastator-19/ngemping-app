import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/membership_card_widget.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  final _pageController = PageController(viewportFraction: 0.92);
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final res = await ApiClient.instance.get('/users/me/cards');
      final data = res.data['data'];
      setState(() {
        _cards = List<Map<String, dynamic>>.from(data ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Kartu Digital',
          style: GoogleFonts.comfortaa(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? _EmptyCards()
              : Column(
                  children: [
                    const SizedBox(height: 24),
                    SizedBox(
                      height: _cardHeight(context),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _cards.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: MembershipCardWidget(card: _cards[i]),
                        ),
                      ),
                    ),
                    if (_cards.length > 1) ...[
                      const SizedBox(height: 20),
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: _cards.length,
                        effect: ExpandingDotsEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: AppColors.primary,
                          dotColor: AppColors.border,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _cards.length,
                        itemBuilder: (_, i) => _CardInfo(card: _cards[i], index: i, onTap: () {
                          _pageController.animateToPage(i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut);
                        }),
                      ),
                    ),
                  ],
                ),
    );
  }

  double _cardHeight(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 48) * 0.92;
    return w / (428 / 270);
  }
}

class _EmptyCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card_off_rounded, size: 64, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'Belum ada kartu anggota',
            style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textMedium),
          ),
          const SizedBox(height: 6),
          Text(
            'Bergabunglah ke komunitas untuk mendapatkan kartu digital.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final Map<String, dynamic> card;
  final int index;
  final VoidCallback onTap;

  const _CardInfo({required this.card, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if ((card['communityLogo'] as String? ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(card['communityLogo'] as String,
                    width: 36, height: 36, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _logoFallback()),
              )
            else
              _logoFallback(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['communityName'] as String? ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    card['memberId'] as String? ?? '-',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 18),
      );
}
