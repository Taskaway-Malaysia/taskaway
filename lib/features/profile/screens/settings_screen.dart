import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/controllers/auth_controller.dart';
import 'payment_options_screen.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Purple header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.posterPrimary,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home/profile');
                    }
                  },
                ),
                const Spacer(),
                Text(
                  'Settings',
                  style: AppTypography.headlineSmall.copyWith(color: AppColors.white),
                ),
                const Spacer(),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),

          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account section
                  _buildSectionHeader('Account'),
                  SizedBox(height: AppSpacing.lg),
                  _buildMenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Payment options',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentOptionsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.star_outline,
                    title: 'My review',
                    onTap: () {
                      context.go('/my-reviews');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Personal information',
                    onTap: () {
                      // TODO: Navigate to personal information screen
                    },
                  ),

                  SizedBox(height: AppSpacing.xxxl),

                  // Notifications settings section
                  _buildSectionHeader('Notifications settings'),
                  SizedBox(height: AppSpacing.lg),
                  _buildSwitchMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Push notification',
                    subtitle: 'Allow Taskaway to send notifications',
                    value: _pushNotificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                    },
                  ),

                  SizedBox(height: AppSpacing.xxxl),

                  // General section
                  _buildSectionHeader('General'),
                  SizedBox(height: AppSpacing.lg),
                  _buildMenuItem(
                    icon: Icons.security_outlined,
                    title: 'Settings & Authentication',
                    onTap: () {
                      // TODO: Navigate to settings & authentication screen
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help Centre',
                    onTap: () {
                      // TODO: Navigate to help centre screen
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {
                      // TODO: Navigate to terms & conditions screen
                    },
                  ),

                  SizedBox(height: AppSpacing.xxxl),

                  // Sign out
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Sign out',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Sign out'),
                          content: Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Sign out'),
                            ),
                          ],
                        ),
                      );
                      
                      if (shouldLogout == true) {
                        await ref.read(authControllerProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Icon(
          title == 'Account' 
              ? Icons.person_outline 
              : title == 'Notifications settings' 
                  ? Icons.notifications_outlined 
                  : Icons.settings_outlined,
          color: AppColors.textPrimary,
          size: 20,
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(width: 28), // Indent to align with section headers
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 28), // Indent to align with section headers
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.posterPrimary,
          ),
        ],
      ),
    );
  }
} 