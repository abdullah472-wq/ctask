// lib/app_theme.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

// Services
import 'services/theme_service.dart';
import 'services/app_config_service.dart';
import 'services/push_notification_service.dart';
import 'badge/badge_service.dart';
import 'achievement/achievement_service.dart';

// Constants
import 'constants/app_colors.dart';

// Localization
import 'localization/localization_wrapper.dart';
import 'localization/app_localizations_delegate.dart';

// Screens
import 'splash_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// APP THEME AND LOCALIZATION
/// ═══════════════════════════════════════════════════════════════════════════

class FindUsApp extends StatefulWidget {
  const FindUsApp({super.key});

  @override
  State<FindUsApp> createState() => _FindUsAppState();
}

class _FindUsAppState extends State<FindUsApp> with WidgetsBindingObserver {
  bool _servicesInitialized = false;
  bool _isFirstLaunch = true;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ✅ FIX: Use correct type for connectivity_plus
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePushNotifications();
    _listenToConnectivity();
    _checkServices();
    _checkAppVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePushNotifications() async {
    try {
      await PushNotificationService.init(navKey: navigatorKey);
      if (kDebugMode) log("✅ Push notifications initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ Push notification init failed: $e");
    }
  }

  // ✅ FIX: Connectivity Plus returns single ConnectivityResult
  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
        // ✅ Single result, not List
        final isConnected = result != ConnectivityResult.none;

