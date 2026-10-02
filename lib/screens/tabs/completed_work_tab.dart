// lib/screens/tabs/completed_work_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/screens/report/report_screen.dart';

class CompletedWorkTab extends StatefulWidget {
  const CompletedWorkTab({super.key});

  @override
  State<CompletedWorkTab> createState() => _CompletedWorkTabState();
}

class _CompletedWorkTabState extends State<CompletedWorkTab> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Helper Methods (আগের মতোই রাখা)
  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  String _s(dynamic v, [String fallback = '']) =>
      (v ?? fallback).toString().trim();

  DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
  }

  String _getTimeGroup(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return "Today";
    if (diff.inDays <= 7) return "This Week";
    if (diff.inDays <= 30) return "This Month";
    return "Earlier";
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return _buildLoginRequired(isDark);
    }

    final uid = currentUser.uid;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.brandMain,
      child: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('completed_jobs')
            .where('participants', arrayContains: uid)
            .orderBy('completedAt', descending: true)
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), isDark);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          // Group by time
          final grouped = <String, List<QueryDocumentSnapshot>>{};
          for (var doc in docs) {
            final completedAt = _asDate(doc['completedAt']);
            final group = _getTimeGroup(completedAt);
            grouped.putIfAbsent(group, () => []).add(doc);
          }

          final groupKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: groupKeys.length,
            itemBuilder: (context, index) {
              final group = groupKeys[index];
              final groupDocs = grouped[group]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      group,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  ...groupDocs.map(
                    (doc) => _buildCompletedJobCard(
                      context,
                      jobId: doc.id,
                      job: doc.data() as Map<String, dynamic>,
                      currentUid: uid,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCompletedJobCard(
    BuildContext context, {
    required String jobId,
    required Map<String, dynamic> job,
    required String currentUid,
    required bool isDark,
  }) {
    final finderId = _s(job['finderId']);
    final supporterId = _s(job['supporterId']);
    final otherUserId = (currentUid == supporterId) ? finderId : supporterId;

    final completedAt = _asDate(job['completedAt']);
    final timeAgo = _getTimeAgo(completedAt);

    final address = _s(job['location'], 'Location Hidden');
    final price = _s(job['price'] ?? job['offerPrice'], 'Negotiable');
    final jobTitle = _s(job['jobTitle'], 'Job');

    String displayTitle = _s(
      job['postTitle'] ?? job['roleLabel'] ?? job['jobTitle'],
      'Completed Job',
    ).toUpperCase();

    final otherNameFromDoc = (currentUid == supporterId)
        ? _s(job['finderName'])
        : _s(job['supporterName']);
    final otherImageFromDoc = (currentUid == supporterId)
        ? _s(job['finderImage'])
        : _s(job['supporterImage']);
    final otherRoleFromDoc = (currentUid == supporterId)
        ? _s(job['finderRole'])
        : _s(job['supporterRole']);

    final needsFetch =
        otherUserId.isNotEmpty &&
        (otherNameFromDoc.isEmpty ||
            otherImageFromDoc.isEmpty ||
            otherImageFromDoc == 'null' ||
            otherImageFromDoc.length < 10);

    return FutureBuilder<DocumentSnapshot?>(
      future: needsFetch
          ? _db
                .collection('users')
                .doc(otherUserId)
                .get(const GetOptions(source: Source.serverAndCache))
          : null,
      builder: (context, snap) {
        String name = otherNameFromDoc.isNotEmpty ? otherNameFromDoc : 'User';
        String role = otherRoleFromDoc.isNotEmpty ? otherRoleFromDoc : 'Member';
        String imageUrl = otherImageFromDoc;

        if (snap.connectionState == ConnectionState.done &&
            snap.hasData &&
            snap.data?.exists == true) {
          final u = snap.data!.data() as Map<String, dynamic>? ?? {};
          name = _s(u['name'] ?? u['fullName'], name);
          role = _s(u['userRole'] ?? u['role'], role);
          imageUrl = _s(
            u['profileImage'] ?? u['image'] ?? u['imageUrl'],
            imageUrl,
          );
        }

        if (imageUrl == 'null' ||
            imageUrl == 'undefined' ||
            imageUrl.length < 10)
          imageUrl = '';

        if (needsFetch && snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(isDark);
        }

        final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardColor,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              UniversalWorkerCard(
                id: otherUserId,
                name: displayTitle,
                imageUrl: imageUrl,
                role: role,
                address: address,
                rating: _asDouble(
                  job['rating'],
                  fallback: 0.0,
                ).toStringAsFixed(1),
                completed: _asInt(job['completedCount']).toString(),
                reviews: _asInt(job['reviewsCount']).toString(),
                price: price,
                time: timeAgo,
                isVerifiedWorker: job['isVerified'] == true,
                followersCount: _asInt(job['followersCount']),
                margin: EdgeInsets.zero,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                showActionButtons: false,
                showSaveButton: false,
                showShareButton: false,
                onTap: () {
                  if (otherUserId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnifiedProfileScreen(
                          uid: otherUserId,
                          isOwner: false,
                          showBack: true,
                        ),
                      ),
                    );
                  }
                },
              ),

              // Job Info + 3-dot + Completed Badge
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (jobTitle.isNotEmpty)
                            Text(
                              jobTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (job['description'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _s(job['description']),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 3-dot menu with badge beside
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) async {
                            switch (value) {
                              case 'delete':
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Job?"),
                                    content: const Text(
                                      "This action cannot be undone.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await _db
                                        .collection('completed_jobs')
                                        .doc(jobId)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Job removed from completed list",
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to delete: $e"),
                                      ),
                                    );
                                  }
                                }
                                break;
                              case 'share':
                                Share.share(
                                  "Completed job: $jobTitle\nWith: $name\nPrice: $price\nCompleted: $timeAgo",
                                );
                                break;
                              case 'report':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportScreen(
                                      reportedUserId: otherUserId,
                                      reportedJobId: jobId,
                                      reportedUserName: name,
                                    ),
                                  ),
                                );
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Text("Share"),
                            ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Text("Report"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Review action
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(
                          context,
                          jobId: jobId,
                          targetId: otherUserId,
                          targetName: name,
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text("Review"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: isDark
                              ? Colors.white70
                              : Colors.grey.shade700,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Review Dialog – Transaction fix
  Future<void> _showReviewDialog(
    BuildContext context, {
    required String jobId,
    required String targetId,
    required String targetName,
  }) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || targetId.isEmpty) {
      _showToast(context, "Cannot submit review", isError: true);
      return;
    }

    // Check existing review
    final existing = await _db
        .collection('reviews')
        .where('fromUserId', isEqualTo: myUid)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      _showToast(context, "You've already reviewed this job!", isError: true);
      return;
    }

    final controller = TextEditingController();
    double rating = 5.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Rate $targetName",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setModalState(() => rating = i + 1.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: i < rating ? 36 : 32,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getRatingText(rating.toInt()),
                style: TextStyle(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 200,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Share your experience (optional)...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                "Cancel",
                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.send, size: 18),
              label: const Text("Submit"),
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

    if (confirm != true || !context.mounted) return;

    _showLoadingDialog(context);

    try {
      await _db.runTransaction((tx) async {
        // 1. Read all required documents FIRST
        final statsRef = _db.collection('user_stats').doc(targetId);
        final jobRef = _db.collection('completed_jobs').doc(jobId);

        final statsSnap = await tx.get(statsRef);
        final jobSnap = await tx.get(jobRef);

        final stats = statsSnap.data() ?? {};
        final int oldCount = _asInt(stats['reviewsCount']);
        final double oldAvg = _asDouble(stats['avgRating']);
        final int newCount = oldCount + 1;
        final double newAvg = oldCount == 0
            ? rating
            : ((oldAvg * oldCount) + rating) / newCount;

        // 2. Now perform writes
        final reviewRef = _db.collection('reviews').doc();
        tx.set(reviewRef, {
          'fromUserId': myUid,
          'targetUserId': targetId,
          'jobId': jobId,
          'rating': rating,
          'comment': controller.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(statsRef, {
          'reviewsCount': newCount,
          'avgRating': double.parse(newAvg.toStringAsFixed(2)),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.update(jobRef, {
          'reviewedBy': FieldValue.arrayUnion([myUid]),
          'rating': newAvg,
        });
      });

      _updateReviewAchievements();

      if (context.mounted) {
        Navigator.pop(context); // loading
        _showToast(context, "✅ Review submitted successfully!");
      }
    } catch (e) {
      debugPrint('❌ Review transaction error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        _showToast(context, "Failed to submit review: $e", isError: true);
      }
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "Poor 😞";
      case 2:
        return "Fair 😐";
      case 3:
        return "Good 🙂";
      case 4:
        return "Very Good 😊";
      case 5:
        return "Excellent! 🌟";
      default:
        return "";
    }
  }

  Future<void> _updateReviewAchievements() async {
    try {
      await Future.wait([
        AchievementService.incrementProgress('daily_give_review'),
        AchievementService.incrementProgress('weekly_give_reviews'),
        AchievementService.incrementProgress('lt_reviews_s1'),
        AchievementService.incrementProgress('lt_reviews_s2'),
        AchievementService.incrementProgress('lt_reviews_s3'),
        AchievementService.syncWeeklyChestFromServer(),
      ]);
    } catch (e) {
      debugPrint('⚠️ Achievement update error: $e');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.brandMain),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ CONNECT AGAIN
  // ════════════════════════════════════════════════════════════════════════════

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ UI HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 140,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Please login to see completed jobs",
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    final isIndex =
        error.contains('FAILED_PRECONDITION') ||
        error.toLowerCase().contains('index');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIndex ? Icons.build_rounded : Icons.error_outline,
              size: 70,
              color: isIndex ? Colors.orange : Colors.redAccent,
            ),
            const SizedBox(height: 20),
            Text(
              isIndex ? "Firestore Index Required!" : "Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isIndex
                  ? "Check debug console for the link to create index."
                  : error,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 80,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                "No completed jobs yet",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white60 : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your finished work will appear here.\nStart finding or posting jobs!",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final tabController = DefaultTabController.of(context);
                  if (tabController != null) {
                    tabController.animateTo(0);
                  }
                },
                icon: const Icon(Icons.explore),
                label: const Text('Find Work'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
