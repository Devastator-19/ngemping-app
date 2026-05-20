import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/event_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../payment/payment_webview_screen.dart';
import '../providers/event_provider.dart';

class RegisterEventSheet extends StatefulWidget {
  final EventModel event;

  const RegisterEventSheet({super.key, required this.event});

  @override
  State<RegisterEventSheet> createState() => _RegisterEventSheetState();
}

class _RegisterEventSheetState extends State<RegisterEventSheet> {
  final _formKey = GlobalKey<FormState>();
  int _participantCount = 1;
  final List<TextEditingController> _nameCtrl = [];
  final List<TextEditingController> _notesCtrl = [];
  bool _isSubmitting = false;
  String? _error;

  int get _maxAllowed {
    final max = widget.event.maxParticipants;
    final current = widget.event.registrationCount;
    if (max == null) return 20;
    final remaining = max - current;
    return remaining.clamp(1, 20);
  }

  void _setCount(int count) {
    final clamped = count.clamp(1, _maxAllowed);
    setState(() {
      _participantCount = clamped;
      final extras = clamped - 1;
      while (_nameCtrl.length < extras) {
        _nameCtrl.add(TextEditingController());
        _notesCtrl.add(TextEditingController());
      }
      while (_nameCtrl.length > extras) {
        _nameCtrl.removeLast().dispose();
        _notesCtrl.removeLast().dispose();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _nameCtrl) { c.dispose(); }
    for (final c in _notesCtrl) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });

    final participants = <Map<String, String>>[];
    for (var i = 0; i < _nameCtrl.length; i++) {
      final entry = <String, String>{'name': _nameCtrl[i].text.trim()};
      final notes = _notesCtrl[i].text.trim();
      if (notes.isNotEmpty) entry['notes'] = notes;
      participants.add(entry);
    }

    try {
      final result = await context.read<EventProvider>().registerForEvent(
        widget.event.id,
        participantCount: _participantCount,
        participants: participants,
      );

      if (!mounted) return;

      if (result.isPaid && result.snapUrl != null) {
        final nav = Navigator.of(context);
        nav.pop(false); // close sheet, don't show success yet
        final paymentResult = await nav.push<PaymentResult>(
          MaterialPageRoute(
            builder: (_) => PaymentWebviewScreen(
              snapUrl: result.snapUrl!,
              orderId: result.orderId ?? '',
              eventTitle: widget.event.title,
            ),
          ),
        );
        nav.pop(paymentResult ?? PaymentResult.cancelled);
      } else {
        Navigator.pop(context, true); // free event success
      }
    } on RegistrationError catch (e) {
      if (mounted) setState(() { _isSubmitting = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _isSubmitting = false; _error = 'Terjadi kesalahan'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().user;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasLimit = widget.event.maxParticipants != null;
    final remaining = hasLimit ? widget.event.maxParticipants! - widget.event.registrationCount : null;

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Text(
                'Daftar Event',
                style: GoogleFonts.comfortaa(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.event.title,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // User info card
              _SectionLabel('Pendaftar'),
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
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
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
                              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textLight),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Participant count
              _SectionLabel('Jumlah Peserta'),
              if (hasLimit) ...[
                const SizedBox(height: 4),
                Text(
                  'Sisa slot: $remaining orang',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _CounterButton(
                    icon: Icons.remove_rounded,
                    onTap: _participantCount > 1 ? () => _setCount(_participantCount - 1) : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$_participantCount',
                    style: GoogleFonts.comfortaa(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _CounterButton(
                    icon: Icons.add_rounded,
                    onTap: _participantCount < _maxAllowed ? () => _setCount(_participantCount + 1) : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'orang (termasuk kamu)',
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium),
                  ),
                ],
              ),

              // Extra participants forms
              if (_participantCount > 1) ...[
                const SizedBox(height: 24),
                _SectionLabel('Data Peserta Tambahan'),
                const SizedBox(height: 4),
                Text(
                  'Isi nama untuk setiap orang yang kamu bawa',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 12),
                ...List.generate(_participantCount - 1, (i) => _ParticipantCard(
                  index: i + 1,
                  nameCtrl: _nameCtrl[i],
                  notesCtrl: _notesCtrl[i],
                )),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.error),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.primaryPastel,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(
                          _participantCount == 1
                              ? 'Daftar Sekarang'
                              : 'Daftar untuk $_participantCount Orang',
                          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Participant card ─────────────────────────────────────────────────────────

class _ParticipantCard extends StatelessWidget {
  final int index;
  final TextEditingController nameCtrl;
  final TextEditingController notesCtrl;

  const _ParticipantCard({
    required this.index,
    required this.nameCtrl,
    required this.notesCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPastel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 22, width: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Peserta $index',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
            decoration: _inputDeco('Nama lengkap *'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: notesCtrl,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
            decoration: _inputDeco('Catatan (opsional, mis: alergi, kebutuhan khusus)'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    isDense: true,
  );
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

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

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36, width: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primarySurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? AppColors.primaryPastel : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.textLight,
        ),
      ),
    );
  }
}
