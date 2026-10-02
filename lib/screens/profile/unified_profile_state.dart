import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Constants & Services
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'package:findus_app/services/card_theme_service.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

// Screens
import 'package:findus_app/screens/tabs/leaderboard_screen.dart';
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/screens/team/team_management_screen.dart';
import 'package:findus_app/screens/explore/notifications_page.dart';
import 'package:findus_app/screens/rating_history_screen.dart';

// Local Files
import 'unified_profile_screen.dart';
import 'unified_profile_constants.dart';
import 'unified_profile_edit_screen.dart';
import 'followers_following_screen.dart';
import 'card_theme_bottom_sheet.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_info_section.dart';
import 'widgets/profile_about_section.dart';
import 'widgets/profile_social_links.dart';
import 'widgets/profile_documents_button.dart';
import 'widgets/profile_visitor_action_bar.dart';
import 'widgets/profile_suggestions_section.dart';
import 'widgets/profile_shimmer_loading.dart';

class UnifiedProfileScreenState extends State<UnifiedProfileScreen> {
  // ═══════════════════════════════════════════════════════════════
  // STREAMS & SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userStatsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _followersCountSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _followingCountSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notifSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _rankSub;

  // ═══════════════════════════════════════════════════════════════
  // STATE VARIABLES
  // ═══════════════════════════════════════════════════════════════
  Map<String, dynamic> userData = {};
  Map<String, dynamic> userStats = {};
  bool isLoading = true;
  bool isFollowing = false;
  bool isBlocked = false;
  bool isOnline = false;
  bool _isFollowProcessing = false;

  int _cardThemeIndex = 0;
  int _followersCountLive = 0;
  int _followingCountLive = 0;
  int _unreadNotifCount = 0;
  int _userRank = 0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _postsSectionKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  late VoidCallback _badgeListener;

