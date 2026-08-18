import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/providers/dashboard_providers.dart';
import 'app_theme_mode.dart';

final appThemeModeProvider = Provider<AppThemeMode>((ref) {
  final settings = ref.watch(userSettingsProvider).valueOrNull;
  return AppThemeMode.fromKey(settings?.themeMode);
});
