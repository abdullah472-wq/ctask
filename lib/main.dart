// lib/main.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// App modules
import 'app_init.dart';
import 'app_error.dart';
import 'app_theme.dart';

// Localization
import 'localization/localization_wrapper.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MAIN ENTRY POINT
/// ═══════════════════════════════════════════════════════════════════════════
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handling
  setupGlobalErrorHandler();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runZonedGuarded(() async {
    try {
      // Load environment variables
      await loadEnvironment();

      // Initialize Firebase
      await initializeFirebase();

      // Initialize push notifications
      await initializePushNotifications();

      // Initialize all services
      await initializeAllServices();

      // Run app
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocalizationWrapper()),
          ],
          child: const FindUsApp(),
        ),
      );
    } catch (error, stackTrace) {
      handleFatalInitializationError(error, stackTrace);
    }
  }, (error, stack) {
    log("❌ Async Error: $error", error: error, stackTrace: stack);
  });
}