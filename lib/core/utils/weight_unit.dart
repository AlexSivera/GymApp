// Every weight is stored in the database as kilograms — this is only about
// how it's *displayed and entered*. Keeping storage unit-agnostic means
// switching the setting never needs a data migration.
enum WeightUnit { kg, lb }

const _kgPerLb = 0.45359237;

WeightUnit weightUnitFromSetting(String? value) => value == 'lb' ? WeightUnit.lb : WeightUnit.kg;

double kgToLb(double kg) => kg / _kgPerLb;

double lbToKg(double lb) => lb * _kgPerLb;

/// Converts a kg value (as stored) into the user's preferred display unit.
double kgToDisplayUnit(double kg, WeightUnit unit) => unit == WeightUnit.lb ? kgToLb(kg) : kg;

/// Converts a value the user typed in their preferred unit back to kg for storage.
double displayUnitToKg(double value, WeightUnit unit) => unit == WeightUnit.lb ? lbToKg(value) : value;

String weightUnitLabel(WeightUnit unit) => unit == WeightUnit.lb ? 'lb' : 'kg';

String _fmtNumber(double value, int decimals) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(decimals);

/// "82.5 kg" or "181.9 lb" from a kg value, respecting [unit].
String formatWeight(double kg, WeightUnit unit, {int decimals = 1}) {
  final converted = kgToDisplayUnit(kg, unit);
  return '${_fmtNumber(converted, decimals)} ${weightUnitLabel(unit)}';
}

/// Same as [formatWeight] but without the unit suffix, for places that render
/// the unit separately (e.g. next to a shared label for two stacked numbers).
String formatWeightValue(double kg, WeightUnit unit, {int decimals = 1}) =>
    _fmtNumber(kgToDisplayUnit(kg, unit), decimals);
