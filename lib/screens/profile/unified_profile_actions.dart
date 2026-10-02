// lib/screens/profile/unified_profile_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'unified_profile_utils.dart';

mixin UnifiedProfileActions<T extends StatefulWidget> on State<T> {
  Map<String, dynamic> get userData;
  String get profileUid;

  Future<void> launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open link')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Link error: $e')));
      }
    }
  }

  Future<void> makePhoneCall() async {
    final phone = userData['phone']?.toString().trim();
    if (phone == null || phone.isEmpty) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      await AchievementService.incrementProgress('daily_contact', amount: 1);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phone call not supported')));
    }
  }

  Future<void> sendEmail() async {
    final email = userData['email']?.toString().trim();
    if (email == null || email.isEmpty) return;

    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      await AchievementService.incrementProgress('daily_contact', amount: 1);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email not supported')));
    }
  }

  Future<void> reportUser() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );

    if (result == true) {
      await AchievementService.incrementProgress('lt_community_s1', amount: 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you!')),
        );
      }
    }
  }

  Future<void> shareProfile() async {
    try {
      final userName = UnifiedProfileUtils.safeString(
        userData['name'],
        defaultValue: 'FindUs User',
      );

      final profileLink = 'https://yourapp.com/profile/$profileUid';
      final message = 'FindUs Profile: $userName\n$profileLink';

      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.share(message, sharePositionOrigin: origin);

      await AchievementService.incrementProgress('daily_share', amount: 1);
      await AchievementService.syncWeeklyChestFromServer();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile shared! Quest updated.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  Future<void> copyProfileLink() async {
    try {
      final profileLink = 'https://yourapp.com/profile/$profileUid';
      await Clipboard.setData(ClipboardData(text: profileLink));
      await AchievementService.incrementProgress('daily_share', amount: 1);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile link copied!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Copy failed: $e')));
      }
    }
  }
}
