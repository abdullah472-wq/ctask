import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

class WorkInProgressTab extends StatefulWidget {
  const WorkInProgressTab({super.key});

  @override
  State<WorkInProgressTab> createState() => _WorkInProgressTabState();
}

class _WorkInProgressTabState extends State<WorkInProgressTab> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ SAFE TYPE CONVERSION HELPERS
  // ════════════════════════════════════════════════════════════════════════════
  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  String _s(dynamic v, [String fallback = '']) =>
      (v ?? fallback).toString().trim();

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Please login to see ongoing jobs.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final uid = currentUser.uid;

    // ✅ Stream with offline support
    final stream = _firestore
        .collection('ongoing_jobs')
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'ongoing')
        .orderBy('startTime', descending: true)
        .snapshots(includeMetadataChanges: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error.toString();
          if (err.contains('FAILED_PRECONDITION') || err.contains('index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 60,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Firestore index required.\nPlease check Firebase console.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brandMain),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_off_outlined,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 10),
                const Text(
                  "No work in progress right now.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return _buildWorkCard(
              context,
              data: data,
              docId: doc.id,
              currentUid: uid,
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ WORK CARD WIDGET
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWorkCard(
    BuildContext context, {
    required Map<String, dynamic> data,
    required String docId,
    required String currentUid,
  }) {
    final finderId = _s(data['finderId']); // Worker
    final supporterId = _s(data['supporterId']); // Employer

    final participants = (data['participants'] is List)
        ? List.from(data['participants'])
        : <dynamic>[];

    // ✅ Determine other user
    final otherUserId = (currentUid == supporterId) ? finderId : supporterId;

    // ✅ Only Finder can complete
    final bool canComplete = currentUid == finderId;

    // ✅ Get post title (selected category)
    String displayTitle = _s(
      data['postTitle'] ?? data['roleLabel'] ?? data['jobTitle'],
      'Job',
    ).toUpperCase();

    // ✅ Get other user's data from ongoing_jobs
    final String otherNameFromDoc = (currentUid == supporterId)
        ? _s(data['finderName'])
        : _s(data['supporterName']);

    final String otherImageFromDoc = (currentUid == supporterId)
        ? _s(data['finderImage'])
        : _s(data['supporterImage']);

    final String otherRoleFromDoc = (currentUid == supporterId)
        ? _s(data['finderRole'])
        : _s(data['supporterRole']);

    final String location = _s(data['location'], 'Location not available');
    final String price = _s(
      data['price'],
      _s(data['offerPrice'], 'Negotiable'),
    );
    final String jobTitle = _s(data['jobTitle'], 'Job'); // Typed title

    // Stats
    final double ratingVal = _asDouble(data['rating']);
    final String ratingStr = ratingVal == 0
        ? '0.0'
        : ratingVal.toStringAsFixed(1);
    final int completedCount = _asInt(data['completedCount']);

    // ✅ Check if need to fetch other user's profile
    final needFetch = _needFetchOther(
      otherNameFromDoc,
      otherRoleFromDoc,
      otherImageFromDoc,
      otherUserId,
    );

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      future: needFetch
          ? _firestore
                .collection('users')
                .doc(otherUserId)
                .get(const GetOptions(source: Source.serverAndCache))
          : null,
      builder: (context, snap) {
        String name = otherNameFromDoc.isNotEmpty
            ? otherNameFromDoc
            : 'Unknown User';
        String role = otherRoleFromDoc.isNotEmpty ? otherRoleFromDoc : 'User';
        String imageUrl = otherImageFromDoc;

        // ✅ Get profile image from users collection
        if (snap.hasData && snap.data != null && snap.data!.exists) {
          final u = snap.data!.data() ?? {};
          name = _s(u['name'], name);
          role = _s(u['userRole'], role);

          // ✅ Priority: profileImage > image > imageUrl
          imageUrl = _s(
            u['profileImage'] ?? u['image'] ?? u['imageUrl'],
            imageUrl,
          );
        }

        // ✅ Clean invalid image URLs
        if (imageUrl == 'null' ||
            imageUrl == 'undefined' ||
            imageUrl.length < 10) {
          imageUrl = '';
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ════════════════════════════════════════════════════════════
              // ✅ UNIVERSAL WORKER CARD
              // ════════════════════════════════════════════════════════════
              UniversalWorkerCard(
                id: otherUserId,

                // ✅ NAME = POST TITLE (Selected Category)
                name: displayTitle,

                // ✅ IMAGE = OTHER USER'S PROFILE IMAGE
                imageUrl: imageUrl,

                role: role,
                address: location,
                rating: ratingStr,
                completed: completedCount.toString(),
                reviews: _asInt(data['reviewsCount']).toString(),
                price: price,
                time: "⏳ ONGOING",
                isVerifiedWorker: completedCount >= 50,
                isTopRated: ratingVal >= 4.7,
                followersCount: _asInt(data['followersCount']),
                margin: EdgeInsets.zero,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                showActionButtons: false,
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

              // ════════════════════════════════════════════════════════════
              // ✅ JOB INFO SECTION (Typed title shown here)
              // ════════════════════════════════════════════════════════════
              if (jobTitle.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black26
                        : Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _s(data['description']),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

              // ════════════════════════════════════════════════════════════
              // ✅ COMPLETE BUTTON
              // ════════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ElevatedButton(
                  onPressed: canComplete
                      ? () => _markJobAsCompleted(
                          context,
                          jobId: docId,
                          finderId: finderId,
                          supporterId: supporterId,
                          participants: participants,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canComplete
                        ? AppColors.brandMain
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        canComplete
                            ? "Mark as Completed"
                            : "Waiting for Worker to Complete",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _needFetchOther(String name, String role, String image, String otherId) {
    if (otherId.isEmpty) return false;
    return name.isEmpty ||
        role.isEmpty ||
        image.isEmpty ||
        name == 'Unknown' ||
        image == 'null' ||
        image.length < 10;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ MARK JOB AS COMPLETED
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _markJobAsCompleted(
    BuildContext context, {
    required String jobId,
    required String finderId,
    required String supporterId,
    required List participants,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // ✅ Only Finder can complete
    if (currentUser.uid != finderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only the worker can complete this job."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Complete Job"),
            content: const Text(
              "Mark this job as completed?\n\n"
              "This will:\n"
              "• Move it to Completed tab\n"
              "• Update your stats & earnings\n"
              "• Notify the employer",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                ),
                child: const Text(
                  "Complete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final ongoingRef = _firestore.collection('ongoing_jobs').doc(jobId);
      final completedRef = _firestore.collection('completed_jobs').doc(jobId);
      final requestRef = _firestore.collection('hire_requests').doc(jobId);

      // ✅ Get ongoing job data first
      final ongoingSnap = await ongoingRef.get();
      if (!ongoingSnap.exists) {
        throw Exception('Ongoing job not found');
      }

      final jobData = ongoingSnap.data() as Map<String, dynamic>;
      final double priceAmount = _extractPriceFromString(jobData['price']);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ongoingRef);
        if (!snap.exists) throw Exception('Ongoing job not found');

        final data = snap.data() as Map<String, dynamic>;
        final status = _s(data['status']);

        // Security checks
        if (_s(data['finderId']) != currentUser.uid) {
          throw Exception('Not authorized');
        }

        if (status != 'ongoing') {
          throw Exception('Job is not ongoing');
        }

        final List parts = (data['participants'] is List)
            ? List.from(data['participants'])
            : [finderId, supporterId];

        // ✅ 1. Update ongoing_jobs status
        tx.update(ongoingRef, {
          'status': 'completed',
          'endTime': FieldValue.serverTimestamp(),
          'completedBy': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ 2. Create completed_jobs entry
        tx.set(completedRef, {
          ...data,
          'participants': parts,
          'finderId': finderId,
          'supporterId': supporterId,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': currentUser.uid,
          'originalRequestId': _s(data['originalRequestId'], jobId),
          'updatedAt': FieldValue.serverTimestamp(),
          'amount': priceAmount,
          'priceOriginal': data['price'],
        }, SetOptions(merge: true));

        // ✅ 3. Update hire_requests
        tx.set(requestRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 4. Update Supporter (Employer) stats
        final supporterStatsRef = _firestore
            .collection('user_stats')
            .doc(supporterId);
        tx.set(supporterStatsRef, {
          'hiresCompleted': FieldValue.increment(1),
          'hiresOngoing': FieldValue.increment(-1),
          'totalSpent': FieldValue.increment(priceAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 5. Update Finder (Worker) stats with earnings
        final finderStatsRef = _firestore
            .collection('user_stats')
            .doc(finderId);
        tx.set(finderStatsRef, {
          'jobsCompleted': FieldValue.increment(1),
          'jobsOngoing': FieldValue.increment(-1),
          'totalEarned': FieldValue.increment(priceAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // ✅ 6. Send notification (non-blocking)
      _sendCompletionNotification(supporterId, finderId, jobId, priceAmount);

      // ✅ 7. Update Achievements (non-blocking)
      _updateAchievements();

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Job completed! Earned ৳${priceAmount.toInt()}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('❌ Complete job error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to complete: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Non-blocking notification
  Future<void> _sendCompletionNotification(
    String supporterId,
    String finderId,
    String jobId,
    double amount,
  ) async {
    try {
      if (supporterId.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'toUserId': supporterId,
          'fromUserId': finderId,
          'type': 'job_completed',
          'title': 'Job Completed! 🎉',
          'body': 'The worker has marked your job as completed.',
          'jobId': jobId,
          'amount': amount,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }
  }

  // ✅ Non-blocking achievements
  Future<void> _updateAchievements() async {
    try {
      await Future.wait([
        AchievementService.incrementProgress('daily_complete_job'),
        AchievementService.incrementProgress('weekly_complete_jobs'),
        AchievementService.incrementProgress('lt_jobs_s1'),
        AchievementService.incrementProgress('lt_jobs_s2'),
        AchievementService.incrementProgress('lt_jobs_s3'),
        AchievementService.syncWeeklyChestFromServer(),
      ]);
    } catch (e) {
      debugPrint('⚠️ Achievement error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ EXTRACT PRICE FROM STRING
  // ════════════════════════════════════════════════════════════════════════════
  double _extractPriceFromString(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    if (value is String) {
      final cleaned = value
          .replaceAll('৳', '')
          .replaceAll(',', '')
          .replaceAll('BDT', '')
          .replaceAll('/day', '')
          .replaceAll('/job', '')
          .replaceAll('per day', '')
          .replaceAll('per job', '')
          .trim();

      final match = RegExp(r'[\d.]+').firstMatch(cleaned);
      if (match != null) {
        return double.tryParse(match.group(0) ?? '0') ?? 0.0;
      }
    }

    return 0.0;
  }
}
