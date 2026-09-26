import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/shell_leading_button.dart';
import '../../../l10n/generated/app_localizations.dart';

class CircleOfFifthsPage extends StatefulWidget {
  const CircleOfFifthsPage({super.key});

  @override
  State<CircleOfFifthsPage> createState() => _CircleOfFifthsPageState();
}

class _CircleOfFifthsPageState extends State<CircleOfFifthsPage> {
  int _selectedIndex = 0;

  static const List<_KeyData> _circleData = [
    _KeyData('C', 'Am', ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim']),
    _KeyData('G', 'Em', ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim']),
    _KeyData('D', 'Bm', ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim']),
    _KeyData('A', 'F#m', ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim']),
    _KeyData('E', 'C#m', ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim']),
    _KeyData('B', 'G#m', ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim']),
    _KeyData('Gb', 'Ebm', ['Gb', 'Abm', 'Bbm', 'Cb', 'Db', 'Ebm', 'Fdim']),
    _KeyData('Db', 'Bbm', ['Db', 'Ebm', 'Fm', 'Gb', 'Ab', 'Bbm', 'Cdim']),
    _KeyData('Ab', 'Fm', ['Ab', 'Bbm', 'Cm', 'Db', 'Eb', 'Fm', 'Gdim']),
    _KeyData('Eb', 'Cm', ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim']),
    _KeyData('Bb', 'Gm', ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim']),
    _KeyData('F', 'Dm', ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim']),
  ];

  static const List<String> _romanNumerals = [
    'I',
    'ii',
    'iii',
    'IV',
    'V',
    'vi',
    'vii°',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final selectedData = _circleData[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.circleOfFifthsTitle),
        leading: const ShellLeadingButton(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final circleSize =
                (constraints.maxWidth - 32).clamp(240.0, 380.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: _buildCircle(colors, selectedData, circleSize),
                  ),
                  const SizedBox(height: 32),
                  _buildHarmonicField(colors, selectedData, l10n),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircle(
    ColorScheme colors,
    _KeyData selectedData,
    double size,
  ) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _dashedRing(size * 0.84, colors.outline.withValues(alpha: 0.25)),
          for (int index = 0; index < _circleData.length; index++)
            ..._buildKeyButtons(index, size, colors),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedData.major,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedData.minor,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKeyButtons(int index, double size, ColorScheme colors) {
    final item = _circleData[index];
    final isSelected = _selectedIndex == index;

    // 12 positions, starting at 12 o'clock (-90deg), 30deg apart.
    final angleRad = (index * 30 - 90) * math.pi / 180;

    // Outer radius for major keys, inner radius for minor keys.
    final rOuter = size * 0.42;
    final rInner = size * 0.28;
    final center = size / 2;

    final outerOffset = Offset(
      center + rOuter * math.cos(angleRad),
      center + rOuter * math.sin(angleRad),
    );
    final innerOffset = Offset(
      center + rInner * math.cos(angleRad),
      center + rInner * math.sin(angleRad),
    );

    final majorSize = (size * 0.16).clamp(44.0, 52.0);
    final minorSize = (size * 0.13).clamp(40.0, 46.0);
    final halfMajor = majorSize / 2;
    final halfMinor = minorSize / 2;

    return [
      Positioned(
        left: outerOffset.dx - halfMajor,
        top: outerOffset.dy - halfMajor,
        child: _KeyButton(
          label: item.major,
          size: majorSize,
          selected: isSelected,
          fontSize: majorSize * 0.3,
          onTap: () => setState(() => _selectedIndex = index),
          selectedBackground: colors.primary,
          selectedForeground: colors.onPrimary,
          unselectedBackground: colors.surface,
          unselectedForeground: colors.onSurface,
          unselectedBorder: colors.outline.withValues(alpha: 0.4),
        ),
      ),
      Positioned(
        left: innerOffset.dx - halfMinor,
        top: innerOffset.dy - halfMinor,
        child: _KeyButton(
          label: item.minor,
          size: minorSize,
          selected: isSelected,
          fontSize: minorSize * 0.28,
          bold: isSelected,
          onTap: () => setState(() => _selectedIndex = index),
          selectedBackground: colors.primaryContainer,
          selectedForeground: colors.primary,
          unselectedBackground: Colors.transparent,
          unselectedForeground: colors.secondary,
          selectedBorder: colors.primary,
        ),
      ),
    ];
  }

  Widget _dashedRing(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
    );
  }

  Widget _buildHarmonicField(
    ColorScheme colors,
    _KeyData selectedData,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.circleOfFifthsHarmonicField.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _degreeCard(0, selectedData, colors, l10n),
                ),
                const SizedBox(width: 8),
                Expanded(child: _degreeCard(1, selectedData, colors, l10n)),
                const SizedBox(width: 8),
                Expanded(child: _degreeCard(2, selectedData, colors, l10n)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _degreeCard(3, selectedData, colors, l10n)),
                const SizedBox(width: 8),
                Expanded(child: _degreeCard(4, selectedData, colors, l10n)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _degreeCard(5, selectedData, colors, l10n),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _degreeCard(6, selectedData, colors, l10n)),
                const SizedBox(width: 8),
                const Expanded(flex: 3, child: SizedBox.shrink()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _degreeCard(
    int i,
    _KeyData selectedData,
    ColorScheme colors,
    AppLocalizations l10n,
  ) {
    final isTonic = i == 0;
    final isRelativeMinor = i == 5;
    final chord = selectedData.degrees[i];

    late final Color background;
    late final Color foreground;
    Border? border;

    if (isTonic) {
      background = colors.primary;
      foreground = colors.onPrimary;
    } else if (isRelativeMinor) {
      background = colors.primaryContainer;
      foreground = colors.primary;
      border = Border.all(color: colors.primary.withValues(alpha: 0.3));
    } else {
      background = colors.surface;
      foreground = colors.onSurface;
      border = Border.all(color: colors.outline.withValues(alpha: 0.4));
    }

    final label = isTonic
        ? l10n.circleOfFifthsTonic.toUpperCase()
        : isRelativeMinor
        ? l10n.circleOfFifthsRelativeMinor.toUpperCase()
        : _romanNumerals[i];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: border,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: (isTonic || isRelativeMinor) ? 1.0 : 0,
              color: foreground.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chord,
            style: TextStyle(
              fontSize: (isTonic || isRelativeMinor) ? 20 : 16,
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.size,
    required this.selected,
    required this.fontSize,
    required this.onTap,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.unselectedBackground,
    required this.unselectedForeground,
    this.unselectedBorder,
    this.selectedBorder,
    this.bold = false,
  });

  final String label;
  final double size;
  final bool selected;
  final double fontSize;
  final bool bold;
  final VoidCallback onTap;
  final Color selectedBackground;
  final Color selectedForeground;
  final Color unselectedBackground;
  final Color unselectedForeground;
  final Color? unselectedBorder;
  final Color? selectedBorder;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size,
            height: size,
            transform: selected
                ? (Matrix4.diagonal3Values(1.06, 1.06, 1.0))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? selectedBackground : unselectedBackground,
              border: Border.all(
                color: selected
                    ? (selectedBorder ?? selectedBackground)
                    : (unselectedBorder ?? Colors.transparent),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: selectedBackground.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: fontSize,
                    fontWeight:
                        (selected || bold) ? FontWeight.bold : FontWeight.w500,
                    color:
                        selected ? selectedForeground : unselectedForeground,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyData {
  const _KeyData(this.major, this.minor, this.degrees);

  final String major;
  final String minor;
  final List<String> degrees;
}
