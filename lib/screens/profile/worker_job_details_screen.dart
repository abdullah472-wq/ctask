// lib/screens/profile/worker_job_details_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/screens/apply/apply_to_post_screen.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';

class WorkerJobDetailsScreen extends StatefulWidget {
  final Worker worker;

  const WorkerJobDetailsScreen({super.key, required this.worker});

  @override
  State<WorkerJobDetailsScreen> createState() => _WorkerJobDetailsScreenState();
}

class _WorkerJobDetailsScreenState extends State<WorkerJobDetailsScreen> {
  Map<String, dynamic>? _postData;
  bool _isLoading = true;
  bool _hasApplied = false;
  bool _isOwner = false;
  String? _errorMessage;

  // ✅ NEW: Owner profile image (fetched from Firestore)
  String _ownerProfileImage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkOwnership();
    await _trackJobView();
    await _fetchPostDetails();
    await _fetchOwnerProfile(); // ✅ NEW: Fetch owner's profile
    await _checkIfAlreadyApplied();
  }

  Future<void> _checkOwnership() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid == widget.worker.uid) {
      setState(() => _isOwner = true);
    }
  }

  Future<void> _trackJobView() async {
    try {
      await AchievementService.incrementProgress('daily_view_jobs', amount: 1);
      await AchievementService.syncWeeklyChestFromServer();
    } catch (e) {
      debugPrint("Error tracking job view: $e");
    }
  }

  Future<void> _fetchPostDetails() async {
    final postId = widget.worker.postId;
    if (postId == null || postId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No post details available";
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (doc.exists) {
        // Track view (only if not owner)
        if (!_isOwner) {
          await PostService.trackCardClick(doc.id, widget.worker.uid);
        }

        setState(() {
          _postData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Post not found";
        });
      }
    } catch (e) {
      debugPrint("Error fetching post: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load post details";
      });
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ NEW: FETCH OWNER'S PROFILE IMAGE FROM FIRESTORE
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _fetchOwnerProfile() async {
    final ownerId = widget.worker.uid;
    if (ownerId.isEmpty) return;

    try {
      // First try to get from post data
      if (_postData != null) {
        _ownerProfileImage =
            (_postData!['ownerImage'] ??
                    _postData!['profileImage'] ??
                    _postData!['userImage'] ??
                    '')
                .toString();
      }

      // If still no image, fetch from user document
      if (_ownerProfileImage.isEmpty ||
          _ownerProfileImage == 'null' ||
          _ownerProfileImage.length < 10) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .get(const GetOptions(source: Source.serverAndCache));

        if (userDoc.exists) {
          final userData = userDoc.data() ?? {};

          _ownerProfileImage =
              (userData['profileImage'] ??
                      userData['image'] ??
                      userData['photoUrl'] ??
                      userData['avatarUrl'] ??
                      '')
                  .toString();
        }
      }

      // Clean invalid values - let card generate avatar
      if (_ownerProfileImage == 'null' ||
          _ownerProfileImage == 'undefined' ||
          _ownerProfileImage.length < 10) {
        _ownerProfileImage = '';
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("⚠️ Error fetching owner profile: $e");
    }
  }

  Future<void> _checkIfAlreadyApplied() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final postId = widget.worker.postId;

    if (currentUid == null || postId == null || postId.isEmpty) return;

    try {
      final applicationQuery = await FirebaseFirestore.instance
          .collection('job_applications')
          .where('postId', isEqualTo: postId)
          .where('applicantId', isEqualTo: currentUid)
          .limit(1)
          .get();

      if (applicationQuery.docs.isNotEmpty) {
        setState(() => _hasApplied = true);
      }
    } catch (e) {
      debugPrint("Error checking application: $e");
    }
  }

  String get _roleLabel {
    final r = widget.worker.userRole.toLowerCase().trim();
    return r == 'finder' ? 'Worker' : 'Supporter';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ NEW: GET POST TITLE (Selected Category - e.g., "ELECTRICIAN")
  // ════════════════════════════════════════════════════════════════════════════
  String get _postTitle {
    // Priority: roleLabel from post > roleKey > worker userRole
    String title =
        (_postData?['roleLabel'] ??
                _postData?['roleKey'] ??
                widget.worker.userRole ??
                'Worker')
            .toString()
            .toUpperCase();

    // Clean up if it's a key format (e.g., "electrician" -> "ELECTRICIAN")
    title = title.replaceAll('_', ' ').trim();

    if (title.isEmpty) title = 'WORKER';

    return title;
  }

  BadgeLevel get _badgeLevel {
    return BadgeService.calculateBadgeFromStats(
      rating: widget.worker.rating,
      completed: widget.worker.completedCount,
    );
  }

  void _navigateToProfile(BuildContext context) {
    if (widget.worker.uid.isEmpty) {
      _showSnackBar("Invalid profile");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: widget.worker.uid,
          isOwner: _isOwner,
          showBack: true,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showFullScreenImage(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _FullScreenImageViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.black87;

    return FloatingScaffold(
      title: "JOB DETAILS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState(textColor)
                  : _buildContent(isDark, textColor, cardColor, subtitleColor),
            ),

            // Bottom Action Bar
            if (!_isLoading && _errorMessage == null)
              _buildBottomBar(context, isDark, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.brandMain),
          SizedBox(height: 16),
          Text("Loading job details..."),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? "Something went wrong",
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchPostDetails();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
            ),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    Color textColor,
    Color cardColor,
    Color subtitleColor,
  ) {
    // Data extraction
    final String title = _postData?['title'] ?? "${_roleLabel} Service";
    final String description =
        _postData?['description'] ?? "No description provided.";
    final List<dynamic> mediaList = _postData?['images'] ?? [];
    final int slots = (_postData?['slots'] as num?)?.toInt() ?? 1;
    final int approvedCount =
        (_postData?['approvedCount'] as num?)?.toInt() ?? 0;
    final String address = _postData?['address'] ?? widget.worker.location;
    final String priceLabel =
        _postData?['priceLabel'] ?? widget.worker.priceText;

    // Posted date
    final Timestamp? createdAt = _postData?['createdAt'] as Timestamp?;
    final String postedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
        : "Unknown";

    // Remaining slots
    final int remainingSlots = (slots - approvedCount).clamp(0, slots);
    final bool isFull = remainingSlots <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Owner Badge (if viewing own post)
          if (_isOwner)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This is your post. You can view analytics in Dashboard.",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ════════════════════════════════════════════════════════════════════
          // 🔥 UNIVERSAL WORKER CARD - ✅ UPDATED DATA MAPPING
          // ════════════════════════════════════════════════════════════════════
          UniversalWorkerCard(
            id: widget.worker.uid,

            // ✅ NAME = POST TITLE (Selected Category like "ELECTRICIAN")
            name: _postTitle,

            // ✅ IMAGE = OWNER'S PROFILE IMAGE (fetched from Firestore)
            // If empty, UniversalWorkerCard will auto-generate avatar
            imageUrl: _ownerProfileImage,

            role: _roleLabel,
            address: widget.worker.location,
            rating: widget.worker.rating.toStringAsFixed(1),
            completed: widget.worker.completedCount.toString(),
            reviews: widget.worker.reviewsCount.toString(),
            price: priceLabel.isNotEmpty ? priceLabel : "Negotiable",
            badgeLevel: _badgeLevel,
            isVerifiedWorker: widget.worker.kycCompleted,
            isTopRated: widget.worker.rating >= 4.8,
            isTrusted:
                widget.worker.completedCount >= 50 &&
                widget.worker.rating >= 4.5,
            showActionButtons: true,
            primaryButtonText: "View Profile",
            onViewProfileTap: () => _navigateToProfile(context),
            showSaveButton: !_isOwner,
            showShareButton: true,
          ),

          const SizedBox(height: 20),

          // 📄 Title Section (This shows the typed title from post)
          _buildSectionTitle("JOB TITLE", textColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 16),

          // 📍 Info Cards Row
          Row(
            children: [
              // Slots Card
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.group,
                  label: "Slots",
                  value: "$remainingSlots / $slots",
                  color: isFull ? Colors.red : AppColors.brandMain,
                  isDark: isDark,
                  cardColor: cardColor,
                ),
              ),
              const SizedBox(width: 12),
              // Posted Date Card
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.access_time,
                  label: "Posted",
                  value: _getRelativeTime(createdAt),
                  color: Colors.orange,
                  isDark: isDark,
                  cardColor: cardColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 📍 Location Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Location",
                        style: TextStyle(
                          fontSize: 11,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        address.isNotEmpty ? address : "Location not specified",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  color: Colors.green,
                  onPressed: () => _openInMaps(address),
                ),
              ],
            ),
          ),

          // Full/Closed Notice
          if (isFull) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This job is no longer accepting applications.",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Already Applied Notice
          if (_hasApplied && !_isOwner) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You have already applied for this job.",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 📄 Description Section
          _buildSectionTitle("DESCRIPTION", textColor),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            child: Text(
              description,
              style: TextStyle(fontSize: 14, color: subtitleColor, height: 1.6),
            ),
          ),

          const SizedBox(height: 20),

          // 📸 Media Section
          if (mediaList.isNotEmpty) ...[
            _buildSectionTitle("ATTACHMENTS (${mediaList.length})", textColor),
            const SizedBox(height: 10),
            _buildMediaGrid(mediaList, cardColor, isDark),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";

    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  void _openInMaps(String address) async {
    if (address.isEmpty) {
      _showSnackBar("No address available");
      return;
    }

    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$encoded",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar("Cannot open maps");
    }
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color.withOpacity(0.6),
        letterSpacing: 1,
      ),
    );
  }

  bool _isVideo(String url) =>
      url.toLowerCase().endsWith('.mp4') ||
      url.toLowerCase().endsWith('.mov') ||
      url.toLowerCase().endsWith('.webm');

  bool _isAudio(String url) =>
      url.toLowerCase().endsWith('.mp3') ||
      url.toLowerCase().endsWith('.wav') ||
      url.toLowerCase().endsWith('.m4a');

  Widget _buildMediaGrid(List<dynamic> urls, Color cardColor, bool isDark) {
    final imageUrls = urls
        .map((e) => e.toString())
        .where((url) => !_isVideo(url) && !_isAudio(url))
        .toList();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (context, index) {
          final url = urls[index].toString();
          final isVideo = _isVideo(url);
          final isAudio = _isAudio(url);

          return GestureDetector(
            onTap: () {
              if (!isVideo && !isAudio) {
                final imageIndex = imageUrls.indexOf(url);
                if (imageIndex >= 0) {
                  _showFullScreenImage(imageUrls, imageIndex);
                }
              }
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideo)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    )
                  else if (isAudio)
                    Container(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.audiotrack,
                            color: AppColors.brandMain,
                            size: 40,
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Audio",
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.brandMain,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isVideo ? "VIDEO" : (isAudio ? "AUDIO" : "IMAGE"),
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark, Color cardColor) {
    final int slots = (_postData?['slots'] as num?)?.toInt() ?? 1;
    final int approvedCount =
        (_postData?['approvedCount'] as num?)?.toInt() ?? 0;
    final bool isFull = (slots - approvedCount) <= 0;

    final bool canApply = !_isOwner && !_hasApplied && !isFull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Apply Button
            Expanded(
              flex: _isOwner ? 1 : 1,
              child: ElevatedButton(
                onPressed: canApply
                    ? () {
                        final postId = widget.worker.postId.toString().trim();
                        if (postId.isEmpty) {
                          _showSnackBar("Post ID not found.");
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplyToPostScreen(postId: postId),
                          ),
                        ).then((_) => _checkIfAlreadyApplied());
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canApply
                      ? AppColors.brandMain
                      : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(50),
                  elevation: canApply ? 4 : 0,
                ),
                child: Text(
                  _isOwner
                      ? "YOUR POST"
                      : (_hasApplied
                            ? "APPLIED ✓"
                            : (isFull ? "SLOTS FULL" : "APPLY NOW")),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// FULL SCREEN IMAGE VIEWER
/// ═══════════════════════════════════════════════════════════
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({required this.images, this.initialIndex = 0});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (_, __) =>
                    const CircularProgressIndicator(color: Colors.white),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
