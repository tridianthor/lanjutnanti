import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';

void main() {
  testWidgets('empty home state offers an Add Content action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Belum ada konten'), findsOneWidget);
    expect(find.text('Add Content'), findsNWidgets(2));
  });
}
