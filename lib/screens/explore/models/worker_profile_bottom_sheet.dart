import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/services/profile_lock_service.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/badge/badge_model.dart';

import 'package:findus_app/screens/auth/login_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/profile/worker_job_details_screen.dart';

Future<void> showWorkerProfileBottomSheet({
  required BuildContext context,
  required Map<String, dynamic> data,
  required bool isWorker,
  required List<Map<String, dynamic>> allWorkers,
  required Worker workerModel,
}) async {
  bool isSaved = SavedService.isSaved(data);
  final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ UPDATED: POST TITLE (Selected Category - e.g., "ELECTRICIAN", "PLUMBER")
  // ════════════════════════════════════════════════════════════════════════════

  String displayTitle =
      (data['roleLabel'] ?? data['roleKey'] ?? workerModel.userRole ?? 'Worker')
          .toString()
          .toUpperCase();

  if (displayTitle.isEmpty) displayTitle = 'WORKER';

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ UPDATED: OWNER'S PROFILE IMAGE (Fetch from user document if needed)
  // ════════════════════════════════════════════════════════════════════════════

  String ownerProfileImage = '';

  // Priority: ownerImage > profileImage > userImage > workerModel.image > data image
  ownerProfileImage =
      (data['ownerImage'] ??
              data['profileImage'] ??
              data['userImage'] ??
              workerModel.image ??
              data['image'] ??
              data['imageUrl'] ??
              '')
          .toString();

  // Clean invalid values - let UniversalWorkerCard generate avatar
  if (ownerProfileImage.isEmpty ||
      ownerProfileImage == 'null' ||
      ownerProfileImage == 'undefined' ||
      ownerProfileImage.length < 10) {
    ownerProfileImage = ''; // Card will auto-generate avatar from name
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ FETCH OWNER PROFILE IMAGE FROM FIRESTORE (if not available)
  // ════════════════════════════════════════════════════════════════════════════

  final String ownerId = (data['ownerId'] ?? workerModel.uid ?? '').toString();

  if (ownerProfileImage.isEmpty && ownerId.isNotEmpty) {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get(const GetOptions(source: Source.cache));

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        ownerProfileImage =
            (userData['profileImage'] ??
                    userData['image'] ??
                    userData['photoUrl'] ??
                    '')
                .toString();
      }
    } catch (e) {
      debugPrint("⚠️ Could not fetch owner image: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // OTHER DATA (unchanged)
  // ════════════════════════════════════════════════════════════════════════════

  // Owner name for avatar generation
  String ownerName = workerModel.name.isNotEmpty
      ? workerModel.name
      : (data['ownerName'] ??
                data['name'] ??
                data['workerName'] ??
                'Unknown User')
            .toString();

  // Role (subtitle)
  final String displayRole = workerModel.userRole.isNotEmpty
      ? workerModel.userRole
      : (data['role'] ?? data['ownerRole'] ?? 'Worker').toString();

  // Address
  final String displayAddress = workerModel.location.isNotEmpty
      ? workerModel.location
      : (data['address'] ?? data['location'] ?? 'Location not available')
            .toString();

  // ════════════════════════════════════════════════════════════════════════════
  // LOGIN CHECK HELPER
  // ════════════════════════════════════════════════════════════════════════════

  bool checkLogin(BuildContext ctx) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Login Required"),
          content: const Text("You need to login to access this feature."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(ctx);
                Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
              ),
              child: const Text("LOGIN NOW"),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SUGGESTIONS (Exclude Current)
  // ════════════════════════════════════════════════════════════════════════════

  final currentId = (data['ownerId'] ?? data['id'] ?? workerModel.uid)
      .toString();
  final suggestions = allWorkers
      .where((w) {
        final wId = (w['ownerId'] ?? w['id'] ?? '').toString();
        return wId.isNotEmpty && wId != currentId;
      })
      .take(5)
      .toList();

  // ════════════════════════════════════════════════════════════════════════════
  // ACTION HANDLERS
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> openProfile() async {
    if (!checkLogin(context)) return;

    final uid = workerModel.uid.trim();
    if (uid.isEmpty) return;

    await PostService.trackProfileClick(uid);

    final locked = await ProfileLockService.isLocked(uid);
    if (locked) {
      ScaffoldMessenger.of(rootNav.context).showSnackBar(
        const SnackBar(content: Text('This profile is locked by the owner.')),
      );
      return;
    }

    Navigator.pop(context);

    rootNav.push(
      MaterialPageRoute(
        builder: (_) =>
            UnifiedProfileScreen(uid: uid, isOwner: false, showBack: true),
      ),
    );
  }

  Future<void> openJobDetails() async {
    if (!checkLogin(context)) return;

    final postId = workerModel.postId?.toString().trim() ?? '';
    if (postId.isEmpty) {
      ScaffoldMessenger.of(
        rootNav.context,
      ).showSnackBar(const SnackBar(content: Text("No post found.")));
      return;
    }

    await PostService.trackCardClick(postId, workerModel.uid);

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (rootNav.context.mounted) {
      rootNav.push(
        MaterialPageRoute(
          builder: (_) => WorkerJobDetailsScreen(worker: workerModel),
        ),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEET UI
  // ════════════════════════════════════════════════════════════════════════════

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final ratingVal = AchievementService.getRating(data);
          final completedJobs = AchievementService.getCompletedCount(data);

          final badgeLevel = (ratingVal >= 4.5 && completedJobs >= 500)
              ? BadgeLevel.gold
              : (completedJobs >= 100 ? BadgeLevel.silver : BadgeLevel.bronze);

          final isVerified =
              data['verified'] == true || data['isVerified'] == true;
          final isTrusted = ratingVal >= 4.2 && completedJobs >= 100;
          final isTopRated = ratingVal >= 4.8;
          final reviewsStr = (data['reviews'] ?? "0").toString();
          final priceStr = (data['price'] ?? data['priceLabel'] ?? "Negotiable")
              .toString();

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (scrollCtx, controller) {
              final isDark = Theme.of(scrollCtx).brightness == Brightness.dark;
              final bgColor = isDark
                  ? const Color(0xFF1E1E1E)
                  : AppColors.bgBlue;
              final handleColor = isDark
                  ? Colors.grey[700]!
                  : Colors.grey[400]!;
              final sectionTitleColor = isDark
                  ? Colors.white70
                  : Colors.black87;

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(10),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // ════════════════════════════════════════════════════════════
                    // 🔹 MAIN CARD - ✅ UPDATED DATA MAPPING
                    // ════════════════════════════════════════════════════════════
                    UniversalWorkerCard(
                      id: workerModel.uid,

                      // ✅ NAME = POST TITLE (Selected Category)
                      name: displayTitle,

                      // ✅ IMAGE = OWNER'S PROFILE IMAGE (or avatar fallback)
                      imageUrl: ownerProfileImage,

                      role: displayRole,
                      address: displayAddress,
                      rating: ratingVal.toStringAsFixed(1),
                      completed: completedJobs.toString(),
                      reviews: reviewsStr,
                      price: priceStr,
                      time: (data['time'] ?? "Available now").toString(),
                      badgeLevel: badgeLevel,
                      isVerifiedWorker: isVerified,
                      isTrusted: isTrusted,
                      isTopRated: isTopRated,
                      isSaved: isSaved,

                      onTap: openProfile,
                      primaryButtonText: "View Details",
                      onViewProfileTap: openJobDetails,
                      showActionButtons: true,

                      onSaveTap: () async {
                        if (!checkLogin(context)) return;
                        await SavedService.toggleSave(data);
                        setSheetState(
                          () => isSaved = SavedService.isSaved(data),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // ════════════════════════════════════════════════════════════
                    // 🔹 SUGGESTIONS - ✅ UPDATED DATA MAPPING
                    // ════════════════════════════════════════════════════════════
                    if (suggestions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 15, bottom: 10),
                        child: Text(
                          "Nearby Verified Workers",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sectionTitleColor,
                          ),
                        ),
                      ),
                      Column(
                        children: suggestions.map((s) {
                          final sRating = AchievementService.getRating(s);
                          final sCompleted =
                              AchievementService.getCompletedCount(s);
                          final sId = (s['ownerId'] ?? s['id'] ?? '')
                              .toString();

                          // ✅ SUGGESTION CARD: Post Title (Selected Category)
                          String sTitle =
                              (s['roleLabel'] ??
                                      s['roleKey'] ??
                                      s['role'] ??
                                      'Worker')
                                  .toString()
                                  .toUpperCase();

                          // ✅ SUGGESTION CARD: Owner's Profile Image
                          String sOwnerImage =
                              (s['ownerImage'] ??
                                      s['profileImage'] ??
                                      s['userImage'] ??
                                      s['image'] ??
                                      '')
                                  .toString();

                          // Clean invalid image URLs
                          if (sOwnerImage.isEmpty ||
                              sOwnerImage == 'null' ||
                              sOwnerImage.length < 10) {
                            sOwnerImage = ''; // Let card generate avatar
                          }

                          // Owner name for avatar generation
                          String sOwnerName =
                              (s['ownerName'] ?? s['name'] ?? 'User')
                                  .toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: UniversalWorkerCard(
                              id: sId,

                              // ✅ NAME = POST TITLE (Selected Category)
                              name: sTitle,

                              // ✅ IMAGE = OWNER'S PROFILE IMAGE
                              imageUrl: sOwnerImage,

                              role: (s['role'] ?? s['ownerRole'] ?? 'Worker')
                                  .toString(),
                              address: (s['address'] ?? 'Bangladesh')
                                  .toString(),
                              rating: sRating.toStringAsFixed(1),
                              completed: sCompleted.toString(),
                              reviews: (s['reviews'] ?? "0").toString(),
                              price:
                                  (s['price'] ??
                                          s['priceLabel'] ??
                                          "Negotiable")
                                      .toString(),
                              time: "Available now",
                              isVerifiedWorker: true,

                              onTap: () {
                                Navigator.pop(sheetCtx);
                                showWorkerProfileBottomSheet(
                                  context: rootNav.context,
                                  data: s,
                                  isWorker: true,
                                  allWorkers: allWorkers,
                                  workerModel: Worker(
                                    uid: sId,
                                    postId: (s['id'] ?? '').toString(),
                                    name: sOwnerName,
                                    userRole: (s['role'] ?? 'finder')
                                        .toString(),
                                    image: sOwnerImage,
                                    location: (s['address'] ?? '').toString(),
                                    priceText:
                                        (s['price'] ??
                                                s['priceLabel'] ??
                                                'Negotiable')
                                            .toString(),
                                    rating: sRating,
                                    kycCompleted: true,
                                  ),
                                );
                              },

                              showActionButtons: false,
                              showSaveButton: false,
                              showShareButton: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
