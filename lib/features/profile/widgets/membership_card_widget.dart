import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MembershipCardWidget extends StatelessWidget {
  final Map<String, dynamic> card;

  const MembershipCardWidget({super.key, required this.card});

  static const double _cardW = 428;
  static const double _cardH = 270;

  Color _hex(dynamic raw, String fallback) {
    final s = (raw as String? ?? fallback).replaceAll('#', '');
    try {
      return Color(int.parse('FF$s', radix: 16));
    } catch (_) {
      return Color(int.parse('FF${fallback.replaceAll('#', '')}', radix: 16));
    }
  }

  double _num(dynamic raw, double fallback) =>
      raw == null ? fallback : (raw as num).toDouble();

  bool _bool(dynamic raw, bool fallback) =>
      raw == null ? fallback : raw as bool;

  String _formatExpiry(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cfg = (card['cardConfig'] as Map<String, dynamic>?) ?? {};
    final screenW = MediaQuery.of(context).size.width - 48;
    final scale = screenW / _cardW;
    final cardH = _cardH * scale;

    final bgType = cfg['bgType'] as String? ?? 'gradient';

    BoxDecoration bgDecoration;
    if (bgType == 'gradient') {
      bgDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _hex(cfg['bgColor'], '#4A7C59'),
            _hex(cfg['bgColor2'], '#1a3d2b'),
          ],
        ),
      );
    } else {
      bgDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _hex(cfg['bgColor'], '#4A7C59'),
      );
    }

    return Container(
      width: screenW,
      height: cardH,
      decoration: bgDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image
            if (bgType == 'image' && (cfg['bgImageUrl'] as String? ?? '').isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  cfg['bgImageUrl'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),

            // Logo
            if (_bool(cfg['showLogo'], true) && (card['communityLogo'] as String? ?? '').isNotEmpty)
              _elem(_num(cfg['logoX'], 11), _num(cfg['logoY'], 16), screenW, cardH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    card['communityLogo'] as String,
                    width: _num(cfg['logoSize'], 36) * scale,
                    height: _num(cfg['logoSize'], 36) * scale,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),

            // Community name
            if (_bool(cfg['showCommunity'], true))
              _elem(_num(cfg['commX'], 38), _num(cfg['commY'], 16), screenW, cardH,
                child: Text(
                  card['communityName'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: _hex(cfg['communityColor'], '#e8f5ec'),
                  ),
                ),
              ),

            // Member name
            _elem(_num(cfg['nameX'], 50), _num(cfg['nameY'], 63), screenW, cardH,
              child: Text(
                card['memberName'] as String? ?? '-',
                style: GoogleFonts.inter(
                  fontSize: _num(cfg['nameFontSize'], 20) * scale,
                  fontWeight: FontWeight.bold,
                  color: _hex(cfg['nameColor'], '#ffffff'),
                  height: 1.2,
                ),
              ),
            ),

            // Member ID
            _elem(_num(cfg['idX'], 50), _num(cfg['idY'], 74), screenW, cardH,
              child: Text(
                card['memberId'] as String? ?? '-',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: _num(cfg['idFontSize'], 12) * scale,
                  letterSpacing: 2,
                  color: _hex(cfg['idColor'], '#d4f0e0'),
                ),
              ),
            ),

            // Expiry
            if (_bool(cfg['showExpiry'], true) && card['expiredAt'] != null)
              _elem(_num(cfg['expX'], 50), _num(cfg['expY'], 82), screenW, cardH,
                child: Text(
                  'Berlaku s/d ${_formatExpiry(card['expiredAt'] as String?)}',
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: _hex(cfg['expiryColor'], '#a8d5bc'),
                  ),
                ),
              ),

            // Tagline
            _elem(_num(cfg['tagX'], 50), _num(cfg['tagY'], 93), screenW, cardH,
              child: Text(
                cfg['tagline'] as String? ?? 'Anggota Komunitas',
                style: TextStyle(
                  fontSize: 10 * scale,
                  letterSpacing: 2,
                  color: _hex(cfg['taglineColor'], '#a8d5bc'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _elem(double x, double y, double cardW, double cardH, {required Widget child}) {
    return Positioned(
      left: x / 100 * cardW,
      top: y / 100 * cardH,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: child,
      ),
    );
  }
}