        if (_isOnline != isConnected) {
          setState(() {
            _isOnline = isConnected;
          });

          if (kDebugMode) {
            log(isConnected ? "🌐 Internet connected" : "📡 No internet");
          }

          if (isConnected) {
            _refreshOnResume();
          }
        }
      },
      onError: (error) {
        if (kDebugMode) log("⚠️ Connectivity listener error: $error");
      },
    );
  }

  Future<void> _checkAppVersion() async {
    try {
      await Future.delayed(const Duration(seconds: 3));

      final updateRequired = await AppConfigService.isUpdateRequired();
      final updateRecommended = await AppConfigService.isUpdateRecommended();

      if (!mounted) return;

      if (updateRequired) {
        _showForceUpdateDialog();
      } else if (updateRecommended) {
        _showOptionalUpdateDialog();
      }
    } catch (e) {
      if (kDebugMode) log("⚠️ Version check failed: $e");
    }
  }

  void _showForceUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false, // ✅ Use PopScope instead of WillPopScope
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update, color: AppColors.brandMain, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Update Required',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfigService.updateMessage.isNotEmpty
                    ? AppConfigService.updateMessage
                    : 'A critical update is required to continue using the app.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update includes important security improvements.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Open app store
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionalUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version is available with exciting features and improvements!',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'What\'s New',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Improved performance\n• Bug fixes\n• New features',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Open app store
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _checkServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final achievements = AchievementService.achievementsNotifier.value;
        final badgeProgress = BadgeService.badgeNotifier.value;

        final isReady = achievements.isNotEmpty && badgeProgress.totalXP >= 0;

        if (kDebugMode) {
          log(
            "📊 Service Status - Achievements: ${achievements.length}, "
                "Badge XP: ${badgeProgress.totalXP}, Ready: $isReady",
          );
        }

        if (mounted) {
          setState(() {
            _servicesInitialized = isReady;
          });
        }

        if (!isReady && _retryCount < _maxRetries) {
          _scheduleRetry();
        }
      } catch (e) {
        if (kDebugMode) log("⚠️ Error checking services: $e");
        if (_retryCount < _maxRetries) {
          _scheduleRetry();
        } else {
          if (kDebugMode) log("⚠️ Max retries reached. Proceeding with app launch.");
          if (mounted) {
            setState(() {
              _servicesInitialized = true;
            });
          }
        }
      }
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _retryCount++;
        if (kDebugMode) {
          log("🔄 Scheduling retry ${_retryCount}/$_maxRetries...");
        }
        _retryServices();
      }
    });
  }

  Future<void> _retryServices() async {
    try {
      if (kDebugMode) {
        log("🔄 Retrying service initialization (attempt $_retryCount/$_maxRetries)...");
      }

      await Future.wait([
        AchievementService.init(),
        BadgeService.init(),
      ]).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }

      if (kDebugMode) log("✅ Services re-initialized successfully");
    } catch (e) {
      if (kDebugMode) log("❌ Failed to re-initialize services: $e");

      if (_retryCount >= _maxRetries) {
        if (kDebugMode) log("⚠️ Max retries reached. Proceeding anyway.");
        if (mounted) {
          setState(() {
            _servicesInitialized = true;
          });
        }
      }
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    ThemeService.onSystemThemeChanged();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (kDebugMode) log("📱 App resumed");
        _refreshOnResume();
        break;

      case AppLifecycleState.paused:
        if (kDebugMode) log("⏸️ App paused");
        break;

      case AppLifecycleState.inactive:
        if (kDebugMode) log("😴 App inactive");
        break;

      case AppLifecycleState.detached:
        if (kDebugMode) log("🔌 App detached");
        break;

      case AppLifecycleState.hidden:
        if (kDebugMode) log("🙈 App hidden");
        break;
    }
  }

  Future<void> _refreshOnResume() async {
    if (!_isOnline) {
      if (kDebugMode) log("⚠️ Cannot refresh - offline");
      return;
    }

    try {
      await Future.wait([
        AppConfigService.refresh(),
        AchievementService.syncWeeklyChestFromServer(),
      ]).timeout(const Duration(seconds: 5));

      if (kDebugMode) log("✅ Data refreshed on resume");
    } catch (e) {
      if (kDebugMode) log("⚠️ Refresh on resume failed: $e");
    }
  }

  void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, themeSettings, _) {
        final isDark = themeSettings.isDarkMode;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateSystemUI(isDark);
        });

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'FINDUS',
          themeMode: themeSettings.isAutoTheme
              ? ThemeMode.system
              : (isDark ? ThemeMode.dark : ThemeMode.light),
          theme: _buildTheme(isDark: false, settings: themeSettings),
          darkTheme: _buildTheme(isDark: true, settings: themeSettings),

          // ════════════════════════════════════════════════════════════════
          // LOCALIZATION
          // ════════════════════════════════════════════════════════════════
          locale: context.read<LocalizationWrapper>().locale,
          supportedLocales: AppLocalizationsDelegate.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: AppLocalizationsDelegate.localeResolutionCallback,

          home: const MySplashScreen(),
          builder: (context, child) => _buildAppWrapper(
            context: context,
            child: child,
            isDark: isDark,
            settings: themeSettings,
          ),
        );
      },
    );
  }

  Widget _buildAppWrapper({
    required BuildContext context,
    required Widget? child,
    required bool isDark,
    required ThemeSettings settings,
  }) {
    final mediaQuery = MediaQuery.of(context);

    // Show loading on first launch
    if (!_servicesInitialized && _isFirstLaunch) {
      return Material(
        color: isDark
            ? (settings.useAmoledBlack ? Colors.black : const Color(0xFF1A1A1A))
            : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ FIX: Remove const - AppColors.brandMain is not const
              CircularProgressIndicator(color: AppColors.brandMain),
              const SizedBox(height: 20),
              Text(
                'Loading services...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isFirstLaunch && _servicesInitialized) {
      _isFirstLaunch = false;
    }

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(settings.fontSize),
        disableAnimations: settings.isReducedMotion,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  ThemeData _buildTheme({
    required bool isDark,
    required ThemeSettings settings,
  }) {
    // ✅ FIX: Get accent color properly
    final primaryColor = settings.isHighContrast
        ? (isDark ? Colors.white : Colors.black)
        : settings.accentColor.color;

    final scaffoldBg = isDark
        ? (settings.useAmoledBlack ? Colors.black : const Color(0xFF1A1A1A))
        : AppColors.bgBlue;

    final cardBg = isDark
        ? (settings.useAmoledBlack ? const Color(0xFF0A0A0A) : const Color(0xFF2C2C2C))
        : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Poppins',
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: scaffoldBg,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ✅ FIX: Use CardTheme.of() pattern or just set properties
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: settings.isReducedMotion ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        thickness: 0.5,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldBg,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? Colors.grey : Colors.grey.shade600,
        elevation: 8,
      ),
    );
  }
}