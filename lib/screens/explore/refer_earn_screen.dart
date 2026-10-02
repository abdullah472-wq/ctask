import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/localization/localization_wrapper.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/services/referral_service.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _downloadBaseUrl = "https://findus.app/download";

  final TextEditingController _enterCodeController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _isApplyingCode = false;
  bool _isRequestingPayout = false;

  String _referralCode = "";
  int _invited = 0;
  int _joined = 0;
  int _totalRewards = 0;
  int _pendingRewards = 0;
  bool _hasReferrer = false;
  String? _error;

  String get _referralLink =>
      _referralCode.isNotEmpty ? "$_downloadBaseUrl?ref=$_referralCode" : "";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadReferralData();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _enterCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadReferralData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = "not_logged_in";
          _isLoading = false;
        });
        return;
      }

      final userDocRef = _db.collection('users').doc(user.uid);
      final snap = await userDocRef.get();

      Map<String, dynamic> data = {};
      if (snap.exists) data = snap.data() as Map<String, dynamic>;

      String code = (data['referralCode'] ?? "") as String;

      if (code.trim().isEmpty) {
        code = _generateReferralCode(user.uid);
        await userDocRef.set({
          'referralCode': code,
          'referralInvitedCount': data['referralInvitedCount'] ?? 0,
          'referralJoinedCount': data['referralJoinedCount'] ?? 0,
          'referralTotalRewards': data['referralTotalRewards'] ?? 0,
          'referralPendingRewards': data['referralPendingRewards'] ?? 0,
          'referralLastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      setState(() {
        _referralCode = code;
        _invited = _parseToInt(data['referralInvitedCount']);
        _joined = _parseToInt(data['referralJoinedCount']);
        _totalRewards = _parseToInt(data['referralTotalRewards']);
        _pendingRewards = _parseToInt(data['referralPendingRewards']);
        _hasReferrer =
            data['referredBy'] != null &&
            data['referredBy'].toString().isNotEmpty;
        _isLoading = false;
      });

      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "load_error";
        _isLoading = false;
      });
    }
  }

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _generateReferralCode(String uid) {
    final short = uid.length >= 6 ? uid.substring(0, 6) : uid;
    return "FD${short.toUpperCase()}";
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : (isSuccess
                        ? Icons.check_circle_outline
                        : Icons.info_outline),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : (isSuccess ? Colors.green.shade600 : AppColors.brandMain),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _copyText(String text, String successMessage) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _showSnackBar(successMessage, isSuccess: true);
  }

  Future<void> _applyCode() async {
    final code = _enterCodeController.text.trim();
    final isBengali = context.read<LocalizationWrapper>().isBengali;

    if (code.isEmpty) {
      _showSnackBar(
        isBengali ? "কোড লিখুন" : "Please enter a code",
        isError: true,
      );
      return;
    }

    if (code == _referralCode) {
      _showSnackBar(
        isBengali
            ? "আপনি নিজের কোড ব্যবহার করতে পারবেন না!"
            : "You cannot use your own code!",
        isError: true,
      );
      return;
    }

    setState(() => _isApplyingCode = true);

    try {
      await ReferralService.applyReferralCode(
        newUserId: _auth.currentUser!.uid,
        code: code,
      );

      await _loadReferralData();

      if (mounted) {
        _showSnackBar(
          isBengali
              ? "রেফারেল কোড সফলভাবে প্রয়োগ হয়েছে!"
              : "Referral code applied successfully!",
          isSuccess: true,
        );
        _enterCodeController.clear();
      }
    } catch (e) {
      _showSnackBar(
        isBengali ? "কোড প্রয়োগ ব্যর্থ হয়েছে" : "Failed to apply code",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isApplyingCode = false);
    }
  }

  Future<void> _requestPayout() async {
    final isBengali = context.read<LocalizationWrapper>().isBengali;

    if (_totalRewards < 100) {
      _showDialog(
        title: isBengali ? "নোটিশ" : "Notice",
        message: isBengali
            ? "উত্তোলনের জন্য সর্বনিম্ন ৳100 প্রয়োজন। আরো বন্ধুদের আমন্ত্রণ করুন!"
            : "You need minimum ৳100 to withdraw. Keep inviting!",
        isError: true,
      );
      return;
    }

    setState(() => _isRequestingPayout = true);

    try {
      final uid = _auth.currentUser!.uid;

      await _db.collection('payout_requests').add({
        'userId': uid,
        'amount': _totalRewards,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'method': 'Manual Review',
      });

      if (mounted) {
        _showDialog(
          title: isBengali ? "সফল" : "Success",
          message: isBengali
              ? "পেআউট অনুরোধ পাঠানো হয়েছে! আমরা শীঘ্রই পর্যালোচনা করে টাকা ট্রান্সফার করব।"
              : "Payout request sent! We will review and transfer the amount shortly.",
          isSuccess: true,
        );
      }
    } catch (e) {
      _showDialog(
        title: isBengali ? "ত্রুটি" : "Error",
        message: isBengali
            ? "অনুরোধ পাঠাতে ব্যর্থ। পরে আবার চেষ্টা করুন।"
            : "Failed to send request. Try again later.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isRequestingPayout = false);
    }
  }

  void _showDialog({
    required String title,
    required String message,
    bool isError = false,
    bool isSuccess = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isError
                  ? Icons.warning_rounded
                  : (isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.info_rounded),
              color: isError
                  ? Colors.red
                  : (isSuccess ? Colors.green : AppColors.brandMain),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isSuccess ? "GREAT" : "OK",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReferral(String platformName) async {
    final isBengali = context.read<LocalizationWrapper>().isBengali;

    if (_referralLink.isEmpty) return;

    final String message = isBengali
        ? "FindUs এ যোগ দিন আমার রেফারেল কোড দিয়ে: $_referralCode\nএখনই ডাউনলোড করুন: $_referralLink"
        : "Join FindUs using my referral code: $_referralCode\nDownload now: $_referralLink";

    await Share.share(message);

    // Update Achievements
    await AchievementService.incrementProgress('lt_invite_s1');
    await AchievementService.incrementProgress('lt_invite_s2');
    await AchievementService.incrementProgress('lt_invite_s3');
    await AchievementService.incrementProgress('daily_share');
    await AchievementService.syncWeeklyChestFromServer();

    if (mounted) {
      _showSnackBar(
        isBengali
            ? "$platformName এ শেয়ার করা হয়েছে! কোয়েস্ট আপডেট হয়েছে।"
            : "Shared via $platformName! Quest updated.",
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBengali = context.watch<LocalizationWrapper>().isBengali;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: isBengali ? "রেফার ও আয়" : "Refer & Earn",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: _buildBody(isDark, isBengali, textColor),
    );
  }

  Widget _buildBody(bool isDark, bool isBengali, Color textColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.brandMain),
            const SizedBox(height: 16),
            Text(
              isBengali ? "লোড হচ্ছে..." : "Loading...",
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState(isDark, isBengali);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              _buildHeaderBanner(isDark, isBengali),

              const SizedBox(height: 20),

              // Enter Code Card (if no referrer)
              if (!_hasReferrer) ...[
                _buildEnterCodeCard(isDark, isBengali),
                const SizedBox(height: 16),
              ],

              // Stats Card
              _buildStatsCard(isDark, isBengali),

              const SizedBox(height: 16),

              // Referral Code Card
              _buildReferralCodeCard(isDark, isBengali),

              const SizedBox(height: 20),

              // Share Actions
              _buildShareActionsSection(isDark, isBengali),

              const SizedBox(height: 20),

              // QR Code Card
              _buildQrCodeCard(isDark, isBengali),

              const SizedBox(height: 20),

              // How It Works
              _buildHowItWorksSection(isDark, isBengali),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, bool isBengali) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              _error == "not_logged_in"
                  ? (isBengali
                        ? "রেফারেল বিবরণ দেখতে লগইন করুন।"
                        : "Please log in to see referral details.")
                  : (isBengali
                        ? "রেফারেল ডেটা লোড করতে ব্যর্থ।"
                        : "Failed to load referral data."),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadReferralData,
              icon: const Icon(Icons.refresh),
              label: Text(isBengali ? "পুনরায় চেষ্টা করুন" : "Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark, bool isBengali) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandMain, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBengali ? "বন্ধুদের আমন্ত্রণ করুন" : "Invite Friends",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBengali
                      ? "প্রতিটি সফল রেফারেলে ৳5 পান!"
                      : "Get ৳5 for every successful referral!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterCodeCard(bool isDark, bool isBengali) {
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.brandMain.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandMain.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.brandMain,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isBengali ? "রেফারেল কোড আছে?" : "Have a referral code?",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _enterCodeController,
                  style: TextStyle(color: textColor),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: isBengali ? "কোড লিখুন" : "Enter code here",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.brandMain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isApplyingCode ? null : _applyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _isApplyingCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isBengali ? "প্রয়োগ" : "APPLY",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDark, bool isBengali) {
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final canWithdraw = _totalRewards >= 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                color: AppColors.brandMain,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isBengali ? "আপনার রেফারেল পরিসংখ্যান" : "Your Referral Stats",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.person_add_alt_rounded,
                label: isBengali ? "আমন্ত্রিত" : "Invited",
                value: _invited.toString(),
                color: Colors.blue,
                isDark: isDark,
              ),
              _buildStatItem(
                icon: Icons.group_rounded,
                label: isBengali ? "যোগ দিয়েছে" : "Joined",
                value: _joined.toString(),
                color: Colors.green,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.account_balance_wallet_rounded,
                label: isBengali ? "মোট আয়" : "Total Earned",
                value: "৳$_totalRewards",
                color: Colors.orange,
                isDark: isDark,
              ),
              _buildStatItem(
                icon: Icons.hourglass_bottom_rounded,
                label: isBengali ? "অপেক্ষমাণ" : "Pending",
                value: "৳$_pendingRewards",
                color: Colors.purple,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Withdraw Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isRequestingPayout || !canWithdraw
                  ? null
                  : _requestPayout,
              style: ElevatedButton.styleFrom(
                backgroundColor: canWithdraw ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: canWithdraw ? 2 : 0,
              ),
              icon: _isRequestingPayout
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.payments_rounded),
              label: Text(
                isBengali ? "পেআউট অনুরোধ" : "REQUEST PAYOUT",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          if (!canWithdraw)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                  isBengali
                      ? "উত্তোলনের জন্য ৳100 প্রয়োজন"
                      : "Reach ৳100 to withdraw",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.brandDark,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
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

  Widget _buildReferralCodeCard(bool isDark, bool isBengali) {
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBengali ? "আপনার রেফারেল কোড" : "Your Referral Code",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.black26, Colors.black12]
                    : [AppColors.brandLight, AppColors.bgBlue],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _referralCode.isNotEmpty ? _referralCode : "...",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _referralCode.isEmpty
                      ? null
                      : () => _copyText(
                          _referralCode,
                          isBengali
                              ? "রেফারেল কোড কপি হয়েছে"
                              : "Referral code copied",
                        ),
                  icon: const Icon(Icons.copy_rounded),
                  color: AppColors.brandMain,
                  tooltip: isBengali ? "কপি করুন" : "Copy code",
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isBengali ? "রেফারেল লিংক" : "Referral Link",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: AppColors.brandMain,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _referralLink.isNotEmpty
                        ? _referralLink
                        : (isBengali
                              ? "লিংক এখানে দেখাবে"
                              : "Link will appear here"),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _referralLink.isEmpty
                      ? null
                      : () => _copyText(
                          _referralLink,
                          isBengali ? "লিংক কপি হয়েছে" : "Link copied",
                        ),
                  child: Text(
                    isBengali ? "কপি" : "COPY",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareActionsSection(bool isDark, bool isBengali) {
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.share_rounded, color: AppColors.brandMain, size: 20),
            const SizedBox(width: 8),
            Text(
              isBengali ? "দ্রুত শেয়ার" : "Quick Share",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildShareButton(
              icon: Icons.share_rounded,
              label: "WhatsApp",
              color: Colors.green,
              onTap: () => _shareReferral("WhatsApp"),
              isDark: isDark,
            ),
            _buildShareButton(
              icon: Icons.facebook_rounded,
              label: "Facebook",
              color: Colors.blue,
              onTap: () => _shareReferral("Facebook"),
              isDark: isDark,
            ),
            _buildShareButton(
              icon: Icons.message_rounded,
              label: isBengali ? "এসএমএস" : "SMS",
              color: Colors.orange,
              onTap: () => _shareReferral("SMS"),
              isDark: isDark,
            ),
            _buildShareButton(
              icon: Icons.more_horiz_rounded,
              label: isBengali ? "আরো" : "More",
              color: Colors.purple,
              onTap: () => _shareReferral("Other Apps"),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(bool isDark, bool isBengali) {
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final qrUrl = _referralCode.isNotEmpty
        ? "https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=$_referralLink"
        : null;

    if (qrUrl == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isBengali ? "QR কোড দিয়ে শেয়ার করুন" : "Share with QR Code",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isBengali
                ? "বন্ধুরা এই QR স্ক্যান করে FINDUS ডাউনলোড করতে পারবে"
                : "Friends can scan this QR to download FINDUS",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brandMain.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                qrUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandMain,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.qr_code_rounded,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(bool isDark, bool isBengali) {
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final steps = isBengali
        ? [
            "আপনার রেফারেল লিংক বা QR কোড বন্ধুদের সাথে শেয়ার করুন।",
            "তারা আপনার লিংক বা কোড ব্যবহার করে সাইন আপ করবে।",
            "তাদের প্রথম কাজ সম্পন্ন হলে, আপনি ৳5 পাবেন!",
          ]
        : [
            "Share your referral link or QR code with friends.",
            "They sign up using your link or code.",
            "When they complete their first job, you get ৳5 reward!",
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: AppColors.brandMain,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isBengali ? "এটি কিভাবে কাজ করে" : "How it works",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brandMain, AppColors.brandDark],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
