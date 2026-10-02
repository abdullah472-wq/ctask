// lib/app_init.dart

import 'dart:async';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:connectivity_plus/connectivity_plus.dart';

// Services
import 'badge/badge_service.dart';
import 'services/theme_service.dart';
import 'services/app_config_service.dart';
import 'services/profile_status_service.dart';
import 'services/saved_service.dart';
import 'services/blocked_user_service.dart';
import 'services/push_notification_service.dart';
import 'achievement/achievement_service.dart';
import 'firebase_options.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// INITIALIZATION HELPERS
/// ═══════════════════════════════════════════════════════════════════════════

Future<void> loadEnvironment() async {
  try {
    await dotenv.load(fileName: ".env");
    if (kDebugMode) log("✅ .env loaded");
  } catch (e) {
    if (kDebugMode) log("⚠️ .env file missing (optional) - $e");
  }
}

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) log("✅ Firebase initialized");

    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (kDebugMode) log("✅ Firestore persistence disabled (Web)");
    }
  } catch (e, stack) {
    log("❌ Firebase initialization failed", error: e, stackTrace: stack);
    rethrow;
  }
}

Future<void> initializePushNotifications() async {
  try {
    await PushNotificationService.init(navKey: navigatorKey);
    if (kDebugMode) log("✅ Push notifications initialized");
  } catch (e) {
    if (kDebugMode) log("⚠️ Push notification init failed: $e");
  }
}

Future<void> initializeAllServices() async {
  try {
    if (kDebugMode) log("🚀 Starting service initialization...");

    try {
      await _parallelInitializeServices();
    } on TimeoutException {
      if (kDebugMode) {
        log("⏱️ Parallel initialization timeout - falling back to sequential");
      }
      await _sequentialInitializeServices();
    } catch (e) {
      if (kDebugMode) {
        log("⚠️ Parallel initialization failed - falling back to sequential: $e");
      }
      await _sequentialInitializeServices();
    }

    if (kDebugMode) log("✅ Service initialization completed");
  } catch (e, stack) {
    log("❌ Service initialization error", error: e, stackTrace: stack);
  }
}

Future<void> _parallelInitializeServices() async {
  await Future.wait(
    [
      ThemeService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) log("⏱️ ThemeService timeout");
          throw TimeoutException("ThemeService timeout");
        },
      ),
      AppConfigService.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) log("⏱️ AppConfigService timeout");
          throw TimeoutException("AppConfigService timeout");
        },
      ),
      BadgeService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) log("⏱️ BadgeService timeout");
          throw TimeoutException("BadgeService timeout");
        },
      ),
      AchievementService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) log("⏱️ AchievementService timeout");
          throw TimeoutException("AchievementService timeout");
        },
      ),
    ],
    eagerError: true,
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      if (kDebugMode) log("⏱️ Overall parallel initialization timeout");
      throw TimeoutException("Overall parallel initialization timeout");
    },
  );

  if (kDebugMode) log("✅ Essential services initialized (parallel)");

  _initializeOptionalServices();
}

Future<void> _sequentialInitializeServices() async {
  try {
    if (kDebugMode) log("🔄 Starting sequential initialization...");

    try {
      await ThemeService.init();
      if (kDebugMode) log("✅ ThemeService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ ThemeService failed: $e");
    }

    try {
      await AppConfigService.init();
      if (kDebugMode) log("✅ AppConfigService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ AppConfigService failed: $e");
    }

    try {
      await BadgeService.init();
      if (kDebugMode) log("✅ BadgeService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ BadgeService failed: $e");
    }

    try {
      await AchievementService.init();
      if (kDebugMode) log("✅ AchievementService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ AchievementService failed: $e");
    }

    _initializeOptionalServices();

    if (kDebugMode) log("✅ Sequential initialization completed");
  } catch (e, stack) {
    log("❌ Sequential initialization failed", error: e, stackTrace: stack);
  }
}

void _initializeOptionalServices() {
  ProfileStatusService.init().catchError((e) {
    if (kDebugMode) log("⚠️ ProfileStatusService failed: $e");
  });

  SavedService.init().catchError((e) {
    if (kDebugMode) log("⚠️ SavedService failed: $e");
  });

  BlockedUserService().syncWithFirestore().catchError((e) {
    if (kDebugMode) log("⚠️ BlockedUserService failed: $e");
  });

  if (kDebugMode) log("🔄 Optional services initializing in background...");
}