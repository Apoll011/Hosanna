import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared navigation helpers for the Logos AI import flow.
///
/// Prefer [push]/[pop]/[pushReplacement] inside this flow. Using [GoRouter.go]
/// resets the stack and leaves users on import/editor screens with no back
/// button (and can nest another source page on top of a broken route).

/// Leave the current import screen: pop when possible, otherwise return to the
/// song library.
void leaveAiImport(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go('/songs');
}

/// Return to the import source page without trapping the user.
///
/// Uses [pushReplacement] when we are already deeper in the flow so the stack
/// stays `[…, source]` instead of stacking another source via [go].
void returnToAiImportSource(BuildContext context, {String? folderId}) {
  final loc = folderId == null || folderId.isEmpty
      ? '/songs/import/ai'
      : '/songs/import/ai?folderId=$folderId';
  if (context.canPop()) {
    context.pushReplacement(loc);
    return;
  }
  context.go(loc);
}

/// AppBar leading that always offers an exit from import screens.
Widget aiImportBackButton(
  BuildContext context, {
  VoidCallback? onPressed,
  bool enabled = true,
}) {
  return IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: !enabled
        ? null
        : (onPressed ?? () => leaveAiImport(context)),
  );
}

/// Shown when a progress/review route is opened without its payload (e.g. deep
/// link or process death). Redirects once to a real source screen.
class AiImportMissingPayloadRedirect extends StatefulWidget {
  const AiImportMissingPayloadRedirect({super.key, this.folderId});

  final String? folderId;

  @override
  State<AiImportMissingPayloadRedirect> createState() =>
      _AiImportMissingPayloadRedirectState();
}

class _AiImportMissingPayloadRedirectState
    extends State<AiImportMissingPayloadRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      returnToAiImportSource(context, folderId: widget.folderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: aiImportBackButton(context),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
