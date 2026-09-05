enum ThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const ThemePreference(this.storageValue);
  final String storageValue;

  static ThemePreference parse(String? value) => switch (value) {
    null || 'system' => ThemePreference.system,
    'light' => ThemePreference.light,
    'dark' => ThemePreference.dark,
    _ => throw FormatException('Unsupported theme preference', value),
  };
}

