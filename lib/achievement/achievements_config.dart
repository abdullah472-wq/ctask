// lib/achievement/achievements_config.dart

import 'achievement_models.dart';

class AchievementsConfig {
  static List<AchievementDef> get all => [
    // ════════════════════════════════════════════════════════════════════════
    // 🎯 DAILY QUESTS (সহজ ও দ্রুত)
    // ════════════════════════════════════════════════════════════════════════
    const AchievementDef(
      id: 'daily_login',
      title: 'Daily Check-in',
      description: 'Open the app daily to earn points',
      target: 1,
      xpReward: 50,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_view_jobs',
      title: 'Window Shopper',
      description: 'View details of 3 jobs',
      target: 3,
      xpReward: 70,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_share',
      title: 'Social Sharer',
      description: 'Share a job or profile',
      target: 1,
      xpReward: 100,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_complete_job',
      title: 'Hard Worker',
      description: 'Complete 1 job today',
      target: 1,
      xpReward: 100,
      workerOnly: true,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'daily_hire',
      title: 'Daily Recruiter',
      description: 'Hire 1 person today',
      target: 1,
      xpReward: 150,
      supporterOnly: true,
      resetPeriod: ResetPeriod.daily,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // 📅 WEEKLY QUESTS
    // ════════════════════════════════════════════════════════════════════════
    const AchievementDef(
      id: 'weekly_daily_chest',
      title: 'Weekly Consistency',
      description: 'Complete 20 daily quests this week',
      target: 20,
      xpReward: 1500,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'weekly_apply',
      title: 'Active Seeker',
      description: 'Apply to 5 jobs this week',
      target: 5,
      xpReward: 400,
      workerOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'weekly_post_free',
      title: 'Weekly Hiring',
      description: 'Post 3 jobs this week',
      target: 3,
      xpReward: 300,
      supporterOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'weekly_complete_jobs',
      title: 'Job Marathon',
      description: 'Complete 3 jobs this week',
      target: 3,
      xpReward: 500,
      workerOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'weekly_hire',
      title: 'Hiring Spree',
      description: 'Hire 3 people this week',
      target: 3,
      xpReward: 600,
      supporterOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // 🏢 TEAM & PRO QUESTS
    // ════════════════════════════════════════════════════════════════════════
    const AchievementDef(
      id: 'team_daily_active',
      title: 'Team Huddle',
      description: '2 Team members active today',
      target: 1,
      xpReward: 200,
      teamOnly: true,
      resetPeriod: ResetPeriod.daily,
    ),
    const AchievementDef(
      id: 'team_weekly_hire',
      title: 'Recruitment Drive',
      description: 'Shortlist 10 candidates as a team',
      target: 10,
      xpReward: 1000,
      teamOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'pro_mass_post',
      title: 'Power Poster',
      description: 'Post 5 jobs in a week (Pro Only)',
      target: 5,
      xpReward: 2000,
      supporterOnly: true,
      proOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),
    const AchievementDef(
      id: 'pro_top_candidate',
      title: 'Elite Hunter',
      description: 'Contact 10 candidates (Pro Only)',
      target: 10,
      xpReward: 1500,
      supporterOnly: true,
      proOnly: true,
      resetPeriod: ResetPeriod.weekly,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // 🏆 LONG-TERM CHAINS
    // ════════════════════════════════════════════════════════════════════════

    // ✅ Profile Setup Chain
    const AchievementDef(
      id: 'lt_profile_s1',
      chainKey: 'lt_profile',
      chainStage: 1,
      title: 'Profile Setup I',
      description: 'Add basic info & photo',
      target: 1,
      xpReward: 300,
    ),
    const AchievementDef(
      id: 'lt_profile_s2',
      chainKey: 'lt_profile',
      chainStage: 2,
      title: 'Profile Setup II',
      description: 'Add bio & location',
      target: 1,
      xpReward: 700,
    ),
    const AchievementDef(
      id: 'lt_profile_s3',
      chainKey: 'lt_profile',
      chainStage: 3,
      title: 'Profile Setup III',
      description: 'Add skills & portfolio',
      target: 1,
      xpReward: 1200,
    ),

    // ✅ Rating Chain (Everyone)
    const AchievementDef(
      id: 'lt_rating_s1',
      chainKey: 'lt_rating',
      chainStage: 1,
      title: 'Rising Star',
      description: 'Receive 50 star ratings',
      target: 50,
      xpReward: 1000,
    ),
    const AchievementDef(
      id: 'lt_rating_s2',
      chainKey: 'lt_rating',
      chainStage: 2,
      title: 'Trusted User',
      description: 'Receive 200 star ratings',
      target: 200,
      xpReward: 2500,
    ),
    const AchievementDef(
      id: 'lt_rating_s3',
      chainKey: 'lt_rating',
      chainStage: 3,
      title: 'Community Legend',
      description: 'Receive 1000 star ratings',
      target: 1000,
      xpReward: 10000,
    ),

    // ✅ Referral Chain (Everyone)
    const AchievementDef(
      id: 'lt_invite_s1',
      chainKey: 'lt_invite',
      chainStage: 1,
      title: 'Friendly Face',
      description: 'Refer 50 friends',
      target: 50,
      xpReward: 1500,
    ),
    const AchievementDef(
      id: 'lt_invite_s2',
      chainKey: 'lt_invite',
      chainStage: 2,
      title: 'Community Builder',
      description: 'Refer 200 friends',
      target: 200,
      xpReward: 5000,
    ),
    const AchievementDef(
      id: 'lt_invite_s3',
      chainKey: 'lt_invite',
      chainStage: 3,
      title: 'Influencer',
      description: 'Refer 1000 friends',
      target: 1000,
      xpReward: 10000,
    ),

    // ✅ Application Chain (Worker Only)
    const AchievementDef(
      id: 'lt_apply_s1',
      chainKey: 'lt_apply',
      chainStage: 1,
      title: 'Job Hunter I',
      description: 'Apply to 50 jobs',
      target: 50,
      xpReward: 2500,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_apply_s2',
      chainKey: 'lt_apply',
      chainStage: 2,
      title: 'Job Hunter II',
      description: 'Apply to 200 jobs',
      target: 200,
      xpReward: 5000,
      workerOnly: true,
    ),
    const AchievementDef(
      id: 'lt_apply_s3',
      chainKey: 'lt_apply',
      chainStage: 3,
      title: 'Job Hunter III',
      description: 'Apply to 1000 jobs',
      target: 1000,
      xpReward: 10000,
      workerOnly: true,
    ),

    // ✅ Hiring Chain (Supporter Only) - FIXED: Removed duplicates
    const AchievementDef(
      id: 'lt_hire_s1',
      chainKey: 'lt_hire',
      chainStage: 1,
      title: 'First Hire',
      description: 'Hire 50 people',
      target: 50,
      xpReward: 2500,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_hire_s2',
      chainKey: 'lt_hire',
      chainStage: 2,
      title: 'Team Builder',
      description: 'Hire 200 people',
      target: 200,
      xpReward: 10000,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_hire_s3',
      chainKey: 'lt_hire',
      chainStage: 3,
      title: 'Business Tycoon',
      description: 'Hire 1000 people',
      target: 1000,
      xpReward: 20000,
      supporterOnly: true,
    ),

    // ✅ Job Posting Chain (Supporter Only)
    const AchievementDef(
      id: 'lt_posts_s1',
      chainKey: 'lt_posts',
      chainStage: 1,
      title: 'First Post',
      description: 'Post 10 jobs',
      target: 10,
      xpReward: 1000,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_posts_s2',
      chainKey: 'lt_posts',
      chainStage: 2,
      title: 'Regular Poster',
      description: 'Post 50 jobs',
      target: 50,
      xpReward: 5000,
      supporterOnly: true,
    ),
    const AchievementDef(
      id: 'lt_posts_s3',
      chainKey: 'lt_posts',
      chainStage: 3,
      title: 'Job Board Master',
      description: 'Post 200 jobs',
      target: 200,
      xpReward: 15000,
      supporterOnly: true,
    ),

    // ✅ Review Chain (Everyone)
    const AchievementDef(
      id: 'lt_reviews_s1',
      chainKey: 'lt_reviews',
      chainStage: 1,
      title: 'Helpful Reviewer',
      description: 'Give 10 reviews',
      target: 10,
      xpReward: 500,
    ),
    const AchievementDef(
      id: 'lt_reviews_s2',
      chainKey: 'lt_reviews',
      chainStage: 2,
      title: 'Review Master',
      description: 'Give 50 reviews',
      target: 50,
      xpReward: 2000,
    ),
    const AchievementDef(
      id: 'lt_reviews_s3',
      chainKey: 'lt_reviews',
      chainStage: 3,
      title: 'Community Critic',
      description: 'Give 200 reviews',
      target: 200,
      xpReward: 10000,
    ),

    // ════════════════════════════════════════════════════════════════════════
    // 🎁 BONUS QUESTS (Side Missions)
    // ════════════════════════════════════════════════════════════════════════
    const AchievementDef(
      id: 'bonus_rate_us',
      title: 'Fan of FindUs',
      description: 'Rate us on Play Store',
      target: 1,
      xpReward: 500,
    ),
    const AchievementDef(
      id: 'bonus_verify_phone',
      title: 'Verified User',
      description: 'Verify your phone number',
      target: 1,
      xpReward: 200,
    ),
    const AchievementDef(
      id: 'bonus_complete_kyc',
      title: 'Trusted Account',
      description: 'Complete KYC verification',
      target: 1,
      xpReward: 1000,
    ),
  ];

  // ✅ Get achievement by ID
  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // ✅ Get achievements by role (for quest_generator.dart)
  static List<AchievementDef> getByRole(bool isWorker) {
    return all.where((achievement) {
      if (achievement.workerOnly && !isWorker) return false;
      if (achievement.supporterOnly && isWorker) return false;
      return true;
    }).toList();
  }

  // ✅ Get daily quests
  static List<AchievementDef> get dailyQuests {
    return all.where((a) => a.resetPeriod == ResetPeriod.daily).toList();
  }

  // ✅ Get weekly quests
  static List<AchievementDef> get weeklyQuests {
    return all.where((a) => a.resetPeriod == ResetPeriod.weekly).toList();
  }

  // ✅ Get long-term quests
  static List<AchievementDef> get longTermQuests {
    return all.where((a) => a.resetPeriod == ResetPeriod.none).toList();
  }

  // ✅ Get chain quests
  static List<AchievementDef> getChainQuests(String chainKey) {
    return all.where((a) => a.chainKey == chainKey).toList()
      ..sort((a, b) => a.chainStage.compareTo(b.chainStage));
  }

  // ✅ Get all chain keys
  static List<String> get allChainKeys {
    return all
        .where((a) => a.chainKey != null)
        .map((a) => a.chainKey!)
        .toSet()
        .toList();
  }

  // ✅ Statistics
  static int get totalAchievements => all.length;
  static int get totalXPRewards => all.fold(0, (sum, a) => sum + a.xpReward);
}
