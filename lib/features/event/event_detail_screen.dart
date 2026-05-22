import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/models/event_model.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../event/providers/event_provider.dart';
import '../payment/payment_webview_screen.dart';
import 'widgets/register_event_sheet.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late bool _registered;
  late bool _waitingPayment;
  bool _proofSubmitted = false;
  PaymentResult? _paymentResult;
  late EventModel _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    final status = _event.myRegistrationStatus;
    _registered = status != null && status != 'CANCELLED';
    _waitingPayment = status == 'WAITING_PAYMENT';
    _proofSubmitted = status == 'REVIEWING';
    if (status == 'PENDING_PAYMENT') _paymentResult = PaymentResult.pending;
  }

  bool get _isFull => _event.status == 'FULL';
  bool get _isOpen => _event.status == 'OPEN';

  Future<void> _openRegisterSheet() async {
    final auth = context.read<AppAuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegisterEventSheet(event: _event),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() { _registered = true; _waitingPayment = false; });
      _showSnack('Pendaftaran berhasil! Sampai ketemu di event 🎉', AppColors.primary);
    } else if (result == 'proof_submitted') {
      setState(() { _registered = true; _waitingPayment = false; _proofSubmitted = true; });
      _showSnack('Bukti pembayaran dikirim — menunggu verifikasi admin', AppColors.secondary);
    } else if (result == 'waiting_payment') {
      setState(() { _registered = true; _waitingPayment = true; _proofSubmitted = false; });
      _showSnack('Kamu terdaftar! Upload bukti transfer untuk melanjutkan', AppColors.secondary);
    } else if (result is PaymentResult) {
      switch (result) {
        case PaymentResult.paid:
          setState(() { _registered = true; _waitingPayment = false; _paymentResult = PaymentResult.paid; });
          _showSnack('Pembayaran berhasil! Kamu sudah terdaftar 🎉', AppColors.primary);
        case PaymentResult.pending:
          setState(() { _registered = true; _waitingPayment = true; _paymentResult = PaymentResult.pending; });
          _showSnack('Pembayaran pending — cek email untuk instruksi selanjutnya', AppColors.secondary);
        case PaymentResult.failed:
          _showSnack('Pembayaran gagal. Silakan coba lagi.', AppColors.error);
        case PaymentResult.cancelled:
          break;
      }
    }
  }

  Future<void> _openProofUploadSheet() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProofUploadSheet(event: _event),
    );
    if (!mounted) return;
    if (submitted == true) {
      setState(() { _waitingPayment = false; _proofSubmitted = true; });
      _showSnack('Bukti pembayaran dikirim — menunggu verifikasi admin', AppColors.secondary);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final isAuth = context.watch<AppAuthProvider>().isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar dengan cover ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: event.accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.coverImageUrl != null)
                    Image.network(
                      event.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ColorBg(event: event),
                    )
                  else
                    _ColorBg(event: event),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderChip(label: event.categoryLabel, color: event.accentColor),
                        const SizedBox(height: 6),
                        Text(
                          event.title,
                          style: GoogleFonts.comfortaa(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status row
                Row(
                  children: [
                    _StatusBadge(status: event.status),
                    const SizedBox(width: 8),
                    if (_isFull)
                      _InfoPill(
                        icon: Icons.people_rounded,
                        label: 'Event penuh',
                        color: AppColors.error,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Meta cards
                _MetaGrid(event: event),
                const SizedBox(height: 20),

                // Location
                if (event.location != null || event.mapsUrl != null)
                  _LocationCard(event: event),

                // Description
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DescriptionCard(text: event.description!),
                ],
              ]),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ────────────────────────────────────────────────────────
      bottomNavigationBar: _BottomCta(
        event: event,
        isRegistered: _registered,
        waitingPayment: _waitingPayment,
        proofSubmitted: _proofSubmitted,
        paymentResult: _paymentResult,
        isFull: _isFull,
        isOpen: _isOpen,
        isAuthenticated: isAuth,
        onRegister: _openRegisterSheet,
        onUploadProof: _openProofUploadSheet,
      ),
    );
  }
}

// ─── Bottom CTA ───────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final EventModel event;
  final bool isRegistered;
  final bool waitingPayment;
  final bool proofSubmitted;
  final PaymentResult? paymentResult;
  final bool isFull;
  final bool isOpen;
  final bool isAuthenticated;
  final VoidCallback onRegister;
  final VoidCallback onUploadProof;

  const _BottomCta({
    required this.event,
    required this.isRegistered,
    required this.waitingPayment,
    required this.proofSubmitted,
    this.paymentResult,
    required this.isFull,
    required this.isOpen,
    required this.isAuthenticated,
    required this.onRegister,
    required this.onUploadProof,
  });

  @override
  Widget build(BuildContext context) {
    final price = event.price;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga',
                  style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textLight),
                ),
                Text(
                  price == 0 ? 'Gratis' : 'Rp ${_fmtPrice(price)}',
                  style: GoogleFonts.comfortaa(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: price == 0 ? AppColors.primary : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Button
          if (isRegistered && proofSubmitted)
            _CtaButton(
              label: 'Menunggu Verifikasi',
              color: const Color(0xFFE8F0FE),
              textColor: const Color(0xFF1A73E8),
              onTap: null,
            )
          else if (isRegistered && (waitingPayment || paymentResult == PaymentResult.pending))
            _CtaButton(
              label: 'Upload Bukti Transfer',
              color: const Color(0xFFFFF3CD),
              textColor: const Color(0xFF8A6200),
              onTap: onUploadProof,
            )
          else if (isRegistered)
            _CtaButton(
              label: 'Terdaftar ✓',
              color: AppColors.primarySurface,
              textColor: AppColors.primary,
              onTap: null,
            )
          else if (isFull)
            _CtaButton(
              label: 'Event Penuh',
              color: AppColors.surfaceVariant,
              textColor: AppColors.textLight,
              onTap: null,
            )
          else if (!isOpen)
            _CtaButton(
              label: 'Pendaftaran Ditutup',
              color: AppColors.surfaceVariant,
              textColor: AppColors.textLight,
              onTap: null,
            )
          else if (!isAuthenticated)
            _CtaButton(
              label: 'Login untuk Daftar',
              color: AppColors.primarySurface,
              textColor: AppColors.primary,
              onTap: onRegister,
            )
          else
            _CtaButton(
              label: 'Daftar Sekarang',
              color: AppColors.primary,
              textColor: Colors.white,
              onTap: onRegister,
            ),
        ],
      ),
    );
  }

  static String _fmtPrice(double price) {
    final n = price.toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}jt';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}rb';
    return '$n';
  }
}

