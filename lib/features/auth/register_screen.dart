import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'phone_auth_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_footer_link.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AuthHeader(
            title: 'Mulai\nPetualanganmu!',
            subtitle: 'Buat akun dan bergabung dengan komunitas pecinta alam.',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BenefitsCard(),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PhoneAuthScreen()),
                      ),
                      icon: const Icon(Icons.phone_iphone_rounded, size: 20),
                      label: Text(
                        'Daftar dengan Nomor HP',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const AuthDivider(label: 'dengan mendaftar kamu akan'),
                  const SizedBox(height: 20),

                  _FeatureList(),
                  const SizedBox(height: 36),

                  AuthFooterLink(
                    question: 'Sudah punya akun?',
                    linkText: 'Masuk Sekarang',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 16),
                  _TermsText(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Benefits Card
// ---------------------------------------------------------------------------

class _BenefitsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.secondaryLight,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Kenapa bergabung?',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BenefitRow(
            icon: Icons.event_available_rounded,
            text: 'Daftar & ikuti event camping eksklusif',
          ),
          const SizedBox(height: 8),
          _BenefitRow(
            icon: Icons.calendar_month_rounded,
            text: 'Jadwal event tersimpan di kalender HP',
          ),
          const SizedBox(height: 8),
          _BenefitRow(
            icon: Icons.people_alt_rounded,
            text: 'Terhubung dengan sesama petualang',
          ),
          const SizedBox(height: 8),
          _BenefitRow(
            icon: Icons.card_membership_rounded,
            text: 'Kartu anggota digital komunitas',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.secondaryLight.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.secondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feature list (what they get after registration)
// ---------------------------------------------------------------------------

class _FeatureList extends StatelessWidget {
  static const _features = [
    (Icons.check_circle_rounded, 'Akses ke semua event komunitas'),
    (Icons.check_circle_rounded, 'Notifikasi event terbaru'),
    (Icons.check_circle_rounded, 'Profil & riwayat perjalanan'),
    (Icons.check_circle_rounded, 'Sinkronisasi kalender otomatis'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(f.$1, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                f.$2,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Terms text
// ---------------------------------------------------------------------------

class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: AppColors.textLight,
          height: 1.6,
        ),
        text: 'Dengan mendaftar, kamu menyetujui ',
        children: [
          TextSpan(
            text: 'Syarat & Ketentuan',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryPastel,
            ),
          ),
          const TextSpan(text: ' dan '),
          TextSpan(
            text: 'Kebijakan Privasi',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryPastel,
            ),
          ),
          const TextSpan(text: ' kami.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
