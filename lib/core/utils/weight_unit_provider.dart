import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/providers/dashboard_providers.dart';
import 'weight_unit.dart';

/// The user's preferred weight unit, derived from UserSettings.units.
/// Defaults to kg while settings are still loading (matches the app's
/// original hardcoded behavior, so there's no flash of "lb" on cold start).
final weightUnitProvider = Provider<WeightUnit>((ref) {
  final settings = ref.watch(userSettingsProvider).valueOrNull;
  return weightUnitFromSetting(settings?.units);
});
