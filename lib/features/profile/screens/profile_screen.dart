import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(children: [
        // Purple header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF6C5CE7), // Purple color from the image
          ),
          child: Row(children: [
            const Spacer(),
            const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon:
                  const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                context.push('/notifications');
              },
            ),
          ]),
        ),

        // Content area with user profile info
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // User profile card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    // User avatar, name and edit button
                    Row(children: [
                      // Avatar with initials
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade300,
                        child: Text(
                          user?.userMetadata?['name']
                                  ?.toString()
                                  .substring(0, 2)
                                  .toUpperCase() ??
                              'IR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and bio
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.userMetadata?['name']?.toString() ??
                                    'Ibrahim R.',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'My bio',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ]),
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF6C5CE7),
                        ),
                        onPressed: () {
                          // Handle edit profile
                        },
                      ),
                    ]),
                    const Divider(height: 32),
                    // Location info
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.grey.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text('From'),
                      const Spacer(),
                      const Text(
                        'Shah Alam',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Member since info
                    Row(children: [
                      Icon(Icons.person_outline,
                          color: Colors.grey.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Text('Member since'),
                      const Spacer(),
                      const Text(
                        'November 2023',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // About section
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Hello! I am a young adult who recently entered the working world. I signed up as a means to expand my income while simultaneously work on balancing my hectic life.',
                          style: TextStyle(height: 1.5),
                        ),
                      ]),
                ),
              ),

              // Skills section
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Skills',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSkillChip('Painting'),
                              _buildSkillChip('General Repairs'),
                              _buildSkillChip('Flooring'),
                              _buildSkillChip('Landscaping'),
                            ],
                          ),
                        ),
                      ]),
                ),
              ),

              // My works section
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: List.generate(
                            4,
                            (index) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6C5CE7),
        ),
      ),
    );
  }
}
