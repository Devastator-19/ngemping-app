import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/event_provider.dart';

class RegisterEventSheet extends StatefulWidget {
  final EventModel event;
  const RegisterEventSheet({super.key, required this.event});

  @override
  State<RegisterEventSheet> createState() => _RegisterEventSheetState();
}

class _RegisterEventSheetState extends State<RegisterEventSheet> {
  final _participantFormKey = GlobalKey<FormState>();
  late final PageController _pageCtrl;
  int _currentStep = 0;

  int _participantCount = 1;
  final List<TextEditingController> _nameCtrl = [];
  final List<TextEditingController> _notesCtrl = [];
  late List<int> _addonQty;

  bool _isSubmitting = false;
  String? _error;

  // Payment proof state (after registration, if paid)
  bool _waitingPayment = false;
  XFile? _pickedProof;
  bool _proofUploading = false;
  bool _proofDone = false;

  bool get _hasAdditionals => widget.event.additionals.isNotEmpty;
  int get _totalSteps => _hasAdditionals ? 3 : 2;
  List<String> get _stepLabels => _hasAdditionals
      ? ['Peserta', 'Perlengkapan', 'Konfirmasi']
      : ['Peserta', 'Konfirmasi'];

  List<String> get _displayLabels =>
      _waitingPayment ? [..._stepLabels, 'Bayar'] : _stepLabels;
  int get _displayStep => _waitingPayment ? _displayLabels.length - 1 : _currentStep;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _addonQty = List.filled(widget.event.additionals.length, 0);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _nameCtrl) { c.dispose(); }
    for (final c in _notesCtrl) { c.dispose(); }
    super.dispose();
  }

  int get _maxAllowed {
    final max = widget.event.maxParticipants;
    if (max == null) return 20;
    return (max - widget.event.registrationCount).clamp(1, 20);
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

  void _setAddonQty(int i, int qty) =>
      setState(() => _addonQty[i] = qty.clamp(0, 99));

  double get _baseTotal {
    if (widget.event.price <= 0) return 0;
    final units = (_participantCount / widget.event.pricePerPax).ceil();
    return units * widget.event.price;
  }

  double get _addonTotal {
    double total = 0;
    for (var i = 0; i < widget.event.additionals.length; i++) {
      total += _addonQty[i] * widget.event.additionals[i].price;
    }
    return total;
  }

  double get _grandTotal => _baseTotal + _addonTotal;

  List<Map<String, dynamic>> get _selectedAdditionals {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < widget.event.additionals.length; i++) {
      if (_addonQty[i] > 0) {
        result.add({
          'name': widget.event.additionals[i].name,
          'qty': _addonQty[i],
        });
      }
    }
    return result;
  }

  void _goToPage(int page) {
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = page);
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_participantFormKey.currentState!.validate()) return;
    }
    if (_currentStep < _totalSteps - 1) _goToPage(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToPage(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
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
        selectedAdditionals: _selectedAdditionals,
      );

      if (!mounted) return;

      if (result.isPaid) {
        // Manual transfer: show Bayar step
        setState(() { _isSubmitting = false; _waitingPayment = true; });
      } else {
        Navigator.pop(context, true);
      }
    } on RegistrationError catch (e) {
      if (mounted) setState(() { _isSubmitting = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _isSubmitting = false; _error = 'Terjadi kesalahan. Coba lagi.'; });
    }
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() { _pickedProof = picked; _error = null; });
  }

  Future<void> _submitProof() async {
    if (_pickedProof == null) return;
    setState(() { _proofUploading = true; _error = null; });
    final provider = context.read<EventProvider>();
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_pickedProof!.path, filename: 'proof.jpg'),
      });
      final uploadRes = await ApiClient.instance.post('/upload/image', data: formData);
      final proofUrl = uploadRes.data['url'] as String;

      await provider.submitPaymentProof(widget.event.id, proofUrl);

      if (!mounted) return;
      setState(() { _proofUploading = false; _proofDone = true; });
    } on RegistrationError catch (e) {
      if (mounted) setState(() { _proofUploading = false; _error = e.message; });
    } catch (e) {
      if (mounted) setState(() { _proofUploading = false; _error = 'Upload gagal. Coba lagi.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final user = context.read<AppAuthProvider>().user;

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle bar ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Step indicator ─────────────────────────────────────────────
          _StepIndicator(
            currentStep: _displayStep,
            totalSteps: _displayLabels.length,
            labels: _displayLabels,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),

          // ── Pages ──────────────────────────────────────────────────────
          Expanded(
            child: _waitingPayment
                ? _StepBayar(
                    event: widget.event,
                    pickedProof: _pickedProof,
                    error: _error,
                  )
                : Form(
                    key: _participantFormKey,
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StepPeserta(
                          event: widget.event,
                          user: user,
                          participantCount: _participantCount,
                          maxAllowed: _maxAllowed,
                          nameCtrl: _nameCtrl,
                          notesCtrl: _notesCtrl,
                          onCountChanged: _setCount,
                        ),
                        if (_hasAdditionals)
                          _StepPerlengkapan(
                            event: widget.event,
                            addonQty: _addonQty,
                            onDecrement: (i) => _setAddonQty(i, _addonQty[i] - 1),
                            onIncrement: (i) => _setAddonQty(i, _addonQty[i] + 1),
                          ),
                        _StepKonfirmasi(
                          event: widget.event,
                          user: user,
                          participantCount: _participantCount,
                          nameCtrl: _nameCtrl,
                          addonQty: _addonQty,
                          baseTotal: _baseTotal,
                          addonTotal: _addonTotal,
                          grandTotal: _grandTotal,
                          error: _error,
                        ),
                      ],
                    ),
                  ),
          ),

          // ── Bottom navigation ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 12 + bottomPadding),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: _waitingPayment
                ? _BayarBottomBar(
                    isDone: _proofDone,
                    isUploading: _proofUploading,
                    hasPicked: _pickedProof != null,
                    onPick: _pickProof,
                    onSubmit: _submitProof,
                    onDone: () => Navigator.pop(context, 'proof_submitted'),
                    onSkip: () => Navigator.pop(context, 'waiting_payment'),
                  )
                : Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : _prevStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                        ),
                        child: Text(
                          _currentStep == 0 ? 'Batal' : 'Kembali',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _currentStep < _totalSteps - 1
                            ? ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Lanjut',
                                      style: GoogleFonts.nunito(
                                          fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  disabledBackgroundColor: AppColors.primaryPastel,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: AppColors.white),
                                      )
                                    : Text(
                                        _grandTotal > 0
                                            ? 'Konfirmasi & Bayar'
                                            : _participantCount == 1
                                                ? 'Daftar Sekarang'
                                                : 'Daftar $_participantCount Orang',
                                        style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
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

// ─── Step: Bayar ──────────────────────────────────────────────────────────────

class _StepBayar extends StatelessWidget {
  final EventModel event;
  final XFile? pickedProof;
  final String? error;
  const _StepBayar({required this.event, this.pickedProof, this.error});

  @override
  Widget build(BuildContext context) {
    final hasBankInfo = event.bankName != null && event.bankName!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD580)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFFB8860B), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kamu sudah terdaftar! Selesaikan pembayaran dengan transfer ke rekening berikut.',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: const Color(0xFF7A5800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Info Transfer Bank'),
          const SizedBox(height: 10),
          if (hasBankInfo)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _BankRow(label: 'Bank', value: event.bankName!),
                  const Divider(height: 20, color: AppColors.divider),
                  _BankRow(
                    label: 'No. Rekening',
                    value: event.bankAccountNumber ?? '-',
                    isMono: true,
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  _BankRow(
                    label: 'Atas Nama',
                    value: event.bankAccountName ?? '-',
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Info bank belum diatur oleh admin. Hubungi penyelenggara untuk instruksi pembayaran.',
                style: GoogleFonts.nunito(
                    fontSize: 13, color: AppColors.textMedium),
              ),
            ),
          const SizedBox(height: 20),

          _SectionLabel('Bukti Transfer'),
          const SizedBox(height: 4),
          Text(
            'Pilih foto struk transfer atau screenshot mutasi rekening',
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),

          // Preview atau placeholder
          if (pickedProof != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(pickedProof!.path),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.border, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image_outlined,
                      size: 36, color: AppColors.textLight),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada foto dipilih',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: AppColors.textLight),
                  ),
                ],
              ),
            ),

          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                error!,
                style:
                    GoogleFonts.nunito(fontSize: 13, color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  const _BankRow({required this.label, required this.value, this.isMono = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, color: AppColors.textLight)),
        Text(
          value,
          style: isMono
              ? GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: 1.5,
                )
              : GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
        ),
      ],
    );
  }
}

