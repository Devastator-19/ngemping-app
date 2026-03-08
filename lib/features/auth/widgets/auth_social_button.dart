import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

enum _SocialType { google, phone }

class AuthSocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isLoading;
  final _SocialType _type;

  const AuthSocialButton._({
    required this.onTap,
    required this.label,
    required _SocialType type,
    this.isLoading = false,
  }) : _type = type;

  factory AuthSocialButton.google({
    required VoidCallback onTap,
    required String label,
    bool isLoading = false,
  }) =>
      AuthSocialButton._(
          onTap: onTap, label: label, type: _SocialType.google, isLoading: isLoading);

  factory AuthSocialButton.phone({
    required VoidCallback onTap,
    required String label,
    bool isLoading = false,
  }) =>
      AuthSocialButton._(
          onTap: onTap, label: label, type: _SocialType.phone, isLoading: isLoading);

  bool get _isGoogle => _type == _SocialType.google;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: _isGoogle ? AppColors.surface : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isGoogle ? AppColors.border : AppColors.primary,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isGoogle ? Colors.black : AppColors.primary)
                    .withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _isGoogle ? AppColors.primary : AppColors.white,
                  ),
                )
              else
                _buildIcon(),
              const SizedBox(width: 12),
              Text(
                isLoading ? 'Memuat...' : label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _isGoogle ? AppColors.textDark : AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_isGoogle) return _GoogleIcon();
    return const Icon(
      Icons.phone_rounded,
      size: 22,
      color: AppColors.white,
    );
  }
}

/// Replicate Google "G" logo using coloured arcs / text
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final strokeW = size.width * 0.13;

    // Segments: blue, red, yellow, green
    final colors = [
      const Color(0xFF4285F4), // blue (top-right)
      const Color(0xFFEA4335), // red (bottom-right)
      const Color(0xFFFBBC05), // yellow (bottom-left)
      const Color(0xFF34A853), // green (top-left)
    ];
    final startAngles = [-0.35, 0.65 * 3.14159, 3.14159, 1.65 * 3.14159];
    final sweepAngles = [
      1.1 * 3.14159,
      0.52 * 3.14159,
      0.52 * 3.14159,
      0.52 * 3.14159,
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: r - strokeW / 2,
    );

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(rect, startAngles[i], sweepAngles[i], false, paint);
    }

    // White horizontal bar (the crossbar of the "G")
    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r - strokeW / 2, cy),
      barPaint,
    );

    // Re-draw blue arc over the bar area
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.05, 0.05, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
