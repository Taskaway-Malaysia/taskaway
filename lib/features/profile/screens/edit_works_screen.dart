import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/image_picker_grid.dart';

class EditWorksScreen extends ConsumerStatefulWidget {
  const EditWorksScreen({super.key});

  @override
  ConsumerState<EditWorksScreen> createState() => _EditWorksScreenState();
}

class _EditWorksScreenState extends ConsumerState<EditWorksScreen> {
  List<String> _workImages = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserWorks();
    });
  }

  void _loadUserWorks() {
    final profileAsync = ref.read(currentProfileProvider);
    profileAsync.when(
      data: (profile) {
        if (profile != null && !_isInitialized) {
          setState(() {
            _workImages = List.from(profile.myWorks ?? []);
            _isInitialized = true;
          });
        }
      },
      loading: () {},
      error: (_, __) {
        setState(() {
          _isInitialized = true;
        });
      },
    );
  }

  Future<void> _saveWorks() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = await ref.read(profileControllerProvider).updateWorks(
        userId: user.id,
        workUrls: _workImages,
      );

      if (mounted && profile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Works updated successfully'),
            backgroundColor: Color(0xFF6C5CE7),
          ),
        );
        
        // Invalidate profile provider to refresh data
        ref.invalidate(currentProfileProvider);
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating works: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: Column(
        children: [
          // Purple header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'My works',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload section
                  const Text(
                    'Showcase your previous work',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload images of your completed work',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image picker grid
                  if (_isInitialized && user != null)
                    ImagePickerGrid(
                      initialImages: _workImages,
                      onImagesChanged: (images) {
                        setState(() {
                          _workImages = images;
                        });
                      },
                      userId: user.id,
                      enabled: !_isLoading,
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(),
                    ),

                  const SizedBox(height: 40),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveWorks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}