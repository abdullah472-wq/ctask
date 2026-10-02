// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

class NotificationService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📤 SEND NOTIFICATION TO USER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> sendNotificationToUser({
    required String toUserId,
    required String title,
    required String body,
    required String
    type, // 'message', 'job', 'profile', 'review', 'admin', etc.
    String? relatedUserId,
    String? relatedPostId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final currentUid = _auth.currentUser?.uid;

      // ✅ Use subcollection for better privacy & scalability
      await _db
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'senderId': relatedUserId ?? currentUid ?? '',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
            'relatedPostId': relatedPostId,
            'data': data ?? {},
          });

      // ✅ Increment unread counter
      await _incrementUnreadCount(toUserId);

      log("✅ Notification sent to $toUserId | Type: $type");
    } catch (e) {
      log("❌ Error sending notification: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📩 LEGACY METHOD (Backward Compatibility)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> sendNotification({
    required String toUserId,
    required String fromUserId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    await sendNotificationToUser(
      toUserId: toUserId,
      title: title,
      body: body,
      type: type,
      relatedUserId: fromUserId,
      relatedPostId: relatedId,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ MARK AS READ
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> markAsRead(String uid, String notifId) async {
    try {
      final notifRef = _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId);

      final notifDoc = await notifRef.get();
      if (!notifDoc.exists) return;

      final wasUnread = !(notifDoc.data()?['read'] ?? false);

      // Update notification
      await notifRef.update({'read': true});

      // Decrement counter only if it was unread
      if (wasUnread) {
        await _decrementUnreadCount(uid);
      }

      log("✅ Notification marked as read: $notifId");
    } catch (e) {
      log("❌ Error marking notification as read: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ MARK AS UNREAD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> markAsUnread(String uid, String notifId) async {
    try {
      final notifRef = _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId);

      final notifDoc = await notifRef.get();
      if (!notifDoc.exists) return;

      final wasRead = notifDoc.data()?['read'] ?? false;

      // Update notification to unread
      await notifRef.update({'read': false});

      // Increment unread counter only if it was previously read
      if (wasRead) {
        await _incrementUnreadCount(uid);
      }

      log("✅ Notification marked as unread: $notifId");
    } catch (e) {
      log("❌ Error marking notification as unread: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ✅ MARK ALL AS READ
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> markAllAsRead(String uid) async {
    try {
      final batch = _db.batch();
      final unreadDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();

      // Reset counter to 0
      await _db.collection('users').doc(uid).update({'unreadNotifications': 0});

      log("✅ All notifications marked as read for $uid");
    } catch (e) {
      log("❌ Error marking all as read: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🗑️ DELETE NOTIFICATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> deleteNotification(String uid, String notifId) async {
    try {
      final notifRef = _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId);

      final notifDoc = await notifRef.get();
      if (!notifDoc.exists) return;

      final wasUnread = !(notifDoc.data()?['read'] ?? false);

      // Delete notification
      await notifRef.delete();

      // Decrement counter if it was unread
      if (wasUnread) {
        await _decrementUnreadCount(uid);
      }

      log("✅ Notification deleted: $notifId");
    } catch (e) {
      log("❌ Error deleting notification: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🗑️ DELETE ALL NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> deleteAllNotifications(String uid) async {
    try {
      final batch = _db.batch();
      final allDocs = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();

      for (var doc in allDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset counter to 0
      await _db.collection('users').doc(uid).update({'unreadNotifications': 0});

      log("✅ All notifications deleted for $uid");
    } catch (e) {
      log("❌ Error deleting all notifications: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📊 STREAM NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamMyNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔢 GET UNREAD COUNT (Stream)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Stream<int> getUnreadCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => (doc.data()?['unreadNotifications'] ?? 0) as int);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔢 GET UNREAD COUNT (One-time fetch)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<int> getUnreadCountOnce(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      return (userDoc.data()?['unreadNotifications'] ?? 0) as int;
    } catch (e) {
      log("❌ Error fetching unread count: $e");
      return 0;
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎁 SEND WELCOME NOTIFICATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> sendWelcomeNotification(String uid, String name) async {
    try {
      // Check if welcome notification already exists
      final existing = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('type', isEqualTo: 'welcome')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        log("⚠️ Welcome notification already exists for $uid");
        return;
      }

      await sendNotificationToUser(
        toUserId: uid,
        title: 'Welcome to FindUs, $name!',
        body:
            'Thanks for joining the FindUs community.\n'
            'You can complete your profile, explore jobs, and connect with local members right away.',
        type: 'welcome',
      );

      log("✅ Welcome notification sent to $uid");
    } catch (e) {
      log("❌ Error sending welcome notification: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 HELPER: INCREMENT UNREAD COUNT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> _incrementUnreadCount(String uid) async {
    try {
      await _db.collection('users').doc(uid).set({
        'unreadNotifications': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      log("❌ Error incrementing unread count: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 HELPER: DECREMENT UNREAD COUNT
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> _decrementUnreadCount(String uid) async {
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final unreadCount = (userDoc.data()?['unreadNotifications'] ?? 0) as int;

      if (unreadCount > 0) {
        await _db.collection('users').doc(uid).update({
          'unreadNotifications': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      log("❌ Error decrementing unread count: $e");
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔔 SEND ADMIN NOTIFICATION (Broadcast to all users)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Future<void> sendAdminNotificationToAll({
    required String title,
    required String body,
  }) async {
    try {
      final usersSnapshot = await _db.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        await sendNotificationToUser(
          toUserId: userDoc.id,
          title: title,
          body: body,
          type: 'admin',
        );
      }

      log("✅ Admin notification sent to all users");
    } catch (e) {
      log("❌ Error sending admin notification: $e");
    }
  }
}
