import 'package:flutter/material.dart';

import 'shell/home_shell.dart';

/// Application Sebae - plateforme modulaire d'outils métier.
class SebaeApp extends StatelessWidget {
  const SebaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sebae',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
