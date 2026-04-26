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

  late final Map<String, TextEditingController> _customControllers;
  bool _isSubmitting = false;

  bool get _hasCustomQuestions => widget.community.customQuestions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _customControllers = {
      for (final q in widget.community.customQuestions)
        q.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _customControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final Map<String, dynamic> formData;
    if (_hasCustomQuestions) {
      final answers = <Map<String, String>>[];
      for (final q in widget.community.customQuestions) {
        final text = _customControllers[q.id]?.text.trim() ?? '';
        answers.add({'id': q.id, 'label': q.label, 'answer': text});
      }
      formData = {'customAnswers': answers};
    } else {
      formData = {};
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

              // Custom questions (jika ada)
              if (_hasCustomQuestions) ..._buildCustomFields(),

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

  // Dynamic fields from community's customQuestions
  List<Widget> _buildCustomFields() {
    final widgets = <Widget>[];
    final questions = widget.community.customQuestions;

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final label = q.required ? '${q.label} *' : q.label;

      if (i > 0) widgets.add(const SizedBox(height: 16));
      widgets.add(_SectionLabel(label));
      widgets.add(const SizedBox(height: 8));
      widgets.add(_FormField(
        controller: _customControllers[q.id]!,
        hint: 'Tulis jawabanmu di sini...',
        maxLines: q.label.length > 50 ? 3 : 1,
        validator: q.required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
            : null,
      ));
    }

    return widgets;
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
