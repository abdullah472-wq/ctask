// lib/screens/settings/activation_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';

class ActivationScreen extends StatefulWidget {
  final String planId;
  final int amount;
  final String trxId;
  final DateTime? submittedAt; // ✅ NEW: When payment was submitted

  const ActivationScreen({
    super.key,
    required this.planId,
    required this.amount,
    required this.trxId,
    this.submittedAt,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen>
    with SingleTickerProviderStateMixin {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _countdown = 5;
  Timer? _timer;
  Timer? _elapsedTimer;
  bool _hasRedirected = false;
  Duration _elapsedTime = Duration.zero;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startElapsedTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startElapsedTimer() {
    final submittedAt = widget.submittedAt ?? DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(submittedAt);
        });
      }
    });
  }

  void _startCountdown() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
        _goToProfile();
      }
    });
  }

  void _goToProfile() {
    if (_hasRedirected) return;
    _hasRedirected = true;

    // ✅ Haptic feedback
    HapticFeedback.heavyImpact();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UnifiedProfileScreen(uid: _uid, isOwner: true, showBack: true),
      ),
      (route) => false,
    );
  }

  void _copyTrxId() {
    Clipboard.setData(ClipboardData(text: widget.trxId));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text("TrxID copied to clipboard"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _contactSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContactSupportSheet(trxId: widget.trxId),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: "VERIFICATION",
      showBack: true,
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(isDark, cardColor, textColor);
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            );
          }

          final userData = snapshot.data!.data() ?? {};
          final String status = userData['subStatus'] ?? 'pending';
          final bool isApproved = status == 'active';
          final bool isRejected = status == 'rejected';

          if (isApproved) {
            _updateLocalPrefs(userData['subscription'] ?? 'free');
            _startCountdown();
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Just trigger a rebuild
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.brandMain,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ✅ Progress Timeline
                  _buildProgressTimeline(isApproved, isRejected, isDark),

                  const SizedBox(height: 30),

                  // Status Icon
                  _buildStatusIcon(isApproved, isRejected),

                  const SizedBox(height: 25),

                  // Status Text
                  _buildStatusText(isApproved, isRejected, isDark, textColor),

                  const SizedBox(height: 25),

                  // Info Card
                  _buildInfoCard(
                    isApproved,
                    isRejected,
                    isDark,
                    cardColor,
                    textColor,
                  ),

                  const SizedBox(height: 20),

                  // Elapsed Time (only for pending)
                  if (!isApproved && !isRejected)
                    _buildElapsedTime(isDark, cardColor, textColor),

                  const SizedBox(height: 30),

                  // Action Buttons
                  if (isApproved)
                    _buildSuccessAction(cardColor, textColor)
                  else if (isRejected)
                    _buildRejectedAction(cardColor, textColor)
                  else
                    _buildPendingAction(cardColor, textColor),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildErrorState(bool isDark, Color cardColor, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              "Error checking status",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check your internet connection",
              style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
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

  // ════════════════════════════════════════════════════════════════════════════
  // PROGRESS TIMELINE
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildProgressTimeline(bool isApproved, bool isRejected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          _timelineStep(
            step: 1,
            label: "Payment",
            isCompleted: true,
            isActive: false,
            isDark: isDark,
          ),
          _timelineLine(isCompleted: true, isDark: isDark),
          _timelineStep(
            step: 2,
            label: "Verifying",
            isCompleted: isApproved,
            isActive: !isApproved && !isRejected,
            isDark: isDark,
          ),
          _timelineLine(isCompleted: isApproved, isDark: isDark),
          _timelineStep(
            step: 3,
            label: isRejected ? "Failed" : "Activated",
            isCompleted: isApproved,
            isActive: false,
            isError: isRejected,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required int step,
    required String label,
    required bool isCompleted,
    required bool isActive,
    bool isError = false,
    required bool isDark,
  }) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    if (isError) {
      bgColor = Colors.red;
      iconColor = Colors.white;
      icon = Icons.close;
    } else if (isCompleted) {
      bgColor = Colors.green;
      iconColor = Colors.white;
      icon = Icons.check;
    } else if (isActive) {
      bgColor = AppColors.brandMain;
      iconColor = Colors.white;
      icon = Icons.hourglass_top;
    } else {
      bgColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
      iconColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;
      icon = Icons.circle;
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = isActive ? 1.0 + (_pulseController.value * 0.1) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.brandMain.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isCompleted
                ? FontWeight.bold
                : FontWeight.normal,
            color: isError
                ? Colors.red
                : (isActive
                      ? AppColors.brandMain
                      : (isDark ? Colors.grey : Colors.grey[600])),
          ),
        ),
      ],
    );
  }

  Widget _timelineLine({required bool isCompleted, required bool isDark}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green
              : (isDark ? Colors.grey[700] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATUS ICON
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildStatusIcon(bool isApproved, bool isRejected) {
    if (isApproved) {
      return Lottie.network(
        'https://assets10.lottiefiles.com/packages/lf20_pqnfmone.json',
        width: 150,
        height: 150,
        repeat: false,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.check_circle, size: 100, color: Colors.green);
        },
      );
    } else if (isRejected) {
      return Lottie.network(
        'https://assets5.lottiefiles.com/packages/lf20_qp1q7mct.json', // Error animation
        width: 150,
        height: 150,
        repeat: false,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.cancel, size: 100, color: Colors.red);
        },
      );
    } else {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.05),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 60,
                color: Colors.orange,
              ),
            ),
          );
        },
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATUS TEXT
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildStatusText(
    bool isApproved,
    bool isRejected,
    bool isDark,
    Color textColor,
  ) {
    String title;
    String subtitle;
    Color titleColor;

    if (isApproved) {
      title = "Verification Success! 🎉";
      subtitle = "Your payment has been verified. Welcome to Premium!";
      titleColor = Colors.green;
    } else if (isRejected) {
      title = "Verification Failed ❌";
      subtitle =
          "We couldn't verify your TrxID. Please contact support or try again.";
      titleColor = Colors.red;
    } else {
      title = "Verification Pending ⏳";
      subtitle = "আমরা আপনার TrxID যাচাই করছি। সাধারণত ৩০-৬০ মিনিট সময় লাগে।";
      titleColor = Colors.orange;
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // INFO CARD
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildInfoCard(
    bool isApproved,
    bool isRejected,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    Color borderColor;
    if (isApproved) {
      borderColor = Colors.green.withOpacity(0.3);
    } else if (isRejected) {
      borderColor = Colors.red.withOpacity(0.3);
    } else {
      borderColor = Colors.orange.withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.workspace_premium,
            label: "Selected Plan",
            value: _formatPlanName(widget.planId),
            color: AppColors.brandMain,
            textColor: textColor,
          ),
          _divider(isDark),
          _infoRow(
            icon: Icons.payments_outlined,
            label: "Amount Paid",
            value: "৳${widget.amount}",
            color: Colors.green,
            textColor: textColor,
          ),
          _divider(isDark),
          _infoRow(
            icon: Icons.receipt_long,
            label: "TrxID",
            value: widget.trxId,
            color: Colors.blue,
            textColor: textColor,
            onCopy: _copyTrxId,
          ),
          _divider(isDark),
          _infoRow(
            icon: isApproved
                ? Icons.check_circle
                : (isRejected ? Icons.cancel : Icons.hourglass_top),
            label: "Status",
            value: isApproved
                ? "VERIFIED ✅"
                : (isRejected ? "REJECTED ❌" : "PENDING ⏳"),
            color: isApproved
                ? Colors.green
                : (isRejected ? Colors.red : Colors.orange),
            textColor: textColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  String _formatPlanName(String planId) {
    // PRO_MONTHLY -> Pro (Monthly)
    final parts = planId.split('_');
    if (parts.length >= 2) {
      final plan = parts[0].toLowerCase();
      final cycle = parts[1].toLowerCase();
      return '${plan[0].toUpperCase()}${plan.substring(1)} ($cycle)';
    }
    return planId;
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    VoidCallback? onCopy,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 14,
                    color: isBold ? color : textColor,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              color: Colors.grey,
              tooltip: "Copy TrxID",
            ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.white10 : Colors.grey[200],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ELAPSED TIME
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildElapsedTime(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: Colors.grey[500], size: 20),
          const SizedBox(width: 10),
          Text(
            "Waiting for: ",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          Text(
            _formatDuration(_elapsedTime),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _elapsedTime.inMinutes > 60 ? Colors.orange : textColor,
              fontSize: 15,
            ),
          ),
          if (_elapsedTime.inMinutes > 60) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: _contactSupport,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                "Contact Support",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPendingAction(Color cardColor, Color textColor) {
    return Column(
      children: [
        // Animated loading
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.orange,
            backgroundColor: Colors.orange.withOpacity(0.2),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          "আপনি এই পেজ বন্ধ করতে পারেন।\nযাচাই হলে আমরা নোটিফিকেশন পাঠাবো।",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5),
        ),

        const SizedBox(height: 25),

        // Close Button
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text("CLOSE & WAIT"),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            side: BorderSide(color: Colors.grey[400]!),
          ),
        ),

        const SizedBox(height: 12),

        // Contact Support
        TextButton.icon(
          onPressed: _contactSupport,
          icon: const Icon(Icons.support_agent, size: 18),
          label: const Text("Need Help? Contact Support"),
          style: TextButton.styleFrom(foregroundColor: AppColors.brandMain),
        ),
      ],
    );
  }

  Widget _buildSuccessAction(Color cardColor, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                "Redirecting in $_countdown seconds...",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: _goToProfile,
          icon: const Icon(Icons.rocket_launch),
          label: const Text(
            "GO TO PREMIUM PROFILE",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandMain,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildRejectedAction(Color cardColor, Color textColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "সমস্যার কারণ: TrxID মেলেনি বা আগে ব্যবহৃত হয়েছে।",
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to payment screen
          },
          icon: const Icon(Icons.refresh),
          label: const Text("TRY AGAIN"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandMain,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: _contactSupport,
          icon: const Icon(Icons.support_agent),
          label: const Text("CONTACT SUPPORT"),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _updateLocalPrefs(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan);
    await prefs.setBool('has_active_subscription', true);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CONTACT SUPPORT SHEET
// ════════════════════════════════════════════════════════════════════════════

class _ContactSupportSheet extends StatelessWidget {
  final String trxId;

  const _ContactSupportSheet({required this.trxId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: AppColors.brandMain,
              size: 40,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "Contact Support",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "আপনার TrxID: $trxId\n\nনিচের যেকোনো মাধ্যমে যোগাযোগ করুন:",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // WhatsApp
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.support_agent, color: Colors.green),
            ),
            title: const Text("WhatsApp"),
            subtitle: const Text("+880 1700-000000"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // Launch WhatsApp
            },
          ),

          // Email
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.email_outlined, color: Colors.blue),
            ),
            title: const Text("Email"),
            subtitle: const Text("support@findus.app"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // Launch email
            },
          ),

          // Phone
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_outlined, color: Colors.orange),
            ),
            title: const Text("Hotline"),
            subtitle: const Text("16000 (9AM - 6PM)"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // Launch phone
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
