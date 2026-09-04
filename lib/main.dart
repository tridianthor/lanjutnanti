import 'package:flutter/widgets.dart';
import 'package:lanjut_nanti/app/app.dart';
import 'package:lanjut_nanti/app/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.createProduction();
  runApp(LanjutNantiApp(dependencies: dependencies));
}
