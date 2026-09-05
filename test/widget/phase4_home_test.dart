import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';

void main() {
  testWidgets('empty home state offers an Add Content action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: HomeScreen(),
      ),
    );

    expect(find.text('No content yet'), findsOneWidget);
    expect(find.text('Add Content'), findsNWidgets(2));
  });
}
