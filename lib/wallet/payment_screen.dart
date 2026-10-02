// lib/screens/wallet/manual_payment_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart'; // ✅ Add to pubspec.yaml
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/settings/activation_screen.dart';

enum PaymentPurpose { subscription, workerPayment, supporterPayment }

class ManualPaymentScreen extends StatefulWidget {
  final String planId;
  final int amount;
  final int duration;
  final PaymentPurpose purpose;
  final String description;

  const ManualPaymentScreen({
    super.key,
    required this.planId,
    required this.amount,
    required this.duration,
    required this.purpose,
    required this.description,
  });

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen>
    with SingleTickerProviderStateMixin {
  final _senderController = TextEditingController();
  final _trxIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedMethod = 'bKash';
  bool _isSubmitting = false;
  bool _hasScreenshot = false;

  // ✅ Payment timer
  Timer? _expiryTimer;
  DateTime? _expiryTime;
  Duration _remainingTime = Duration.zero;

  late TabController _tabController;
  int _currentStep = 0;

  final Map<String, Map<String, dynamic>> _paymentMethods = {
    'bKash': {
      'number': '01581818368',
      'color': const Color(0xFFE2136E),
      'icon': Icons.payment,
      'qrData': 'bkash:01581818368',
    },
    'Nagad': {
      'number': '01312200043',
      'color': const Color(0xFFEC1C24),
      'icon': Icons.account_balance_wallet,
      'qrData': 'nagad:01312200043',
    },
    'Rocket': {
      'number': '01312200043',
      'color': const Color(0xFF8B3A91),
      'icon': Icons.rocket_launch,
      'qrData': 'rocket:01312200043',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startExpiryTimer();
  }

  @override
  void dispose() {
    _senderController.dispose();
    _trxIdController.dispose();
    _tabController.dispose();
    _expiryTimer?.cancel();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⏱️ PAYMENT EXPIRY TIMER
  // ════════════════════════════════════════════════════════════════════════════

  void _startExpiryTimer() {
    _expiryTime = DateTime.now().add(const Duration(minutes: 30));

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = _expiryTime!.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        if (mounted) {
          setState(() => _remainingTime = Duration.zero);
          _showTimeoutDialog();
        }
      } else {
        if (mounted) {
          setState(() => _remainingTime = remaining);
        }
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange),
            SizedBox(width: 10),
            Text("Session Expired"),
          ],
        ),
        content: const Text(
          "Your payment session has expired.\n\n"
          "Please restart the payment process.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
            ),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimer(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ VALIDATION
  // ════════════════════════════════════════════════════════════════════════════

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number required';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Check if starts with 01 and has 11 digits
    if (!RegExp(r'^01[0-9]{9}$').hasMatch(cleaned)) {
      return 'Invalid Bangladesh phone number';
    }

    return null;
  }

  String? _validateTrxId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Transaction ID required';
    }

    if (value.length < 8) {
      return 'TrxID must be at least 8 characters';
    }

    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💳 SUBMIT PAYMENT
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check timer
    if (_remainingTime.isNegative || _remainingTime == Duration.zero) {
      _showSnack("Payment session expired. Please restart.", Colors.red);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("Please login first", Colors.red);
      return;
    }

    final sender = _senderController.text.trim();
    final trxId = _trxIdController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final uid = user.uid;
      final paymentRef = FirebaseFirestore.instance
          .collection('payment_requests')
          .doc();

