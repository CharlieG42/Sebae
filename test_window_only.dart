import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
  
  await windowManager.maximize();
  await windowManager.show();
  
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Test Window')),
        body: Center(child: Text('Window Manager Test')),
      ),
    ),
  );
}
