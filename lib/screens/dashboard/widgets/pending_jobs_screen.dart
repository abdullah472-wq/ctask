// lib/screens/dashboard/widgets/pending_jobs_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

import '../utils/dashboard_constants.dart';

class PendingJobsScreen extends StatelessWidget {
  final String? userId;

  const PendingJobsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    // ════════════════════════════════════════════════════════════════════════════
    // ✅ LOGIN CHECK
    // ════════════════════════════════════════════════════════════════════════════
    if (uid == null || uid.isEmpty) {
      return FloatingScaffold(
        title: 'Pending Requests',
        backgroundColor: bgColor,
        titleColor: textColor,
        iconColor: textColor,
        scrollable: false,
        bodyPadding: EdgeInsets.zero,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Please login to view requests',
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ════════════════════════════════════════════════════════════════════════════
    // ✅ STREAM PENDING REQUESTS (with offline support)
    // ════════════════════════════════════════════════════════════════════════════
    final pendingStream = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: DashboardConstants.pendingStatus)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true); // ✅ Offline support

    return FloatingScaffold(
      title: 'PENDING REQUESTS',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pendingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorBox(
              message: 'Error loading requests',
              isDark: isDark,
              onRetry: () {
                // Trigger rebuild
                (context as Element).markNeedsBuild();
              },
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildRequestItem(context, docs[index], uid, isDark);
            },
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ REQUEST ITEM WIDGET
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildRequestItem(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String finderId,
    bool isDark,
  ) {
    final data = doc.data();
    final supporterId = (data['senderId'] ?? '').toString();
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    // ✅ Get post title (selected category) instead of typed title
    String displayTitle =
        (data['postTitle'] ??
                data['roleLabel'] ??
                data['jobTitle'] ??
                'Job Request')
            .toString()
            .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ════════════════════════════════════════════════════════════════════
          // ✅ SUPPORTER CARD (with updated data mapping)
          // ════════════════════════════════════════════════════════════════════
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('user_stats')
                .doc(supporterId)
                .get(const GetOptions(source: Source.serverAndCache)),
            builder: (context, statSnap) {
              final stats =
                  statSnap.data?.data() as Map<String, dynamic>? ?? {};

              // ✅ Get supporter's profile image
              String supporterImage = '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(supporterId)
                    .get(const GetOptions(source: Source.serverAndCache)),
                builder: (context, userSnap) {
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>? ?? {};
                    supporterImage =
                        (userData['profileImage'] ??
                                userData['image'] ??
                                userData['imageUrl'] ??
                                data['senderImage'] ??
                                '')
                            .toString();
                  } else {
                    supporterImage = (data['senderImage'] ?? '').toString();
                  }

                  // Clean invalid image URLs
                  if (supporterImage == 'null' ||
                      supporterImage == 'undefined' ||
                      supporterImage.length < 10) {
                    supporterImage = '';
                  }

                  return UniversalWorkerCard(
                    id: supporterId,

                    // ✅ NAME = POST TITLE (Selected Category)
                    name: displayTitle,

                    // ✅ IMAGE = SUPPORTER'S PROFILE IMAGE
                    imageUrl: supporterImage,

                    role: (data['senderRole'] ?? 'User').toString(),
                    address: (data['location'] ?? 'Not set').toString(),
                    rating: (stats['avgRating'] ?? 0.0).toStringAsFixed(1),
                    completed: (stats['hiresCompleted'] ?? 0).toString(),
                    reviews: (stats['totalReviews'] ?? 0).toString(),
                    price: (data['price'] ?? data['offerPrice'] ?? '')
                        .toString(),
                    time: "⏳ WAITING FOR APPROVAL",
                    margin: EdgeInsets.zero,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    showActionButtons: false,
                  );
                },
              );
            },
          ),

          // ════════════════════════════════════════════════════════════════════
          // ✅ JOB DETAILS (Typed title shown here)
          // ════════════════════════════════════════════════════════════════════
          if (data['jobTitle'] != null || data['details'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['jobTitle'] != null)
                    Text(
                      data['jobTitle'].toString(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  if (data['details'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      data['details'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

          // ════════════════════════════════════════════════════════════════════
          // ✅ ACTION BUTTONS
          // ════════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(context, doc, finderId),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("REJECT"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => _approveRequest(context, doc, finderId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("APPROVE"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ REJECT REQUEST
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _rejectRequest(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String finderId,
  ) async {
    final confirm = await _confirmDialog(
      context,
      title: 'Reject Request?',
      message: 'Are you sure you want to reject this job request?',
      confirmText: 'REJECT',
      confirmColor: Colors.redAccent,
    );

    if (confirm != true) return;

    try {
      String supporterId = '';
      String senderName = '';

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc.reference);
        if (!snap.exists) throw Exception('Request not found');

        final data = snap.data() as Map<String, dynamic>;

        // Security check
        if (data['receiverId'] != finderId) {
          throw Exception('Unauthorized action');
        }

        if (data['status'] != DashboardConstants.pendingStatus) {
          throw Exception('Request already processed');
        }

        supporterId = (data['senderId'] ?? '').toString();
        senderName = (data['senderName'] ?? 'User').toString();

        // Update status
        tx.update(doc.reference, {
          'status': DashboardConstants.rejectedStatus,
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': finderId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // ✅ Send notification (non-blocking)
      if (supporterId.isNotEmpty) {
        _sendRejectionNotification(supporterId, finderId, doc.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Reject error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sendRejectionNotification(
    String supporterId,
    String finderId,
    String requestId,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': supporterId,
        'fromUserId': finderId,
        'type': 'hire_request_rejected',
        'title': 'Request Rejected',
        'body': 'Your job request was declined.',
        'requestId': requestId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ APPROVE REQUEST
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _approveRequest(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String finderId,
  ) async {
    final confirm = await _confirmDialog(
      context,
      title: 'Approve Request?',
      message: 'Accept this job? It will move to "Work in Progress".',
      confirmText: 'APPROVE',
      confirmColor: Colors.green,
    );

    if (confirm != true) return;

    try {
      String supporterId = '';
      Map<String, dynamic>? requestData;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc.reference);
        if (!snap.exists) throw Exception('Request not found');

        requestData = snap.data() as Map<String, dynamic>;
        final data = requestData!;

        // Security checks
        if (data['receiverId'] != finderId) {
          throw Exception('Unauthorized');
        }

        if (data['status'] != DashboardConstants.pendingStatus) {
          throw Exception('Already processed');
        }

        supporterId = (data['senderId'] ?? '').toString();

        // ✅ 1. Update hire request status
        tx.update(doc.reference, {
          'status': DashboardConstants.ongoingStatus,
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': finderId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ 2. Create ongoing job entry
        final ongoingRef = FirebaseFirestore.instance
            .collection('ongoing_jobs')
            .doc(doc.id);

        tx.set(ongoingRef, {
          'participants': [finderId, supporterId],

          // ✅ Correct naming
          'finderId': finderId, // Worker (will do the job)
          'supporterId': supporterId, // Employer (hired)

          'finderName': data['receiverName'] ?? 'Finder',
          'finderImage': data['receiverImage'] ?? '',
          'finderRole': data['receiverRole'] ?? 'Finder',

          'supporterName': data['senderName'] ?? 'Supporter',
          'supporterImage': data['senderImage'] ?? '',
          'supporterRole': data['senderRole'] ?? 'Supporter',

          'jobTitle': data['jobTitle'] ?? data['postTitle'] ?? 'Job',
          'description': data['details'] ?? data['description'] ?? '',
          'location': data['location'] ?? '',
          'price': data['price'] ?? data['offerPrice'] ?? '0',

          'status': DashboardConstants.ongoingStatus,
          'startTime': FieldValue.serverTimestamp(),
          'originalRequestId': doc.id,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ 3. Update Supporter stats
        if (supporterId.isNotEmpty) {
          final supporterStatsRef = FirebaseFirestore.instance
              .collection('user_stats')
              .doc(supporterId);

          tx.set(supporterStatsRef, {
            'hiresCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // ✅ 4. Update Finder stats
        final finderStatsRef = FirebaseFirestore.instance
            .collection('user_stats')
            .doc(finderId);

        tx.set(finderStatsRef, {
          'jobsAccepted': FieldValue.increment(1),
          'jobsOngoing': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // ✅ 5. Send notification (non-blocking)
      if (supporterId.isNotEmpty && requestData != null) {
        _sendApprovalNotification(supporterId, finderId, doc.id, requestData!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job approved! Check Work in Progress tab.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Approve error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sendApprovalNotification(
    String supporterId,
    String finderId,
    String requestId,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': supporterId,
        'fromUserId': finderId,
        'type': 'hire_request_approved',
        'title': 'Request Approved! 🎉',
        'body':
            'Your request for "${data['jobTitle'] ?? data['postTitle'] ?? 'a job'}" has been approved!',
        'requestId': requestId,
        'jobTitle': data['jobTitle'] ?? data['postTitle'],
        'price': data['price'] ?? data['offerPrice'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ CONFIRMATION DIALOG
  // ════════════════════════════════════════════════════════════════════════════
  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ EMPTY STATE
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No pending requests",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "New job requests will appear here",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ✅ ERROR BOX WIDGET
// ════════════════════════════════════════════════════════════════════════════
class _ErrorBox extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback? onRetry;

  const _ErrorBox({required this.message, required this.isDark, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
