import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExpressPayWebView extends StatefulWidget {
  final String checkoutUrl;
  final Function(String) onPaymentComplete;
  final Function(String) onError;

  const ExpressPayWebView({
    super.key,
    required this.checkoutUrl,
    required this.onPaymentComplete,
    required this.onError,
  });

  @override
  _ExpressPayWebViewState createState() => _ExpressPayWebViewState();
}

class _ExpressPayWebViewState extends State<ExpressPayWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            widget.onError('WebView Error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle payment completion URLs
            if (request.url.contains('expresspaygh.com/payment/success')) {
              widget.onPaymentComplete('Payment successful');
              return NavigationDecision.prevent;
            } else if (request.url.contains('expresspaygh.com/payment/failed')) {
              widget.onError('Payment failed');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpressPay Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}