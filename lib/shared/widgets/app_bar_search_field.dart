import 'package:flutter/material.dart';

/// Compact AppBar title replacement — title-sized text cursor, not a filled
/// Material text field. Overrides the global [InputDecorationTheme] so search
/// does not inherit the large filled/padded form control look.
class AppBarSearchField extends StatelessWidget {
  const AppBarSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          hoverColor: Colors.transparent,
        ),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        style: titleStyle,
        cursorColor: scheme.primary,
        cursorWidth: 2,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: titleStyle?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          filled: false,
          isDense: true,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
