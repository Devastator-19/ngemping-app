import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'register_screen.dart';
import 'phone_auth_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_footer_link.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AuthHeader(
            title: 'Selamat\nDatang Kembali!',
            subtitle: 'Masuk dan lanjutkan petualanganmu bersama komunitas.',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoBox(),
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
                        'Masuk dengan Nomor HP',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  AuthFooterLink(
                    question: 'Belum punya akun?',
                    linkText: 'Daftar Sekarang',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
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

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryPastel),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Masuk menggunakan nomor HP yang sudah terdaftar.',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.primary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.nunito(
            fontSize: 12, color: AppColors.textLight, height: 1.6),
        text: 'Dengan masuk, kamu menyetujui ',
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
