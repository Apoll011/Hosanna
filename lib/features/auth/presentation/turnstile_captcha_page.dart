import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';

/// Renders the hosted Cloudflare Turnstile page in a WebView and returns the
/// token.
///
/// Turnstile's challenge is browser-side JS and validates the *hostname* of the
/// page rendering the widget, so the challenge is always loaded from
/// [AppConfig.turnstileUrl] (a page served from a domain listed in Cloudflare's
/// "Hostname Management"). The page must render the Turnstile widget and call
/// `TurnstileCallback.postMessage(token)` on success.
///
/// Pops with the token on success, or `null` when the user backs out / fails.
class TurnstileCaptchaPage extends StatefulWidget {
  const TurnstileCaptchaPage({super.key, required this.url});

  final String url;

  @override
  State<TurnstileCaptchaPage> createState() => _TurnstileCaptchaPageState();
}

class _TurnstileCaptchaPageState extends State<TurnstileCaptchaPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TurnstileCallback',
        onMessageReceived: (message) {
          final token = message.message;
          if (token.isEmpty || token == 'error' || token == 'expired') {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop(token);
          }
        },
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

/// Helper for auth pages: resolves a Turnstile token via the WebView page, or
/// returns `null` when captcha is not configured (the controller then surfaces
/// a clear "captcha not configured" state).
Future<String?> resolveCaptchaToken(
  BuildContext context,
  AppConfig config,
) async {
  if (!config.isTurnstileConfigured) return null;
  final token = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => TurnstileCaptchaPage(url: config.turnstileUrl),
    ),
  );
  return token;
}
