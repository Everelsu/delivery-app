import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Управление темой (светлая/тёмная/системная). Синглтон-ChangeNotifier.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController I = ThemeController._();

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void set(ThemeMode m) {
    _mode = m;
    notifyListeners();
  }

  /// Эффективная тёмность без зависимости от context (для системного режима
  /// берём яркость платформы напрямую) — чтобы значение было корректно уже
  /// на первом кадре и при переключении.
  bool get effectiveDark => switch (_mode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
      };
}

/// Дизайн-система «Спринт» — зелёно-красная схема (в духе продуктового ритейла).
/// Бренд-цвета одинаковы в обеих темах; семантические зависят от [AppColors.dark].
class AppColors {
  static bool dark = false;

  // --- Бренд и статусы ---
  static const primary = Color(0xFF43A82E); // фирменный зелёный
  static const primaryDark = Color(0xFF2E7D1E);
  static const accent = Color(0xFFE30A17); // фирменный красный

  static const success = Color(0xFF2FA84F);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFE30A17);
  static const info = Color(0xFF2B7FFF);
  static const violet = Color(0xFF6D4AE0);

  // --- Семантические (тема-зависимые) ---
  static Color inkOf(bool d) => d ? const Color(0xFFEDF1F5) : const Color(0xFF16261B);
  static Color inkSoftOf(bool d) => d ? const Color(0xFFC2C9D2) : const Color(0xFF3A4A40);
  static Color mutedOf(bool d) => d ? const Color(0xFF929BA6) : const Color(0xFF6B7A70);
  static Color faintOf(bool d) => d ? const Color(0xFF667080) : const Color(0xFF9CA8A0);
  static Color lineOf(bool d) => d ? const Color(0xFF262D37) : const Color(0xFFE6EBE6);
  static Color bgOf(bool d) => d ? const Color(0xFF0B0F14) : const Color(0xFFF3F6F2);
  static Color surfaceOf(bool d) => d ? const Color(0xFF161C24) : const Color(0xFFFFFFFF);
  static Color primarySoftOf(bool d) => d ? const Color(0xFF163019) : const Color(0xFFE7F5E2);
  static Color accentSoftOf(bool d) => d ? const Color(0xFF3A1517) : const Color(0xFFFCE3E4);

  static Color get ink => inkOf(dark);
  static Color get inkSoft => inkSoftOf(dark);
  static Color get muted => mutedOf(dark);
  static Color get faint => faintOf(dark);
  static Color get line => lineOf(dark);
  static Color get bg => bgOf(dark);
  static Color get surface => surfaceOf(dark);
  static Color get primarySoft => primarySoftOf(dark);
  static Color get accentSoft => accentSoftOf(dark);
}

class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.dark ? 0.35 : 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
  static List<BoxShadow> get lift => [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.dark ? 0.5 : 0.10),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ];
}

class AppTheme {
  static ThemeData build(bool dark) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final ink = AppColors.inkOf(dark);
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: brightness,
        surface: AppColors.surfaceOf(dark),
      ),
      scaffoldBackgroundColor: AppColors.bgOf(dark),
      fontFamily: GoogleFonts.rubik().fontFamily,
    );

    return base.copyWith(
      textTheme: _textTheme(dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: ink),
        titleTextStyle: GoogleFonts.rubik(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AppColors.lineOf(dark),
    );
  }

  static TextTheme _textTheme(bool dark) {
    TextStyle s(double size, FontWeight w, {double h = 1.25, double ls = -0.2, Color? c}) =>
        GoogleFonts.rubik(fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: c ?? AppColors.inkOf(dark));
    return TextTheme(
      displaySmall: s(30, FontWeight.w800, ls: -0.8),
      headlineMedium: s(26, FontWeight.w800, ls: -0.6),
      headlineSmall: s(22, FontWeight.w800, ls: -0.5),
      titleLarge: s(19, FontWeight.w800, ls: -0.4),
      titleMedium: s(16, FontWeight.w700, ls: -0.2),
      bodyLarge: s(15.5, FontWeight.w500, h: 1.4, ls: -0.1),
      bodyMedium: s(14, FontWeight.w500, h: 1.4, ls: -0.1, c: AppColors.inkSoftOf(dark)),
      bodySmall: s(12.5, FontWeight.w600, h: 1.3, ls: 0, c: AppColors.mutedOf(dark)),
      labelLarge: s(14, FontWeight.w700, ls: 0),
    );
  }
}

/// Утилита: капсула-бейдж.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.text,
    this.color = AppColors.primary,
    this.bg,
    this.icon,
  });
  final String text;
  final Color color;
  final Color? bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 11 : 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
