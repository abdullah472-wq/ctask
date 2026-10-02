// lib/screens/main_nav_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';

import 'home_feed_screen.dart';
import 'explore/explore_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  static final GlobalKey<_MainNavScreenState> navKey =
      GlobalKey<_MainNavScreenState>();

  static void goToHomeTab() => navKey.currentState?._goToTab(0);
  static void goToExploreTab() => navKey.currentState?._goToTab(1);
  static void goToProfileTab() => navKey.currentState?._goToTab(2);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  // Badge Variables
  bool showHomeRedDot = false;

  // ✅ Stream Subscriptions (for proper cleanup)
  StreamSubscription? _ongoingJobsSubscription;
  StreamSubscription? _completedJobsSubscription;

  @override
  void initState() {
    super.initState();
    _handleDailyCheckIn();

    AchievementService.achievementsNotifier.addListener(_checkHomeRedDot);
    _initListeners();
  }

  @override
  void dispose() {
    // ✅ Cancel all subscriptions
    _ongoingJobsSubscription?.cancel();
    _completedJobsSubscription?.cancel();

    AchievementService.achievementsNotifier.removeListener(_checkHomeRedDot);
    _pageController.dispose();
    super.dispose();
  }

  void _initListeners() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ 1. Ongoing Jobs Stream
    _ongoingJobsSubscription = FirebaseFirestore.instance
        .collection('ongoing_jobs')
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .listen(
          (snap) => _checkHomeRedDot(),
          onError: (e) => debugPrint('Ongoing jobs stream error: $e'),
        );

    // ✅ 2. Completed Jobs Stream
    _completedJobsSubscription = FirebaseFirestore.instance
        .collection('completed_jobs')
        .where('participants', arrayContains: uid)
        .orderBy('completedAt', descending: true)
        .limit(10)
        .snapshots()
        .listen(
          (snap) => _checkHomeRedDot(),
          onError: (e) => debugPrint('Completed jobs stream error: $e'),
        );
  }

  Future<void> _checkHomeRedDot() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    bool hasClaimableQuest = false;
    bool hasPendingJobCompletion = false;

    // 1. Quest Check
    final allAchievements = AchievementService.achievementsNotifier.value;
    hasClaimableQuest = allAchievements.any(
      (st) => st.isCompleted && !st.claimed,
    );

    // ✅ 2. Job Completion Check (Finder can mark complete)
    try {
      final ongoingSnap = await FirebaseFirestore.instance
          .collection('ongoing_jobs')
          .where('finderId', isEqualTo: uid) // ✅ Fixed field name
          .where('status', isEqualTo: 'ongoing')
          .limit(1)
          .get();

      hasPendingJobCompletion = ongoingSnap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Check ongoing jobs error: $e');
    }

    if (mounted) {
      setState(() {
        showHomeRedDot = hasClaimableQuest || hasPendingJobCompletion;
      });
    }
  }

  Future<void> _handleDailyCheckIn() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await AchievementService.incrementProgress('daily_login', amount: 1);
        await AchievementService.syncWeeklyChestFromServer();
      } catch (e) {
        debugPrint('Daily check-in error: $e');
      }
    }
  }

  void _goToTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : AppColors.bgBlue;

    return PopScope(
      canPop: _currentIndex == 1,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 1) {
          _goToTab(1);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: bgColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            uid != null
                ? HomeFeedScreen(key: HomeFeedScreen.feedKey)
                : const ProfileNotLoggedIn(
                    title: "Home Feed",
                    showBackButton: false,
                  ),
            const ExploreScreen(),
            uid != null
                ? UnifiedProfileScreen(uid: uid, isOwner: true, showBack: false)
                : const ProfileNotLoggedIn(
                    title: "Your Profile",
                    showBackButton: false,
                  ),
          ],
        ),
        bottomNavigationBar: _buildModernNavBar(isDark),
      ),
    );
  }

  Widget _buildModernNavBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 25),
      height: 75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.7)
                  : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0,
                  currentIndex: _currentIndex,
                  activeIcon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                  label: 'Home',
                  showRedDot: showHomeRedDot,
                  onTap: _goToTab,
                ),
                _NavItem(
                  index: 1,
                  currentIndex: _currentIndex,
                  activeIcon: Icons.explore_rounded,
                  inactiveIcon: Icons.explore_outlined,
                  label: 'Explore',
                  onTap: _goToTab,
                ),
                _NavItem(
                  index: 2,
                  currentIndex: _currentIndex,
                  activeIcon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outline,
                  label: 'Profile',
                  onTap: _goToTab,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final Function(int) onTap;
  final int badgeCount;
  final bool showRedDot;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
    this.showRedDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    const activeColor = AppColors.brandMain;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),

                // Badge with count
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.black : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                // Red dot only
                else if (showRedDot)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.black : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: isSelected ? 3 : 0,
              decoration: const BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
