import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';

/// Renders a Cloudflare Turnstile widget in a WebView and returns the token.
///
/// Turnstile's challenge is a browser-side JS widget, so a native WebView is
/// the only reliable way to obtain a token on Android/iOS. Pops with the token
/// on success, or `null` when the user backs out / the challenge fails.
class TurnstileCaptchaPage extends StatefulWidget {
  const TurnstileCaptchaPage({super.key, required this.siteKey});

  final String siteKey;

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
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <style>
    body { margin: 0; display: flex; align-items: center; justify-content: center;
           min-height: 100vh; background: transparent; }
  </style>
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=__onload" async defer></script>
</head>
<body>
  <div id="cf-turnstile"></div>
  <script>
    function __onload() {
      turnstile.render('#cf-turnstile', {
        sitekey: '${widget.siteKey}',
        callback: function(token) { TurnstileCallback.postMessage(token); },
        'error-callback': function() { TurnstileCallback.postMessage('error'); },
        'expired-callback': function() { TurnstileCallback.postMessage('expired'); },
        theme: 'auto'
      });
    }
  </script>
</body>
</html>
''';
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
      builder: (_) => TurnstileCaptchaPage(siteKey: config.turnstileSiteKey),
    ),
  );
  return token;
}
