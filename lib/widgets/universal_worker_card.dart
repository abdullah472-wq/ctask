// lib/widgets/universal_worker_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_theme.dart';

class UniversalWorkerCard extends StatefulWidget {
  final String? id;
  final String name;
  final String role;
  final String imageUrl;
  final String address;
  final String rating;
  final String completed;
  final String reviews;
  final String price;
  final String time;
  final String? phoneNumber;
  final EdgeInsetsGeometry margin;
  final int? followersCount;

  final String? facebookUrl;
  final String? emailAddress;
  final String? whatsappNumber;
  final String? websiteUrl;

  final int? colorIndex;

  final bool isVerifiedWorker;
  final bool isTopRated;
  final bool isTrusted;
  final bool isEditable;
  final bool isOnline;

  final VoidCallback? onTap;
  final VoidCallback? onViewProfileTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;

  final BadgeLevel? badgeLevel;
  final bool isSaved;

  final bool showActionButtons;
  final bool showStats;
  final bool showSaveButton;
  final bool showShareButton;
  final bool showOnlineStatus;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool enableImageZoom;
  final String primaryButtonText;
  final String jobLabel;

  final String? tagText;
  final Color? tagColor;
  final IconData? tagIcon;

  const UniversalWorkerCard({
    super.key,
    this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.address,
    required this.rating,
    required this.completed,
    required this.reviews,
    this.price = "Negotiable",
    this.time = "Available Now",
    this.phoneNumber,
    this.facebookUrl,
    this.emailAddress,
    this.whatsappNumber,
    this.websiteUrl,
    this.isVerifiedWorker = false,
    this.isTopRated = false,
    this.isTrusted = false,
    this.isEditable = false,
    this.isOnline = false,
    this.onTap,
    this.onViewProfileTap,
    this.onShareTap,
    this.badgeLevel,
    this.colorIndex,
    this.isSaved = false,
    this.onSaveTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    this.followersCount,
    this.showActionButtons = true,
    this.showStats = true,
    this.showSaveButton = true,
    this.showShareButton = true,
    this.showOnlineStatus = false,
    this.elevation,
    this.borderRadius,
    this.enableImageZoom = true,
    this.primaryButtonText = "View Job Details",
    this.jobLabel = "JOBS",
    this.tagText,
    this.tagColor,
    this.tagIcon,
  });

  @override
  State<UniversalWorkerCard> createState() => _UniversalWorkerCardState();
}

class _UniversalWorkerCardState extends State<UniversalWorkerCard> {
  late bool _isSavedLocal;
  bool _isSaveLoading = false;

  static const List<List<Color>> _themeGradients = [
    [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
    [Color(0xFFFFF3E0), Color(0xFFFFFFFF)],
    [Color(0xFFE8EAF6), Color(0xFFFFFFFF)],
    [Color(0xFFFCE4EC), Color(0xFFFFFFFF)],
  ];

  @override
  void initState() {
    super.initState();
    _isSavedLocal = widget.isSaved;
  }

  @override
  void didUpdateWidget(covariant UniversalWorkerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSaved != widget.isSaved) {
      _isSavedLocal = widget.isSaved;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE URL VALIDATION
  // ═══════════════════════════════════════════════════════════════

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    if (url.toLowerCase() == 'null') return false;
    if (url.toLowerCase() == 'undefined') return false;
    if (url.length < 10) return false; // Too short to be valid URL

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }

    return uri.host.isNotEmpty;
  }

