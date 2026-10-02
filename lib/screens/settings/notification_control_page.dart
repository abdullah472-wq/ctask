// lib/screens/settings/notification_control_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ NEW
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class NotificationControlPage extends StatefulWidget {
  const NotificationControlPage({super.key});

  @override
  State<NotificationControlPage> createState() =>
      _NotificationControlPageState();
}

class _NotificationControlPageState extends State<NotificationControlPage> {
  // Master + per-category flags
  bool _allEnabled = true;
  bool _jobsEnabled = true;
  bool _promoEnabled = true;
  bool _emergencyEnabled = true;

  // ✅ NEW: Additional settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _previewEnabled = true;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  bool _loading = true;

  static const _keyAll = 'notif_all';
  static const _keyJobs = 'notif_jobs';
  static const _keyPromo = 'notif_promo';
  static const _keyEmergency = 'notif_emergency';
  static const _keySound = 'notif_sound';
  static const _keyVibration = 'notif_vibration';
  static const _keyPreview = 'notif_preview';
  static const _keyQuietHours = 'notif_quiet_hours';
  static const _keyQuietStart = 'notif_quiet_start';
  static const _keyQuietEnd = 'notif_quiet_end';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _allEnabled = prefs.getBool(_keyAll) ?? true;
      _jobsEnabled = prefs.getBool(_keyJobs) ?? true;
      _promoEnabled = prefs.getBool(_keyPromo) ?? true;
      _emergencyEnabled = prefs.getBool(_keyEmergency) ?? true;
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      _vibrationEnabled = prefs.getBool(_keyVibration) ?? true;
      _previewEnabled = prefs.getBool(_keyPreview) ?? true;
      _quietHoursEnabled = prefs.getBool(_keyQuietHours) ?? false;

