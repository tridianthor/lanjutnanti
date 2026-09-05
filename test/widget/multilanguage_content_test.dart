import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/app/app.dart';

void main() {
  testWidgets(
    'Indonesian content form and tag dialog translate visible validation',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const LanjutNantiApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tambah Konten'));
      await tester.pumpAndSettle();
      expect(find.text('Nama konten'), findsOneWidget);
      await tester.tap(find.text('Simpan Konten'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan nama konten.'), findsOneWidget);
      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();
      expect(find.text('Enter a content name.'), findsOneWidget);
      await tester.tap(find.text('Create tag'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
      await tester.pumpAndSettle();
      expect(find.text('Masukkan nama tag.'), findsOneWidget);
      expect(find.text('Buat tag'), findsWidgets);
    },
  );
  testWidgets('Indonesian detail form validates links and preserves notes', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const LanjutNantiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tambah Konten'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Cerita {é}');
    await tester.tap(find.text('Simpan Konten'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('0 detail'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus konten'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus konten?'), findsOneWidget);
    tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
    await tester.pumpAndSettle();
    expect(find.text('Delete content?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Tautan'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Catatan {é}');
    await tester.tap(find.text('Simpan Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan tautan absolut yang valid.'), findsOneWidget);
    tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid absolute link.'), findsOneWidget);
    expect(find.text('Catatan {é}'), findsOneWidget);
  });

  testWidgets(
    'duplicate tag failure is localized without creating another tag',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const LanjutNantiApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tambah Konten'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Buat tag'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'Manga',
        );
        await tester.tap(find.text('Buat'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Tag dengan nama tersebut sudah ada.'), findsOneWidget);
      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();
      expect(find.text('A tag with that name already exists.'), findsOneWidget);
    },
  );
}
