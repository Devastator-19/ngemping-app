import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberCardScreen extends StatelessWidget {
  final Map<String, dynamic> cardConfig;
  final String memberName;
  final String? communityMemberId;
  final String? memberPhotoUrl;
  final String communityName;
  final String? communityLogoUrl;

  const MemberCardScreen({
    super.key,
    required this.cardConfig,
    required this.memberName,
    this.communityMemberId,
    this.memberPhotoUrl,
    required this.communityName,
    this.communityLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Kartu Anggota',
          style: GoogleFonts.comfortaa(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth;
              final cardHeight = cardWidth * (270 / 428);
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _CardRenderer(
                  width: cardWidth,
                  height: cardHeight,
                  cardConfig: cardConfig,
                  memberName: memberName,
                  communityMemberId: communityMemberId,
                  memberPhotoUrl: memberPhotoUrl,
                  communityName: communityName,
                  communityLogoUrl: communityLogoUrl,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardRenderer extends StatelessWidget {
  final double width;
  final double height;
  final Map<String, dynamic> cardConfig;
  final String memberName;
  final String? communityMemberId;
  final String? memberPhotoUrl;
  final String communityName;
  final String? communityLogoUrl;

  const _CardRenderer({
    required this.width,
    required this.height,
    required this.cardConfig,
    required this.memberName,
    this.communityMemberId,
    this.memberPhotoUrl,
    required this.communityName,
    this.communityLogoUrl,
  });

  Color _hex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgType = cardConfig['bgType'] as String? ?? 'gradient';
    final bgImageUrl = cardConfig['bgImageUrl'] as String? ?? '';
    final bgColor = _hex(cardConfig['bgColor'] as String?, const Color(0xFF4A7C59));
    final bgColor2 = _hex(cardConfig['bgColor2'] as String?, const Color(0xFF1A3D2B));
    final nameColor = _hex(cardConfig['nameColor'] as String?, Colors.white);
    final idColor = _hex(cardConfig['idColor'] as String?, const Color(0xFFD4F0E0));
    final communityColor = _hex(cardConfig['communityColor'] as String?, const Color(0xFFE8F5EC));
    final taglineColor = _hex(cardConfig['taglineColor'] as String?, const Color(0xFFA8D5BC));
    final accentColor = _hex(cardConfig['accentColor'] as String?, const Color(0xFF6AAA86));
    final expiryColor = _hex(cardConfig['expiryColor'] as String?, const Color(0xFFA8D5BC));
    final showLogo = cardConfig['showLogo'] as bool? ?? true;
    final showCommunity = cardConfig['showCommunity'] as bool? ?? true;
    final showExpiry = cardConfig['showExpiry'] as bool? ?? true;
    final tagline = cardConfig['tagline'] as String? ?? 'Anggota Komunitas';
    final nameFontSize = (cardConfig['nameFontSize'] as num?)?.toDouble() ?? 20;
    final idFontSize = (cardConfig['idFontSize'] as num?)?.toDouble() ?? 12;

    final scale = width / 428;
    final expiryYear = DateTime.now().year + 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: Stack(
        children: [
          // Background
          Positioned.fill(child: _buildBackground(bgType, bgColor, bgColor2, bgImageUrl)),

          // Content
          Padding(
            padding: EdgeInsets.all(28 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: logo + community name
                Row(
                  children: [
                    if (showLogo) ...[
                      _LogoWidget(
                        logoUrl: communityLogoUrl,
                        accentColor: accentColor,
                        size: 36 * scale,
                      ),
                      SizedBox(width: 10 * scale),
                    ],
                    if (showCommunity)
                      Expanded(
                        child: Text(
                          communityName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                            color: communityColor,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 10 * scale),
                Divider(color: accentColor, thickness: 1, height: 1),
                const Spacer(),

                // Member name
                Text(
                  memberName,
                  style: GoogleFonts.nunito(
                    fontSize: nameFontSize * scale,
                    fontWeight: FontWeight.w800,
                    color: nameColor,
                  ),
                ),
                SizedBox(height: 4 * scale),

                // Member ID
                if (communityMemberId != null)
                  Text(
                    communityMemberId!,
                    style: GoogleFonts.robotoMono(
                      fontSize: idFontSize * scale,
                      color: idColor,
                      letterSpacing: 1,
                    ),
                  ),

                // Expiry
                if (showExpiry) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    'Berlaku s/d Des $expiryYear',
                    style: GoogleFonts.nunito(
                      fontSize: 10 * scale,
                      color: expiryColor,
                    ),
                  ),
                ],

                const Spacer(),

                // Tagline bottom
                Center(
                  child: Text(
                    tagline.toUpperCase(),
                    style: GoogleFonts.nunito(
                      fontSize: 9 * scale,
                      letterSpacing: 1.5,
                      color: taglineColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(
    String bgType, Color bgColor, Color bgColor2, String bgImageUrl,
  ) {
    if (bgType == 'image' && bgImageUrl.isNotEmpty) {
      return Image.network(
        bgImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientBox(bgColor, bgColor2),
      );
    }
    if (bgType == 'solid') {
      return Container(color: bgColor);
    }
    return _gradientBox(bgColor, bgColor2);
  }

  Widget _gradientBox(Color c1, Color c2) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  final String? logoUrl;
  final Color accentColor;
  final double size;

  const _LogoWidget({this.logoUrl, required this.accentColor, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.3),
              child: Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.cabin_rounded, color: Colors.white),
              ),
            )
          : const Icon(Icons.cabin_rounded, color: Colors.white),
    );
  }
}
