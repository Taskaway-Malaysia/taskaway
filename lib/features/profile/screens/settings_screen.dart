import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/controllers/auth_controller.dart';
import 'payment_options_screen.dart';

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
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7), // Purple color
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home/profile');
                    }
                  },
                ),
                const Spacer(),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),

          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account section
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 16),
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

                  const SizedBox(height: 32),

                  // Notifications settings section
                  _buildSectionHeader('Notifications settings'),
                  const SizedBox(height: 16),
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

                  const SizedBox(height: 32),

                  // General section
                  _buildSectionHeader('General'),
                  const SizedBox(height: 16),
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

                  const SizedBox(height: 32),

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
                          title: const Text('Sign out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign out'),
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
          color: Colors.black87,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
                  color: titleColor ?? Colors.black87,
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
                    color: Colors.black87,
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
            activeColor: const Color(0xFF6C5CE7),
          ),
        ],
      ),
    );
  }
} 