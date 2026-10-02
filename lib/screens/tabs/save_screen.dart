// lib/screens/tabs/save_screen.dart
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class SaveScreen extends StatefulWidget {
  const SaveScreen({super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  // ✅ ক্যাটাগরি লিস্ট
  final List<String> _categories = [
    "All",
    "Farmer",
    "Painter",
    "Shopper",
    "Driver",
    "Others",
  ];
  String _selectedCategory = "All";

  // ✅ ফিল্টার লজিক
  List<Map<String, dynamic>> _getFilteredWorkers() {
    if (_selectedCategory == "All") {
      return SavedService.savedWorkers;
    }

    return SavedService.savedWorkers.where((worker) {
      final role = (worker['role'] ?? '').toString().toUpperCase();

      if (_selectedCategory == "Farmer")
        return role.contains("FARMER") || role.contains("GARDEN");
      if (_selectedCategory == "Painter")
        return role.contains("PAINTER") || role.contains("COLOR");
      if (_selectedCategory == "Shopper")
        return role.contains("SHOPPER") || role.contains("BAZAR");
      if (_selectedCategory == "Driver")
        return role.contains("DRIVER") || role.contains("RIKSHAW");

      // Others Logic
      final mainRoles = [
        'FARMER',
        'GARDEN',
        'PAINTER',
        'COLOR',
        'SHOPPER',
        'BAZAR',
        'DRIVER',
        'RIKSHAW',
      ];
      if (_selectedCategory == "Others") {
        return !mainRoles.any((r) => role.contains(r));
      }
      return true;
    }).toList();
  }

  String _getUserId(Map<String, dynamic> data) {
    return (data['userId'] ?? data['id'] ?? '').toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    final workers = _getFilteredWorkers();

    return FloatingScaffold(
      title: 'SAVED PROFILES',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          // 🔍 Category Filter
          _buildCategoryFilter(isDark),

          // 📋 List
          Expanded(
            child: workers.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      return _buildWorkerCard(workers[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 🔥 Category Filter Widget
  Widget _buildCategoryFilter(bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedCategory = cat);
              },
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              selectedColor: AppColors.brandMain,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> data) {
    final workerId = _getUserId(data);
    final name = (data['name'] ?? 'User').toString();
    final role = (data['role'] ?? 'Worker').toString();
    final image = (data['image'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: UniversalWorkerCard(
        id: workerId,
        name: name,
        role: role,
        imageUrl: image,
        address: (data['location'] ?? 'Bangladesh').toString(),
        rating: (data['rating'] ?? 0.0).toString(),
        completed: (data['completed'] ?? 0).toString(),
        reviews: (data['reviews'] ?? 0).toString(),
        price: (data['price'] ?? 'Negotiable').toString(),
        isVerifiedWorker: data['isVerified'] == true,
        followersCount: data['followersCount'],
        margin: EdgeInsets.zero,

        primaryButtonText: "View Profile",

        // Actions
        onTap: () => _navigateToProfile(workerId),
        onViewProfileTap: () => _navigateToProfile(workerId),

        // ❤️ Save/Unsave Logic
        isSaved: true, // Saved Screen এ সব আইটেমই সেভড থাকে
        showSaveButton: true,
        onSaveTap: () async {
          // ১. আনসেভ করা (লিস্ট থেকে রিমুভ)
          await SavedService.toggleSave(data);

          // ২. UI আপডেট করা
          setState(() {
            // লিস্ট অটো আপডেট হবে কারণ SavedService.savedWorkers আপডেট হয়েছে
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Removed from saved list"),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  void _navigateToProfile(String uid) {
    if (uid.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UnifiedProfileScreen(uid: uid, isOwner: false, showBack: true),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 15),
          Text(
            "No saved profiles found",
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
