import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/platform/web_bridge.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class GymApp extends ConsumerWidget {
  const GymApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    // Browser toolbar / installed-PWA status bar follows the active palette
    // (no-op on native).
    setBrowserThemeColor(AppTheme.colorsFor(themeMode).background);
    return MaterialApp.router(
      title: 'Machoke',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(themeMode),
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