  // ═══════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupBadgeListener();
    if (widget.isOwner) _listenToNotifications();
    _listenToUserRank();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _userStatsSub?.cancel();
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();
    _notifSub?.cancel();
    _rankSub?.cancel();
    _scrollController.dispose();
    BadgeService.badgeNotifier.removeListener(_badgeListener);
    super.dispose();
  }

  void _setupBadgeListener() {
    _badgeListener = () {
      if (mounted) setState(() {});
    };
    BadgeService.badgeNotifier.addListener(_badgeListener);
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION & LISTENERS
  // ═══════════════════════════════════════════════════════════════

  void _initializeData() async {
    final blocked = await BlockedUserService().isBlocked(widget.uid);
    if (!blocked) {
      _listenToUserData();
      _listenToUserStats();
      _listenToFollowCounts();
      if (!widget.isOwner) _checkIfFollowing();
    } else if (mounted) {
      setState(() => isBlocked = true);
      _showBlockedDialog();
    }
  }

  void _listenToUserData() {
    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots()
        .listen(
          (snap) {
            if (!snap.exists || !mounted) return;
            final data = snap.data() ?? {};

            // Owner হলে BadgeService এ পয়েন্ট সেট করা
            if (widget.isOwner) {
              final rawXp = data['user_badge_points'] ?? data['xpPoints'] ?? 0;
              final int xp = int.tryParse(rawXp.toString()) ?? 0;
              BadgeService.setPointsFromServer(xp);
            }

            final rawIdx = data['cardThemeIndex'];
            final idx = (rawIdx is int)
                ? rawIdx
                : int.tryParse(rawIdx?.toString() ?? '') ?? 0;

            setState(() {
              userData = data;
              _cardThemeIndex = idx.clamp(0, 3);
              isOnline = (data['isOnline'] ?? false) == true;
              isLoading = false;
            });
          },
          onError: (_) {
            if (mounted) setState(() => isLoading = false);
          },
        );
  }

  void _listenToUserStats() {
    _userStatsSub?.cancel();
    _userStatsSub = FirebaseFirestore.instance
        .collection('user_stats')
        .doc(widget.uid)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() => userStats = snap.data() ?? {});
        });
  }

  void _listenToFollowCounts() {
    _followersCountSub?.cancel();
    _followingCountSub?.cancel();

    _followersCountSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('followers')
        .snapshots()
        .listen((q) {
          if (mounted) setState(() => _followersCountLive = q.size);
        });

    _followingCountSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('following')
        .snapshots()
        .listen((q) {
          if (mounted) setState(() => _followingCountLive = q.size);
        });
  }

  void _listenToNotifications() {
    _notifSub?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _notifSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false) // ✅ শুধু unread count
        .snapshots()
        .listen(
          (q) {
            if (mounted) {
              debugPrint("🔔 Unread notifications: ${q.docs.length}");
              setState(() {
                _unreadNotifCount = q.docs.length;
              });
            }
          },
          onError: (e) {
            debugPrint("❌ Notification error: $e");
          },
        );
  }

  void _listenToUserRank() {
    _rankSub?.cancel();
    _rankSub = FirebaseFirestore.instance
        .collection('users')
        .orderBy('xpPoints', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          int rank = 0;
          for (int i = 0; i < snapshot.docs.length; i++) {
            if (snapshot.docs[i].id == widget.uid) {
              rank = i + 1;
              break;
            }
          }
          if (_userRank != rank) setState(() => _userRank = rank);
        });
  }

  Future<void> _checkIfFollowing() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('following')
          .doc(widget.uid)
          .get();
      if (mounted) setState(() => isFollowing = doc.exists);
    } catch (_) {}
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    _initializeData();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD METHOD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (isBlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User Blocked')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final subscriptionType =
        userData['subscription_type']?.toString() ?? 'free';

    return Scaffold(
      bottomNavigationBar: !widget.isOwner
          ? SafeArea(
              top: false,
              child: ProfileVisitorActionBar(
                isDark: isDark,
                isPaused: userData['workPaused'] == true,
                hasPhone: userData['phone']?.toString().isNotEmpty == true,
                onCallTap: _makePhoneCall,
                onEmailTap: _sendEmail,
                onViewPostsTap: _scrollToPosts,
              ),
            )
          : null,
      body: Builder(
        builder: (ctx) {
          final bool shouldShowBack =
              widget.showBack ?? Navigator.of(ctx).canPop();

          return FloatingScaffold(
            showBack: shouldShowBack,
            title: 'PROFILE',
            backgroundColor: scaffoldBg,
            titleColor: titleColor,
            iconColor: titleColor,
            actions: widget.isOwner
                ? _buildOwnerActions(isDark, subscriptionType)
                : _buildVisitorActions(isDark),
            scrollable: false,
            bodyPadding: EdgeInsets.zero,
            body: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshData,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  child: isLoading
                      ? _buildShimmerLoading()
                      : _buildBody(isDark),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BODY BUILDER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBody(bool isDark) {
    final locked = userData['accountLocked'] == true;
    final hidden = userData['profileHidden'] == true;

    // Visitor দেখলে এবং locked/hidden থাকলে restricted view
    if (!widget.isOwner && (locked || hidden)) {
      return _buildRestrictedView(isDark, locked);
    }

    final bool isWorker = _isWorkerRole();
    final String roleLabel = isWorker ? "Worker" : "Supporter";
    final double bottomSpacer = widget.isOwner ? 40.0 : 80.0;

    // ✅ Target role for suggestions (opposite of current user's role)
    final String oppositeRole = isWorker ? 'maker' : 'finder';

    return Column(
      children: [
        // ═══════════════════════════════════════════════════════════
        // 1. HEADER CARD
        // ═══════════════════════════════════════════════════════════
        ProfileHeaderCard(
          userData: userData,
          roleLabel: roleLabel,
          isDark: isDark,
          isOwner: widget.isOwner,
          isOnline: isOnline,
          cardThemeIndex: _cardThemeIndex,
          followersCount: _followersCountLive,
          followingCount: _followingCountLive,
          userRank: _userRank,
          isFollowing: isFollowing,
          isFollowProcessing: _isFollowProcessing,
          onFollowTap: _toggleFollow,
          onFollowersTap: _showFollowersList,
          onFollowingTap: _showFollowingList,
          onBadgeTap: _showBadgeDetails,
          onRankTap: _showLeaderboard,
          onRatingTap: _openRatingHistory,
          onImageTap: _openFullScreenImage,
        ),

        // ═══════════════════════════════════════════════════════════
        // 2. SOCIAL LINKS
        // ═══════════════════════════════════════════════════════════
        ProfileSocialLinks(userData: userData),

        // ═══════════════════════════════════════════════════════════
        // 3. INFO SECTION (Worker/Supporter Info)
        // ═══════════════════════════════════════════════════════════
        ProfileInfoSection(
          userData: userData,
          isWorker: isWorker,
          isDark: isDark,
        ),

        // ═══════════════════════════════════════════════════════════
        // 4. DOCUMENTS BUTTON (CV & Portfolio)
        // ═══════════════════════════════════════════════════════════
        ProfileDocumentsButton(
          uid: widget.uid,
          isOwner: widget.isOwner,
          isDark: isDark,
        ),

        // ═══════════════════════════════════════════════════════════
        // 5. ABOUT SECTION
        // ═══════════════════════════════════════════════════════════
        ProfileAboutSection(
          about: userData['about']?.toString() ?? '',
          isDark: isDark,
        ),

        const SizedBox(height: 24),

        // ═══════════════════════════════════════════════════════════
        // 6. DYNAMIC SUGGESTIONS (Owner vs Visitor)
        // ═══════════════════════════════════════════════════════════

        // ✅ VISITOR VIEW - Show profile owner's posts
        if (!widget.isOwner) ...[
          // User's Active Posts (4 cards)
          ProfileSuggestionsSection(
            key: _postsSectionKey,
            type: SuggestionType.userPosts,
            targetRole: '',
            targetUid: widget.uid,
            isDark: isDark,
            limit: 4, // ✅ 4 cards
            showSeeAll: false,
          ),

          const SizedBox(height: 24),

          // Similar Profiles (4 cards)
          ProfileSuggestionsSection(
            type: SuggestionType.similarProfiles,
            targetRole: isWorker ? 'finder' : 'maker',
            isDark: isDark,
            excludeUid: widget.uid,
            limit: 4,
          ),

          const SizedBox(height: 24),

          // Top Rated (5 cards)
          ProfileSuggestionsSection(
            type: SuggestionType.topRated,
            targetRole: isWorker ? 'finder' : 'maker',
            isDark: isDark,
            excludeUid: widget.uid,
            limit: 5,
          ),
        ],
        // ✅ OWNER VIEW
        if (widget.isOwner) ...[
          // Recommended Users (4 cards)
          ProfileSuggestionsSection(
            key: _postsSectionKey,
            type: SuggestionType.recommended,
            targetRole: oppositeRole,
            isDark: isDark,
            excludeUid: widget.uid,
            limit: 4,
          ),

          const SizedBox(height: 24),

          // Top Rated (5 cards)
          ProfileSuggestionsSection(
            type: SuggestionType.topRated,
            targetRole: oppositeRole,
            isDark: isDark,
            excludeUid: widget.uid,
            limit: 5,
            onSeeAllTap: _showLeaderboard,
          ),

          const SizedBox(height: 24),

          // New Users (4 cards)
          ProfileSuggestionsSection(
            type: SuggestionType.newUsers,
            targetRole: oppositeRole,
            isDark: isDark,
            excludeUid: widget.uid,
            limit: 4,
          ),
        ],

        SizedBox(height: bottomSpacer),
      ],
    );
  }

  Widget _buildRestrictedView(bool isDark, bool isLocked) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        ProfileHeaderCard(
          userData: userData,
          roleLabel: _isWorkerRole() ? "Worker" : "Supporter",
          isDark: isDark,
          isOwner: false,
          cardThemeIndex: _cardThemeIndex,
        ),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                isLocked ? Icons.lock_outline : Icons.visibility_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                isLocked
                    ? 'This profile is locked.'
                    : 'This profile is currently hidden.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR ACTIONS
  // ═══════════════════════════════════════════════════════════════

  List<Widget> _buildOwnerActions(bool isDark, String subscriptionType) {
    return [
      // Notification Button
      _buildActionButton(
        Icons.notifications_none_rounded,
        'Notifications',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        ),
        isDark,
        showBadge: true,
        badgeCount: _unreadNotifCount,
      ),

      // Team Button
      _buildActionButton(
        Icons.groups_outlined,
        'Team',
        () => _isBusinessUser
            ? Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamManagementScreen(userId: widget.uid),
                ),
              )
            : _showUpgradeToBusinessPopup(),
        isDark,
      ),

      // Settings Button
      _buildActionButton(
        Icons.settings_outlined,
        'Settings',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
        isDark,
      ),

      // Menu Button
      _buildMenuButton(subscriptionType, isDark),
    ];
  }

  List<Widget> _buildVisitorActions(bool isDark) {
    return [_buildVisitorMenuButton(isDark)];
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    bool isDark, {
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            tooltip: tooltip,
          ),
          if (showBadge && badgeCount > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String subscriptionType, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: PopupMenuButton<ProfileMenuOwner>(
        onSelected: _handleOwnerMenu,
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 20,
          color: isDark ? Colors.white : Colors.black,
        ),
        itemBuilder: (ctx) => _buildOwnerMenuItems(subscriptionType),
      ),
    );
  }

  Widget _buildVisitorMenuButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: PopupMenuButton<ProfileMenuOther>(
        onSelected: _handleVisitorMenu,
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 20,
          color: isDark ? Colors.white : Colors.black,
        ),
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: ProfileMenuOther.report,
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 20, color: Colors.orange[400]),
                const SizedBox(width: 12),
                Text(
                  'Report',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: ProfileMenuOther.block,
            child: Row(
              children: [
                Icon(Icons.block, size: 20, color: Colors.red[400]),
                const SizedBox(width: 12),
                Text(
                  'Block',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<ProfileMenuOwner>> _buildOwnerMenuItems(
    String subscriptionType,
  ) {
    final bool isFreeUser = subscriptionType == 'free';
    final bool isLocked = userData['accountLocked'] == true;
    final bool isPaused = userData['workPaused'] == true;
    final bool isHidden = userData['profileHidden'] == true;

    Widget menuRow(
      IconData icon,
      String text,
      Color color, {
      bool showLock = false,
    }) {
      return Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (showLock)
            const Icon(
              Icons.workspace_premium,
              size: 16,
              color: Colors.deepPurpleAccent,
            ),
        ],
      );
    }

    return [
      PopupMenuItem(
        value: ProfileMenuOwner.edit,
        child: menuRow(Icons.edit_rounded, 'Edit Profile', Colors.blue),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.shareProfile,
        child: menuRow(Icons.share_rounded, 'Share Profile', Colors.green),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.previewPublicCard,
        child: menuRow(Icons.visibility_rounded, 'Preview Card', Colors.purple),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: ProfileMenuOwner.lockAccount,
        child: menuRow(
          isLocked ? Icons.lock_open_rounded : Icons.lock_outline,
          isLocked ? 'Unlock Profile' : 'Lock Profile',
          Colors.redAccent,
          showLock: isFreeUser,
        ),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.theme,
        child: menuRow(
          Icons.palette_rounded,
          'Change Theme',
          Colors.orange,
          showLock: isFreeUser,
        ),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.hideProfile,
        child: menuRow(
          isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          isHidden ? 'Unhide Profile' : 'Hide Profile',
          Colors.grey,
          showLock: isFreeUser,
        ),
      ),
      PopupMenuItem(
        value: ProfileMenuOwner.pauseWork,
        child: menuRow(
          isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
          isPaused ? 'Resume Work' : 'Pause Work',
          Colors.amber.shade800,
          showLock: isFreeUser,
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU HANDLERS
  // ═══════════════════════════════════════════════════════════════

  void _handleOwnerMenu(ProfileMenuOwner value) {
    final subscriptionType =
        userData['subscription_type']?.toString() ?? 'free';
    final bool isFreeUser = subscriptionType == 'free';

    switch (value) {
      case ProfileMenuOwner.edit:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedProfileEditScreen(uid: widget.uid),
          ),
        );
        break;

      case ProfileMenuOwner.shareProfile:
        _shareProfile();
        break;

      case ProfileMenuOwner.previewPublicCard:
        _showPublicCardPreview();
        break;

      case ProfileMenuOwner.lockAccount:
      case ProfileMenuOwner.hideProfile:
      case ProfileMenuOwner.pauseWork:
        if (isFreeUser) {
          _showUpgradeToPremiumPopup();
        } else {
          _handlePremiumFeature(value);
        }
        break;

      case ProfileMenuOwner.theme:
        _showCardThemeBottomSheet();
        break;
    }
  }

  void _handleVisitorMenu(ProfileMenuOther value) {
    switch (value) {
      case ProfileMenuOther.report:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportScreen()),
        );
        break;
      case ProfileMenuOther.block:
        _blockUser();
        break;
    }
  }

  void _handlePremiumFeature(ProfileMenuOwner value) async {
    String field;
    String successMsg;
    String failMsg;

    switch (value) {
      case ProfileMenuOwner.lockAccount:
        field = 'accountLocked';
        final current = userData['accountLocked'] == true;
        successMsg = current ? "Profile Unlocked" : "Profile Locked";
        failMsg = "Failed to update lock status";
        break;

      case ProfileMenuOwner.hideProfile:
        field = 'profileHidden';
        final current = userData['profileHidden'] == true;
        successMsg = current ? "Profile Visible" : "Profile Hidden";
        failMsg = "Failed to update visibility";
        break;

      case ProfileMenuOwner.pauseWork:
        field = 'workPaused';
        final current = userData['workPaused'] == true;
        successMsg = current ? "Work Resumed" : "Work Paused";
        failMsg = "Failed to update work status";
        break;

      default:
        return;
    }

    try {
      final current = userData[field] == true;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({field: !current, 'updatedAt': FieldValue.serverTimestamp()});

      setState(() => userData[field] = !current);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$failMsg: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FOLLOW ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _toggleFollow() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || _isFollowProcessing) return;

    setState(() => _isFollowProcessing = true);
    HapticFeedback.lightImpact();

    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid);
      final currentUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid);
      final followRef = currentUserRef.collection('following').doc(widget.uid);
      final followerRef = userRef.collection('followers').doc(currentUid);

      if (isFollowing) {
        // Unfollow
        batch.delete(followRef);
        batch.delete(followerRef);
        batch.update(userRef, {'followersCount': FieldValue.increment(-1)});
        batch.update(currentUserRef, {
          'followingCount': FieldValue.increment(-1),
        });
      } else {
        // Follow
        final currentUserName =
            FirebaseAuth.instance.currentUser?.displayName ?? 'User';
        batch.set(followRef, {
          'followedAt': FieldValue.serverTimestamp(),
          'userName': userData['name'] ?? 'User',
        });
        batch.set(followerRef, {
          'followedAt': FieldValue.serverTimestamp(),
          'userName': currentUserName,
        });
        batch.update(userRef, {'followersCount': FieldValue.increment(1)});
        batch.update(currentUserRef, {
          'followingCount': FieldValue.increment(1),
        });

        // Achievement tracking
        await AchievementService.incrementProgress('daily_follow');
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          isFollowing = !isFollowing;
          _isFollowProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFollowersList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersFollowingScreen(
          userId: widget.uid,
          listType: FollowListType.followers,
        ),
      ),
    );
  }

  void _showFollowingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowersFollowingScreen(
          userId: widget.uid,
          listType: FollowListType.following,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BADGE & RATING
  // ═══════════════════════════════════════════════════════════════

  void _showBadgeDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int xp;
    double stars;
    BadgeLevel badge;

    if (widget.isOwner) {
      final stats = BadgeService.badgeNotifier.value;
      badge = stats.badgeLevel;
      xp = stats.totalXP;
      stars = stats.totalStars;
    } else {
      xp = int.tryParse((userData['xpPoints'] ?? 0).toString()) ?? 0;
      stars =
          double.tryParse(
            (userData['user_accumulated_stars'] ?? 0.0).toString(),
          ) ??
          0.0;
      badge = BadgeService.getBadgeByStars(stars);
    }

    final Color mainColor = _getBadgeColor(badge);
    final String badgeName = badge.toString().split('.').last.toUpperCase();
    final int level = BadgeService.getNumericLevel(xp);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: mainColor.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [mainColor, mainColor.withOpacity(0.6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: mainColor.withOpacity(0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 16),

                // Badge Name
                Text(
                  "$badgeName BADGE",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: mainColor,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                // Level
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Level $level  •  $xp XP",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stars Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "${stars.toStringAsFixed(0)} Stars Collected",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Close Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "CLOSE",
                    style: TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LeaderboardScreen(isStandalone: true),
      ),
    );
  }

  void _openRatingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingHistoryScreen(targetUserId: widget.uid),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE VIEWER
  // ═══════════════════════════════════════════════════════════════

  void _openFullScreenImage() {
    final imageUrl = userData['image']?.toString() ?? '';
    final userName = userData['name']?.toString() ?? 'User';

    if (imageUrl.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (_, __, ___) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 80),
                      SizedBox(height: 16),
                      Text(
                        "Image not available",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COMMUNICATION ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _makePhoneCall() async {
    final phone = userData['phone']?.toString();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        await AchievementService.incrementProgress('daily_contact');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to make call: $e')));
      }
    }
  }

  void _sendEmail() async {
    final email = userData['email']?.toString();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email not available')));
      return;
    }

    try {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        await AchievementService.incrementProgress('daily_contact');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send email: $e')));
      }
    }
  }

  void _scrollToPosts() {
    final ctx = _postsSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No posts available")));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARE & BLOCK
  // ═══════════════════════════════════════════════════════════════

  Future<void> _shareProfile() async {
    final String link = "https://findus.app/profile/${widget.uid}";
    final String name = userData['name']?.toString() ?? 'FindUs User';

    await Share.share("Check out $name on FindUs: $link");

    // Track achievements
    await AchievementService.incrementProgress('daily_share');
    await AchievementService.incrementProgress('lt_invite_s1');
    await AchievementService.syncWeeklyChestFromServer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shared successfully! Quest progress updated."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _blockUser() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetName = userData['name']?.toString() ?? 'User';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red[400]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Block $targetName?",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "They won't be able to:\n\n"
          "• Send you messages\n"
          "• See your profile\n"
          "• Contact you\n\n"
          "You can unblock them anytime.",
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Block"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BlockedUserService().blockUser(widget.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text("$targetName blocked"),
              ],
            ),
            backgroundColor: Colors.green[600],
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to block: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // THEME & CARD PREVIEW
  // ═══════════════════════════════════════════════════════════════

  void _showCardThemeBottomSheet() async {
    try {
      final subscriptionType =
          userData['subscription_type']?.toString() ?? 'free';
      final bool isProUser = subscriptionType != 'free';
      final currentColorIndex = await CardThemeService.getCardThemeIndex(
        widget.uid,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return CardThemeBottomSheet(
            userId: widget.uid,
            initialColorIndex: currentColorIndex,
            isfree: !isProUser,
            subscriptionType: subscriptionType,
            onThemeChanged: (index) {
              setState(() => _cardThemeIndex = index);
              CardThemeService.setCardThemeIndex(widget.uid, index);
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading themes')));
    }
  }

  void _showPublicCardPreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isWorker = _isWorkerRole();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "PUBLIC VIEW PREVIEW",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),

              // Preview card (simplified)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          userData['image'] != null &&
                              userData['image'].toString().isNotEmpty
                          ? NetworkImage(userData['image'].toString())
                          : null,
                      child:
                          userData['image'] == null ||
                              userData['image'].toString().isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userData['name']?.toString() ?? 'User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWorker ? "Worker" : "Supporter",
                      style: const TextStyle(color: AppColors.brandMain),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _previewStat(
                          "Rating",
                          userData['rating']?.toString() ?? '0.0',
                        ),
                        const SizedBox(width: 24),
                        _previewStat(
                          isWorker ? "Jobs" : "Hired",
                          userData['completedCount']?.toString() ?? '0',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // POPUPS
  // ═══════════════════════════════════════════════════════════════

  void _showBlockedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Blocked User'),
          content: const Text('You have blocked this user.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ).then((_) => Navigator.pop(context));
    });
  }

  void _showUpgradeToPremiumPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'Unlock exclusive features like Locking Account, Custom Themes, and more!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeToBusinessPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Business'),
        content: const Text(
          'Unlock Team Management and other business features!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  bool _isWorkerRole() {
    final role = (userData['userRole'] ?? 'finder').toString().toLowerCase();
    return role == 'finder';
  }

  bool get _isBusinessUser {
    return (userData['subscription_type'] ?? 'free') == 'business';
  }

  Color _getBadgeColor(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze:
        return const Color(0xFFFFB74D);
      case BadgeLevel.silver:
        return const Color(0xFFE0E0E0);
      case BadgeLevel.gold:
        return const Color(0xFFFFD700);
      case BadgeLevel.platinum:
        return const Color(0xFF00E5FF);
      case BadgeLevel.diamond:
        return const Color(0xFFB388FF);
      default:
        return Colors.white;
    }
  }

  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ProfileShimmerLoading(isDark: isDark);
  }
}
