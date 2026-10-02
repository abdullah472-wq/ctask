import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class CommunityStandardsScreen extends StatelessWidget {
  const CommunityStandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0F7FA);
    final titleColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'Community Standards',
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: _CommunityContent(isDark: isDark),
    );
  }
}

class _CommunityContent extends StatelessWidget {
  final bool isDark;
  const _CommunityContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white.withOpacity(0.85) : Colors.black87;
    final headingColor = isDark ? Colors.white : AppColors.brandDark;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final accentColor = isDark ? Colors.teal.shade300 : Colors.teal;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Header Section
          _buildHeaderCard(
            headingColor: headingColor,
            subtitleColor: subtitleColor,
            cardBg: cardBg,
            textColor: textColor,
          ),

          const SizedBox(height: 24),

          // 📌 Community Standards Sections
          _buildSection(
            number: "1",
            title: "Respect & Safe Behaviour",
            icon: Icons.handshake_rounded,
            content: [
              "Respect all users – no abuse, bullying, harassment, or threats during calls or in-person.",
              "Do not use hate speech or slurs based on religion, race, gender, caste, disability, or any personal identity.",
              "Do not ask for or share sexually explicit content. Any sexual harassment, abuse or exploitation is strictly prohibited.",
              "Always behave politely during jobs – both workers and supporters must follow basic respect and professionalism.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "2",
            title: "Honest Profile & Identity",
            icon: Icons.verified_user_rounded,
            content: [
              "Use your real name, clear photo and correct information in your profile.",
              "Do not create fake accounts, duplicate profiles, or pretend to be someone else.",
              "Do not share or sell accounts – each account is for one real person only.",
              "If you are using a team, agency or company, be honest and clear in your profile and job description.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "3",
            title: "Jobs, Work & Content Guidelines",
            icon: Icons.work_rounded,
            content: [
              "Only post legal jobs and services. Any job related to drugs, weapons, human trafficking or other illegal work is not allowed.",
              "Job descriptions must be clear, honest and not misleading. Mention real location, schedule and payment range.",
              "Do not post spam jobs, fake jobs, or jobs just to collect personal data.",
              "Do not share pirated software, cracked apps or any content that violates copyright or law.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          _buildSection(
            number: "4",
            title: "Payment & Wallet Safety",
            icon: Icons.account_balance_wallet_rounded,
            content: [
              "Never ask or force someone to pay outside of agreed payment methods (e.g. wallet/bKash/Nagad/bank) if job was created in app.",
              "Do not offer or accept bribes, fake discounts, or schemes that look like fraud.",
              "Supporters should pay fairly for completed work as agreed. Workers should not demand unfair extra money.",
              "FINDUS never asks for your wallet PIN, OTP or password in official communications. Do not share these with anyone.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: Colors.green,
            cardBg: cardBg,
            iconBgColor: Colors.green.withOpacity(0.15),
          ),

          _buildSection(
            number: "5",
            title: "Reviews & Ratings",
            icon: Icons.star_rounded,
            content: [
              "Give honest, fair reviews based on real experience – do not post fake reviews to promote or attack someone.",
              "Do not threaten others with bad ratings to get discounts, free work or personal benefits.",
              "Do not offer or accept money, gifts or favours in exchange for positive reviews.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: Colors.amber,
            cardBg: cardBg,
            iconBgColor: Colors.amber.withOpacity(0.15),
          ),

          _buildSection(
            number: "6",
            title: "Communication Rules",
            icon: Icons.call_rounded,
            content: [
              "Keep calls and in-person conversations focused on work – details, timing, location, payment, and safety.",
              "Do not send spam, advertisements, or unrelated promotional links through available contact channels.",
              "Do not share harmful links, malware, or suspicious files.",
              "If someone behaves badly, threatens you or makes you uncomfortable, block/report them using app options.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: Colors.blue,
            cardBg: cardBg,
            iconBgColor: Colors.blue.withOpacity(0.15),
          ),

          _buildSection(
            number: "7",
            title: "In‑Person Safety",
            icon: Icons.shield_rounded,
            content: [
              "Always meet in safe, public or well-known locations when possible.",
              "Share job details with a trusted friend/family if you are going to a new location.",
              "Do not carry large amounts of cash; use safe digital payments where possible.",
              "If you ever feel unsafe, leave the place and contact local authorities immediately.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: Colors.purple,
            cardBg: cardBg,
            iconBgColor: Colors.purple.withOpacity(0.15),
          ),

          _buildSection(
            number: "8",
            title: "Prohibited Activities",
            icon: Icons.block_rounded,
            content: [
              "Fraud, scam, phishing, or trying to steal money/personal data.",
              "Selling fake services, fake documents, ID cards or certificates.",
              "Using FINDUS to promote other illegal platforms or activities.",
              "Harassment, stalking, blackmail, or sharing someone's private information without consent.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: Colors.red,
            cardBg: cardBg,
            isWarning: true,
            iconBgColor: Colors.red.withOpacity(0.15),
          ),

          _buildSection(
            number: "9",
            title: "Reporting & Enforcement",
            icon: Icons.report_rounded,
            content: [
              "If you see any harmful, illegal or abusive behaviour, please report it from the profile or report section.",
              "Our team may temporarily suspend, permanently ban or limit features of accounts that violate these standards.",
              "Repeated or serious violations (fraud, abuse, harassment) may lead to legal action and sharing information with law enforcement.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: Colors.orange,
            cardBg: cardBg,
            isWarning: true,
            iconBgColor: Colors.orange.withOpacity(0.15),
          ),

          _buildSection(
            number: "10",
            title: "Your Responsibilities",
            icon: Icons.person_pin_rounded,
            content: [
              "Read these standards carefully and follow them in all your activities on FINDUS.",
              "Keep your account secure. Do not share your OTP, password or device access with others.",
              "Update your profile information if something changes (phone number, location, skills, etc.).",
              "Use common sense and caution – online and offline safety starts with you.",
            ],
            textColor: textColor,
            headingColor: headingColor,
            accentColor: accentColor,
            cardBg: cardBg,
          ),

          // 📝 Footer Note
          _buildFooterNote(
            textColor: textColor,
            cardBg: cardBg,
            accentColor: accentColor,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // 🎯 Header Card
  Widget _buildHeaderCard({
    required Color headingColor,
    required Color subtitleColor,
    required Color cardBg,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A3A3A), const Color(0xFF1E2828)]
              : [Colors.teal.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(isDark ? 0.2 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: Colors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to FINDUS",
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Community Standards",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "These Community Standards apply to all workers (earners) and supporters (job makers) using FINDUS. "
              "By using the app, you agree to follow these rules so that everyone can work, earn and hire safely.",
              style: TextStyle(color: textColor, height: 1.5, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.update_rounded, size: 14, color: subtitleColor),
              const SizedBox(width: 6),
              Text(
                "Last updated: January 2025",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📌 Section Builder
  Widget _buildSection({
    required String number,
    required String title,
    required IconData icon,
    required List<String> content,
    required Color textColor,
    required Color headingColor,
    required Color accentColor,
    required Color cardBg,
    bool isWarning = false,
    Color? iconBgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? accentColor.withOpacity(0.4)
              : accentColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
              color: accentColor.withOpacity(isDark ? 0.1 : 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor ?? accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          number,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Points
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: content
                  .map(
                    (point) => _buildBulletPoint(point, textColor, accentColor),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Bullet Point Widget
  Widget _buildBulletPoint(String text, Color textColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.6)],
              ),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.6, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  // 📝 Footer Note
  Widget _buildFooterNote({
    required Color textColor,
    required Color cardBg,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF222222)]
              : [Colors.grey.shade100, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "We may update these Community Standards from time to time to keep everyone safe. "
              "By continuing to use FINDUS, you agree to the latest version of these rules.",
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.8),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
