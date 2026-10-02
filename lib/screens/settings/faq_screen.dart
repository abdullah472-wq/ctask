// lib/screens/settings/faq_screen.dart

import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/services/theme_service.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        // ✅ Theme Colors
        final isDark = settings.isDarkMode;
        final colors = _FaqColors(
          isDark: isDark,
          useAmoled: settings.useAmoledBlack,
        );

        // Get filtered FAQs
        final filteredFaqs = _getFilteredFaqs();

        return FloatingScaffold(
          title: 'FAQ',
          backgroundColor: colors.bgColor,
          titleColor: colors.titleColor,
          iconColor: colors.iconColor,
          showBack: true,
          scrollable: false, // Custom scroll করবো
          bodyPadding: EdgeInsets.zero,
          body: Column(
            children: [
              // ═══════════════════════════════════════════════════════════
              // SEARCH BAR
              // ═══════════════════════════════════════════════════════════
              _buildSearchBar(colors),

              // ═══════════════════════════════════════════════════════════
              // CATEGORY FILTER
              // ═══════════════════════════════════════════════════════════
              _buildCategoryFilter(colors),

              // ═══════════════════════════════════════════════════════════
              // FAQ LIST
              // ═══════════════════════════════════════════════════════════
              Expanded(
                child: filteredFaqs.isEmpty
                    ? _buildEmptyState(colors)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredFaqs.length,
                        itemBuilder: (context, index) {
                          final faq = filteredFaqs[index];
                          return _buildFaqItem(faq, colors, index);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search Bar
  Widget _buildSearchBar(_FaqColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        style: TextStyle(color: colors.textColor),
        decoration: InputDecoration(
          hintText: 'Search FAQs...',
          hintStyle: TextStyle(color: colors.subTextColor),
          prefixIcon: Icon(Icons.search, color: colors.subTextColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: colors.subTextColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: colors.isDark ? Colors.white10 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Category Filter
  Widget _buildCategoryFilter(_FaqColors colors) {
    final categories = ['All', 'General', 'Badges', 'Payment', 'Verification'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandMain
                    : colors.isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brandMain.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textColor,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// FAQ Item
  Widget _buildFaqItem(_FaqItem faq, _FaqColors colors, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark
              ? Colors.grey.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.1 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: faq.categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(faq.icon, color: faq.categoryColor, size: 20),
          ),
          title: Text(
            faq.question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textColor,
              fontSize: 15,
            ),
          ),
          subtitle: faq.tags.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: faq.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: faq.categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: faq.categoryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : null,
          iconColor: AppColors.brandMain,
          collapsedIconColor: colors.subTextColor,
          children: [
            // Answer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq.answer,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: colors.textColor,
                    ),
                  ),
                  if (faq.helpfulLinks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Helpful Links:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.subTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...faq.helpfulLinks.map((link) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () {
                            // TODO: Navigate to link
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 14,
                                color: AppColors.brandMain,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  link,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.brandMain,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            // Helpful feedback
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Was this helpful?',
                  style: TextStyle(fontSize: 12, color: colors.subTextColor),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    _showFeedback(context, true);
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  color: Colors.green,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _showFeedback(context, false);
                  },
                  icon: const Icon(Icons.thumb_down_outlined, size: 18),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State
  Widget _buildEmptyState(_FaqColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: colors.subTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No FAQs Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different keywords'
                  : 'No FAQs available in this category',
              style: TextStyle(fontSize: 14, color: colors.subTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get filtered FAQs based on search and category
  List<_FaqItem> _getFilteredFaqs() {
    var faqs = _allFaqs;

    // Filter by category
    if (_selectedCategory != 'All') {
      faqs = faqs.where((faq) => faq.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      faqs = faqs.where((faq) {
        return faq.question.toLowerCase().contains(_searchQuery) ||
            faq.answer.toLowerCase().contains(_searchQuery) ||
            faq.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    return faqs;
  }

  /// Show feedback snackbar
  void _showFeedback(BuildContext context, bool isHelpful) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isHelpful ? Icons.check_circle : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              isHelpful
                  ? 'Thanks for your feedback!'
                  : 'We\'ll improve this answer',
            ),
          ],
        ),
        backgroundColor: isHelpful ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAQ DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static final List<_FaqItem> _allFaqs = [
    // General
    _FaqItem(
      category: 'General',
      question: 'How does FINDUS work?',
      answer:
          'FINDUS connects Job Makers (supporters) and Job Finders (workers) in a hyper-local way. You can post a request or offer your service.',
      icon: Icons.help_outline,
      categoryColor: Colors.blue,
      tags: ['basics', 'getting started'],
      helpfulLinks: ['How to post a job', 'How to find workers'],
    ),

    _FaqItem(
      category: 'General',
      question: 'How do I report a problem?',
      answer:
          'You can report from Help Center > Email Support, or contact our support team by email with details of your issue.',
      icon: Icons.report_problem_outlined,
      categoryColor: Colors.blue,
      tags: ['support', 'help'],
      helpfulLinks: ['Contact Support'],
    ),

    // Verification
    _FaqItem(
      category: 'Verification',
      question: 'How do I get a verified badge?',
      answer:
          'You need to complete KYC verification from the Settings > Verification section. Once approved, a blue verified badge will appear on your profile.',
      icon: Icons.verified_user,
      categoryColor: Colors.green,
      tags: ['kyc', 'verification', 'badge'],
      helpfulLinks: ['Verification Guide'],
    ),

    _FaqItem(
      category: 'Verification',
      question: "'Verified' ব্যাজ কীভাবে পাবো?",
      answer:
          'Verified ব্যাজ পাওয়ার জন্য আপনাকে Settings > Verification থেকে KYC ভেরিফিকেশন সম্পূর্ণ করতে হবে। NID/Passport ও প্রয়োজন হলে সেলফি/লাইভ ফেস ভেরিফিকেশন জমা দিলে এবং আমাদের টিম অ্যাপ্রুভ করলে আপনার প্রোফাইলে Verified ব্যাজ দেখা যাবে।',
      icon: Icons.verified,
      categoryColor: Colors.green,
      tags: ['verification', 'kyc', 'বাংলা'],
    ),

    // Payment
    _FaqItem(
      category: 'Payment',
      question: 'How is payment handled?',
      answer:
          'Currently payment is managed offline between worker and supporter. In future, in-app wallet and secure payment will be available.',
      icon: Icons.payment,
      categoryColor: Colors.orange,
      tags: ['payment', 'wallet', 'transaction'],
      helpfulLinks: ['Payment Methods', 'Safety Tips'],
    ),

    // Badges
    _FaqItem(
      category: 'Badges',
      question: 'FINDUS‑এ ব্যাজ (Badge) আর স্ট্যাটাস (Status) কী?',
      answer:
          'FINDUS‑এ ব্যাজ ও স্ট্যাটাস হলো আপনার প্রোফাইলের বিশ্বাসযোগ্যতা (trust), গুণগত মান (quality) এবং অ্যাক্টিভিটি (activity) দেখানোর ভিজ্যুয়াল প্রমাণ।',
      icon: Icons.stars,
      categoryColor: Colors.purple,
      tags: ['badge', 'status', 'বাংলা'],
    ),

    _FaqItem(
      category: 'Badges',
      question: "'Top Rated' স্ট্যাটাস কী? এটা কীভাবে পাবো?",
      answer:
          'Top Rated স্ট্যাটাস পাচ্ছেন সেই সব ইউজার, যাদের প্রোফাইলে ৫‑স্টার রেটিং থাকে। যখন আপনার গড় বা সাম্প্রতিক রেটিং ৫ স্টার থাকবে, তখনই Top Rated আইকন হাইলাইটেড হবে।',
      icon: Icons.star,
      categoryColor: Colors.purple,
      tags: ['top rated', 'rating', 'বাংলা'],
    ),

    _FaqItem(
      category: 'Badges',
      question: "'Trusted' ব্যাজ কারা পায়?",
      answer:
          'Trusted ব্যাজ দেয়া হয় সেই ইউজারদের, যারা নিয়মিত সময়মতো পেমেন্ট করেন এবং অ্যাপের ভেতর অন‑টাইম পেমেন্ট হিস্ট্রি ভালো রাখেন।',
      icon: Icons.verified_outlined,
      categoryColor: Colors.purple,
      tags: ['trusted', 'payment', 'বাংলা'],
    ),

    _FaqItem(
      category: 'Badges',
      question:
          'Bronze / Silver / Gold / Platinum / Diamond ব্যাজগুলো কীভাবে কাজ করে?',
      answer:
          'এই ব্যাজগুলো আপনার লং‑টার্ম প্রগ্রেস দেখায়। বিভিন্ন টাস্ক ও অ্যাক্টিভিটি (জব কমপ্লিট করা, রিভিউ দেওয়া, ট্রানজ্যাকশন ইত্যাদি) করলে আপনি পয়েন্ট আর্ন করবেন। জমা হওয়া পয়েন্ট অনুযায়ী আপনার ব্যাজ আপগ্রেড হবে।',
      icon: Icons.military_tech,
      categoryColor: Colors.purple,
      tags: ['badge levels', 'progress', 'বাংলা'],
    ),

    _FaqItem(
      category: 'Badges',
      question: 'অন্য সব ব্যাজ কীভাবে আনলক হবে?',
      answer:
          'Top Rated / Trusted / Verified ছাড়া অন্য ব্যাজগুলো মূলত টাস্ক ও পয়েন্ট সিস্টেমের মাধ্যমে আনলক হবে। নির্দিষ্ট টাস্ক পূর্ণ করলে নতুন অ্যাচিভমেন্ট ও ব্যাজ আনলক হবে।',
      icon: Icons.lock_open,
      categoryColor: Colors.purple,
      tags: ['unlock', 'achievements', 'বাংলা'],
    ),

    _FaqItem(
      category: 'Badges',
      question: 'আমার ব্যাজ/স্ট্যাটাস কি অটো আপডেট হবে?',
      answer:
          'হ্যাঁ। আপনার নতুন রেটিং, পেমেন্ট হিস্ট্রি, KYC স্ট্যাটাস বা টাস্ক/পয়েন্ট আপডেট হওয়ার সাথে সাথে FINDUS স্বয়ংক্রিয়ভাবে ব্যাজ ও স্ট্যাটাস আপডেট করে।',
      icon: Icons.autorenew,
      categoryColor: Colors.purple,
      tags: ['auto update', 'বাংলা'],
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

/// FAQ Colors Helper
class _FaqColors {
  final bool isDark;
  final bool useAmoled;

  _FaqColors({required this.isDark, this.useAmoled = false});

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
  Color get subTextColor =>
      isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get titleColor => isDark ? Colors.white : AppColors.brandDark;
  Color get iconColor => isDark ? Colors.white : AppColors.brandDark;
}

/// FAQ Item Model
class _FaqItem {
  final String category;
  final String question;
  final String answer;
  final IconData icon;
  final Color categoryColor;
  final List<String> tags;
  final List<String> helpfulLinks;

  _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
    required this.icon,
    required this.categoryColor,
    this.tags = const [],
    this.helpfulLinks = const [],
  });
}
