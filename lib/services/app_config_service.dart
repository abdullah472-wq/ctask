// lib/services/app_config_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConfigService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // 📊 APP STATE
  // ════════════════════════════════════════════════════════════════════════════

  static bool isAppInMaintenance = false;
  static bool isSignupDisabled = false;
  static bool isPostingDisabled = false;
  static bool isPaymentDisabled = false;

  static String minAppVersion = '1.0.0';
  static String recommendedVersion = '1.0.0';
  static String maintenanceNote = '';
  static String updateMessage = '';

  // ✅ Feature Flags
  static bool enableNewFeatures = true;
  static bool enablePushNotifications = true;
  static bool enableAnalytics = true;

  // ✅ Notification for UI updates
  static final ValueNotifier<bool> configNotifier = ValueNotifier(false);

  // ✅ Stream subscription for real-time updates
  static StreamSubscription<DocumentSnapshot>? _configSubscription;

  // ════════════════════════════════════════════════════════════════════════════
  // 🚀 INITIALIZATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Initialize app config with real-time updates
  static Future<void> init() async {
    try {
      // ✅ 1. Load cached config first (for offline mode)
      await _loadCachedConfig();

      // ✅ 2. Fetch latest config from Firestore
      await _fetchConfig();

      // ✅ 3. Listen for real-time updates
      _startConfigListener();

      debugPrint("✅ AppConfigService initialized");
    } catch (e) {
      debugPrint("❌ Error initializing AppConfigService: $e");
      // App will continue with default/cached values
    }
  }

  /// Fetch config once
  static Future<void> _fetchConfig() async {
    try {
      final doc = await _db.collection('appConfig').doc('global').get();

      if (!doc.exists) {
        debugPrint("⚠️ appConfig/global document not found");
        return;
      }

      _updateConfigFromDoc(doc);
      await _cacheConfig(doc.data() ?? {});

      debugPrint("✅ Config fetched successfully");
    } catch (e) {
      debugPrint("❌ Error fetching config: $e");
      rethrow;
    }
  }

  /// Listen for real-time config updates
  static void _startConfigListener() {
    _configSubscription?.cancel();

    _configSubscription = _db
        .collection('appConfig')
        .doc('global')
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              debugPrint("🔄 Config updated from Firestore");
              _updateConfigFromDoc(doc);
              _cacheConfig(doc.data() ?? {});

              // Notify UI
              configNotifier.value = !configNotifier.value;
            }
          },
          onError: (error) {
            debugPrint("❌ Config listener error: $error");
          },
        );
  }

  /// Update in-memory config from Firestore doc
  static void _updateConfigFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Maintenance & Restrictions
    isAppInMaintenance = data['isAppInMaintenance'] == true;
    isSignupDisabled = data['isSignupDisabled'] == true;
    isPostingDisabled = data['isPostingDisabled'] == true;
    isPaymentDisabled = data['isPaymentDisabled'] == true;

    // Version Control
    minAppVersion = (data['minAppVersion'] ?? '1.0.0').toString();
    recommendedVersion = (data['recommendedVersion'] ?? '1.0.0').toString();

    // Messages
    maintenanceNote = (data['maintenanceNote'] ?? '').toString();
    updateMessage =
        (data['updateMessage'] ??
                'A new version is available. Please update for the best experience.')
            .toString();

    // Feature Flags
    enableNewFeatures = data['enableNewFeatures'] != false;
    enablePushNotifications = data['enablePushNotifications'] != false;
    enableAnalytics = data['enableAnalytics'] != false;

    debugPrint("📝 Config updated: Maintenance=$isAppInMaintenance");
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💾 CACHING
  // ════════════════════════════════════════════════════════════════════════════

  /// Save config to SharedPreferences for offline access
  static Future<void> _cacheConfig(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
        'isAppInMaintenance',
        data['isAppInMaintenance'] == true,
      );
      await prefs.setBool('isSignupDisabled', data['isSignupDisabled'] == true);
      await prefs.setBool(
        'isPostingDisabled',
        data['isPostingDisabled'] == true,
      );
      await prefs.setString('minAppVersion', data['minAppVersion'] ?? '1.0.0');
      await prefs.setString('maintenanceNote', data['maintenanceNote'] ?? '');

      debugPrint("💾 Config cached");
    } catch (e) {
      debugPrint("❌ Error caching config: $e");
    }
  }

  /// Load config from cache
  static Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      isAppInMaintenance = prefs.getBool('isAppInMaintenance') ?? false;
      isSignupDisabled = prefs.getBool('isSignupDisabled') ?? false;
      isPostingDisabled = prefs.getBool('isPostingDisabled') ?? false;
      minAppVersion = prefs.getString('minAppVersion') ?? '1.0.0';
      maintenanceNote = prefs.getString('maintenanceNote') ?? '';

      debugPrint("📂 Cached config loaded");
    } catch (e) {
      debugPrint("❌ Error loading cached config: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔍 VERSION CHECKING
  // ════════════════════════════════════════════════════════════════════════════

  /// Check if app update is required
  static Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      return _isVersionLower(currentVersion, minAppVersion);
    } catch (e) {
      debugPrint("❌ Error checking version: $e");
      return false;
    }
  }

  /// Check if app update is recommended
  static Future<bool> isUpdateRecommended() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      return _isVersionLower(currentVersion, recommendedVersion);
    } catch (e) {
      debugPrint("❌ Error checking recommended version: $e");
      return false;
    }
  }

  /// Compare two version strings (e.g., "1.2.3" vs "1.3.0")
  static bool _isVersionLower(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minimumParts = minimum.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final currentPart = currentParts.length > i ? currentParts[i] : 0;
        final minimumPart = minimumParts.length > i ? minimumParts[i] : 0;

        if (currentPart < minimumPart) return true;
        if (currentPart > minimumPart) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      debugPrint("❌ Version comparison error: $e");
      return false;
    }
  }

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint("❌ Error getting version: $e");
      return '1.0.0';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎯 FEATURE CHECKS
  // ════════════════════════════════════════════════════════════════════════════

  /// Check if a specific feature is enabled
  static bool isFeatureEnabled(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'signup':
        return !isSignupDisabled;
      case 'posting':
        return !isPostingDisabled;
      case 'payment':
        return !isPaymentDisabled;
      case 'notifications':
        return enablePushNotifications;
      case 'analytics':
        return enableAnalytics;
      case 'new_features':
        return enableNewFeatures;
      default:
        return true;
    }
  }

  /// Get feature-specific message
  static String getFeatureDisabledMessage(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'signup':
        return 'New signups are temporarily disabled. Please try again later.';
      case 'posting':
        return 'Job posting is temporarily disabled. Please try again later.';
      case 'payment':
        return 'Payments are temporarily disabled. Please try again later.';
      default:
        return 'This feature is temporarily unavailable.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🧹 CLEANUP
  // ════════════════════════════════════════════════════════════════════════════

  /// Dispose listeners
  static void dispose() {
    _configSubscription?.cancel();
    configNotifier.dispose();
    debugPrint("🧹 AppConfigService disposed");
  }

  /// Refresh config manually
  static Future<void> refresh() async {
    debugPrint("🔄 Manually refreshing config...");
    await _fetchConfig();
  }
}
