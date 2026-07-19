import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/local_database.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/views/dashboard_screen.dart';
import 'features/ocr/controllers/ocr_controller.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before async setup
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local database (Hive)
  final localDb = LocalDatabase();
  await localDb.init();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the initialized database singleton into the Riverpod graph
        localDatabaseProvider.overrideWithValue(localDb),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current theme mode selection
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'OmniOCR Offline',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
