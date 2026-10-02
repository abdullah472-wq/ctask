// lib/screens/settings/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/services/theme_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = [];
  int _currentSection = 0;
  bool _showTOC = false;

  // Privacy Policy Sections
  final List<_PolicySection> _sections = [
    _PolicySection(
      title: "Information We Collect",
      icon: Icons.folder_outlined,
      content:
          """We collect the following types of information to operate and improve our service:

• Account Information: Name, phone number, email (optional), profile photo, role (Job Maker / Job Finder), language preference.

• Profile & Work Information: Skills, experience, price rate, location area, short bio, ratings, reviews and badges.

• Location Data: Approximate or precise location (with your permission) to show nearby jobs and workers.

• Usage Data: App pages visited, actions taken (search, hire, wallet usage), device information (model, OS version), IP address and anonymized analytics.

• Communication Data: Messages and call details (only meta information such as time and participant, not call recording) between workers and supporters inside the app.

• Wallet & Payment Data: Transaction history, amounts, linked payment method type (e.g. bKash, Nagad, card). We do not store your wallet PIN, OTP or full card number.""",
    ),
    _PolicySection(
      title: "How We Use Your Information",
      icon: Icons.analytics_outlined,
      content: """We use your information to:

• Create and manage your FINDUS account and profile.

• Match and suggest nearby jobs and workers using location and profile data.

• Show accurate profile details, badges, ratings and reviews so that others can make informed decisions.

• Process wallet transactions, show balance and maintain transaction history.

• Improve app performance, measure analytics and prevent fraud or abuse.

• Send important notifications about jobs, payments, security alerts or app updates.

• Provide customer support and respond to your queries or reports.""",
    ),
    _PolicySection(
      title: "Sharing of Information",
      icon: Icons.share_outlined,
      content:
          """We do not sell your personal information to third parties. We may share limited information in the following cases:

• With Other Users: When you apply for or post a job, basic profile information (name, photo, rating, location area, work details) is visible to relevant workers or supporters.

• Service Providers: With secure third-party services (e.g. payment gateways, analytics providers, cloud hosting) who help us run the app.

• Legal and Safety Reasons: If required by law, court order, or to protect the rights, property and safety of FINDUS users or the public.

• Business Transfers: If we merge, acquire or sell part of our business, user data may be transferred as part of that transaction.""",
    ),
    _PolicySection(
      title: "Location Data",
      icon: Icons.location_on_outlined,
      content:
          """Location services are used to show nearby jobs and workers, and to improve search relevance.

• You can control location access from your device settings.

• If you turn off location, some location-based features may not work correctly.

• We do not continuously track your background location without your permission.""",
    ),
    _PolicySection(
      title: "Cookies & Analytics",
      icon: Icons.cookie_outlined,
      content:
          """We may use in-app analytics and similar technologies to understand how users interact with the app.

This helps us improve features, fix bugs and optimize performance. We do not use these tools to personally identify you without your consent.""",
    ),
    _PolicySection(
      title: "Data Retention",
      icon: Icons.storage_outlined,
      content:
          """• We keep your account and profile data as long as your account is active.

• Transaction and legal records may be kept for a longer period as required by law or for dispute resolution.

• If you request to delete your account, we will remove or anonymize your personal data within a reasonable time, except where retention is legally required.""",
    ),
    _PolicySection(
      title: "Security",
      icon: Icons.security_outlined,
      content:
          """We use reasonable technical and organizational measures to protect your information:

• Encryption where possible
• Secure storage
• Access controls

However, no system is 100% secure, and we cannot guarantee absolute security of data transmitted over the internet.""",
    ),
    _PolicySection(
      title: "Children's Privacy",
      icon: Icons.child_care_outlined,
      content: """FINDUS is not intended for children under 13 years of age.

We do not knowingly collect personal information from children under 13. If you believe a child has provided us data, please contact us so we can remove it.""",
    ),
    _PolicySection(
      title: "Your Rights & Controls",
      icon: Icons.admin_panel_settings_outlined,
      content: """Depending on local law, you may have the right to:

• Access the personal data we hold about you.

• Correct or update incorrect or incomplete information.

• Request deletion of your account and associated data (subject to legal retention).

• Change permissions like location, notifications or camera from device/app settings.""",
    ),
    _PolicySection(
      title: "Third-Party Links & Services",
      icon: Icons.link_outlined,
      content:
          """Our app may contain links or integrations to third-party websites or services (e.g. payment providers, map services).

We are not responsible for the privacy practices of those third parties. Please review their privacy policies separately.""",
    ),
    _PolicySection(
      title: "Changes to This Policy",
      icon: Icons.update_outlined,
      content: """We may update this Privacy Policy from time to time.

We will update the 'Last updated' date at the top and may notify you inside the app for major changes.

By continuing to use FINDUS after changes, you agree to the updated Policy.""",
    ),
    _PolicySection(
      title: "Contact Us",
      icon: Icons.mail_outlined,
      content:
          """If you have any questions or concerns about this Privacy Policy or how we handle your data, you can contact us at:

📧 Email: admin@findus.odditybd.shop
📝 Subject: Privacy Policy – FINDUS

We typically respond within 48 hours.""",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sectionKeys.addAll(List.generate(_sections.length, (_) => GlobalKey()));
    _scrollController.addListener(_updateCurrentSection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCurrentSection() {
    // Track which section is currently visible
    for (int i = 0; i < _sectionKeys.length; i++) {
      final key = _sectionKeys[i];
      if (key.currentContext != null) {
        final box = key.currentContext!.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          if (position.dy > 100 && position.dy < 300) {
            if (_currentSection != i) {
              setState(() => _currentSection = i);
            }
            break;
          }
        }
      }
    }
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    setState(() {
      _showTOC = false;
      _currentSection = index;
    });
  }

  void _copyToClipboard() {
    final fullText = _sections
        .map((s) => "${s.title}\n\n${s.content}")
        .join("\n\n---\n\n");
    Clipboard.setData(
      ClipboardData(text: "FINDUS Privacy Policy\n\n$fullText"),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Privacy Policy copied to clipboard"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _sharePolicy() {
    final fullText = _sections
        .map((s) => "${s.title}\n\n${s.content}")
        .join("\n\n---\n\n");
    Share.share(
      "FINDUS Privacy Policy\n\nLast updated: January 2025\n\n$fullText",
      subject: "FINDUS Privacy Policy",
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _PolicyColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return FloatingScaffold(
          title: 'PRIVACY POLICY',
          backgroundColor: colors.bgColor,
          titleColor: colors.textColor,
          iconColor: colors.textColor,
          showBack: true,
          scrollable: false,
          bodyPadding: EdgeInsets.zero,
          actions: [
            IconButton(
              icon: Icon(Icons.list, color: colors.textColor),
              onPressed: () => setState(() => _showTOC = !_showTOC),
              tooltip: "Table of Contents",
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colors.textColor),
              onSelected: (value) {
                if (value == 'copy') _copyToClipboard();
                if (value == 'share') _sharePolicy();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 20),
                      SizedBox(width: 10),
                      Text("Copy All"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 10),
                      Text("Share"),
                    ],
                  ),
                ),
              ],
            ),
          ],
          body: Stack(
            children: [
              // Main Content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: _buildHeader(colors)),

                  // Quick Stats
                  SliverToBoxAdapter(child: _buildQuickStats(colors)),

                  // Sections
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildSection(index, colors);
                    }, childCount: _sections.length),
                  ),

                  // Footer
                  SliverToBoxAdapter(child: _buildFooter(colors)),
                ],
              ),

              // Table of Contents Overlay
              if (_showTOC) _buildTOCOverlay(colors),

              // Section Indicator
              _buildSectionIndicator(colors),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(_PolicyColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.privacy_tip,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FINDUS",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "Privacy Policy",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  "Last updated: January 2025",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(_PolicyColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatChip(
            icon: Icons.description,
            label: "${_sections.length} Sections",
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.timer,
            label: "~5 min read",
            colors: colors,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            icon: Icons.verified_user,
            label: "GDPR Ready",
            colors: colors,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required _PolicyColors colors,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.withOpacity(0.1) : colors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? Colors.green.withOpacity(0.3)
              : colors.isDark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? Colors.green : colors.subTextColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: highlight ? Colors.green : colors.subTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(int index, _PolicyColors colors) {
    final section = _sections[index];

    return Container(
      key: _sectionKeys[index],
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _currentSection == index
              ? AppColors.brandMain.withOpacity(0.5)
              : colors.isDark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandMain.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: AppColors.brandMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(section.icon, color: AppColors.brandMain, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              section.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: colors.textColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(_PolicyColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user, color: colors.subTextColor, size: 40),
          const SizedBox(height: 12),
          Text(
            "Your Privacy Matters",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We are committed to protecting your data and being transparent about how we use it.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.subTextColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text("Copy"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textColor,
                  side: BorderSide(
                    color: colors.isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _sharePolicy,
                icon: const Icon(Icons.share, size: 16),
                label: const Text("Share"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "© 2025 FINDUS. All rights reserved.",
            style: TextStyle(fontSize: 11, color: colors.subTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTOCOverlay(_PolicyColors colors) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showTOC = false),
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping TOC
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TOC Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brandMain.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.list, color: AppColors.brandMain),
                          const SizedBox(width: 10),
                          Text(
                            "Table of Contents",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: colors.subTextColor),
                            onPressed: () => setState(() => _showTOC = false),
                          ),
                        ],
                      ),
                    ),

                    // TOC Items
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(10),
                        itemCount: _sections.length,
                        itemBuilder: (ctx, index) {
                          final section = _sections[index];
                          final isActive = _currentSection == index;

                          return ListTile(
                            leading: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.brandMain
                                    : colors.isDark
                                    ? Colors.white10
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "${index + 1}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.white
                                        : colors.subTextColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              section.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive
                                    ? AppColors.brandMain
                                    : colors.textColor,
                              ),
                            ),
                            onTap: () => _scrollToSection(index),
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionIndicator(_PolicyColors colors) {
    return Positioned(
      right: 8,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: colors.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_sections.length, (index) {
            final isActive = _currentSection == index;
            return GestureDetector(
              onTap: () => _scrollToSection(index),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brandMain
                      : colors.subTextColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ════════════════════════════════════════════════════════════════════════════

class _PolicyColors {
  final bool isDark;
  final bool useAmoled;

  _PolicyColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF0A0A0A);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;
}

class _PolicySection {
  final String title;
  final IconData icon;
  final String content;

  const _PolicySection({
    required this.title,
    required this.icon,
    required this.content,
  });
}
