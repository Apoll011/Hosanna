import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design/tokens.dart';
import '../../app/providers.dart';

/// Shows a modal bottom sheet and hides the shell floating nav pill while it
/// is open, so the pill does not cover sheet actions.
Future<T?> showShellModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = true,
  bool useSafeArea = true,
  Color? backgroundColor,
  ShapeBorder? shape,
}) async {
  final container = ProviderScope.containerOf(context);
  final previous = container.read(shellNavVisibleProvider);
  container.read(shellNavVisibleProvider.notifier).state = false;
  final theme = Theme.of(context);
  try {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      shape: shape ??
          const RoundedRectangleBorder(borderRadius: HosannaRadii.sheet),
      builder: builder,
    );
  } finally {
    container.read(shellNavVisibleProvider.notifier).state = previous;
  }
}
