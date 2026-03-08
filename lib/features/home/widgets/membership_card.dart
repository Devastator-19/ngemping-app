import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_model.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatMonth(DateTime date) => '${_months[date.month - 1]} ${date.year}';

class MembershipCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const MembershipCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3D2B), Color(0xFF2D5C3F), Color(0xFF4A7C59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              right: -30,
              top: -30,
              child: _Circle(size: 140, opacity: 0.06),
            ),
            Positioned(
              right: 60,
              bottom: -50,
              child: _Circle(size: 120, opacity: 0.05),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: _Circle(size: 100, opacity: 0.04),
            ),
            // Subtle grid pattern
            Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter()),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: community logo + member badge
                  Row(
                    children: [
                      // Community logo
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.cabin_rounded,
                          size: 18,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ngemping',
                            style: GoogleFonts.comfortaa(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            'Kartu Anggota Digital',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color:
                                  AppColors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.secondaryLight
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.secondaryLight,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Aktif',
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // User info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar
                      _Avatar(user: user),
                      const SizedBox(width: 12),
                      // Name + member ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'Petualang',
                              style: GoogleFonts.comfortaa(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.memberId,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color:
                                    AppColors.white.withValues(alpha: 0.65),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Join date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Bergabung',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: AppColors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          Text(
                            user.createdAt != null
                                ? _formatMonth(user.createdAt!)
                                : '-',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar widget
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  final UserModel user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: user.photoURL != null
            ? Image.network(
                user.photoURL!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialsAvatar(user: user),
              )
            : _InitialsAvatar(user: user),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final UserModel user;
  const _InitialsAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          user.initials,
          style: GoogleFonts.comfortaa(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative helpers
// ---------------------------------------------------------------------------

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;
  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 1.5;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