      await paymentRef.set({
        'id': paymentRef.id,
        'uid': uid,
        'planId': widget.planId,
        'amount': widget.amount,
        'duration': widget.duration,
        'purpose': widget.purpose.name,
        'method': _selectedMethod,
        'senderNumber': sender,
        'trxId': trxId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(_expiryTime!),
        'description': widget.description,
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'subStatus': 'pending',
        'lastPaymentMethod': _selectedMethod,
        'lastTrxId': trxId,
        'lastPaymentAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActivationScreen(
              planId: widget.planId,
              amount: widget.amount,
              trxId: trxId,
              submittedAt: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📱 QR CODE DIALOG
  // ════════════════════════════════════════════════════════════════════════════

  void _showQRCode() {
    final methodData = _paymentMethods[_selectedMethod]!;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Scan to Pay",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: methodData['qrData'],
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: methodData['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        methodData['icon'],
                        color: methodData['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        methodData['number'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: methodData['color'],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Amount: ৳${widget.amount}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎨 BUILD UI
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final hintColor = isDark ? Colors.grey : Colors.grey.shade600;

    return FloatingScaffold(
      title: "PAYMENT",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      bodyPadding: EdgeInsets.zero,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Timer Banner
              _buildTimerBanner(isDark, cardColor),

              const SizedBox(height: 20),

              // Summary Box
              _buildSummaryBox(isDark, cardColor, textColor),

              const SizedBox(height: 20),

              // Tab Bar (Instructions / History)
              _buildTabBar(isDark, cardColor, textColor),

              const SizedBox(height: 20),

              // Tab Content
              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInstructionBox(isDark),
                    _buildPaymentHistory(isDark, cardColor, textColor),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Stepper
              _buildPaymentStepper(isDark, textColor),

              const SizedBox(height: 25),

              // Method Selector
              Text(
                "Select Payment Method",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              _buildMethodSelector(isDark, cardColor, textColor),

              const SizedBox(height: 25),

              // Input Fields
              _buildInputFields(isDark, cardColor, textColor, hintColor),

              const SizedBox(height: 30),

              // Submit Button
              _buildSubmitButton(),

              const SizedBox(height: 20),

              // Help Center
              _buildHelpCenter(isDark, cardColor, textColor),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⏱️ TIMER BANNER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTimerBanner(bool isDark, Color cardColor) {
    final isExpiringSoon = _remainingTime.inMinutes < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiringSoon
              ? [Colors.red.shade400, Colors.orange.shade400]
              : [AppColors.brandMain, AppColors.brandMain.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpiringSoon ? Icons.warning_amber : Icons.timer_outlined,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            "Complete payment within: ${_formatTimer(_remainingTime)}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📊 TAB BAR
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTabBar(bool isDark, Color cardColor, Color textColor) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.brandMain,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey : Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Instructions"),
          Tab(text: "History"),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📜 PAYMENT HISTORY
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentHistory(bool isDark, Color cardColor, Color textColor) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Not logged in"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payment_requests')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No previous payments",
              style: TextStyle(
                color: isDark ? Colors.grey : Colors.grey.shade600,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            final status = doc['status'] ?? 'pending';
            final amount = doc['amount'] ?? 0;
            final method = doc['method'] ?? 'N/A';

            Color statusColor;
            IconData statusIcon;
            switch (status) {
              case 'approved':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                break;
              case 'rejected':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                break;
              default:
                statusColor = Colors.orange;
                statusIcon = Icons.schedule;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "৳$amount via $method",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎯 PAYMENT STEPPER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentStepper(bool isDark, Color textColor) {
    return Row(
      children: [
        _stepIndicator(1, "Send Money", _currentStep >= 0, isDark),
        _stepLine(_currentStep >= 1, isDark),
        _stepIndicator(2, "Get TrxID", _currentStep >= 1, isDark),
        _stepLine(_currentStep >= 2, isDark),
        _stepIndicator(3, "Submit", _currentStep >= 2, isDark),
      ],
    );
  }

  Widget _stepIndicator(int step, String label, bool isActive, bool isDark) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.brandMain
                : (isDark ? Colors.grey[700] : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$step",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? AppColors.brandMain : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool isActive, bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive
            ? AppColors.brandMain
            : (isDark ? Colors.grey[700] : Colors.grey[300]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // EXISTING WIDGETS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryBox(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandMain.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planId.replaceAll('_', ' '),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandMain.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "৳${widget.amount}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandMain,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Duration:", style: TextStyle(color: Colors.grey)),
              Text(
                "${widget.duration} month${widget.duration > 1 ? 's' : ''}",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.withOpacity(0.1)
            : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Text(
                  "How to pay?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _instructionStep("1", "Select your payment method"),
            _instructionStep("2", "Send ৳${widget.amount} to the number shown"),
            _instructionStep("3", "Copy the Transaction ID (TrxID)"),
            _instructionStep("4", "Enter your number & TrxID below"),
            _instructionStep("5", "Submit and wait for verification"),
          ],
        ),
      ),
    );
  }

  Widget _instructionStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(bool isDark, Color cardColor, Color textColor) {
    return Column(
      children: _paymentMethods.keys.map((method) {
        final methodData = _paymentMethods[method]!;
        final isSelected = _selectedMethod == method;

        return GestureDetector(
          onTap: () => setState(() {
            _selectedMethod = method;
            _currentStep = 1;
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? methodData['color'].withOpacity(0.1)
                  : cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? methodData['color']
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: methodData['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    methodData['icon'],
                    color: methodData['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        methodData['number'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // QR Code Button
                    IconButton(
                      icon: Icon(Icons.qr_code, color: methodData['color']),
                      onPressed: _showQRCode,
                      tooltip: "Show QR",
                    ),
                    // Copy Button
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: methodData['color'],
                        size: 18,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: methodData['number']),
                        );
                        HapticFeedback.lightImpact();
                        _showSnack("$method number copied!", Colors.green);
                      },
                    ),
                    // Radio
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected ? methodData['color'] : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInputFields(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) {
    return Column(
      children: [
        TextFormField(
          controller: _senderController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: textColor),
          validator: _validatePhone,
          onChanged: (val) {
            if (val.isNotEmpty) setState(() => _currentStep = 2);
          },
          decoration: InputDecoration(
            labelText: "Your $_selectedMethod Number",
            hintText: "01XXXXXXXXX",
            labelStyle: TextStyle(color: hintColor),
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(
              Icons.phone,
              color: _paymentMethods[_selectedMethod]!['color'],
            ),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: AppColors.brandMain),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _trxIdController,
          style: TextStyle(color: textColor),
          validator: _validateTrxId,
          onChanged: (val) {
            if (val.length >= 8) setState(() => _currentStep = 3);
          },
          decoration: InputDecoration(
            labelText: "Transaction ID (TrxID)",
            hintText: "8N7X6W5V...",
            labelStyle: TextStyle(color: hintColor),
            hintStyle: TextStyle(color: hintColor),
            prefixIcon: const Icon(
              Icons.receipt_long,
              color: AppColors.brandMain,
            ),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: AppColors.brandMain),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isExpired =
        _remainingTime.isNegative || _remainingTime == Duration.zero;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (isExpired || _isSubmitting) ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: isExpired ? Colors.grey : AppColors.brandMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    isExpired ? "SESSION EXPIRED" : "SUBMIT PAYMENT INFO",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🆘 HELP CENTER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHelpCenter(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            "Need Help?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _helpButton(Icons.call, "Call", () {}),
              _helpButton(Icons.email, "Email", () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _helpButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandMain, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
