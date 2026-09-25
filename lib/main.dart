import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage/hive_service.dart';
import 'modules/ssdm/services/ssdm_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SsdmService()),
      ],
      child: const SebaeApp(),
    ),
  );
}
