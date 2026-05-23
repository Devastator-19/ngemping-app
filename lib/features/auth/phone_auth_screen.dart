import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_header.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> with CodeAutoFill {
  final _phoneController = TextEditingController(text: '+62 ');
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _phoneFocus = FocusNode();

  bool _showOtp = false;

  @override
  void codeUpdated() {
    final digits = code?.characters.toList() ?? [];
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].text = i < digits.length ? digits[i] : '';
    }
    if ((code?.length ?? 0) == 6 && mounted) {
      _verifyOtp(context);
    }
  }

  @override
  void dispose() {
    cancel();
    SmsAutoFill().unregisterListener();
    _phoneController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    _phoneFocus.dispose();
    super.dispose();
  }

  String get _rawPhone {
    return _phoneController.text.replaceAll(' ', '');
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  void _sendOtp(BuildContext context) {
    final provider = context.read<AppAuthProvider>();
    final phone = _rawPhone;

    if (phone.length < 10) {
      _showSnack(context, 'Masukkan nomor HP yang valid.');
      return;
    }

    provider.sendOtp(
      phoneNumber: phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() => _showOtp = true);
        listenForCode();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
      },
      onError: (msg) {
        if (mounted) _showSnack(context, msg);
      },
    );
  }

  Future<void> _verifyOtp(BuildContext context) async {
    final otp = _otpCode;
    if (otp.length < 6) {
      _showSnack(context, 'Masukkan 6 digit kode OTP.');
      return;
    }

    final provider = context.read<AppAuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.verifyOtp(otp);
    if (!mounted) return;

    if (success) {
      navigator.popUntil((route) => route.isFirst);
    } else {
      final err = provider.error;
      if (err != null) {
        messenger.showSnackBar(SnackBar(
          content: Text(err, style: GoogleFonts.nunito()),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito()),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthHeader(
            title: _showOtp ? 'Masukkan\nKode OTP' : 'Masuk dengan\nNomor HP',
            subtitle: _showOtp
                ? 'Kami mengirim kode 6 digit ke ${_phoneController.text.trim()}'
                : 'Kami akan kirim kode verifikasi ke nomor HP kamu.',
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _showOtp
                    ? _OtpSection(
                        key: const ValueKey('otp'),
                        controllers: _otpControllers,
                        focusNodes: _otpFocusNodes,
                        phone: _phoneController.text.trim(),
                        onVerify: () => _verifyOtp(context),
                        onResend: () {
                          setState(() => _showOtp = false);
                          context.read<AppAuthProvider>().resetPhoneStep();
                        },
                      )
                    : _PhoneSection(
                        key: const ValueKey('phone'),
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        onSend: () => _sendOtp(context),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phone input section
// ---------------------------------------------------------------------------

class _PhoneSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _PhoneSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppAuthProvider>();
    final isSending = provider.phoneStep == PhoneAuthStep.sendingOtp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryPastel),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_iphone_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Masukkan nomor HP aktif. Kode OTP akan dikirim via SMS.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.primary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phone input
        Text(
          'Nomor HP',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: '+62 812 3456 7890',
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.flag_rounded,
                  color: AppColors.primary, size: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isSending ? null : onSend,
            child: isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white),
                  )
                : Text('Kirim Kode OTP'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OTP verification section
// ---------------------------------------------------------------------------

class _OtpSection extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final String phone;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  const _OtpSection({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.phone,
    required this.onVerify,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppAuthProvider>();
    final isVerifying = provider.phoneStep == PhoneAuthStep.verifying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    focusNodes[i + 1].requestFocus();
                  } else if (val.isEmpty && i > 0) {
                    focusNodes[i - 1].requestFocus();
                  }
                  // Auto verify when all filled
                  final code =
                      controllers.map((c) => c.text).join();
                  if (code.length == 6) onVerify();
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isVerifying ? null : onVerify,
            child: isVerifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white),
                  )
                : Text('Verifikasi OTP'),
          ),
        ),
        const SizedBox(height: 20),

        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tidak menerima kode? ',
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textMedium),
            ),
            GestureDetector(
              onTap: onResend,
              child: Text(
                'Kirim Ulang',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
