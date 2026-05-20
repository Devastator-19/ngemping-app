import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';

enum PaymentResult { paid, pending, failed, cancelled }

class PaymentWebviewScreen extends StatefulWidget {
  final String snapUrl;
  final String orderId;
  final String eventTitle;

  const PaymentWebviewScreen({
    super.key,
    required this.snapUrl,
    required this.orderId,
    required this.eventTitle,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  PaymentResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (req) {
            final url = req.url.toLowerCase();
            // Intercept Midtrans finish/error/pending redirect
            if (url.contains('/payment/finish') || url.contains('transaction_status=settlement') || url.contains('transaction_status=capture')) {
              _finishWithResult(PaymentResult.paid);
              return NavigationDecision.prevent;
            }
            if (url.contains('/payment/pending') || url.contains('transaction_status=pending')) {
              _finishWithResult(PaymentResult.pending);
              return NavigationDecision.prevent;
            }
            if (url.contains('/payment/error') || url.contains('transaction_status=deny') || url.contains('transaction_status=cancel') || url.contains('transaction_status=failure')) {
              _finishWithResult(PaymentResult.failed);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.snapUrl));
  }

  void _finishWithResult(PaymentResult result) {
    if (_result != null) return;
    _result = result;
    Navigator.of(context).pop(result);
  }

  Future<bool> _onWillPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar dari Pembayaran?',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Pembayaranmu belum selesai. Kamu bisa melanjutkan nanti dari halaman event.',
          style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Lanjutkan Bayar', style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Keluar', style: GoogleFonts.nunito(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _finishWithResult(PaymentResult.cancelled);
    }
    return false; // handled manually
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _onWillPop,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembayaran',
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                widget.eventTitle,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: AppColors.surface,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
