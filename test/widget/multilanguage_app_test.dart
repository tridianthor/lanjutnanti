import 'package:lanjut_nanti/app/app_dependencies.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/settings/application/locale_controller.dart';
import 'package:lanjut_nanti/features/settings/domain/locale_preference.dart';
import '../unit/features/settings/locale_controller_test.dart'
    show FakeRepository;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/app/app.dart';

void main() {
  testWidgets('selecting Indonesian updates the home screen', (tester) async {
    await tester.pumpWidget(const LanjutNantiApp());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Language'), findsOneWidget);
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bahasa'), findsOneWidget);
    expect(find.text('Cari konten'), findsOneWidget);
    expect(find.text('Belum ada konten'), findsOneWidget);
  });
  for (final locale in [
    const Locale('id', 'ID'),
    const Locale('en', 'GB'),
    const Locale('fr', 'FR'),
  ]) {
    testWidgets('device $locale resolves to supported base language', (
      tester,
    ) async {
      tester.binding.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const LanjutNantiApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      expect(
        Localizations.localeOf(context).languageCode,
        locale.languageCode == 'id' ? 'id' : 'en',
      );
    });
  }
  testWidgets('read and write failures offer localized recovery', (
    tester,
  ) async {
    final repo = FakeRepository()..failRead = true;
    final controller = LocaleController(repo);
    await controller.load();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      LanjutNantiApp(
        dependencies: AppDependencies(
          clock: const SystemClock(),
          idGenerator: RandomIdGenerator(),
          localeController: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Could not read your language preference. Using System default.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    repo.failWrite = true;
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Could not save your language preference. Try selecting it again.',
      ),
      findsOneWidget,
    );
    expect(controller.preference, LocalePreference.system);
    repo.failWrite = false;
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byTooltip('Bahasa'), findsOneWidget);
  });

  testWidgets(
    'preferred locale list [fr_FR, id_ID] resolves to supported Indonesian',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [
        const Locale('fr', 'FR'),
        const Locale('id', 'ID'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const LanjutNantiApp());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      expect(Localizations.localeOf(context).languageCode, 'id');
      expect(find.text('Belum ada konten'), findsOneWidget);
    },
  );

  testWidgets(
    'choosing system default removes saved override and follows device locale',
    (tester) async {
      final repo = FakeRepository()..preference = LocalePreference.indonesian;
      final controller = LocaleController(repo);
      await controller.load();
      addTearDown(controller.dispose);
      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(
        LanjutNantiApp(
          dependencies: AppDependencies(
            clock: const SystemClock(),
            idGenerator: RandomIdGenerator(),
            localeController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Bahasa'), findsOneWidget);
      expect(find.text('Belum ada konten'), findsOneWidget);

      await tester.tap(find.byTooltip('Bahasa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ikuti sistem'));
      await tester.pumpAndSettle();

      expect(controller.preference, LocalePreference.system);
      expect(repo.preference, LocalePreference.system);
      expect(find.byTooltip('Language'), findsOneWidget);
      expect(find.text('No content yet'), findsOneWidget);

      tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bahasa'), findsOneWidget);
      expect(find.text('Belum ada konten'), findsOneWidget);
    },
  );

  testWidgets('home search query is preserved across language switch', (
    tester,
  ) async {
    await tester.pumpWidget(const LanjutNantiApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Manga');
    await tester.pumpAndSettle();
    expect(find.text('Manga'), findsOneWidget);

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Indonesia'));
    await tester.pumpAndSettle();

    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Nama, tag, atau catatan'), findsOneWidget);
  });

  testWidgets(
    'open route and unsaved form input are preserved across system locale change',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const LanjutNantiApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Tambah Konten'));
      await tester.pumpAndSettle();

      expect(find.text('Nama konten'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'One Piece');
      await tester.pumpAndSettle();

      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();

      expect(find.text('One Piece'), findsOneWidget);
      expect(find.text('Content name'), findsOneWidget);
      expect(find.text('Add Content'), findsOneWidget);
    },
  );

  group('Responsive layouts, text scaling, and input methods (ML-012)', () {
    for (final entry in [
      ('mobile 390x844', const Size(390, 844)),
      ('desktop 1440x900', const Size(1440, 900)),
    ]) {
      testWidgets('language dialog and forms are usable at ${entry.$1}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(entry.$2);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const LanjutNantiApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Language'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('System default'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Bahasa Indonesia'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        await tester.tap(find.byTooltip('Add Content'));
        await tester.pumpAndSettle();
        expect(find.text('Add Content'), findsOneWidget);
        expect(find.text('Content name'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'Responsive test');
        await tester.pumpAndSettle();
        expect(find.text('Responsive test'), findsOneWidget);
      });
    }

    testWidgets('language dialog supports Escape key dismissal on desktop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const LanjutNantiApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'renders cleanly with 1.5x enlarged text scaling without overflow',
      (tester) async {
        tester.binding.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );

        await tester.pumpWidget(const LanjutNantiApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Language'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Bahasa Indonesia'), findsOneWidget);

        await tester.tap(find.text('Bahasa Indonesia'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byTooltip('Bahasa'), findsOneWidget);
      },
    );
  });
}
