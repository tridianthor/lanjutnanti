enum LocalePreference {
  system(null),
  english('en'),
  indonesian('id');

  const LocalePreference(this.languageCode);
  final String? languageCode;

  static LocalePreference parse(String? value) => switch (value) {
    null => LocalePreference.system,
    'en' => LocalePreference.english,
    'id' => LocalePreference.indonesian,
    _ => throw FormatException('Unsupported locale preference', value),
  };
}
