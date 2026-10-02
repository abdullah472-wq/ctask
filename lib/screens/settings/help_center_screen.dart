// lib/screens/settings/help_center_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/services/theme_service.dart';
import 'faq_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _HelpColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return FloatingScaffold(
          title: 'HELP CENTER',
          backgroundColor: colors.bgColor,
          titleColor: colors.textColor,
          iconColor: colors.textColor,
          showBack: true,
          scrollable: true,
          bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(colors),

              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(context, colors),

              const SizedBox(height: 25),

              // Help Options
              Text(
                "Support Options",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 12),

              // FAQ
              _buildHelpTile(
                context,
                icon: Icons.help_outline_rounded,
                title: "FAQ",
                subtitle: "Common questions and answers",
                iconColor: Colors.blue,
                colors: colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),

              // Email Support
              _buildHelpTile(
                context,
                icon: Icons.email_outlined,
                title: "Email Support",
                subtitle: "support@findus.app",
                iconColor: Colors.orange,
                colors: colors,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailSupportScreen()),
                ),
              ),

              // Phone Support
              _buildHelpTile(
                context,
                icon: Icons.phone_outlined,
                title: "Phone Support",
                subtitle: "+880 1581818368",
                iconColor: Colors.purple,
                colors: colors,
                onTap: () => _makePhoneCall(context),
              ),

              const SizedBox(height: 25),

              // Resources Section
              Text(
                "Resources",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textColor,
                ),
              ),
              const SizedBox(height: 12),

              // Community
              _buildHelpTile(
                context,
                icon: Icons.people_outline,
                title: "Community Forum",
                subtitle: "Connect with other users",
                iconColor: Colors.teal,
                colors: colors,
                onTap: () => _openUrl('https://community.findus.app'),
              ),

              // Video Tutorials
              _buildHelpTile(
                context,
                icon: Icons.play_circle_outline,
                title: "Video Tutorials",
                subtitle: "Learn how to use FINDUS",
                iconColor: Colors.red,
                colors: colors,
                onTap: () => _openUrl('https://youtube.com/@findusapp'),
              ),

              const SizedBox(height: 30),

              // Feedback Button
              _buildFeedbackButton(context, colors),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(_HelpColors colors) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Need Help?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We're here 24/7 to assist you",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, _HelpColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            icon: Icons.email_outlined,
            label: "Email",
            color: Colors.orange,
            colors: colors,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmailSupportScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            icon: Icons.phone_outlined,
            label: "Call",
            color: Colors.green,
            colors: colors,
            onTap: () => _makePhoneCall(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required _HelpColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required _HelpColors colors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colors.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.subTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colors.subTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackButton(BuildContext context, _HelpColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.feedback_outlined, color: colors.subTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Give us feedback",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Help us improve FINDUS",
                  style: TextStyle(color: colors.subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showFeedbackDialog(context, colors),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
            ),
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    const phoneNumber = 'tel:+8801581818368';
    final uri = Uri.parse(phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFeedbackDialog(BuildContext context, _HelpColors colors) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardColor,
        title: Text(
          "Give us feedback",
          style: TextStyle(color: colors.textColor),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: colors.textColor),
          decoration: InputDecoration(
            hintText: "Tell us how we can improve",
            hintStyle: TextStyle(color: colors.subTextColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Thank you for your feedback!")),
              );
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMAIL SUPPORT SCREEN
// ════════════════════════════════════════════════════════════════════════════

class EmailSupportScreen extends StatefulWidget {
  const EmailSupportScreen({super.key});

  @override
  State<EmailSupportScreen> createState() => _EmailSupportScreenState();
}

class _EmailSupportScreenState extends State<EmailSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Account Issue',
    'Payment Problem',
    'Bug Report',
    'Feature Request',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _HelpColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return Scaffold(
          backgroundColor: colors.bgColor,
          appBar: AppBar(
            backgroundColor: colors.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: colors.textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Email Support",
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info Card
                _buildInfoCard(colors),

                const SizedBox(height: 24),

                // Category Dropdown
                _buildCategoryDropdown(colors),

                const SizedBox(height: 16),

                // Subject Field
                _buildTextField(
                  label: "Subject",
                  hint: "Brief description of your issue",
                  controller: _subjectController,
                  icon: Icons.subject,
                  colors: colors,
                ),

                const SizedBox(height: 16),

                // Message Field
                _buildTextField(
                  label: "Message",
                  hint: "Describe your issue in detail...",
                  controller: _messageController,
                  icon: Icons.message,
                  colors: colors,
                  maxLines: 6,
                ),

                const SizedBox(height: 16),

                // Attachment Button
                _buildAttachmentButton(colors),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 10),
                            Text(
                              "SEND EMAIL",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(_HelpColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain.withOpacity(0.1),
            AppColors.brandMain.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.email_rounded, color: AppColors.brandMain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "support@findus.app",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We typically respond within 24 hours",
                  style: TextStyle(color: colors.subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(_HelpColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: colors.subTextColor),
              dropdownColor: colors.cardColor,
              style: TextStyle(color: colors.textColor),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required _HelpColors colors,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: colors.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.subTextColor),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: AppColors.brandMain)
                : null,
            filled: true,
            fillColor: colors.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colors.isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.brandMain,
                width: 2,
              ),
            ),
          ),
          validator: (val) =>
              (val == null || val.isEmpty) ? "$label is required" : null,
        ),
      ],
    );
  }

  Widget _buildAttachmentButton(_HelpColors colors) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Implement file picker
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attachment feature coming soon!")),
        );
      },
      icon: const Icon(Icons.attach_file),
      label: const Text("Add Attachment"),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textColor,
        side: BorderSide(
          color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Email sent successfully!"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ════════════════════════════════════════════════════════════════════════════

class _HelpColors {
  final bool isDark;
  final bool useAmoled;

  _HelpColors({required this.isDark, this.useAmoled = false});

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
