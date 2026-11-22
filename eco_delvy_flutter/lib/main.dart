// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'client.dart';
import 'core/theme/app_theme.dart';
import 'screens/optimizer_screen.dart';
import 'screens/sign_in_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const EcoDelvyApp());
}

class EcoDelvyApp extends StatelessWidget {
  const EcoDelvyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoDelvy Fleet Optimizer',
      theme: AppTheme.light,
      home: SignInScreen(child: const OptimizerScreen()),
    );
  }
}