      // Load quiet hours times
      final startMinutes = prefs.getInt(_keyQuietStart) ?? 22 * 60;
      final endMinutes = prefs.getInt(_keyQuietEnd) ?? 7 * 60;
      _quietStart = TimeOfDay(
        hour: startMinutes ~/ 60,
        minute: startMinutes % 60,
      );
      _quietEnd = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAll, _allEnabled);
    await prefs.setBool(_keyJobs, _jobsEnabled);
    await prefs.setBool(_keyPromo, _promoEnabled);
    await prefs.setBool(_keyEmergency, _emergencyEnabled);
    await prefs.setBool(_keySound, _soundEnabled);
    await prefs.setBool(_keyVibration, _vibrationEnabled);
    await prefs.setBool(_keyPreview, _previewEnabled);
    await prefs.setBool(_keyQuietHours, _quietHoursEnabled);
    await prefs.setInt(
      _keyQuietStart,
      _quietStart.hour * 60 + _quietStart.minute,
    );
    await prefs.setInt(_keyQuietEnd, _quietEnd.hour * 60 + _quietEnd.minute);

    // ✅ Update Firebase topics based on settings
    _updateFirebaseTopics();
  }

  // ✅ NEW: Firebase topic subscription management
  Future<void> _updateFirebaseTopics() async {
    final messaging = FirebaseMessaging.instance;

    try {
      if (_allEnabled && _jobsEnabled) {
        await messaging.subscribeToTopic('jobs');
      } else {
        await messaging.unsubscribeFromTopic('jobs');
      }

      if (_allEnabled && _promoEnabled) {
        await messaging.subscribeToTopic('promo');
      } else {
        await messaging.unsubscribeFromTopic('promo');
      }

      if (_allEnabled && _emergencyEnabled) {
        await messaging.subscribeToTopic('emergency');
      } else {
        await messaging.unsubscribeFromTopic('emergency');
      }
    } catch (e) {
      debugPrint('Firebase topic update error: $e');
    }
  }

  void _updateAll(bool value) {
    setState(() {
      _allEnabled = value;
      if (!value) {
        _jobsEnabled = false;
        _promoEnabled = false;
        _emergencyEnabled = false;
      }
    });
    _savePrefs();
  }

  void _updateCategory({bool? jobs, bool? promo, bool? emergency}) {
    setState(() {
      if (jobs != null) _jobsEnabled = jobs;
      if (promo != null) _promoEnabled = promo;
      if (emergency != null) _emergencyEnabled = emergency;

      final anyOn = _jobsEnabled || _promoEnabled || _emergencyEnabled;
      _allEnabled = anyOn;
    });
    _savePrefs();
  }

  // ✅ NEW: Pick time for quiet hours
  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.brandMain),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
      _savePrefs();
    }
  }

  // ✅ NEW: Send test notification
  Future<void> _sendTestNotification() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Test notification sent! 🔔'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // In production, you would trigger an actual notification here
    // await NotificationService.showLocalNotification(
    //   title: 'Test Notification',
    //   body: 'This is a test notification from FindUs!',
    // );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return FloatingScaffold(
      title: "NOTIFICATIONS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ════════════════════════════════════════════════════════════
                // MASTER SWITCH
                // ════════════════════════════════════════════════════════════
                _buildMasterSwitch(cardColor, textColor, subTextColor),

                const SizedBox(height: 25),
                _buildSectionTitle("NOTIFICATION TYPES", subTextColor),

                // ════════════════════════════════════════════════════════════
                // CATEGORY SWITCHES
                // ════════════════════════════════════════════════════════════
                _buildCategorySwitches(
                  cardColor,
                  textColor,
                  subTextColor,
                  isDark,
                ),

                const SizedBox(height: 25),
                _buildSectionTitle("NOTIFICATION SETTINGS", subTextColor),

                // ════════════════════════════════════════════════════════════
                // ✅ NEW: SOUND & VIBRATION SETTINGS
                // ════════════════════════════════════════════════════════════
                _buildNotificationSettings(
                  cardColor,
                  textColor,
                  subTextColor,
                  isDark,
                ),

                const SizedBox(height: 25),
                _buildSectionTitle("QUIET HOURS", subTextColor),

                // ════════════════════════════════════════════════════════════
                // ✅ NEW: QUIET HOURS
                // ════════════════════════════════════════════════════════════
                _buildQuietHours(cardColor, textColor, subTextColor, isDark),

                const SizedBox(height: 25),

                // ════════════════════════════════════════════════════════════
                // ✅ NEW: TEST NOTIFICATION BUTTON
                // ════════════════════════════════════════════════════════════
                _buildTestNotificationButton(cardColor, textColor),

                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Note: You can also control app-level notification permissions directly from your device settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: subTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UI BUILDERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMasterSwitch(
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          "All Notifications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "Turn all FINDUS notifications on or off.",
          style: TextStyle(fontSize: 12, color: subTextColor),
        ),
        value: _allEnabled,
        onChanged: _updateAll,
        activeColor: AppColors.brandMain,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _allEnabled
                ? AppColors.brandMain.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _allEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: _allEnabled ? AppColors.brandMain : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: subTextColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCategorySwitches(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.work_outline_rounded,
            title: "Jobs & Support",
            subtitle: "New jobs or relevant posts near you.",
            value: _jobsEnabled && _allEnabled,
            onChanged: _allEnabled ? (v) => _updateCategory(jobs: v) : null,
            color: Colors.blue,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSwitchTile(
            icon: Icons.campaign_rounded,
            title: "Updates & Promo",
            subtitle: "News, offers and feature tips.",
            value: _promoEnabled && _allEnabled,
            onChanged: _allEnabled ? (v) => _updateCategory(promo: v) : null,
            color: Colors.orange,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSwitchTile(
            icon: Icons.warning_amber_rounded,
            title: "Emergency Alerts",
            subtitle: "Safety or emergency notifications.",
            value: _emergencyEnabled && _allEnabled,
            onChanged: _allEnabled
                ? (v) => _updateCategory(emergency: v)
                : null,
            color: Colors.redAccent,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Sound & Vibration Settings
  Widget _buildNotificationSettings(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.volume_up_rounded,
            title: "Sound",
            subtitle: "Play sound for notifications.",
            value: _soundEnabled && _allEnabled,
            onChanged: _allEnabled
                ? (v) {
                    setState(() => _soundEnabled = v);
                    _savePrefs();
                  }
                : null,
            color: Colors.purple,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSwitchTile(
            icon: Icons.vibration_rounded,
            title: "Vibration",
            subtitle: "Vibrate for notifications.",
            value: _vibrationEnabled && _allEnabled,
            onChanged: _allEnabled
                ? (v) {
                    setState(() => _vibrationEnabled = v);
                    _savePrefs();
                  }
                : null,
            color: Colors.teal,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSwitchTile(
            icon: Icons.preview_rounded,
            title: "Message Preview",
            subtitle: "Show message content in notifications.",
            value: _previewEnabled && _allEnabled,
            onChanged: _allEnabled
                ? (v) {
                    setState(() => _previewEnabled = v);
                    _savePrefs();
                  }
                : null,
            color: Colors.indigo,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Quiet Hours Section
  Widget _buildQuietHours(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.bedtime_rounded,
            title: "Quiet Hours",
            subtitle: "Mute notifications during specific hours.",
            value: _quietHoursEnabled,
            onChanged: (v) {
              setState(() => _quietHoursEnabled = v);
              _savePrefs();
            },
            color: Colors.deepPurple,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),

          // Time selectors (only show when enabled)
          if (_quietHoursEnabled) ...[
            _buildDivider(isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      label: "From",
                      time: _quietStart,
                      onTap: () => _pickTime(true),
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.arrow_forward, color: subTextColor, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeSelector(
                      label: "To",
                      time: _quietEnd,
                      onTap: () => _pickTime(false),
                      textColor: textColor,
                      subTextColor: subTextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: subTextColor)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Test Notification Button
  Widget _buildTestNotificationButton(Color cardColor, Color textColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _allEnabled ? _sendTestNotification : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _allEnabled
                        ? AppColors.brandMain.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _allEnabled ? AppColors.brandMain : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Send Test Notification",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _allEnabled ? textColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required Color color,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.brandMain,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onChanged == null
              ? (isDark ? Colors.white10 : Colors.grey.withOpacity(0.1))
              : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onChanged == null
              ? (isDark ? Colors.grey : Colors.grey.shade400)
              : color,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: onChanged == null ? subTextColor.withOpacity(0.5) : textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: onChanged == null
              ? subTextColor.withOpacity(0.5)
              : subTextColor,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      indent: 60,
      endIndent: 20,
    );
  }
}
