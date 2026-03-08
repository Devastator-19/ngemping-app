import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'register_screen.dart';
import 'phone_auth_screen.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_social_button.dart';
import 'widgets/auth_divider.dart';
import 'widgets/auth_footer_link.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    final provider = context.read<AppAuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.signInWithGoogle();
    if (!context.mounted) return;

    if (success) {
      navigator.popUntil((route) => route.isFirst);
    } else if (provider.error != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(provider.error!, style: GoogleFonts.nunito()),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppAuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
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
                  // Google button
                  AuthSocialButton.google(
                    onTap: isLoading ? () {} : () => _signInWithGoogle(context),
                    label: 'Masuk dengan Google',
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 14),

                  // Phone button
                  AuthSocialButton.phone(
                    onTap: isLoading
                        ? () {}
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PhoneAuthScreen()),
                            ),
                    label: 'Masuk dengan Nomor HP',
                  ),

                  const SizedBox(height: 28),
                  const AuthDivider(),
                  const SizedBox(height: 28),

                  _InfoBox(),

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
              'Masuk menggunakan akun Google atau nomor HP yang sudah terdaftar.',
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