class _BayarBottomBar extends StatelessWidget {
  final bool isDone;
  final bool isUploading;
  final bool hasPicked;
  final VoidCallback onPick;
  final VoidCallback onSubmit;
  final VoidCallback onDone;
  final VoidCallback onSkip;

  const _BayarBottomBar({
    required this.isDone,
    required this.isUploading,
    required this.hasPicked,
    required this.onPick,
    required this.onSubmit,
    required this.onDone,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // Bukti sudah terkirim → tombol Selesai
    if (isDone) {
      return ElevatedButton.icon(
        onPressed: onDone,
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: Text('Selesai',
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      );
    }

    // Ada preview → Ganti Foto + Kirim Bukti
    if (hasPicked) {
      return Row(
        children: [
          OutlinedButton(
            onPressed: isUploading ? null : onPick,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            child: Text('Ganti',
                style: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : onSubmit,
              icon: isUploading
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                isUploading ? 'Mengirim…' : 'Kirim Bukti',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    // Belum pilih foto → Nanti + Pilih Foto
    return Row(
      children: [
        OutlinedButton(
          onPressed: onSkip,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          child: Text('Nanti',
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text('Pilih Foto',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < totalSteps; i++) ...[
            _StepCircle(
              index: i,
              isCurrent: i == currentStep,
              isCompleted: i < currentStep,
              label: labels[i],
            ),
            if (i < totalSteps - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Container(
                    height: 2,
                    color: i < currentStep ? AppColors.primary : AppColors.border,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final bool isCurrent;
  final bool isCompleted;
  final String label;

  const _StepCircle({
    required this.index,
    required this.isCurrent,
    required this.isCompleted,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final active = isCurrent || isCompleted;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : AppColors.textLight,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppColors.primary : AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

// ─── Step 0: Peserta ──────────────────────────────────────────────────────────

class _StepPeserta extends StatelessWidget {
  final EventModel event;
  final dynamic user;
  final int participantCount;
  final int maxAllowed;
  final List<TextEditingController> nameCtrl;
  final List<TextEditingController> notesCtrl;
  final ValueChanged<int> onCountChanged;

  const _StepPeserta({
    required this.event,
    required this.user,
    required this.participantCount,
    required this.maxAllowed,
    required this.nameCtrl,
    required this.notesCtrl,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = event.maxParticipants != null;
    final remaining = hasLimit ? event.maxParticipants! - event.registrationCount : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                              fontSize: 12, color: AppColors.textLight),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppColors.textLight),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Participant count
          _SectionLabel('Jumlah Peserta'),
          const SizedBox(height: 4),
          if (hasLimit)
            Text(
              'Sisa slot: $remaining orang',
              style:
                  GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
            ),
          if (event.price > 0) ...[
            const SizedBox(height: 2),
            Text(
              'Rp ${_fmtPrice(event.price)} / ${event.pricePerPax} orang',
              style:
                  GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _CounterButton(
                icon: Icons.remove_rounded,
                onTap: participantCount > 1
                    ? () => onCountChanged(participantCount - 1)
                    : null,
              ),
              const SizedBox(width: 20),
              Text(
                '$participantCount',
                style: GoogleFonts.comfortaa(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 20),
              _CounterButton(
                icon: Icons.add_rounded,
                onTap: participantCount < maxAllowed
                    ? () => onCountChanged(participantCount + 1)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'orang (termasuk kamu)',
                style:
                    GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium),
              ),
            ],
          ),

          // Extra participant forms
          if (participantCount > 1) ...[
            const SizedBox(height: 24),
            _SectionLabel('Data Peserta Tambahan'),
            const SizedBox(height: 4),
            Text(
              'Isi nama untuk setiap orang yang kamu bawa',
              style:
                  GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              participantCount - 1,
              (i) => _ParticipantCard(
                index: i + 1,
                nameCtrl: nameCtrl[i],
                notesCtrl: notesCtrl[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Step 1: Perlengkapan ─────────────────────────────────────────────────────

class _StepPerlengkapan extends StatelessWidget {
  final EventModel event;
  final List<int> addonQty;
  final ValueChanged<int> onDecrement;
  final ValueChanged<int> onIncrement;

  const _StepPerlengkapan({
    required this.event,
    required this.addonQty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Item Tambahan'),
          const SizedBox(height: 4),
          Text(
            'Pilih item yang kamu butuhkan (opsional)',
            style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          ...List.generate(event.additionals.length, (i) {
            final item = event.additionals[i];
            return _AdditionalItemRow(
              name: item.name,
              price: item.price,
              qty: addonQty[i],
              onDecrement: addonQty[i] > 0 ? () => onDecrement(i) : null,
              onIncrement: () => onIncrement(i),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step 2: Konfirmasi ───────────────────────────────────────────────────────

class _StepKonfirmasi extends StatelessWidget {
  final EventModel event;
  final dynamic user;
  final int participantCount;
  final List<TextEditingController> nameCtrl;
  final List<int> addonQty;
  final double baseTotal;
  final double addonTotal;
  final double grandTotal;
  final String? error;

  const _StepKonfirmasi({
    required this.event,
    required this.user,
    required this.participantCount,
    required this.nameCtrl,
    required this.addonQty,
    required this.baseTotal,
    required this.addonTotal,
    required this.grandTotal,
    this.error,
  });

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final selectedAddons = <({String name, double price, int qty})>[];
    for (var i = 0; i < event.additionals.length; i++) {
      if (addonQty[i] > 0) {
        selectedAddons.add((
          name: event.additionals[i].name,
          price: event.additionals[i].price,
          qty: addonQty[i],
        ));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info event
          _SectionLabel('Detail Event'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ConfirmRow(
                  icon: Icons.celebration_rounded,
                  label: 'Event',
                  value: event.title,
                ),
                const SizedBox(height: 10),
                _ConfirmRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal',
                  value:
                      '${_fmtDate(event.startDate)} – ${_fmtDate(event.endDate)}',
                ),
                const SizedBox(height: 10),
                _ConfirmRow(
                  icon: Icons.person_rounded,
                  label: 'Pendaftar',
                  value: user?.displayName ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Ringkasan peserta
          _SectionLabel('Peserta'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PersonRow(
                    number: 0, name: user?.displayName ?? 'Kamu', isYou: true),
                ...List.generate(nameCtrl.length, (i) {
                  final name = nameCtrl[i].text.trim();
                  return _PersonRow(
                    number: i + 1,
                    name: name.isEmpty ? 'Peserta ${i + 2}' : name,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Item tambahan (kalau ada)
          if (selectedAddons.isNotEmpty) ...[
            _SectionLabel('Item Tambahan'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: selectedAddons
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${a.name} ×${a.qty}',
                              style: GoogleFonts.nunito(
                                  fontSize: 13, color: AppColors.textDark),
                            ),
                            Text(
                              'Rp ${_fmtPrice(a.price * a.qty)}',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Price breakdown
          if (event.price > 0 || selectedAddons.isNotEmpty) ...[
            _SectionLabel('Rincian Pembayaran'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPastel),
              ),
              child: Column(
                children: [
                  if (event.price > 0)
                    _PriceRow(
                      label:
                          'Tiket (${(participantCount / event.pricePerPax).ceil()}x paket)',
                      amount: baseTotal,
                    ),
                  ...selectedAddons.map((a) => _PriceRow(
                        label: '${a.name} (${a.qty}x)',
                        amount: a.price * a.qty,
                      )),
                  const Divider(height: 16, color: AppColors.primaryPastel),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        grandTotal > 0
                            ? 'Rp ${_fmtPrice(grandTotal)}'
                            : 'Gratis',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Free event, no addons
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPastel),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Event ini gratis — tidak ada biaya pendaftaran',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                error!,
                style:
                    GoogleFonts.nunito(fontSize: 13, color: AppColors.error),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Confirm row ──────────────────────────────────────────────────────────────

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: AppColors.textLight)),
            Text(value,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                )),
          ],
        ),
      ],
    );
  }
}

// ─── Person row ───────────────────────────────────────────────────────────────

class _PersonRow extends StatelessWidget {
  final int number;
  final String name;
  final bool isYou;
  const _PersonRow({required this.number, required this.name, this.isYou = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isYou ? AppColors.primary : AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isYou ? 'K' : '${number + 1}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isYou ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (isYou) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Kamu',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Additional item row ──────────────────────────────────────────────────────

class _AdditionalItemRow extends StatelessWidget {
  final String name;
  final double price;
  final int qty;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _AdditionalItemRow({
    required this.name,
    required this.price,
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: qty > 0 ? AppColors.primaryPastel : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Rp ${_fmtPrice(price)} / satuan',
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          _CounterButton(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$qty',
              style: GoogleFonts.comfortaa(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: qty > 0 ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ),
          _CounterButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

// ─── Price row ────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  const _PriceRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textMedium)),
          Text(
            'Rp ${_fmtPrice(amount)}',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
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
                height: 22,
                width: 22,
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
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            style:
                GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
            decoration: _inputDeco('Nama lengkap *'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: notesCtrl,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            style:
                GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
            decoration: _inputDeco(
                'Catatan (opsional, mis: alergi, kebutuhan khusus)'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
        letterSpacing: 0.3,
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
        height: 36,
        width: 36,
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtPrice(double amount) {
  return amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
}
