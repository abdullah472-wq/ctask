// lib/screens/settings/about_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/services/theme_service.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Add this to pubspec.yaml

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  /// Load app version from package info
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load package info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        // ✅ Theme Colors
        final isDark = settings.isDarkMode;
        final colors = _AppColors(
          isDark: isDark,
          useAmoled: settings.useAmoledBlack,
        );

        return FloatingScaffold(
          title: 'ABOUT APP',
          backgroundColor: colors.bgColor,
          titleColor: colors.titleColor,
          iconColor: colors.iconColor,
          showBack: true,
          scrollable: false, // Custom scroll করবো
          bodyPadding: EdgeInsets.zero,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════════
                // APP HEADER CARD
                // ═══════════════════════════════════════════════════════════
                _buildAppHeader(colors),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════════
                // CONTENT SECTIONS
                // ═══════════════════════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // About FINDUS
                      _buildSection(
                        icon: Icons.info_outline,
                        title: "About FINDUS",
                        content:
                            "FINDUS is a hyper-local service marketplace that connects Job Makers (supporters) and Job Finders (workers/earners) with trust, transparency and speed in Bangladesh.",
                        colors: colors,
                        accentColor: Colors.blue,
                      ),

                      const SizedBox(height: 20),

                      // Core Idea
                      _buildSection(
                        icon: Icons.lightbulb_outline,
                        title: "Core Idea",
                        content:
                            "FINDUS helps people quickly find nearby workers like farmers, rickshaw pullers, cleaners, electricians, painters or computer experts, and helps workers get more jobs digitally instead of waiting on streets or corners.",
                        colors: colors,
                        accentColor: Colors.amber.shade700,
                      ),

                      const SizedBox(height: 20),

                      // Key Features
                      _buildFeaturesSection(colors),

                      const SizedBox(height: 20),

                      // Trust & Quality
                      _buildTrustSection(colors),

                      const SizedBox(height: 20),

                      // Technology
                      _buildSection(
                        icon: Icons.code,
                        title: "Technology",
                        content:
                            "FINDUS is built with Flutter so that the same codebase can run smoothly on both Android and iOS, with a fast and modern user experience.",
                        colors: colors,
                        accentColor: Colors.purple,
                      ),

                      const SizedBox(height: 20),

                      // Mission Statement
                      _buildMissionCard(colors),

                      const SizedBox(height: 20),

                      // Social Links
                      _buildSocialLinks(colors),

                      const SizedBox(height: 20),

                      // Legal & Support
                      _buildLegalSection(colors),

                      const SizedBox(height: 30),

                      // Footer
                      _buildFooter(colors),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// App Header with Logo
  Widget _buildAppHeader(_AppColors colors) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandMain, AppColors.brandMain.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'F',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandMain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Name
          const Text(
            "FINDUS",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          // Version Info
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Version $_version (Build $_buildNumber)",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Tagline
          const Text(
            "Connecting Communities",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Generic Section Builder
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required _AppColors colors,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: colors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Key Features Section
  Widget _buildFeaturesSection(_AppColors colors) {
    final features = [
      _Feature(
        icon: Icons.swap_horiz,
        title: "Dual Role",
        description: "Switch between Job Maker and Job Finder in one account",
        color: Colors.green,
      ),
      _Feature(
        icon: Icons.verified_user_outlined,
        title: "Clear Profiles",
        description:
            "Photo, skills, pricing, completed jobs, ratings and badges",
        color: Colors.orange,
      ),
      _Feature(
        icon: Icons.emergency_outlined,
        title: "Emergency Directory",
        description: "Quick access to hospital, police, fire service",
        color: Colors.red,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star_outline,
                  color: Colors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Key Features",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => _buildFeatureItem(feature, colors)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(_Feature feature, _AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(feature.icon, color: feature.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.subTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trust & Quality Section
  Widget _buildTrustSection(_AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Trust & Quality",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoint(
            "Badge System (Bronze → Diamond) based on activity and reviews",
            colors,
          ),
          _buildBulletPoint(
            "Verified profiles (KYC), transparent ratings and review history",
            colors,
          ),
          _buildBulletPoint(
            "Smart suggestion: Closest workers first, then better badges and ratings",
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, _AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.brandMain,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colors.subTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mission Statement Card
  Widget _buildMissionCard(_AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain.withOpacity(0.1),
            AppColors.brandMain.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandMain.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.brandMain, size: 24),
              const SizedBox(width: 12),
              Text(
                "Our Mission",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "FINDUS aims to digitalize the local informal job market of Bangladesh and create a safe, fast and transparent bridge between people who want to work and people who need work done.",
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: colors.textColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Social Links Section
  Widget _buildSocialLinks(_AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Connect With Us",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSocialButton(
              icon: Icons.language,
              label: "Website",
              onTap: () {
                // TODO: Open website
              },
              colors: colors,
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              icon: Icons.facebook,
              label: "Facebook",
              onTap: () {
                // TODO: Open Facebook
              },
              colors: colors,
            ),
            const SizedBox(width: 12),
            _buildSocialButton(
              icon: Icons.mail_outline,
              label: "Email",
              onTap: () {
                // TODO: Open email
              },
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required _AppColors colors,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.brandMain, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: colors.subTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Legal & Support Section
  Widget _buildLegalSection(_AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Legal & Support",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildLegalLink("Privacy Policy", colors),
        _buildLegalLink("Terms of Service", colors),
        _buildLegalLink("Refund Policy", colors),
        _buildLegalLink("Help & Support", colors),
      ],
    );
  }

  Widget _buildLegalLink(String title, _AppColors colors) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to respective page
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: colors.subTextColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: colors.textColor),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: colors.subTextColor, size: 16),
          ],
        ),
      ),
    );
  }

  /// Footer
  Widget _buildFooter(_AppColors colors) {
    return Center(
      child: Column(
        children: [
          Text(
            "Made with ❤️ in Bangladesh",
            style: TextStyle(
              color: colors.subTextColor,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "© 2026 FINDUS. All rights reserved.",
            style: TextStyle(color: colors.subTextColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// Theme Colors Helper
class _AppColors {
  final bool isDark;
  final bool useAmoled;

  _AppColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF121212);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.grey.shade700;
  Color get titleColor => isDark ? Colors.white : AppColors.brandDark;
  Color get iconColor => isDark ? Colors.white : AppColors.brandDark;
}

/// Feature Model
class _Feature {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _Feature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
