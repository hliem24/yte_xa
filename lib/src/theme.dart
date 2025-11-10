import 'package:flutter/material.dart';

/// Palette tím–xanh neon
class NeonPalette {
  static const Color bgTop    = Color(0xFF0B1020);
  static const Color bgBottom = Color(0xFF0F1633);
  static const Color primary  = Color(0xFF7A5CFF); // tím neon
  static const Color cyan     = Color(0xFF00E0D1); // xanh dạ quang
  static const Color pink     = Color(0xFFFF3D9B);
  static const Color card     = Color(0xFF111834);
  static const Color cardHi   = Color(0xFF162046);
}

/// ThemeData neon (Material 3)
ThemeData buildNeonTheme(Brightness brightness) {
  final cs = ColorScheme(
    brightness: Brightness.dark,
    primary: NeonPalette.primary,
    onPrimary: Colors.white,
    secondary: NeonPalette.cyan,
    onSecondary: Colors.black,
    surface: NeonPalette.card,
    onSurface: Colors.white.withOpacity(.92),
    surfaceContainerHighest: NeonPalette.cardHi,
    error: NeonPalette.pink,
    onError: Colors.white,
    tertiary: NeonPalette.pink,
    onTertiary: Colors.white,
    background: NeonPalette.bgBottom,
    onBackground: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: NeonPalette.bgBottom.withOpacity(.65),
      indicatorColor: NeonPalette.primary.withOpacity(.25),
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? NeonPalette.cyan : Colors.white70,
          size: 24,
          shadows: selected ? [const Shadow(color: Colors.black, blurRadius: 8)] : const [],
        );
      }),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: NeonPalette.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NeonPalette.cardHi,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(.55)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NeonPalette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shadowColor: NeonPalette.primary.withOpacity(.7),
        elevation: 0,
      ),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(.08)),
  );
}

/// Nền gradient tím–xanh cho toàn app
class NeonGradientBackground extends StatelessWidget {
  final Widget child;
  const NeonGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeonPalette.bgTop, NeonPalette.bgBottom],
        ),
      ),
      child: child,
    );
  }
}

/// Thẻ neo-morphism có viền sáng + bóng mềm
class NeoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final Color? glow;
  const NeoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.radius = 22,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surface;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.45), blurRadius: 22, offset: const Offset(0, 14)),
          BoxShadow(color: (glow ?? NeonPalette.cyan).withOpacity(.08), blurRadius: 26, spreadRadius: 2),
        ],
        border: Border.all(color: Colors.white.withOpacity(.08), width: 1.2),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Nút phát sáng (glow)
class GlowButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const GlowButton({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(color: NeonPalette.cyan.withOpacity(.35), blurRadius: 18),
      ]),
      child: FilledButton(onPressed: onPressed, child: child),
    );
  }
}