  String _getValidImageUrl() {
    String url = widget.imageUrl.trim();

    if (_isValidImageUrl(url)) {
      return url;
    }

    // ✅ Generate avatar from name if no valid image
    final encodedName = Uri.encodeComponent(
      widget.name.isNotEmpty ? widget.name : 'User',
    );
    return 'https://ui-avatars.com/api/?name=$encodedName&size=150&background=38B6FF&color=fff&bold=true';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final cleanName = name.trim();
    final parts = cleanName.split(RegExp(r'\s+'));

    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    if (cleanName.isNotEmpty) {
      return cleanName[0].toUpperCase();
    }

    return '?';
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFILE IMAGE - ALWAYS SHOW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileImage(bool isDark) {
    const double size = 75;
    final String imageUrl = _getValidImageUrl();
    final bool hasValidImage = _isValidImageUrl(widget.imageUrl.trim());

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              width: 2,
            ),
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: size,
              height: size,
              memCacheWidth: 200,
              memCacheHeight: 200,
              placeholder: (context, url) => _buildLoadingPlaceholder(isDark),
              errorWidget: (context, url, error) => _buildErrorFallback(isDark),
            ),
          ),
        ),

        // Online Status Dot
        if (widget.showOnlineStatus && widget.isOnline)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingPlaceholder(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorFallback(bool isDark) {
    final initials = _getInitials(widget.name);

    return Container(
      color: AppColors.brandMain.withOpacity(0.15),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.brandMain,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE HANDLER
  // ═══════════════════════════════════════════════════════════════

  Future<void> _toggleSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final workerId = widget.id;

    if (uid == null || workerId == null || workerId.isEmpty) {
      _showSnackBar("Cannot save: Invalid user or profile");
      return;
    }

    if (uid == workerId) {
      _showSnackBar("You cannot save your own profile");
      return;
    }

    if (_isSaveLoading) return;

    setState(() {
      _isSaveLoading = true;
      _isSavedLocal = !_isSavedLocal;
    });

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_profiles')
          .doc(workerId);

      if (_isSavedLocal) {
        await ref.set({
          'savedAt': FieldValue.serverTimestamp(),
          'workerId': workerId,
          'name': widget.name,
          'image': widget.imageUrl,
          'role': widget.role,
          'rating': widget.rating,
        });
      } else {
        await ref.delete();
      }

      widget.onSaveTap?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _isSavedLocal = !_isSavedLocal);
        _showSnackBar("Save failed: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isSaveLoading = false);
      }
    }
  }

  void _shareProfile() {
    if (widget.onShareTap != null) {
      widget.onShareTap!();
      return;
    }

    final workerId = widget.id;
    if (workerId == null || workerId.isEmpty) {
      _showSnackBar("Cannot share: Invalid profile");
      return;
    }

    final String link = "https://findus.app/profile/$workerId";
    final String text =
        "Check out ${widget.name} on FindUs!\n"
        "Role: ${widget.role}\n"
        "Rating: ${widget.rating} ⭐\n"
        "$link";

    Share.share(text);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Color> bgColors;
    if (widget.colorIndex != null) {
      final index = widget.colorIndex!.clamp(0, _themeGradients.length - 1);
      final theme = _themeGradients[index];
      bgColors = isDark
          ? [theme[0].withOpacity(0.8), const Color(0xFF1E1E1E)]
          : theme;
    } else {
      bgColors = isDark
          ? [const Color(0xFF2C2C2C), const Color(0xFF2C2C2C)]
          : [Colors.white, Colors.white];
    }

    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    final activeBadge = widget.badgeLevel ?? _calculateBadgeFromRating();
    final badgeColor = AppBadgeTheme.colorForLevel(activeBadge);
    final badgeName = activeBadge.name.toUpperCase();

    final bool isNegotiableText = widget.price.toLowerCase().contains(
      'negotiable',
    );
    final String followersDisplay = _formatNumber(widget.followersCount ?? 0);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: widget.elevation ?? 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                top: -15,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(
                    Icons.workspace_premium,
                    size: 120,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileImage(isDark),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildUserInfo(isDark, isNegotiableText),
                        ),
                        _buildBadgeColumn(badgeColor, badgeName, isDark),
                      ],
                    ),
                    if (widget.showStats) ...[
                      const SizedBox(height: 16),
                      _buildStatsRow(isDark, followersDisplay),
                    ],
                    if (widget.showActionButtons) ...[
                      const SizedBox(height: 16),
                      _buildActionButtons(isDark),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BadgeLevel _calculateBadgeFromRating() {
    final rating = double.tryParse(widget.rating) ?? 0.0;
    final completed = int.tryParse(widget.completed) ?? 0;

    if (completed >= 100 && rating >= 4.8) return BadgeLevel.diamond;
    if (completed >= 50 && rating >= 4.5) return BadgeLevel.platinum;
    if (completed >= 30 && rating >= 4.2) return BadgeLevel.gold;
    if (completed >= 15 && rating >= 4.0) return BadgeLevel.silver;
    if (completed >= 5 && rating >= 3.5) return BadgeLevel.bronze;
    return BadgeLevel.newbie;
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  Widget _buildUserInfo(bool isDark, bool isNegotiableText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (widget.isVerifiedWorker)
              _statusIcon(Icons.verified, Colors.blue),
            if (widget.isTopRated) _statusIcon(Icons.star, Colors.orange),
            if (widget.isTrusted) _statusIcon(Icons.shield, Colors.green),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          widget.role.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.brandMain,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.brandMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isNegotiableText)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Text(
                    "৳",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMain,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  widget.price,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeColumn(Color badgeColor, String badgeName, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.tagText != null && widget.tagText!.trim().isNotEmpty) ...[
          _buildTagChip(
            text: widget.tagText!.trim(),
            color: widget.tagColor ?? AppColors.brandMain,
            icon: widget.tagIcon,
            isDark: isDark,
          ),
          const SizedBox(height: 6),
        ],
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.workspace_premium, size: 24, color: badgeColor),
        ),
        const SizedBox(height: 4),
        Text(
          badgeName,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: badgeColor,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, String followersValue) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(widget.completed, widget.jobLabel, isDark),
          _verticalDivider(isDark),
          _buildStat(widget.rating, "RATING", isDark),
          _verticalDivider(isDark),
          _buildStat(followersValue, "FOLLOWERS", isDark),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: widget.onViewProfileTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.brandMain),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: isDark ? Colors.transparent : Colors.white,
                foregroundColor: AppColors.brandMain,
              ),
              child: Text(
                widget.primaryButtonText.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
        if (widget.showSaveButton) ...[
          const SizedBox(width: 8),
          _buildIconButton(
            _isSavedLocal ? Icons.favorite : Icons.favorite_border,
            _isSaveLoading ? null : _toggleSave,
            _isSavedLocal
                ? Colors.red
                : (isDark ? Colors.white70 : Colors.grey.shade600),
            isDark,
          ),
        ],
        if (widget.showShareButton) ...[
          const SizedBox(width: 8),
          _buildIconButton(
            Icons.share_outlined,
            _shareProfile,
            isDark ? Colors.white70 : Colors.grey.shade600,
            isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback? onTap,
    Color color,
    bool isDark,
  ) {
    final isDisabled = onTap == null;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: isDisabled ? Colors.grey : color, size: 18),
      ),
    );
  }

  Widget _statusIcon(IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip({
    required String text,
    required Color color,
    IconData? icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider(bool isDark) {
    return Container(
      height: 20,
      width: 1,
      color: isDark ? Colors.white12 : Colors.grey.shade300,
    );
  }
}
