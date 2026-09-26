import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class StripeWebviewModal extends StatefulWidget {
  final String initialUrl;
  final String title;
  final Function(String sessionId)? onPaymentSuccess;
  final VoidCallback? onPaymentCancel;
  final VoidCallback? onConnectComplete;

  const StripeWebviewModal({
    super.key,
    required this.initialUrl,
    this.title = 'Stripe Secure Checkout',
    this.onPaymentSuccess,
    this.onPaymentCancel,
    this.onConnectComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialUrl,
    String title = 'Stripe Secure Checkout',
    Function(String sessionId)? onPaymentSuccess,
    VoidCallback? onPaymentCancel,
    VoidCallback? onConnectComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (ctx) => ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.92,
          child: StripeWebviewModal(
            initialUrl: initialUrl,
            title: title,
            onPaymentSuccess: onPaymentSuccess,
            onPaymentCancel: onPaymentCancel,
            onConnectComplete: onConnectComplete,
          ),
        ),
      ),
    );
  }

  @override
  State<StripeWebviewModal> createState() => _StripeWebviewModalState();
}

class _StripeWebviewModalState extends State<StripeWebviewModal> {
  InAppWebViewController? webViewController;
  double progress = 0.0;
  bool isCompleted = false;

  void _handleUrlChange(WebUri? uri) {
    if (uri == null || isCompleted) return;
    final urlStr = uri.toString();

    // Check for Checkout Success
    if (urlStr.contains('/checkout/success') || (urlStr.contains('session_id=') && !urlStr.contains('cancel'))) {
      isCompleted = true;
      final sessionId = uri.queryParameters['session_id'] ?? '';
      Navigator.of(context).pop();
      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!(sessionId);
      }
      return;
    }

    // Check for Checkout Cancel
    if (urlStr.contains('/checkout/cancel')) {
      isCompleted = true;
      Navigator.of(context).pop();
      if (widget.onPaymentCancel != null) {
        widget.onPaymentCancel!();
      }
      return;
    }

    // Check for Stripe Connect Return
    if (urlStr.contains('/stripe/connect/return')) {
      isCompleted = true;
      Navigator.of(context).pop();
      if (widget.onConnectComplete != null) {
        widget.onConnectComplete!();
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1550A6),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onPaymentCancel?.call();
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF93C5FD)),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              webViewController?.reload();
            },
          ),
        ],
        bottom: progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF1E3A8A),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          supportZoom: false,
          useShouldOverrideUrlLoading: true,
          userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Mobile Safari/537.36',
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onProgressChanged: (controller, p) {
          setState(() {
            progress = p / 100.0;
          });
        },
        onLoadStart: (controller, url) {
          _handleUrlChange(url);
        },
        onLoadStop: (controller, url) {
          _handleUrlChange(url);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url;
          if (uri != null) {
            final urlStr = uri.toString();
            if (urlStr.contains('/checkout/success') ||
                urlStr.contains('/checkout/cancel') ||
                urlStr.contains('/stripe/connect/return')) {
              _handleUrlChange(uri);
              return NavigationActionPolicy.CANCEL;
            }
          }
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
