// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;

    return FloatingScaffold(
      title: 'ANALYTICS',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.all(16),
      body: _buildAnalyticsBody(isDark, cardColor, textColor, subTextColor),
    );
  }

  // ✅ Combined Stream Builder - 3 Collections থেকে ডাটা নিচ্ছে
  Widget _buildAnalyticsBody(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      // 1️⃣ Users Collection
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<DocumentSnapshot>(
          // 2️⃣ User Stats Collection
          stream: FirebaseFirestore.instance
              .collection('user_stats')
              .doc(_uid)
              .snapshots(),
          builder: (context, statsSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              // 3️⃣ Completed Jobs Collection
              stream: FirebaseFirestore.instance
                  .collection('completed_jobs')
                  .where('participants', arrayContains: _uid)
                  .orderBy('completedAt', descending: true)
                  .snapshots(),
              builder: (context, jobSnapshot) {
                // Loading State
                if (userSnapshot.connectionState == ConnectionState.waiting ||
                    statsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandMain,
                    ),
                  );
                }

                // Error Handling
                if (jobSnapshot.hasError) {
                  return _buildError(jobSnapshot.error.toString(), textColor);
                }

                // Extract Data
                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final userStats =
                    statsSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final jobDocs = jobSnapshot.data?.docs ?? [];

                // Calculate Stats
                final stats = _calculateStats(jobDocs, userData, userStats);

                return Column(
                  children: [
                    // ১. স্ট্যাটস গ্রিড
                    _buildStatsCards(
                      stats,
                      isDark,
                      cardColor,
                      textColor,
                      subTextColor,
                    ),

                    const SizedBox(height: 25),

                    // ২. আর্নিং চার্ট
                    _buildChartSection(
                      "Monthly Earnings",
                      stats['monthlyEarnings'],
                      isDark,
                      cardColor,
                      textColor,
                      isBarChart: true,
                    ),

                    const SizedBox(height: 25),

                    // ৩. জব ট্রেন্ড
                    _buildChartSection(
                      "Job Completion Trend",
                      stats['monthlyJobs'],
                      isDark,
                      cardColor,
                      textColor,
                      isBarChart: false,
                    ),

                    const SizedBox(height: 25),

                    // ৪. পারফরম্যান্স মেট্রিক্স
                    _buildPerformanceMetrics(
                      stats,
                      isDark,
                      cardColor,
                      textColor,
                      subTextColor,
                    ),

                    const SizedBox(height: 50),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ✅ Updated Calculation Logic - সব জায়গা থেকে ডাটা নিচ্ছে
  Map<String, dynamic> _calculateStats(
    List<QueryDocumentSnapshot> jobDocs,
    Map<String, dynamic> userData,
    Map<String, dynamic> userStats,
  ) {
    double totalEarned = 0;
    int jobsCompleted = jobDocs.length;
    double totalRating = 0;
    int ratedJobs = 0;

    Map<String, double> monthlyEarnings = {};
    Map<String, int> monthlyJobs = {};

    // Initialize last 6 months
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateFormat(
        'MMM',
      ).format(DateTime(now.year, now.month - i, 1));
      monthlyEarnings[month] = 0.0;
      monthlyJobs[month] = 0;
    }

    // Process completed jobs
    for (var doc in jobDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // ✅ Price extraction (handle both string and number)
      final priceRaw =
          data['price'] ?? data['amount'] ?? data['offerPrice'] ?? 0;
      double amount = _extractPrice(priceRaw);

      // ✅ Rating extraction
      final rating = _toDouble(data['rating']);

      // ✅ Timestamp extraction
      final Timestamp? ts = data['completedAt'] as Timestamp?;

      totalEarned += amount;

      if (rating > 0) {
        totalRating += rating;
        ratedJobs++;
      }

      if (ts != null) {
        final date = ts.toDate();
        final monthKey = DateFormat('MMM').format(date);
        if (monthlyEarnings.containsKey(monthKey)) {
          monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + amount;
          monthlyJobs[monthKey] = (monthlyJobs[monthKey] ?? 0) + 1;
        }
      }
    }

    // ✅ Get Impressions from Posts (aggregated)
    int totalImpressions =
        _toInt(userData['totalImpressions']) +
        _toInt(userData['impressions']) +
        _toInt(userStats['totalImpressions']);

    // ✅ Profile Views
    int profileViews =
        _toInt(userData['profileViews']) + _toInt(userStats['profileViews']);

    // ✅ Jobs Completed from user_stats (fallback)
    if (jobsCompleted == 0) {
      jobsCompleted =
          _toInt(userStats['jobsCompleted']) +
          _toInt(userStats['hiresCompleted']);
    }

    // ✅ Rating from user profile (fallback)
    double avgRating = ratedJobs > 0 ? (totalRating / ratedJobs) : 0.0;
    if (avgRating == 0) {
      avgRating = _toDouble(userData['rating']) > 0
          ? _toDouble(userData['rating'])
          : _toDouble(userStats['avgRating']);
    }

    // ✅ Total earned from user_stats (fallback)
    if (totalEarned == 0) {
      totalEarned =
          _toDouble(userStats['totalEarned']) +
          _toDouble(userStats['earnings']);
    }

    return {
      'totalEarned': totalEarned,
      'jobsCompleted': jobsCompleted,
      'avgRating': avgRating,
      'monthlyEarnings': monthlyEarnings,
      'monthlyJobs': monthlyJobs,
      'impressions': totalImpressions,
      'profileViews': profileViews,
      'totalReviews': _toInt(userStats['totalReviews']),
    };
  }

  // ✅ Extract price from various formats
  double _extractPrice(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) return value.toDouble();

    if (value is String) {
      // Remove currency symbols and parse
      // "৳1200" -> 1200.0
      // "1200 / day" -> 1200.0
      final cleaned = value
          .replaceAll('৳', '')
          .replaceAll(',', '')
          .replaceAll('BDT', '')
          .replaceAll('/day', '')
          .replaceAll('/job', '')
          .replaceAll('per day', '')
          .trim();

      // Extract first number
      final match = RegExp(r'[\d.]+').firstMatch(cleaned);
      if (match != null) {
        return double.tryParse(match.group(0) ?? '0') ?? 0.0;
      }
    }

    return 0.0;
  }

  // --- Chart Section ---
  Widget _buildChartSection(
    String title,
    Map data,
    bool isDark,
    Color cardColor,
    Color textColor, {
    required bool isBarChart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isBarChart
              ? _buildBarChart(
                  Map<String, double>.from(data),
                  isDark,
                  textColor,
                )
              : _buildLineChart(Map<String, int>.from(data), isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    Map<String, double> data,
    bool isDark,
    Color textColor,
  ) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              "No earnings data yet",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final keys = data.keys.toList();
    final values = data.values.toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        barGroups: List.generate(keys.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: AppColors.brandMain,
                width: 14,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue * 1.2,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      keys[value.toInt()],
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildLineChart(Map<String, int> data, bool isDark, Color textColor) {
    if (data.isEmpty || data.values.every((v) => v == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              "No job completion data yet",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final keys = data.keys.toList();
    final values = data.values.toList();

    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(keys.length, (index) {
              return FlSpot(index.toDouble(), values[index].toDouble());
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.15),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      keys[value.toInt()],
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }

  // --- Stats Cards ---
  Widget _buildStatsCards(
    Map stats,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard(
          "Total Earned",
          "৳${_formatNumber(stats['totalEarned'].toInt())}",
          Icons.attach_money,
          Colors.green,
          cardColor,
          textColor,
          subTextColor,
        ),
        _statCard(
          "Jobs Done",
          "${stats['jobsCompleted']}",
          Icons.work_outline,
          Colors.blue,
          cardColor,
          textColor,
          subTextColor,
        ),
        _statCard(
          "Impressions",
          _format(stats['impressions']),
          Icons.visibility_outlined,
          Colors.purpleAccent,
          cardColor,
          textColor,
          subTextColor,
        ),
        _statCard(
          "Profile Views",
          _format(stats['profileViews']),
          Icons.person_search_outlined,
          Colors.teal,
          cardColor,
          textColor,
          subTextColor,
        ),
        _statCard(
          "Avg Rating",
          "${(stats['avgRating'] as double).toStringAsFixed(1)} ★",
          Icons.star_border,
          Colors.amber,
          cardColor,
          textColor,
          subTextColor,
        ),
        _statCard(
          "Reviews",
          "${stats['totalReviews']}",
          Icons.rate_review_outlined,
          Colors.pinkAccent,
          cardColor,
          textColor,
          subTextColor,
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: subTextColor)),
        ],
      ),
    );
  }

  // --- Performance Metrics ---
  Widget _buildPerformanceMetrics(
    Map stats,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    // Calculate click rate
    final impressions = _toInt(stats['impressions']);
    final views = _toInt(stats['profileViews']);
    final clickRate = impressions > 0 ? ((views / impressions) * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance Metrics",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _metricRow(
            "Impressions (Reach)",
            "${_format(stats['impressions'])} users",
            textColor,
            subTextColor,
          ),
          _metricRow(
            "Profile Click Rate",
            "${clickRate.toStringAsFixed(1)}%",
            textColor,
            subTextColor,
          ),
          _metricRow(
            "Jobs Completed",
            "${stats['jobsCompleted']}",
            textColor,
            subTextColor,
          ),
          _metricRow(
            "Average Rating",
            "${(stats['avgRating'] as double).toStringAsFixed(1)} ★",
            textColor,
            subTextColor,
          ),
        ],
      ),
    );
  }

  Widget _metricRow(
    String label,
    String val,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subTextColor, fontSize: 13)),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---
  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  String _format(dynamic val) {
    int n = _toInt(val);
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(0)}K";
    return n.toString();
  }

  Widget _buildError(String err, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              "Error loading analytics",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
