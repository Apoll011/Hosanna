import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/settings_controller.dart';
import 'pedal_bindings.dart';

/// Wraps a stage reader and routes Bluetooth HID pedal keys to prev/next.
///
/// Most page-turners appear as system keyboards; no BLE package is required.
/// Uses a global [HardwareKeyboard] handler so taps on FABs don't steal focus
/// and silently disable the pedal.
class PedalNavigator extends ConsumerStatefulWidget {
  const PedalNavigator({
    super.key,
    required this.child,
    this.onPrev,
    this.onNext,
    this.onScrollPrev,
    this.onScrollNext,
  });

  final Widget child;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  /// Used when [PedalActionMode.scrollPage] is selected. Falls back to
  /// [onPrev]/[onNext] when null (e.g. non-song service items).
  final VoidCallback? onScrollPrev;
  final VoidCallback? onScrollNext;

  @override
  ConsumerState<PedalNavigator> createState() => _PedalNavigatorState();
}

class _PedalNavigatorState extends ConsumerState<PedalNavigator> {
  static const _debounce = Duration(milliseconds: 120);

  DateTime? _lastFire;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    super.dispose();
  }

  bool _isEditableFocused() {
    final primary = FocusManager.instance.primaryFocus;
    final ctx = primary?.context;
    if (ctx == null) return false;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;

    final settings = ref.read(settingsControllerProvider);
    if (!settings.pedalEnabled) return false;
    if (_isEditableFocused()) return false;

    final bindings = resolvePedalBindings(
      preset: settings.pedalPreset,
      customNextKeyId: settings.pedalCustomNextKeyId,
      customPrevKeyId: settings.pedalCustomPrevKeyId,
    );

    final key = event.logicalKey;
    final isNext = bindings.isNext(key);
    final isPrev = bindings.isPrev(key);
    if (!isNext && !isPrev) return false;

    final now = DateTime.now();
    final last = _lastFire;
    if (last != null && now.difference(last) < _debounce) {
      return true;
    }
    _lastFire = now;

    final scrollMode = settings.pedalActionMode == PedalActionMode.scrollPage;
    if (isNext) {
      final action = scrollMode
          ? (widget.onScrollNext ?? widget.onNext)
          : widget.onNext;
      action?.call();
    } else {
      final action = scrollMode
          ? (widget.onScrollPrev ?? widget.onPrev)
          : widget.onPrev;
      action?.call();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
