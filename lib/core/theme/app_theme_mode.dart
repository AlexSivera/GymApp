/// The 5 visual themes the user can pick in Configuración. Persisted as
/// [key] in UserSettings.themeMode; [fromKey] must tolerate unknown/legacy
/// values so a bad DB value never crashes app startup.
enum AppThemeMode {
  dark('dark', 'Oscuro'),
  light('light', 'Claro'),
  pastel('pastel', 'Pastel'),
  pastelGreen('pastel_green', 'Pastel verde'),
  pastelBlue('pastel_blue', 'Pastel azul');

  const AppThemeMode(this.key, this.label);

  final String key;
  final String label;

  static AppThemeMode fromKey(String? key) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.key == key,
      orElse: () => AppThemeMode.dark,
    );
  }
}
