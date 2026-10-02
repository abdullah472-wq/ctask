import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class ProfileVisitorActionBar extends StatelessWidget {
  final bool isDark;
  final bool isPaused;
  final bool hasPhone;
  final VoidCallback onCallTap;
  final VoidCallback onEmailTap;
  final VoidCallback onViewPostsTap;

  const ProfileVisitorActionBar({
    super.key,
    required this.isDark,
    required this.isPaused,
    required this.hasPhone,
    required this.onCallTap,
    required this.onEmailTap,
    required this.onViewPostsTap,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isDark ? const Color(0xFF2C2C2C) : AppColors.brandLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Call or Email
          if (hasPhone)
            _buildActionButton(
              icon: Icons.call_outlined,
              label: 'Call',
              color: Colors.green,
              onPressed: onCallTap,
            )
          else
            _buildActionButton(
              icon: Icons.email_outlined,
              label: 'Email',
              color: Colors.orange,
              onPressed: onEmailTap,
            ),

          const SizedBox(width: 12),

          // View Posts Button
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandMain,
                    AppColors.brandMain.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isPaused ? null : onViewPostsTap,
                  borderRadius: BorderRadius.circular(15),
                  child: Center(
                    child: Text(
                      isPaused ? 'UNAVAILABLE' : 'VIEW POSTS',
                      style: TextStyle(
                        color: isPaused ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
