import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileScreenNew extends ConsumerWidget {
  const ProfileScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8E9F1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                child: profileAsync.when(
                  data: (profile) => Column(
                    children: [
                      // User Info Card
                      _UserInfoCard(
                        name: profile?.fullName ?? 'Guest User',
                        rating: 5.0,
                        avatarUrl: profile?.avatarUrl,
                      ),
                      const SizedBox(height: 14),
                      // Location Card
                      _InfoCard(
                        children: [
                          _InfoRow(
                            label: 'From',
                            value: profile?.postcode != null
                                ? 'Postcode ${profile!.postcode}'
                                : 'Add your location',
                            isPlaceholder: profile?.postcode == null,
                          ),
                          const SizedBox(height: 14),
                          _InfoRow(
                            label: 'Member since',
                            value: profile?.createdAt != null
                                ? DateFormat('MMMM yyyy').format(profile!.createdAt!)
                                : 'November 2023',
                            isPlaceholder: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // About Card
                      _EditableInfoCard(
                        title: 'About',
                        content: profile?.bio ?? 'Add information about yourself to let others know more about you.',
                        isPlaceholder: profile?.bio == null,
                        onEdit: () {
                          // TODO: Navigate to edit about
                        },
                      ),
                      const SizedBox(height: 14),
                      // Skills Card
                      _EditableInfoCard(
                        title: 'Skills',
                        content: 'Please add your skills',
                        isPlaceholder: true,
                        onEdit: () {
                          // TODO: Navigate to edit skills
                        },
                      ),
                      const SizedBox(height: 14),
                      // My Works Card
                      _MyWorksCard(),
                    ],
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading profile',
                      style: TextStyle(
                        fontFamily: 'Instrument Sans',
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  final String name;
  final double rating;
  final String? avatarUrl;

  const _UserInfoCard({
    required this.name,
    required this.rating,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE4E4E4),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                          style: const TextStyle(
                            fontFamily: 'Instrument Sans',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF788494),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              // Name and Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.24,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Star rating
                  Row(
                    children: List.generate(5, (index) {
                      return const Icon(
                        Icons.star,
                        size: 17,
                        color: Color(0xFFFCC133),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          // Edit button
          InkWell(
            onTap: () {
              // TODO: Navigate to edit profile
            },
            child: Container(
              width: 14,
              height: 14,
              child: const Icon(
                Icons.edit,
                size: 12,
                color: Color(0xFFFCC133),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPlaceholder;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.22,
            color: Color(0xFF000000),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Instrument Sans',
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1.22,
            letterSpacing: 0.2,
            color: isPlaceholder ? const Color(0xFF788494) : const Color(0xFF788494),
          ),
        ),
      ],
    );
  }
}

class _EditableInfoCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isPlaceholder;
  final VoidCallback onEdit;

  const _EditableInfoCard({
    required this.title,
    required this.content,
    required this.isPlaceholder,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.22,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'Instrument Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.22,
                    letterSpacing: 0.2,
                    color: isPlaceholder ? const Color(0xFF788494) : const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            child: Container(
              width: 14,
              height: 14,
              child: const Icon(
                Icons.edit,
                size: 12,
                color: Color(0xFFFCC133),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My works',
                    style: TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.22,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 11),
                  const Text(
                    'Please add your skills',
                    style: TextStyle(
                      fontFamily: 'Instrument Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 1.22,
                      letterSpacing: 0.2,
                      color: Color(0xFF788494),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  // TODO: Navigate to edit works
                },
                child: Container(
                  width: 14,
                  height: 14,
                  child: const Icon(
                    Icons.edit,
                    size: 12,
                    color: Color(0xFFFCC133),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Work thumbnails
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                child: Container(
                  width: 107,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE4E4E4)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 15,
                      color: Color(0xFF777676),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}