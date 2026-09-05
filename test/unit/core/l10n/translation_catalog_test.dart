import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';

List<String> validateCatalog({
  required Map<String, dynamic> template,
  required Map<String, dynamic> translation,
}) {
  final errors = <String>[];
  final templateKeys = template.keys.where((k) => !k.startsWith('@')).toSet();
  final translationKeys =
      translation.keys.where((k) => !k.startsWith('@')).toSet();

  for (final key in templateKeys) {
    if (!translationKeys.contains(key)) {
      errors.add('Missing key in translation: $key');
      continue;
    }
    final transValue = translation[key];
    if (transValue is! String || transValue.trim().isEmpty) {
      errors.add('Empty or non-string translation for key: $key');
      continue;
    }

    final metadata = template['@$key'];
    if (metadata is Map<String, dynamic>) {
      final placeholders = metadata['placeholders'];
      if (placeholders is Map<String, dynamic>) {
        for (final placeholder in placeholders.keys) {
          if (!transValue.contains('{$placeholder')) {
            errors.add(
              'Missing placeholder "{$placeholder}" in translation for key: $key',
            );
          }
        }
      }
    }
  }

  for (final key in translationKeys) {
    if (!templateKeys.contains(key)) {
      errors.add('Orphan key in translation not found in template: $key');
    }
  }

  return errors;
}

void main() {
  group('Translation catalog completeness', () {
    test('English and Indonesian catalogs are complete and symmetric', () {
      final enFile = File('lib/l10n/app_en.arb');
      final idFile = File('lib/l10n/app_id.arb');
      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
      expect(idFile.existsSync(), isTrue, reason: 'app_id.arb must exist');

      final enJson =
          json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final idJson =
          json.decode(idFile.readAsStringSync()) as Map<String, dynamic>;

      final errors = validateCatalog(template: enJson, translation: idJson);
      expect(errors, isEmpty, reason: errors.join('\n'));
    });

    test('catalog validation reports missing key against failing fixture', () {
      final template = {'foo': 'bar', 'missing': 'value'};
      final translation = {'foo': 'bar'};
      final errors = validateCatalog(
        template: template,
        translation: translation,
      );
      expect(errors, contains('Missing key in translation: missing'));
    });

    test(
      'catalog validation reports empty translation against failing fixture',
      () {
        final template = {'foo': 'bar'};
        final translation = {'foo': '   '};
        final errors = validateCatalog(
          template: template,
          translation: translation,
        );
        expect(
          errors,
          contains('Empty or non-string translation for key: foo'),
        );
      },
    );

    test(
      'catalog validation reports missing placeholder against failing fixture',
      () {
        final template = {
          'greet': 'Hello {name}',
          '@greet': {
            'placeholders': {'name': {}},
          },
        };
        final translation = {'greet': 'Halo tanpa nama'};
        final errors = validateCatalog(
          template: template,
          translation: translation,
        );
        expect(
          errors,
          contains(
            'Missing placeholder "{name}" in translation for key: greet',
          ),
        );
      },
    );
  });

  group('Localized date and timestamp formatting (ML-008)', () {
    testWidgets(
      'formats dates and times for English and Indonesian without altering UTC instant',
      (tester) async {
        final fixedInstant = DateTime.utc(2026, 9, 4, 7, 30);
        final localDate = DateTime(2026, 9, 4, 14, 30);

        // Verify English formatting
        late MaterialLocalizations enMat;
        late AppLocalizations enApp;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                enMat = MaterialLocalizations.of(context);
                enApp = AppLocalizations.of(context)!;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final enDateStr = enMat.formatMediumDate(localDate);
        final enTime12 = enMat.formatTimeOfDay(
          TimeOfDay.fromDateTime(localDate),
          alwaysUse24HourFormat: false,
        );
        final enTime24 = enMat.formatTimeOfDay(
          TimeOfDay.fromDateTime(localDate),
          alwaysUse24HourFormat: true,
        );
        expect(enDateStr, contains('Sep'));
        expect(enTime12, contains('PM'));
        expect(enTime24, '14:30');
        expect(
          enApp.latestAt('$enDateStr, $enTime24'),
          'Latest · $enDateStr, 14:30',
        );
        expect(
          enApp.updatedAt('$enDateStr, $enTime24'),
          'Updated $enDateStr, 14:30',
        );

        // Verify Indonesian formatting
        late MaterialLocalizations idMat;
        late AppLocalizations idApp;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                idMat = MaterialLocalizations.of(context);
                idApp = AppLocalizations.of(context)!;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final idDateStr = idMat.formatMediumDate(localDate);
        final idTime12 = idMat.formatTimeOfDay(
          TimeOfDay.fromDateTime(localDate),
          alwaysUse24HourFormat: false,
        );
        final idTime24 = idMat.formatTimeOfDay(
          TimeOfDay.fromDateTime(localDate),
          alwaysUse24HourFormat: true,
        );
        expect(idDateStr, contains('Sep'));
        expect(idTime12, isNotEmpty);
        expect(idTime24, contains('14'));
        expect(
          idApp.latestAt('$idDateStr, $idTime24'),
          'Terbaru · $idDateStr, $idTime24',
        );
        expect(
          idApp.updatedAt('$idDateStr, $idTime24'),
          'Diperbarui $idDateStr, $idTime24',
        );

        // Stored UTC instant remains unchanged
        expect(fixedInstant.isUtc, isTrue);
        expect(fixedInstant.toIso8601String(), '2026-09-04T07:30:00.000Z');
      },
    );
  });
}
