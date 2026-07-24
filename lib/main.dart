import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/theme.dart';
import 'features/auth/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SprintApp());
}

class SprintApp extends StatelessWidget {
  const SprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.I,
      builder: (context, _) {
        final dark = ThemeController.I.effectiveDark;
        AppColors.dark = dark;
        // Системные полосы (статус-бар и панель навигации Android) красим
        // вместе с темой — иначе жестовая полоса снизу остаётся от старой темы.
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: AppColors.bgOf(dark),
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ));
        return MaterialApp(
          title: 'Спринт · Курьер',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(false),
          darkTheme: AppTheme.build(true),
          themeMode: ThemeController.I.mode,
          builder: (context, child) {
            // Синхронизируем глобальный флаг с фактической темой MaterialApp.
            AppColors.dark = Theme.of(context).brightness == Brightness.dark;
            return child!;
          },
          home: const LoginPage(),
        );
      },
    );
  }
}