class _CtaButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _CtaButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ─── Meta grid ────────────────────────────────────────────────────────────────

class _MetaGrid extends StatelessWidget {
  final EventModel event;
  const _MetaGrid({required this.event});

  @override
  Widget build(BuildContext context) {
    final slots = event.maxParticipants != null
        ? '${event.registrationCount} / ${event.maxParticipants}'
        : '${event.registrationCount}';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetaCard(
          icon: Icons.calendar_today_rounded,
          label: 'Mulai',
          value: _fmtDateTime(event.startDate),
        ),
        _MetaCard(
          icon: Icons.event_rounded,
          label: 'Selesai',
          value: _fmtDateTime(event.endDate),
        ),
        _MetaCard(
          icon: Icons.people_rounded,
          label: 'Peserta',
          value: slots,
        ),
        _MetaCard(
          icon: Icons.confirmation_number_rounded,
          label: 'Tiket',
          value: event.price == 0 ? 'Gratis' : 'Berbayar',
          valueColor: event.price == 0 ? AppColors.primary : AppColors.secondary,
        ),
      ],
    );
  }

  static String _fmtDateTime(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
  }
}

class _MetaCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textLight)),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final EventModel event;
  const _LocationCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.location ?? '',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Description card ─────────────────────────────────────────────────────────

class _DescriptionCard extends StatefulWidget {
  final String text;
  const _DescriptionCard({required this.text});

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _expanded = false;
  static const _maxLines = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deskripsi',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.text,
            maxLines: _expanded ? null : _maxLines,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          if (widget.text.length > 200) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Tampilkan lebih sedikit' : 'Selengkapnya',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'OPEN'      => ('Buka', const Color(0xFFE8F5EC), AppColors.primary),
      'FULL'      => ('Penuh', const Color(0xFFFFF3E0), AppColors.secondary),
      'CLOSED'    => ('Tutup', const Color(0xFFFDECEC), AppColors.error),
      'CANCELLED' => ('Batal', AppColors.surfaceVariant, AppColors.textLight),
      _           => ('Draft', AppColors.surfaceVariant, AppColors.textLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.nunito(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Proof upload sheet ───────────────────────────────────────────────────────

class _ProofUploadSheet extends StatefulWidget {
  final EventModel event;
  const _ProofUploadSheet({required this.event});

  @override
  State<_ProofUploadSheet> createState() => _ProofUploadSheetState();
}

class _ProofUploadSheetState extends State<_ProofUploadSheet> {
  bool _uploading = false;
  bool _done = false;
  String? _error;

  Future<void> _pick() async {
    setState(() { _uploading = true; _error = null; });
    final provider = context.read<EventProvider>();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) { setState(() => _uploading = false); return; }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: 'proof.jpg'),
      });
      final uploadRes = await ApiClient.instance.post('/upload/image', data: formData);
      final proofUrl = uploadRes.data['url'] as String;

      await provider.submitPaymentProof(widget.event.id, proofUrl);

      if (mounted) setState(() { _uploading = false; _done = true; });
    } on RegistrationError catch (e) {
      if (mounted) setState(() { _uploading = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _uploading = false; _error = 'Upload gagal. Coba lagi.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasBankInfo = widget.event.bankName != null && widget.event.bankName!.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            'Upload Bukti Transfer',
            style: GoogleFonts.comfortaa(
              fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (hasBankInfo) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _BankInfoRow('Bank', widget.event.bankName!),
                  const SizedBox(height: 8),
                  _BankInfoRow('No. Rekening', widget.event.bankAccountNumber ?? '-', isMono: true),
                  const SizedBox(height: 8),
                  _BankInfoRow('Atas Nama', widget.event.bankAccountName ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_error != null) ...[
            Text(_error!, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.error)),
            const SizedBox(height: 12),
          ],
          if (_done)
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: Text('Selesai', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pick,
              icon: _uploading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(
                _uploading ? 'Mengupload…' : 'Pilih Foto dari Galeri',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _BankInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  const _BankInfoRow(this.label, this.value, {this.isMono = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight)),
        Text(
          value,
          style: isMono
              ? GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 1.5)
              : GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ColorBg extends StatelessWidget {
  final EventModel event;
  const _ColorBg({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            event.accentColor.withValues(alpha: 0.85),
            event.accentColor.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
