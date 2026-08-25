import 'package:health/health.dart';

// Wraps the `health` package's Health Connect access down to just what the
// app needs: calories actually burned during a workout window, as recorded
// by whatever wearable app (Mi Fitness, etc.) writes into Health Connect.
// Trackers are inconsistent about which of the two calorie types they
// actually populate — some only ever write TOTAL_CALORIES_BURNED for a
// workout, others only ACTIVE_ENERGY_BURNED — so both are requested and
// queried, preferring total (it's usually what the wearable's own workout
// screen shows) and falling back to active only if total has nothing.
class HealthConnectService {
  const HealthConnectService();

  static const _types = [HealthDataType.TOTAL_CALORIES_BURNED, HealthDataType.ACTIVE_ENERGY_BURNED];
  static const _permissions = [HealthDataAccess.READ, HealthDataAccess.READ];

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

  // Calories burned in [start, end) as recorded by Health Connect, or null if
  // it has nothing for that window (band not worn, not synced yet,
  // permission revoked) so callers know to fall back to the app's own
  // estimate.
  Future<double?> caloriesBurnedInRange(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) return null;
    if (!await hasPermissions()) return null;

    final points = await Health().getHealthDataFromTypes(
      types: _types,
      startTime: start,
      endTime: end,
    );
    if (points.isEmpty) return null;

    final totalCalories = _sum(points, HealthDataType.TOTAL_CALORIES_BURNED);
    if (totalCalories != null) return totalCalories;
    return _sum(points, HealthDataType.ACTIVE_ENERGY_BURNED);
  }

  double? _sum(List<HealthDataPoint> points, HealthDataType type) {
    var total = 0.0;
    for (final point in points) {
      if (point.type != type) continue;
      final value = point.value;
      if (value is NumericHealthValue) total += value.numericValue.toDouble();
    }
    return total > 0 ? total : null;
  }
}
