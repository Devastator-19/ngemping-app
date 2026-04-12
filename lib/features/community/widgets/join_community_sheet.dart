import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/community_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_provider.dart';

class JoinCommunitySheet extends StatefulWidget {
  final CommunityModel community;

  const JoinCommunitySheet({super.key, required this.community});

  @override
  State<JoinCommunitySheet> createState() => _JoinCommunitySheetState();
}

class _JoinCommunitySheetState extends State<JoinCommunitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _motivationController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cityController.dispose();
    _motivationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final formData = <String, dynamic>{
      'domisili': _cityController.text.trim(),
      'motivasi': _motivationController.text.trim(),
    };
    if (_experienceController.text.trim().isNotEmpty) {
      formData['pengalaman'] = _experienceController.text.trim();
    }

    final msg = await context.read<CommunityProvider>().joinCommunity(
          widget.community.id,
          formData: formData,
        );

    if (!mounted) return;
    Navigator.pop(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().user;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Text(
                'Daftar ke Komunitas',
                style: GoogleFonts.comfortaa(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (widget.community.logoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        widget.community.logoUrl!,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Icon(Icons.park_rounded,
                        size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    widget.community.name,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info akun (readonly)
              _SectionLabel('Informasi Akun'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primarySurface,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                              user?.initials ?? 'U',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? '-',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (user?.email != null || user?.phoneNumber != null)
                            Text(
                              user!.email ?? user.phoneNumber ?? '',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.textLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: AppColors.textLight),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Domisili
              _SectionLabel('Kota / Domisili *'),
              const SizedBox(height: 8),
              _FormField(
                controller: _cityController,
                hint: 'Contoh: Bandung, Jawa Barat',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Motivasi
              _SectionLabel('Alasan Ingin Bergabung *'),
              const SizedBox(height: 8),
              _FormField(
                controller: _motivationController,
                hint:
                    'Ceritakan alasan kamu ingin bergabung ke komunitas ini...',
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Pengalaman (opsional)
              _SectionLabel('Pengalaman Outdoor (opsional)'),
              const SizedBox(height: 8),
              _FormField(
                controller: _experienceController,
                hint: 'Ceritakan pengalaman camping atau kegiatan outdoor kamu...',
                maxLines: 2,
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.primaryPastel,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Kirim Pendaftaran',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Pendaftaran akan ditinjau oleh pengelola komunitas',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textMedium,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
