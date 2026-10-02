import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/achievement/achievement_models.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';

import 'package:findus_app/screens/profile/support_post_screen.dart';
import 'package:findus_app/screens/profile/earn_post_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_edit_screen.dart';
import 'package:findus_app/screens/profile/worker_documents_screen.dart';

class _PeriodMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _PeriodMeta(this.icon, this.color, this.label);
}

class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  bool _isLoading = true;
  bool _showCompleted = false;
  String _currentFilter = 'all'; // all / daily / weekly / long

  bool _isWorker = true;
  bool _isPro = false;
  bool _hasTeam = false;
  String _userRole = 'finder';

  int _totalXpEarned = 0;
  int _totalAchievements = 0;
  int _completedAchievements = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  late ConfettiController _confettiController;
  late VoidCallback _badgeListener;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _badgeListener = () {
      if (!mounted) return;
      _updateStats();
      setState(() {});
    };
    BadgeService.badgeNotifier.addListener(_badgeListener);

    // সপ্তাহ শুরু/শেষ অনুযায়ী weekly reset
    _checkWeeklyReset();

    _initializeData();
  }

  // ✅ উইকলি রিসেট ফাংশন (শুক্রবার শেষ, শনিবার শুরু)
  Future<void> _checkWeeklyReset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    try {
      final doc = await userRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;

      // আজকের তারিখ
      final now = DateTime.now();

      // সপ্তাহের আইডি (শনিবার থেকে শুরু)
      // 1 week = 604,800,000 ms
      // Thursday → Saturday offset = 2 days = 172,800,000 ms
      final int currentWeekId =
          ((now.millisecondsSinceEpoch + 172800000) / 604800000).floor();

      final int lastSavedWeekId = data['last_week_id'] ?? 0;

      if (currentWeekId > lastSavedWeekId) {
        await userRef.update({
          'weekly_quest_progress': 0,
          'last_week_id': currentWeekId,
          'weekly_quest_claimed': false,
        });
        // ignore: avoid_print
        print("Weekly progress reset successful. New Week ID: $currentWeekId");
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error checking weekly reset: $e");
    }
  }

  Future<void> _initializeData() async {
    try {
      String role = 'finder';

      setState(() {
        _userRole = role;
        _isWorker = (role == 'finder' || role == 'worker');
      });

      _listenUserDoc();
      await _checkAchievements();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _listenUserDoc();
    }
  }

  Future<void> _checkAchievements() async {
    try {
      final achievements = AchievementService.achievementsNotifier.value;
      if (achievements.isEmpty) {
        await Future.delayed(const Duration(seconds: 1));
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    BadgeService.badgeNotifier.removeListener(_badgeListener);
    _userSub?.cancel();
    super.dispose();
  }

  void _listenUserDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snap) {
            if (!snap.exists) return;

            final data = snap.data() ?? {};
            final plan = (data['subscription_plan'] ?? 'free')
                .toString()
                .toLowerCase();
            final bool isProUser = plan == 'pro' || plan == 'business';
            final teamId = data['team_id'];
            final bool hasTeam = teamId != null && teamId.toString().isNotEmpty;
            final firebaseRole = (data['userRole'] ?? _userRole)
                .toString()
                .toLowerCase();
            final bool isWorker =
                (firebaseRole == 'finder' || firebaseRole == 'worker');

            final rawXp = data['xpPoints'] ?? 0;
            final int xp = rawXp is num
                ? rawXp.toInt()
                : int.tryParse(rawXp.toString()) ?? 0;
            BadgeService.setPointsFromServer(xp);

            if (mounted) {
              setState(() {
                _isPro = isProUser;
                _hasTeam = hasTeam;
                _userRole = firebaseRole;
                _isWorker = isWorker;
                _isLoading = false;
              });
              _updateStats();
            }
          },
          onError: (error) {
            if (mounted) setState(() => _isLoading = false);
          },
        );
  }

  void _updateStats() {
    final points = BadgeService.badgeNotifier.value.totalXP;

    final all = AchievementService.getAllForUser(
      isWorker: _isWorker,
      currentPoints: points,
      isProUser: _isPro,
      hasTeam: _hasTeam,
      ignoreChainGating: true,
    );

    int totalXp = 0;
    int completed = 0;
    for (final st in all) {
      if (st.claimed) {
        totalXp += st.def.xpReward;
        completed++;
      }
    }

    if (!mounted) return;
    setState(() {
      _totalXpEarned = totalXp;
      _totalAchievements = all.length;
      _completedAchievements = completed;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // FILTERED LIST
  // ─────────────────────────────────────────────────────────────

  List<AchievementState> _getFilteredAchievements() {
    final points = BadgeService.badgeNotifier.value.totalXP;

    final all = AchievementService.getAllForUser(
      isWorker: _isWorker,
      currentPoints: points,
      isProUser: _isPro,
      hasTeam: _hasTeam,
      ignoreChainGating: false,
    );

    final filtered = all.where((st) {
      // Active / Completed toggle
      if (_showCompleted) {
        if (!st.claimed) return false;
      } else {
        if (st.claimed) return false;
      }

      // Period filter
      switch (_currentFilter) {
        case 'daily':
          return st.def.resetPeriod == ResetPeriod.daily;
        case 'weekly':
          return st.def.resetPeriod == ResetPeriod.weekly;
        case 'long':
          return st.def.resetPeriod == ResetPeriod.none;
        default:
          return true;
      }
    }).toList();

    // Sorting: unlocked আগে, claimable আগে, তারপর progress বেশি
    filtered.sort((a, b) {
      if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;

      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;

      final aPct = a.def.target == 0 ? 0.0 : a.progress / a.def.target;
      final bPct = b.def.target == 0 ? 0.0 : b.progress / b.def.target;
      return bPct.compareTo(aPct);
    });

    return filtered;
  }

  Widget _buildQuestList(bool isDark) {
    return ValueListenableBuilder<List<AchievementState>>(
      valueListenable: AchievementService.achievementsNotifier,
      builder: (context, _, __) {
        final list = _getFilteredAchievements();

        if (list.isEmpty) {
          return _buildEmptyBox(
            isDark,
            _showCompleted
                ? "No completed quests in this category yet."
                : "No active quests in this category right now.",
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final st = list[index];
            return _buildQuestCard(st, isDark);
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_totalAchievements == 0)
            _buildNoAchievementsWidget(isDark)
          else
            Column(
              children: [
                _buildHero(isDark),
                const SizedBox(height: 12),
                _buildToggle(isDark),
                const SizedBox(height: 8),
                _buildFilterChips(isDark),
                const SizedBox(height: 8),
                Expanded(child: _buildQuestList(isDark)),
              ],
            ),

          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TOP PARTS (Hero + Toggle + Filters)
  // ─────────────────────────────────────────────────────────────

  Widget _buildNoAchievementsWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            "No Quests Found",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await AchievementService.init();
              await _initializeData();
            },
            child: const Text("Reload"),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    final stats = BadgeService.badgeNotifier.value;

    final badgeName = stats.badgeName.toUpperCase();
    final badgeColor = stats.badgeColor;
    final totalStars = stats.totalStars;
    final starsNeeded = _getNextStarThreshold(stats.badgeLevel);

    final currentLevel = stats.numericLevel;
    final currentXP = stats.totalXP;

    final xpProgress = _calculateLevelProgress(currentLevel, currentXP);
    final nextLevelXP = _getXPForLevel(currentLevel + 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandMain.withOpacity(0.9), AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ACHIEVEMENTS",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: _showInfoDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: badgeColor, width: 2),
                        ),
                        child: Icon(
                          Icons.workspace_premium,
                          color: badgeColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CURRENT RANK",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              badgeName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${totalStars.toStringAsFixed(0)} Stars",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                if (stats.badgeLevel != BadgeLevel.diamond)
                                  Text(
                                    "/ ${starsNeeded.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stats.badgeProgressPercent,
                      minHeight: 8,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation(badgeColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.15), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "LEVEL $currentLevel",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${(xpProgress * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: xpProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.amber],
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            "$currentXP / $nextLevelXP XP",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getNextStarThreshold(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return 100;
      case BadgeLevel.bronze:
        return 500;
      case BadgeLevel.silver:
        return 2000;
      case BadgeLevel.gold:
        return 5000;
      case BadgeLevel.platinum:
        return 10000;
      default:
        return 10000;
    }
  }

  int _getXPForLevel(int level) {
    if (level <= 1) return 0;
    return (44 * (level - 1) * (level - 1)).toInt();
  }

  double _calculateLevelProgress(int currentLevel, int currentXP) {
    int startXP = _getXPForLevel(currentLevel);
    int nextXP = _getXPForLevel(currentLevel + 1);
    if (nextXP <= startXP) return 1.0;
    return ((currentXP - startXP) / (nextXP - startXP)).clamp(0.0, 1.0);
  }

  Widget _buildToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _toggleButton(
                "Active",
                !_showCompleted,
                isDark,
                () => setState(() => _showCompleted = false),
              ),
            ),
            Expanded(
              child: _toggleButton(
                "Completed",
                _showCompleted,
                isDark,
                () => setState(() => _showCompleted = true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(
    String text,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandMain : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isActive
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    Color bg(String key) => _currentFilter == key
        ? AppColors.brandMain
        : (isDark ? Colors.white10 : Colors.white);
    Color fg(String key) => _currentFilter == key
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip('all', 'All', bg, fg),
          const SizedBox(width: 8),
          _filterChip('daily', 'Daily', bg, fg),
          const SizedBox(width: 8),
          _filterChip('weekly', 'Weekly', bg, fg),
          const SizedBox(width: 8),
          _filterChip('long', 'Long‑term', bg, fg),
        ],
      ),
    );
  }

  Widget _filterChip(
    String key,
    String label,
    Color Function(String) bg,
    Color Function(String) fg,
  ) {
    final selected = _currentFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: fg(key), fontSize: 12)),
      selected: selected,
      selectedColor: AppColors.brandMain,
      backgroundColor: bg(key),
      onSelected: (_) {
        setState(() {
          _currentFilter = key;
        });
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // QUEST CARD
  // ─────────────────────────────────────────────────────────────

  _PeriodMeta _periodMeta(ResetPeriod p) {
    switch (p) {
      case ResetPeriod.daily:
        return const _PeriodMeta(Icons.wb_sunny, Colors.orange, 'Daily');
      case ResetPeriod.weekly:
        return const _PeriodMeta(
          Icons.calendar_view_week,
          Colors.purple,
          'Weekly',
        );
      case ResetPeriod.monthly:
        return const _PeriodMeta(Icons.calendar_today, Colors.teal, 'Monthly');
      case ResetPeriod.none:
      default:
        return const _PeriodMeta(
          Icons.all_inclusive,
          Colors.blueGrey,
          'Long‑term',
        );
    }
  }

  Widget _smallChip(String text, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: isDark ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildQuestSideStatus(AchievementState st, bool canClaim) {
    if (st.claimed) {
      return const Icon(Icons.emoji_events, size: 22, color: Colors.amber);
    }

    if (canClaim) {
      return Column(
        children: [
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () => _claim(st),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'CLAIM',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: const [
        Icon(Icons.hourglass_empty, size: 20, color: Colors.grey),
        SizedBox(height: 4),
        Text('ACTIVE', style: TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuestCard(AchievementState st, bool isDark) {
    if (st.isLocked) return _buildLockedCard(st, isDark);

    final def = st.def;
    final canClaim = st.isCompleted && !st.claimed;
    final progress = st.progress.clamp(0, def.target);
    final pct = def.target == 0 ? 0.0 : progress / def.target;

    final meta = _periodMeta(def.resetPeriod);

    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = canClaim
        ? Colors.green
        : (isDark ? Colors.white10 : Colors.grey.shade200);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: () {
        if (canClaim) {
          _claim(st);
        } else if (!st.claimed) {
          _navigateToTask(def.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: canClaim ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: meta.color, size: 20),
            ),
            const SizedBox(width: 10),

            // Middle content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + XP pill
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          def.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _xpPill(def.xpReward),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.description,
                    style: TextStyle(fontSize: 12, color: subColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  if (!st.claimed)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              canClaim ? Colors.green : AppColors.brandMain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$progress / ${def.target}',
                              style: TextStyle(
                                fontSize: 11,
                                color: subColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _smallChip(meta.label, meta.color, isDark),
                            if (def.workerOnly)
                              _smallChip('Worker', Colors.green, isDark),
                            if (def.supporterOnly)
                              _smallChip('Employer', Colors.red, isDark),
                            if (def.proOnly)
                              _smallChip('Pro', Colors.deepPurple, isDark),
                          ],
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          _smallChip(meta.label, meta.color, isDark),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Claimed',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right side action
            _buildQuestSideStatus(st, canClaim),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LOCKED / XP PILL / EMPTY
  // ─────────────────────────────────────────────────────────────

  Widget _buildLockedCard(AchievementState st, bool isDark) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Upgrade to PRO to unlock this quest & earn massive XP!",
            ),
            backgroundColor: Colors.amber,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    st.def.title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Pro Plan Exclusive",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            _xpPill(st.def.xpReward, isLocked: true),
          ],
        ),
      ),
    );
  }

  Widget _xpPill(int xp, {bool isLocked = false}) {
    final color = isLocked ? Colors.grey : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            "+$xp",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(bool isDark, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Text(
          msg,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CLAIM + NAVIGATION
  // ─────────────────────────────────────────────────────────────

  Future<void> _claim(AchievementState st) async {
    HapticFeedback.heavyImpact();
    _confettiController.play();

    // ১. ক্লেম ফাংশন কল করা
    await AchievementService.claim(st.def.id);

    // ২. Weekly Progress বাড়ানো (যদি ডেইলি কোয়েস্ট হয়)
    if (st.def.resetPeriod == ResetPeriod.daily) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'weekly_quest_progress': FieldValue.increment(1),
        });
      }
    }

    if (mounted) setState(() {});
  }

  void _navigateToTask(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final key = id.toLowerCase();

    if (key.contains('login') || key.contains('check')) {
      await AchievementService.incrementProgress('daily_login', amount: 1);
      await AchievementService.syncWeeklyChestFromServer();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Checked in!")));
        setState(() {});
      }
      return;
    }

    if (key.contains('share')) {
      _shareMyProfileFromQuest();
      return;
    }

    if (key.contains('portfolio') ||
        key.contains('cv') ||
        key.contains('upload')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerDocumentsScreen(uid: uid, isOwner: true),
        ),
      );
      return;
    }

    if ((key.contains('job') || key.contains('post')) &&
        !key.contains('view')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _isWorker ? const EarnPostScreen() : const SupportPostScreen(),
        ),
      );
      return;
    }

    if (key.contains('profile')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UnifiedProfileEditScreen(uid: uid)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Action not available from here.")),
    );
  }

  void _showInfoDialog() {
    final stats = BadgeService.badgeNotifier.value;

    final BadgeLevel badgeLevel = stats.badgeLevel;
    final String currentBadgeName = stats.badgeName; // e.g. GOLD
    final double currentStars = stats.totalStars;
    final int currentXP = stats.totalXP;
    final int numericLevel = stats.numericLevel;

    // পরের badge এর নাম + stars threshold
    String? nextBadgeName;
    double? nextBadgeStars;

    switch (badgeLevel) {
      case BadgeLevel.newbie:
        nextBadgeName = 'Bronze';
        nextBadgeStars = 100; // 100 stars থেকে Bronze
        break;
      case BadgeLevel.bronze:
        nextBadgeName = 'Silver';
        nextBadgeStars = 500;
        break;
      case BadgeLevel.silver:
        nextBadgeName = 'Gold';
        nextBadgeStars = 2000;
        break;
      case BadgeLevel.gold:
        nextBadgeName = 'Platinum';
        nextBadgeStars = 5000;
        break;
      case BadgeLevel.platinum:
        nextBadgeName = 'Diamond';
        nextBadgeStars = 10000;
        break;
      case BadgeLevel.diamond:
        nextBadgeName = null;
        nextBadgeStars = null;
        break;
    }

    double? starsRemaining;
    if (nextBadgeStars != null) {
      starsRemaining = (nextBadgeStars - currentStars);
      if (starsRemaining < 0) starsRemaining = 0;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quest & Badge Guide"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "How quests work:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                "• Daily quests: প্রতিদিন reset হয়।\n"
                "• Weekly quests: পুরো সপ্তাহ ধরে progress গুনে।\n"
                "• Long‑term quests: কখনও reset হয় না, বড় reward দেয়।\n",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),

              const Text(
                "XP (Level) কীভাবে বাড়ে:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                "• তুমি যখন কোনো quest সম্পূর্ণ করে CLAIM করো, তখন XP পয়েন্ট যোগ হয়।\n"
                "• XP থেকে তোমার numeric level (1–100) বাড়ে।\n"
                "• যত বেশি XP, তত বেশি লেভেল – মানে তুমি অ্যাপে তত বেশি এক্টিভ।\n",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),

              const Text(
                "Badge কীভাবে আপডেট হয়:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                "• যখন তুমি ভালো রেটিং পাও, তখন Stars বাড়ে।\n"
                "• মোট Stars নির্দিষ্ট লেভেল পার করলে তোমার Badge আপগ্রেড হয়:\n"
                "    – 0+  → NEWBIE\n"
                "    – 100+  → BRONZE\n"
                "    – 500+  → SILVER\n"
                "    – 2000+ → GOLD\n"
                "    – 5000+ → PLATINUM\n"
                "    – 10000+ → DIAMOND\n",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // বর্তমান স্ট্যাটাস
              const Text(
                "Your current progress:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "• Badge: $currentBadgeName",
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                "• Stars: ${currentStars.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                "• Level: $numericLevel  (XP: $currentXP)",
                style: const TextStyle(fontSize: 13),
              ),

              if (nextBadgeName != null &&
                  nextBadgeStars != null &&
                  starsRemaining != null) ...[
                const SizedBox(height: 8),
                Text(
                  "Next badge: $nextBadgeName",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "Unlocked at: ${nextBadgeStars.toStringAsFixed(0)} stars",
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  "Stars needed: ${starsRemaining.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 13),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  "You already reached the highest badge (DIAMOND). Keep completing quests and getting ratings to stay on top!",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _shareMyProfileFromQuest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = userDoc.data() ?? {};
      final name = (data['name'] ?? 'FindUs User').toString();

      final message =
          'Check out $name on FindUs! https://yourapp.com/profile/$uid';
      await Share.share(message);

      await AchievementService.incrementProgress('daily_share', amount: 1);
      await AchievementService.syncWeeklyChestFromServer();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }
}
