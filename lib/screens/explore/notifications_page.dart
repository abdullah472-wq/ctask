// lib/screens/explore/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart';
import 'package:findus_app/screens/settings/help_center_screen.dart';
import 'package:findus_app/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // ✅ Screen open হলে সব unread mark as read
    if (_uid.isNotEmpty) {
      _markAllAsReadOnOpen();
    }
  }

  // ✅ Screen খুললে সব read করা
  Future<void> _markAllAsReadOnOpen() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_uid.isNotEmpty) {
      NotificationService.markAllAsRead(_uid);
    }
  }

  void _showAdminNoticeDialog(String title, String body, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.brandMain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                foregroundColor: isDark ? Colors.white : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("CLOSE"),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSenderProfile(String senderId) {
    if (senderId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UnifiedProfileScreen(uid: senderId, isOwner: false, showBack: true),
      ),
    );
  }

  Future<void> _createWelcomeNotificationIfNeeded() async {
    if (_uid.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();

    final userData = userDoc.data() ?? {};
    final name = (userData['name'] ?? userData['fullName'] ?? 'User')
        .toString();

    final notifRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications');

    final existing = await notifRef
        .where('type', isEqualTo: 'welcome')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    await notifRef.add({
      'title': 'Welcome to FindUs, $name!',
      'body':
          'Thanks for joining the FindUs community.\n'
          'You can complete your profile, explore jobs, and connect with local members right away.',
      'type': 'welcome',
      'senderId': '',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _showDeleteAllDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete All Notifications?",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          "This action cannot be undone.",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              NotificationService.deleteAllNotifications(_uid);
            },
            child: const Text(
              "Delete All",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ 3-DOT MENU OPTIONS FOR EACH NOTIFICATION
  // ═══════════════════════════════════════════════════════════════

  void _showNotificationOptions(
    BuildContext context,
    String notifId,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    final String title = data['title'] ?? 'Notification';
    final String body = data['body'] ?? '';
    final String type = (data['type'] ?? '').toString().toLowerCase();
    final String senderId = data['senderId'] ?? '';
    final bool isRead = data['read'] ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ✅ Option 1: Mark as Read/Unread
              _buildOptionTile(
                icon: isRead ? Icons.mark_email_unread : Icons.done_all,
                iconColor: Colors.blue,
                title: isRead ? "Mark as Unread" : "Mark as Read",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  if (isRead) {
                    NotificationService.markAsUnread(_uid, notifId);
                    _showSnackBar("Marked as unread");
                  } else {
                    NotificationService.markAsRead(_uid, notifId);
                    _showSnackBar("Marked as read");
                  }
                },
              ),

              // ✅ Option 2: View Sender Profile (if available)
              if (senderId.isNotEmpty)
                _buildOptionTile(
                  icon: Icons.person,
                  iconColor: Colors.teal,
                  title: "View Sender Profile",
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToSenderProfile(senderId);
                  },
                ),

              // ✅ Option 3: Copy Text
              _buildOptionTile(
                icon: Icons.copy,
                iconColor: Colors.purple,
                title: "Copy Text",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  final textToCopy = "$title\n$body";
                  Clipboard.setData(ClipboardData(text: textToCopy));
                  _showSnackBar("Copied to clipboard");
                },
              ),

              // ✅ Option 4: Share
              _buildOptionTile(
                icon: Icons.share,
                iconColor: Colors.orange,
                title: "Share",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share("$title\n\n$body");
                },
              ),

              // ✅ Option 5: Mute Similar (Type-based)
              if (type.isNotEmpty && type != 'welcome')
                _buildOptionTile(
                  icon: Icons.notifications_off,
                  iconColor: Colors.grey,
                  title: "Mute ${_getTypeLabel(type)} Notifications",
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _muteNotificationType(type);
                  },
                ),

              const Divider(height: 20),

              // ✅ Option 6: Delete
              _buildOptionTile(
                icon: Icons.delete,
                iconColor: Colors.red,
                title: "Delete Notification",
                isDark: isDark,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(notifId, isDark);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive
        ? Colors.red
        : (isDark ? Colors.white : Colors.black87);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? Colors.white38 : Colors.grey,
        size: 20,
      ),
    );
  }

  String _getTypeLabel(String type) {
    if (type.contains('admin')) return 'Admin';
    if (type.contains('job')) return 'Job';
    if (type.contains('profile')) return 'Profile';
    if (type.contains('review')) return 'Review';
    if (type.contains('help')) return 'Help';
    return 'Notification';
  }

  Future<void> _muteNotificationType(String type) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('notifications')
          .set({
            'muted_types': FieldValue.arrayUnion([type]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showSnackBar("${_getTypeLabel(type)} notifications muted");
    } catch (e) {
      _showSnackBar("Failed to mute notifications");
    }
  }

  void _confirmDelete(String notifId, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Notification?",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          "This notification will be permanently deleted.",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              NotificationService.deleteNotification(_uid, notifId);
              _showSnackBar("Notification deleted");
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    if (_uid.isEmpty) {
      return const ProfileNotLoggedIn(
        title: "Notifications",
        showBackButton: true,
      );
    }

    return FloatingScaffold(
      title: "NOTIFICATIONS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textColor),
          onSelected: (value) {
            if (value == 'mark_all_read') {
              NotificationService.markAllAsRead(_uid);
              _showSnackBar("All notifications marked as read");
            } else if (value == 'delete_all') {
              _showDeleteAllDialog(isDark);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(Icons.done_all, size: 20),
                  SizedBox(width: 10),
                  Text("Mark All as Read"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Delete All", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            _createWelcomeNotificationIfNeeded();
            return _buildEmptyState(isDark);
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final notifId = docs[index].id;
              return _buildNotificationItem(data, notifId, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.brandMain.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 60,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No notifications yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ NOTIFICATION ITEM WITH 3-DOT MENU
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNotificationItem(
    Map<String, dynamic> data,
    String id,
    bool isDark,
  ) {
    final title = data['title'] ?? 'New Notification';
    final body = data['body'] ?? '';
    final type = (data['type'] ?? 'info').toString().toLowerCase();
    final senderId = data['senderId'] ?? '';
    final bool isRead = data['read'] ?? false;
    final Timestamp? ts = data['createdAt'];

    IconData icon = Icons.notifications;
    Color iconColor = AppColors.brandMain;

    if (type.contains('admin')) {
      icon = Icons.admin_panel_settings;
      iconColor = Colors.redAccent;
    } else if (type.contains('job')) {
      icon = Icons.work;
      iconColor = Colors.orange;
    } else if (type.contains('help') || type.contains('welcome')) {
      icon = Icons.support_agent;
      iconColor = Colors.purpleAccent;
    } else if (type.contains('profile')) {
      icon = Icons.visibility;
      iconColor = Colors.teal;
    } else if (type.contains('review')) {
      icon = Icons.star;
      iconColor = Colors.amber;
    } else if (type.contains('follow')) {
      icon = Icons.person_add;
      iconColor = Colors.blue;
    } else if (type.contains('like')) {
      icon = Icons.favorite;
      iconColor = Colors.red;
    }

    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final unreadBg = isDark
        ? const Color(0xFF383838)
        : AppColors.brandMain.withOpacity(0.05);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Delete Notification?",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        NotificationService.deleteNotification(_uid, id);
        _showSnackBar("Notification deleted");
      },
      child: InkWell(
        onTap: () {
          if (type.contains('admin')) {
            _showAdminNoticeDialog(title, body, isDark);
          } else if (type.contains('help') || type.contains('welcome')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            );
          } else if (senderId.isNotEmpty) {
            _navigateToSenderProfile(senderId);
          }

          if (!isRead) {
            NotificationService.markAsRead(_uid, id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? cardColor : unreadBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? (isDark ? Colors.white10 : Colors.grey.shade200)
                  : AppColors.brandMain.withOpacity(0.3),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unread dot
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brandMain,
                              shape: BoxShape.circle,
                            ),
                          ),
                        // Title
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Time
                    if (ts != null)
                      Text(
                        _formatTime(ts),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),

              // ✅ 3-DOT MENU BUTTON
              InkWell(
                onTap: () =>
                    _showNotificationOptions(context, id, data, isDark),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat('MMM d').format(date);
  }
}
