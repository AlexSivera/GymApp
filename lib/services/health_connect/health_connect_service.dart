import 'package:health/health.dart';

// Wraps the `health` package's Health Connect access down to just what the
// app needs: calories actually burned during a workout window, as recorded
// by whatever wearable app (Mi Fitness, etc.) writes into Health Connect.
// Active energy (not total, which also includes resting BMR) is the closest
// match to what the MET-based estimator in calories_engine computes, so this
// is a drop-in replacement/fallback pair with it.
class HealthConnectService {
  const HealthConnectService();

  static const _types = [HealthDataType.ACTIVE_ENERGY_BURNED];
  static const _permissions = [HealthDataAccess.READ];

  Future<void> configure() => Health().configure();

  Future<bool> isAvailable() async {
    final status = await Health().getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  Future<bool> hasPermissions() async {
    final granted = await Health().hasPermissions(_types, permissions: _permissions);
    return granted ?? false;
  }

  Future<bool> requestPermissions() async {
    if (await hasPermissions()) return true;
    return Health().requestAuthorization(_types, permissions: _permissions);
  }

  // Total active calories burned in [start, end), or null if Health Connect
  // has nothing for that window (band not worn, not synced yet, permission
  // revoked) so callers know to fall back to the app's own estimate.
  Future<double?> caloriesBurnedInRange(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) return null;
    if (!await hasPermissions()) return null;

    final points = await Health().getHealthDataFromTypes(
      types: _types,
      startTime: start,
      endTime: end,
    );
    if (points.isEmpty) return null;

    var total = 0.0;
    for (final point in points) {
      final value = point.value;
      if (value is NumericHealthValue) total += value.numericValue.toDouble();
    }
    return total > 0 ? total : null;
  }
}
