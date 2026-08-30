// lib/features/auth/presentation/turnstile_captcha_desktop.dart
//
// Linux/Windows implementation of the Turnstile captcha flow.
//
// `webview_flutter` has no Linux or Windows implementation, so instead of an
// in-app WebView the challenge is loaded in a native webview window
// (WebKitGTK on Linux, WebView2 on Windows) via `desktop_webview_window`.
//
// The hosted page still calls `TurnstileCallback.postMessage(token)`; a small
// script injected on document creation shims that object onto whichever
// bridge the platform exposes:
//
//  * Linux  -> `window.webkit.messageHandlers.TurnstileCallback.postMessage`
//              (wired up with `registerJavaScriptMessageHandler`)
//  * Windows -> `window.chrome.webview.postMessage`
//              (wired up with `addOnWebMessageReceivedCallback`)
//
// The token (or `null` when the user closes the window without solving) is
// returned to the awaiting auth form through the same push/pop contract as the
// WebView page.
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Resolves a Turnstile token on Linux/Windows by opening the hosted captcha
/// page in a native webview window.
///
/// Pushes [DesktopTurnstileCaptchaPage] and resolves to the token, or `null`
/// when the user cancels (closes the captcha window or the page).
Future<String?> resolveDesktopCaptchaToken(
  BuildContext context,
  AppConfig config,
) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => DesktopTurnstileCaptchaPage(url: config.turnstileUrl),
    ),
  );
}

enum _CaptchaStatus { opening, waiting, error }

/// Waiting page shown while the native captcha window is up.
///
/// The actual Turnstile challenge runs in a separate native window, so this
/// page is a lightweight "please solve the captcha" state that pops with the
/// token once it arrives (or `null` when the window is closed / creation
/// fails).
class DesktopTurnstileCaptchaPage extends StatefulWidget {
  const DesktopTurnstileCaptchaPage({super.key, required this.url});

  final String url;

  @override
  State<DesktopTurnstileCaptchaPage> createState() =>
      _DesktopTurnstileCaptchaPageState();
}

class _DesktopTurnstileCaptchaPageState extends State<DesktopTurnstileCaptchaPage> {
  Webview? _webview;
  _CaptchaStatus _status = _CaptchaStatus.opening;
  bool _resolved = false;
  bool _started = false;

  /// Shims `TurnstileCallback.postMessage` (the contract the hosted captcha
  /// page relies on) onto the message bridge of the current platform. Runs
  /// before the page's own scripts, mirroring webview_flutter's JavaScript
  /// channel behaviour.
  static const String _bridgeScript = '''
window.TurnstileCallback = {
  postMessage: function (token) {
    if (window.chrome && window.chrome.webview && window.chrome.webview.postMessage) {
      window.chrome.webview.postMessage(token);
    } else if (window.webkit && window.webkit.messageHandlers &&
               window.webkit.messageHandlers.TurnstileCallback) {
      window.webkit.messageHandlers.TurnstileCallback.postMessage(token);
    }
  }
};
''';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start as late as possible so the localized window title is available.
    if (!_started) {
      _started = true;
      _openCaptchaWindow();
    }
  }

  @override
  void dispose() {
    _webview?.close();
    super.dispose();
  }

  Future<void> _openCaptchaWindow() async {
    setState(() => _status = _CaptchaStatus.opening);
    try {
      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          title: AppLocalizations.of(context).authCaptchaWindowTitle,
          windowWidth: 420,
          windowHeight: 640,
          titleBarHeight: 48,
        ),
      );
      _webview = webview;
      _installMessageBridge(webview);
      webview.addScriptToExecuteOnDocumentCreated(_bridgeScript);
      webview.launch(widget.url);
      if (!mounted) return;
      setState(() => _status = _CaptchaStatus.waiting);

      // Completes when the user closes the native window.
      await webview.onClose;
      _handleCaptchaWindowClosed();
    } catch (_) {
      _webview?.close();
      _webview = null;
      if (!mounted) return;
      setState(() => _status = _CaptchaStatus.error);
    }
  }

  void _installMessageBridge(Webview webview) {
    if (Platform.isWindows) {
      webview.addOnWebMessageReceivedCallback(_handleToken);
    } else if (Platform.isLinux) {
      webview.registerJavaScriptMessageHandler(
        'TurnstileCallback',
        (name, body) => _handleToken(body?.toString() ?? ''),
      );
    }
  }

  void _handleToken(String token) {
    if (_resolved) return;
    if (token.isEmpty || token == 'error' || token == 'expired') {
      _finish(null);
    } else {
      _finish(token);
    }
  }

  void _handleCaptchaWindowClosed() {
    // No token arrived before the user closed the window: treat as cancel.
    _finish(null);
  }

  void _finish(String? token) {
    if (_resolved) return;
    _resolved = true;
    _webview?.close();
    _webview = null;
    if (mounted) {
      Navigator.of(context).pop(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_status) {
            _CaptchaStatus.opening || _CaptchaStatus.waiting => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_status == _CaptchaStatus.opening)
                    const CircularProgressIndicator()
                  else
                    const Icon(Icons.verified_user_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.authCaptchaWaitingMessage,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            _CaptchaStatus.error => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.authCaptchaOpenFailed,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _openCaptchaWindow,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}
