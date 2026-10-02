// lib/screens/profile/support_post_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/app_config_service.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class SupportPostScreen extends StatefulWidget {
  const SupportPostScreen({super.key});

  @override
  State<SupportPostScreen> createState() => _SupportPostScreenState();
}

class _SupportPostScreenState extends State<SupportPostScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final _picker = ImagePicker();
  final List<XFile> _mediaFiles = [];

  bool _isSaving = false;
  double _budget = 1200.0;

  int _slots = 1;

  final List<Map<String, dynamic>> _categories = const [
    {"icon": Icons.electric_bolt, "name": "Electrician"},
    {"icon": Icons.plumbing, "name": "Plumber"},
    {"icon": Icons.directions_car, "name": "Driver"},
    {"icon": Icons.cleaning_services, "name": "Cleaner"},
    {"icon": Icons.format_paint, "name": "Painter"},
    {"icon": Icons.construction, "name": "Carpenter"},
    {"icon": Icons.person, "name": "Helper"},
    {"icon": Icons.more_horiz, "name": "Other"},
  ];

  String _selectedCategory = "Electrician";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📸 MEDIA HANDLING
  // ════════════════════════════════════════════════════════════════════════════

  bool _isVideoFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.m4v') ||
        p.endsWith('.avi');
  }

  /// ✅ Upload media with progress tracking
  Future<List<String>> _uploadMedia() async {
    if (_mediaFiles.isEmpty) return const [];

    final urls = <String>[];
    int uploaded = 0;

    for (final f in _mediaFiles) {
      try {
        final isVideo = _isVideoFile(f.path);
        final res = await CloudinaryService.uploadXFile(
          f,
          folder: 'findus/posts/media',
          resourceType: isVideo ? 'video' : 'image',
          tags: const ['post', 'support'],
        );

        final url = res['secure_url']?.toString();
        if (url != null && url.isNotEmpty) {
          urls.add(url);
          uploaded++;
          debugPrint("✅ Uploaded ${uploaded}/${_mediaFiles.length}: $url");
        }
      } catch (e) {
        debugPrint("❌ Upload failed for ${f.name}: $e");
      }
    }

    if (uploaded < _mediaFiles.length) {
      final failed = _mediaFiles.length - uploaded;
      _showSnack("$uploaded uploaded, $failed failed", Colors.orange);
    }

    return urls;
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C2C2C)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Attach Media",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mediaOption(
                  Icons.camera_alt,
                  "Camera",
                      () => _pickMedia(ImageSource.camera),
                ),
                _mediaOption(
                  Icons.photo_library,
                  "Gallery",
                      () => _pickMedia(ImageSource.gallery, multi: true),
                ),
                _mediaOption(
                  Icons.videocam,
                  "Video",
                      () => _pickMedia(ImageSource.camera, video: true),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(
      ImageSource source, {
        bool multi = false,
        bool video = false,
      }) async {
    Navigator.pop(context);

    try {
      if (video) {
        final file = await _picker.pickVideo(source: source);
        if (file != null) {
          // ✅ Check file size (max 50MB)
          final fileSize = await File(file.path).length();
          if (fileSize > 50 * 1024 * 1024) {
            _showSnack("Video too large (max 50MB)", Colors.redAccent);
            return;
          }
          setState(() => _mediaFiles.add(file));
        }
      } else if (multi) {
        final files = await _picker.pickMultiImage(
          imageQuality: 80,
          limit: 5,
        );
        if (files.isNotEmpty) {
          setState(() => _mediaFiles.addAll(files));
        }
      } else {
        final file = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );
        if (file != null) {
          setState(() => _mediaFiles.add(file));
        }
      }
    } catch (e) {
      debugPrint("❌ Media pick error: $e");
      _showSnack("Failed to pick media", Colors.redAccent);
    }
  }

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.brandLight,
            child: Icon(icon, color: AppColors.brandDark, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 👤 USER METADATA
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Get user profile data with safe type conversion
  Future<Map<String, dynamic>> _getCurrentUserProfileMeta(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!snap.exists) {
        debugPrint("⚠️ User document not found");
        return _getDefaultUserMeta();
      }

      final data = snap.data() ?? {};

      // ✅ Safe conversion helpers
      double toDouble(dynamic value) {
        if (value is double) return value;
        if (value is int) return value.toDouble();
        return double.tryParse('$value') ?? 0.0;
      }

      String toString(dynamic value, String defaultValue) {
        if (value == null) return defaultValue;
        return value.toString();
      }

      bool toBool(dynamic value) {
        if (value is bool) return value;
        return value == true || value == 'true' || value == 1;
      }

      int toInt(dynamic value) {
        if (value is int) return value;
        if (value is double) return value.toInt();
        return int.tryParse('$value') ?? 0;
      }

      final rating = toDouble(data['rating']);
      final experience = toDouble(data['experienceYears']);
      final completedCount = toInt(data['completedCount']);

      return {
        'userRole': (data['userRole'] == 'finder') ? 'finder' : 'maker',
        'gender': toString(data['gender'], 'Any'),
        'experience': experience,
        'rating': rating,
        'verified': toBool(data['kyc_completed']),
        'trusted': completedCount >= 50 && rating >= 4.5,
      };
    } catch (e) {
      debugPrint("❌ Error getting user meta: $e");
      return _getDefaultUserMeta();
    }
  }

  Map<String, dynamic> _getDefaultUserMeta() {
    return {
      'userRole': 'maker',
      'gender': 'Any',
      'experience': 0.0,
      'rating': 0.0,
      'verified': false,
      'trusted': false,
    };
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📤 POST CREATION
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _handlePost() async {
    if (_isSaving) return;

    // ✅ Validation
    if (AppConfigService.isPostingDisabled) {
      _showSnack("Posting is currently disabled", Colors.redAccent);
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showSnack("Please enter a job title", Colors.redAccent);
      return;
    }

    if (_titleController.text.trim().length < 5) {
      _showSnack("Title must be at least 5 characters", Colors.redAccent);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("You must be logged in to post", Colors.redAccent);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.brandMain),
                    SizedBox(height: 16),
                    Text("Creating job request..."),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // ✅ Get user metadata
      final meta = await _getCurrentUserProfileMeta(user.uid);

      // ✅ Upload media
      final uploadedUrls = await _uploadMedia();

      // ✅ Create post
      await PostService.createPost(
        ownerId: user.uid,
        ownerRole: meta['userRole'] as String,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? "No description provided"
            : _descController.text.trim(),
        roleLabel: _selectedCategory.toUpperCase(),
        roleKey: _selectedCategory.toLowerCase().replaceAll(' ', '_'),
        lat: 0.0,
        lng: 0.0,
        address: "Global",
        locationKeys: const ["global"],
        price: _budget,
        priceLabel: '৳ ${_budget.toInt()} / job',
        images: uploadedUrls,
        isLive: true,
        createdAt: FieldValue.serverTimestamp(),
        gender: meta['gender'] as String,
        experience: meta['experience'] as double,
        rating: meta['rating'] as double,
        trusted: meta['trusted'] as bool,
        verified: meta['verified'] as bool,
        isPromoted: false,
        status: 'open',
        slots: _slots.clamp(1, 10), // ✅ Ensure valid range
        approvedCount: 0,
      );

      // ✅ Send notification
      await NotificationService.sendNotificationToUser(
        toUserId: user.uid,
        title: "Job Request Posted",
        body: "Your request for ${_selectedCategory} is now live! (${_slots} ${_slots == 1 ? 'person' : 'people'} needed)",
        type: "support_post",
        data: {
          'roleLabel': _selectedCategory,
          'budget': _budget.toString(),
          'slots': _slots.toString(),
        },
      );

      // ✅ Update achievements (non-blocking)
      _updateAchievements();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnack("Job request posted successfully!", AppColors.brandMain);
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      debugPrint("❌ Post creation error: $e");
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnack("Failed to create post: ${e.toString()}", Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// ✅ Non-blocking achievement update
  Future<void> _updateAchievements() async {
    try {
      await Future.wait([
        AchievementService.incrementProgress('weekly_post_free'),
        AchievementService.syncWeeklyChestFromServer(),
      ]);
    } catch (e) {
      debugPrint("⚠️ Achievement update failed: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎨 UI HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD UI
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final hintColor = isDark ? Colors.grey : Colors.grey.shade600;

    return FloatingScaffold(
      title: "POST A JOB REQUEST",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: EdgeInsets.zero,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: _isSaving ? null : _handlePost,
            child: _isSaving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              "POST",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isSaving ? Colors.grey : textColor,
              ),
            ),
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            Text(
              "Select Worker Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) =>
                    _buildCategoryItem(_categories[index], isDark),
              ),
            ),

            const SizedBox(height: 20),

            // Job Title
            Text(
              "Job Title",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _titleController,
              "e.g. Need a full day cleaner...",
              isDark,
              cardColor,
              textColor,
              hintColor,
            ),

            const SizedBox(height: 20),

            // Description
            Text(
              "Description (Optional)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              _descController,
              "Describe the work details...",
              isDark,
              cardColor,
              textColor,
              hintColor,
              maxLines: 4,
            ),

            const SizedBox(height: 20),

            // Slots Selector
            Text(
              "How many people do you need?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _slots > 1
                        ? () => setState(() => _slots--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: _slots > 1 ? AppColors.brandMain : Colors.grey,
                  ),
                  Text(
                    "$_slots",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: _slots < 10
                        ? () => setState(() => _slots++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: _slots < 10 ? AppColors.brandMain : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${_slots == 1 ? 'person' : 'people'} (max 10)",
                      style: TextStyle(color: hintColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Media Upload
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.camera_alt, color: AppColors.brandMain),
                label: Text(
                  _mediaFiles.isEmpty
                      ? "Add Photo / Video"
                      : "Add More (${_mediaFiles.length})",
                  style: const TextStyle(color: AppColors.brandMain),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.brandMain),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: cardColor,
                ),
              ),
            ),

            // Media Preview
            _buildAttachmentsSection(),

            const SizedBox(height: 20),

            // Budget Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Budget (per job)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Text(
                  "৳ ${_budget.toInt()}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            Slider(
              value: _budget,
              min: 300,
              max: 10000,
              divisions: 97,
              activeColor: AppColors.brandMain,
              inactiveColor: isDark ? Colors.grey : Colors.grey.shade300,
              onChanged: (val) => setState(() => _budget = val),
            ),

            const SizedBox(height: 30),

            // Post Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "POST JOB REQUEST",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎨 UI COMPONENTS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      bool isDark,
      Color fillColor,
      Color textColor,
      Color hintColor, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandMain, width: 2),
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    if (_mediaFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaFiles.length,
        itemBuilder: (context, index) {
          final file = _mediaFiles[index];
          final isVideo = _isVideoFile(file.path);

          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade300,
                  image: isVideo
                      ? null
                      : DecorationImage(
                    image: FileImage(File(file.path)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: isVideo
                    ? const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                )
                    : null,
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () => setState(() => _mediaFiles.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> item, bool isDark) {
    final bool isSelected = _selectedCategory == item['name'];
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = item['name']),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandMain.withOpacity(0.2)
              : cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? AppColors.brandMain
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item['icon'],
              size: 28,
              color: isSelected ? AppColors.brandMain : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              item['name'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.brandMain : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}