import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.splashGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _Circle(size: 160, opacity: 0.06),
          ),
          Positioned(
            bottom: 20,
            right: 30,
            child: _Circle(size: 80, opacity: 0.06),
          ),
          Positioned(
            top: 80,
            left: -30,
            child: _Circle(size: 100, opacity: 0.05),
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + app name row
                Row(
                  children: [
                    _BackButton(),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.cabin_rounded,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.comfortaa(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Illustration icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.forest_rounded,
                    size: 34,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: GoogleFonts.comfortaa(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.75),
                    height: 1.5,
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

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.18),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: AppColors.white,
        ),
      ),
    );
  }
}

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
