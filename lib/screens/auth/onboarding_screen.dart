import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // ✅ Lottie প্যাকেজ ইমপোর্ট

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ✅ আইকনের বদলে JSON ফাইলের পাথ দেওয়া হয়েছে
  final List<_OnboardItem> _pages = const [
    _OnboardItem(
      title: "Find trusted local workers",
      description:
          "Quickly find nearby workers for your daily needs — from cleaners, drivers, technicians to many more.",
      lottieAsset: "assets/animations/world_map_pinging_and_searching.json",
    ),
    _OnboardItem(
      title: "Verified & rated by real users",
      description:
          "Workers are verified and reviewed by real users, so you can hire with confidence.",
      lottieAsset: "assets/animations/job_hr.json",
    ),
  ];

  void _goToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _goToWelcome();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _goToWelcome,
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Section
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return _buildPage(item);
                },
              ),
            ),

            // Bottom Section: Indicators + Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(isActive: index == _currentPage),
                    ),
                  ),
                  const Spacer(),
                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.brandMain.withOpacity(0.4),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? "Get Started"
                          : "Next",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center contents slightly
        children: [
          // ✅ Animation Container (Icon-এর বদলে Lottie)
          SizedBox(
            height: 280, // অ্যানিমেশনের জন্য পর্যাপ্ত জায়গা
            width: double.infinity,
            child: Lottie.asset(
              item.lottieAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // ফাইল না পেলে আইকন দেখাবে
                return const Icon(
                  Icons.image_not_supported,
                  size: 80,
                  color: Colors.grey,
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.brandDark,
              fontFamily: 'Poppins', // আপনার ফন্ট ফ্যামিলি
            ),
          ),

          const SizedBox(height: 16),

          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: isActive ? 24 : 8, // অ্যাক্টিভ হলে একটু লম্বা হবে
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandMain : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

// ✅ মডেল ক্লাসে IconData-র বদলে String lottieAsset ব্যবহার করা হলো
class _OnboardItem {
  final String title;
  final String description;
  final String lottieAsset;

  const _OnboardItem({
    required this.title,
    required this.description,
    required this.lottieAsset,
  });
}
