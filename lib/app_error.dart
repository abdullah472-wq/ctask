// lib/app_error.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ERROR HANDLING
/// ═══════════════════════════════════════════════════════════════════════════

void setupGlobalErrorHandler() {
  FlutterError.onError = (details) {
    log(
      "Flutter Error: ${details.exception}",
      error: details.exception,
      stackTrace: details.stack,
    );
  };
}

void handleFatalInitializationError(Object error, StackTrace stackTrace) {
  log(
    "❌ Fatal Initialization Error",
    error: error,
    stackTrace: stackTrace,
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ErrorScreen(
        error: error.toString(),
        stackTrace: stackTrace.toString(),
      ),
    ),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ERROR SCREEN
/// ═══════════════════════════════════════════════════════════════════════════

class _ErrorScreen extends StatelessWidget {
  final String error;
  final String stackTrace;

  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandMain,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'System Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Failed to initialize the app.\nPlease restart or contact support.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error Details:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (kDebugMode)
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: '$error\n\n$stackTrace'),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Error'),
                      ),

                    if (kDebugMode) const SizedBox(width: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brandMain,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Close App'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}