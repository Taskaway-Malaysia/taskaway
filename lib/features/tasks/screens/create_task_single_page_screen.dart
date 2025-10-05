import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import '../../auth/controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import '../../../core/services/analytics_service.dart';
import 'map_location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

final createTaskSinglePageDataProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'category': 'cleaning',
      'title': '',
      'description': '',
      'scheduledTime': DateTime.now().add(const Duration(days: 1)),
      'location': '',
      'price': 0.0,
      'dateOption': 'on_date',
      'needsSpecificTime': false,
      'timeOfDay': null,
      'locationType': 'physical',
      'providesMaterials': false,
      'images': <dynamic>[],
    });

class CreateTaskSinglePageScreen extends ConsumerStatefulWidget {
  const CreateTaskSinglePageScreen({super.key});

  @override
  ConsumerState<CreateTaskSinglePageScreen> createState() => _CreateTaskSinglePageScreenState();
}

class _CreateTaskSinglePageScreenState extends ConsumerState<CreateTaskSinglePageScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskData = ref.read(createTaskSinglePageDataProvider);
      _titleController.text = taskData['title'] ?? '';
      _descriptionController.text = taskData['description'] ?? '';
      _locationController.text = taskData['location'] ?? '';
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final taskData = ref.read(createTaskSinglePageDataProvider);
    LatLng? initialLocation;

    // If location already selected, use those coordinates
    if (taskData['latitude'] != null && taskData['longitude'] != null) {
      initialLocation = LatLng(
        taskData['latitude'],
        taskData['longitude'],
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPickerScreen(
          initialLocation: initialLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      final locationData = result as Map<String, dynamic>;
      final updatedTaskData = Map<String, dynamic>.from(taskData);
      updatedTaskData['location'] = locationData['address'];
      updatedTaskData['latitude'] = locationData['latitude'];
      updatedTaskData['longitude'] = locationData['longitude'];
      ref.read(createTaskSinglePageDataProvider.notifier).state = updatedTaskData;
      _locationController.text = locationData['address'];

      print('Location updated: ${locationData['address']}');
      print('Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final taskData = ref.read(createTaskSinglePageDataProvider);

    // Validate price
    final price = taskData['price'];
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set the task price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate payment method selection
    final paymentMethod = taskData['paymentMethod'];
    if (paymentMethod == null || paymentMethod.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider)!;
      String category = taskData['category'] ?? 'cleaning';

      final createdTask = await ref.read(taskControllerProvider).createTask(
            title: _titleController.text,
            description: _descriptionController.text,
            category: category,
            price: price,
            location: _locationController.text,
            scheduledTime: taskData['scheduledTime'] ?? DateTime.now(),
            posterId: user.id,
            dateOption: taskData['dateOption'],
            needsSpecificTime: taskData['needsSpecificTime'],
            timeOfDay: taskData['timeOfDay'],
            locationType: taskData['locationType'],
            providesMaterials: taskData['providesMaterials'],
            images: taskData['images'] is List ? taskData['images'] : <dynamic>[],
            latitude: taskData['latitude'] as double?,
            longitude: taskData['longitude'] as double?,
            paymentMethod: paymentMethod as String?,
          );

      final analytics = ref.read(analyticsServiceProvider);
      await analytics.logTaskCreated(
        taskId: createdTask.id,
        category: category,
        price: price,
      );

      // If payment method is online banking, initiate CHIP payment
      if (paymentMethod == 'online_banking') {
        dev.log('[CreateTask] Task created successfully with ID: ${createdTask.id}');
        dev.log('[CreateTask] Initiating CHIP payment for task ${createdTask.id}');

        try {
          // Small delay to ensure task is committed to database
          await Future.delayed(const Duration(milliseconds: 500));

          // Call Supabase Edge Function to create CHIP payment
          final supabase = Supabase.instance.client;
          dev.log('[CreateTask] Calling chip-create-payment with taskId: ${createdTask.id}, posterId: ${user.id}');

          final response = await supabase.functions.invoke(
            'chip-create-payment',
            body: {
              'taskId': createdTask.id,
              'amount': price,
              'posterId': user.id,
              'posterEmail': user.email,
              'taskTitle': _titleController.text,
              'posterName': user.userMetadata?['full_name'],
            },
          );

          dev.log('[CreateTask] CHIP payment RAW response: ${response.toString()}');
          dev.log('[CreateTask] CHIP payment response.data: ${response.data}');
          dev.log('[CreateTask] CHIP payment response.data type: ${response.data.runtimeType}');

          if (response.data == null) {
            throw Exception('No response from payment service');
          }

          if (response.data['success'] != true) {
            final error = response.data['error'] ?? 'Failed to create payment';
            dev.log('[CreateTask] Payment creation failed: $error');
            throw Exception(error);
          }

          final checkoutUrl = response.data['checkout_url'];
          if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
            dev.log('[CreateTask] Missing checkout_url in response: ${response.data}');
            throw Exception('Payment service did not return checkout URL');
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // Navigate to CHIP payment screen
            context.go('/chip-payment', extra: {
              'checkoutUrl': checkoutUrl,
              'taskId': createdTask.id,
              'amount': price,
              'taskTitle': _titleController.text,
            });
          }
        } catch (paymentError) {
          dev.log('[CreateTask] Payment initialization error: $paymentError');

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // Show error and allow user to try again or change payment method
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('Payment Initialization Failed'),
                content: Text(
                  'Failed to initialize online banking payment: ${paymentError.toString()}\n\nYour task has been created but payment could not be processed. Please try again or contact support.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/home/browse/${createdTask.id}');
                    },
                    child: Text('View Task'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      } else {
        // For other payment methods (cash, taskaway_credit), navigate to waiting screen
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          context.go('/waiting-for-tasker/${createdTask.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final taskData = Map<String, dynamic>.from(ref.read(createTaskSinglePageDataProvider));
      final images = taskData['images'] as List? ?? [];

      if (images.length >= 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only add up to 5 images')),
          );
        }
        return;
      }

      if (kIsWeb) {
        images.add(pickedFile);
      } else {
        final imageFile = File(pickedFile.path);
        images.add(imageFile);
      }

      taskData['images'] = images;
      ref.read(createTaskSinglePageDataProvider.notifier).state = taskData;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  void _removeImage(dynamic image) {
    final taskData = Map<String, dynamic>.from(ref.read(createTaskSinglePageDataProvider));
    final images = taskData['images'] as List;
    images.remove(image);

    taskData['images'] = images;
    ref.read(createTaskSinglePageDataProvider.notifier).state = taskData;
  }

  Widget _buildImagePreview(dynamic imageObj) {
    if (kIsWeb) {
      if (imageObj is XFile) {
        return Image.network(
          imageObj.path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Icon(Icons.broken_image, color: Colors.red));
          },
        );
      }
    }
    if (imageObj is File) {
      return Image.file(
        imageObj,
        fit: BoxFit.cover,
      );
    }
    return const Center(child: Icon(Icons.image_not_supported));
  }

  Future<void> _showDatePicker(BuildContext context, bool isEndDate) async {
    final taskData = ref.read(createTaskSinglePageDataProvider);
    final initialDate = taskData['scheduledTime'] as DateTime? ?? DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFDB5B),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final updatedData = Map<String, dynamic>.from(taskData);
      updatedData['scheduledTime'] = pickedDate;

      if (isEndDate) {
        final dateFormat = DateFormat('EEEE, d MMMM');
        updatedData['beforeDateText'] = 'Before ${dateFormat.format(pickedDate)}';
      }

      ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
    }
  }

  Widget _buildDateOption(String value, String label, {String? dateText}) {
    final taskData = ref.watch(createTaskSinglePageDataProvider);
    final isSelected = taskData['dateOption'] == value;

    return InkWell(
      onTap: () {
        final updatedData = Map<String, dynamic>.from(taskData);
        updatedData['dateOption'] = value;
        ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;

        if (value == 'on_date' || value == 'before_date') {
          _showDatePicker(context, value == 'before_date');
        }
      },
      borderRadius: AppRadius.smMd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFDB5B).withOpacity(0.2) : AppColors.white,
          borderRadius: AppRadius.smMd,
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC333) : const Color(0xFFE4E4E4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          dateText ?? label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeOption(String value, String label, String timeRange, IconData icon) {
    final taskData = ref.watch(createTaskSinglePageDataProvider);
    final isSelected = taskData['timeOfDay'] == value;

    return InkWell(
      onTap: () {
        final updatedData = Map<String, dynamic>.from(taskData);
        updatedData['timeOfDay'] = value;
        ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
      },
      borderRadius: AppRadius.smMd,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC333) : const Color(0xFFE4E4E4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.smMd,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              timeRange,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF788494),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationType(String value, String label, String description, IconData icon) {
    final taskData = ref.watch(createTaskSinglePageDataProvider);
    final isSelected = taskData['locationType'] == value;

    return InkWell(
      onTap: () {
        final updatedData = Map<String, dynamic>.from(taskData);
        updatedData['locationType'] = value;
        if (_locationController.text.isNotEmpty) {
          updatedData['location'] = _locationController.text;
        }
        ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
      },
      borderRadius: AppRadius.smMd,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC333) : const Color(0xFFE4E4E4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.smMd,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.textPrimary,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF788494),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodDisplayText(String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.isEmpty) {
      return 'Select payment';
    }

    switch (paymentMethod) {
      case 'cash':
        return 'Cash payment';
      case 'online_banking':
        return 'Online banking';
      case 'taskaway_credit':
        return 'Taskaway credit';
      default:
        return 'Select payment';
    }
  }

  Widget _buildPaymentMethodOption(
    String value,
    String label,
    String description,
    IconData icon,
    Map<String, dynamic> taskData,
    WidgetRef ref, {
    bool isComingSoon = false,
  }) {
    final isSelected = taskData['paymentMethod'] == value;

    return InkWell(
      onTap: isComingSoon
          ? null
          : () {
              final updatedData = Map<String, dynamic>.from(taskData);
              updatedData['paymentMethod'] = value;
              ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
            },
      borderRadius: AppRadius.smMd,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC333) : const Color(0xFFE4E4E4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.smMd,
          color: isComingSoon ? const Color(0xFFF5F5F5) : AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFDB5B).withOpacity(0.2) : const Color(0xFFF5F5F5),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isComingSoon ? const Color(0xFF788494) : Colors.black,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isComingSoon ? const Color(0xFF788494) : const Color(0xFF000000),
                        ),
                      ),
                      if (isComingSoon) ...[
                        SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDB5B).withOpacity(0.25),
                            borderRadius: AppRadius.smMd,
                          ),
                          child: Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF788494),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: taskData['paymentMethod'] as String?,
              onChanged: isComingSoon
                  ? null
                  : (newValue) {
                      final updatedData = Map<String, dynamic>.from(taskData);
                      updatedData['paymentMethod'] = newValue;
                      ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
                    },
              activeColor: const Color(0xFFFFDB5B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricePaymentRow(Map<String, dynamic> taskData) {
    final price = taskData['price'] ?? 0.0;
    final paymentMethod = taskData['paymentMethod'];

    final priceText = 'RM ${price.toStringAsFixed(2)}';
    final paymentText = _getPaymentMethodDisplayText(paymentMethod);

    final hasValues = price > 0 && paymentMethod != null && paymentMethod.toString().isNotEmpty;

    return InkWell(
      onTap: () => _showPricePaymentModal(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE4E4E4)),
          borderRadius: AppRadius.smMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price • Payment method',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.24,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$priceText • $paymentText',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasValues ? const Color(0xFF000000) : const Color(0xFF788494),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF788494)),
          ],
        ),
      ),
    );
  }

  Future<void> _showPricePaymentModal() async {
    final taskData = ref.read(createTaskSinglePageDataProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PricePaymentModalContent(
        initialPrice: taskData['price'] != null && taskData['price'] > 0
            ? taskData['price'].toString()
            : '',
        initialPayment: taskData['paymentMethod'],
        onConfirm: (price, paymentMethod) {
          final updatedData = Map<String, dynamic>.from(taskData);
          updatedData['price'] = price;
          updatedData['paymentMethod'] = paymentMethod;
          ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskData = ref.watch(createTaskSinglePageDataProvider);
    final selectedCategory = taskData['category'];
    final scheduledTime = taskData['scheduledTime'] as DateTime;
    final dateFormat = DateFormat('EEEE, d MMMM');

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8E9F1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: AppSpacing.lg),
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Post a Task',
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter task title',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Describe your task',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.smMd,
                            borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 33,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: const Color(0xFFE4E4E4)),
                          borderRadius: AppRadius.smMd,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                              DropdownMenuItem(value: 'handyman', child: Text('Handyman')),
                              DropdownMenuItem(value: 'gardening', child: Text('Gardening')),
                              DropdownMenuItem(value: 'painting', child: Text('Painting')),
                              DropdownMenuItem(value: 'organizing', child: Text('Organizing')),
                              DropdownMenuItem(value: 'pet_care', child: Text('Pet Care')),
                              DropdownMenuItem(value: 'self_care', child: Text('Self Care')),
                              DropdownMenuItem(value: 'events_photography', child: Text('Events & Photography')),
                              DropdownMenuItem(value: 'others', child: Text('Others')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                final updatedData = Map<String, dynamic>.from(taskData);
                                updatedData['category'] = value;
                                ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Date & Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _buildDateOption('on_date', 'On date',
                          dateText: taskData['dateOption'] == 'on_date'
                              ? 'On ${dateFormat.format(scheduledTime)}'
                              : null),
                      SizedBox(height: AppSpacing.sm),
                      _buildDateOption('before_date', 'Before date',
                          dateText: taskData['beforeDateText'] ??
                              'Before ${dateFormat.format(scheduledTime)}'),
                      SizedBox(height: AppSpacing.sm),
                      _buildDateOption('any_day', 'Any day'),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Checkbox(
                            value: taskData['needsSpecificTime'] ?? false,
                            onChanged: (value) {
                              final updatedData = Map<String, dynamic>.from(taskData);
                              updatedData['needsSpecificTime'] = value;
                              if (value == false) {
                                updatedData['timeOfDay'] = null;
                              }
                              ref.read(createTaskSinglePageDataProvider.notifier).state = updatedData;
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.sm,
                            ),
                            activeColor: const Color(0xFFFFDB5B),
                          ),
                          Text('I need a certain time of the day'),
                        ],
                      ),
                      if (taskData['needsSpecificTime'] == true) ...[
                        SizedBox(height: AppSpacing.md),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.0,
                          children: [
                            _buildTimeOption('morning', 'Morning', '8AM - 12PM', Icons.wb_sunny_outlined),
                            _buildTimeOption('afternoon', 'Afternoon', '12PM - 5PM', Icons.wb_sunny),
                            _buildTimeOption('evening', 'Evening', '5PM - 8PM', Icons.wb_twilight),
                            _buildTimeOption('night', 'Night', 'After 8PM', Icons.nightlight_round),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLocationType('physical', 'Physical',
                                'In-person help', Icons.place_outlined),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildLocationType(
                                'online', 'Online', 'Done remotely', Icons.language),
                          ),
                        ],
                      ),
                      if (taskData['locationType'] == 'physical') ...[
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: _openMapPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE4E4E4)),
                              borderRadius: AppRadius.smMd,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.map, size: 20, color: Color(0xFF788494)),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    taskData['location'] != null && taskData['location'].toString().isNotEmpty
                                        ? taskData['location']
                                        : 'Select location on map',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: taskData['location'] != null && taskData['location'].toString().isNotEmpty
                                          ? const Color(0xFF000000)
                                          : const Color(0xFF788494),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                const Icon(Icons.chevron_right, size: 20, color: Color(0xFF788494)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Photos (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          InkWell(
                            onTap: _pickImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE4E4E4)),
                                borderRadius: AppRadius.smMd,
                              ),
                              child: const Icon(Icons.add, color: Color(0xFF788494)),
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          if (taskData['images'] != null &&
                              (taskData['images'] as List).isNotEmpty)
                            Expanded(
                              child: SizedBox(
                                height: 80,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: (taskData['images'] as List).length,
                                  separatorBuilder: (context, index) => SizedBox(width: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    final image = (taskData['images'] as List)[index];
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 80,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: AppRadius.smMd,
                                            border: Border.all(
                                              color: const Color(0xFFE4E4E4),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: AppRadius.smMd,
                                            child: _buildImagePreview(image),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(image),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildPricePaymentRow(taskData),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom button with shadow
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDB5B),
                      foregroundColor: const Color(0xFF000000),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.md,
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Text(
                            'Find tasker',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
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

// Modal widget for price and payment selection
class _PricePaymentModalContent extends StatefulWidget {
  final String initialPrice;
  final String? initialPayment;
  final Function(double, String) onConfirm;

  const _PricePaymentModalContent({
    required this.initialPrice,
    required this.initialPayment,
    required this.onConfirm,
  });

  @override
  State<_PricePaymentModalContent> createState() => _PricePaymentModalContentState();
}

class _PricePaymentModalContentState extends State<_PricePaymentModalContent> {
  late TextEditingController _priceController;
  String? _selectedPayment;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.initialPrice);
    _selectedPayment = widget.initialPayment;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Header with drag handle
              Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E4E4),
                      borderRadius: AppRadius.xs,
                    ),
                  ),
                  // Title and close button
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Price & Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 24, color: Color(0xFF000000)),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E4)),
                ],
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Section
                      Text(
                        'Task Price *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          hintText: 'RM 0.00',
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF788494),
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md,
                            borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.md,
                            borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.md,
                            borderSide: const BorderSide(color: Color(0xFFFFDB5B), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF000000),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          // Update in real-time for immediate feedback
                          setState(() {});
                        },
                      ),

                      SizedBox(height: AppSpacing.xxl),

                      // Payment Method Section
                      Text(
                        'Payment Method *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.24,
                          color: Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Choose how you want to pay',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF788494),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),

                      // Payment Options
                      _buildPaymentMethodOption(
                        'taskaway_credit',
                        'Taskaway Credit',
                        'Pay using your wallet balance',
                        Icons.account_balance_wallet,
                        isComingSoon: true,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _buildPaymentMethodOption(
                        'cash',
                        'Cash',
                        'Pay in person after task completion',
                        Icons.money,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _buildPaymentMethodOption(
                        'online_banking',
                        'Online Banking',
                        'FPX / Credit Card / GrabPay',
                        Icons.credit_card,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Confirm Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDB5B),
                      foregroundColor: const Color(0xFF000000),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.md,
                      ),
                    ),
                    onPressed: () {
                      // Validate
                      final price = double.tryParse(_priceController.text);
                      if (price == null || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid price'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (_selectedPayment == null || _selectedPayment!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a payment method'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Call the onConfirm callback
                      widget.onConfirm(price, _selectedPayment!);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildPaymentMethodOption(
    String value,
    String label,
    String description,
    IconData icon, {
    bool isComingSoon = false,
  }) {
    final isSelected = _selectedPayment == value;

    return InkWell(
      onTap: isComingSoon
          ? null
          : () {
              setState(() {
                _selectedPayment = value;
              });
            },
      borderRadius: AppRadius.md,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFFDB5B) : const Color(0xFFE4E4E4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.md,
          color: isComingSoon ? const Color(0xFFF8F8F8) : AppColors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFDB5B).withOpacity(0.15)
                    : const Color(0xFFF5F5F5),
                borderRadius: AppRadius.md,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isComingSoon ? const Color(0xFF788494) : const Color(0xFF000000),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isComingSoon ? const Color(0xFF788494) : const Color(0xFF000000),
                        ),
                      ),
                      if (isComingSoon) ...[
                        SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDB5B).withOpacity(0.25),
                            borderRadius: AppRadius.smMd,
                          ),
                          child: Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF788494),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPayment,
              onChanged: isComingSoon
                  ? null
                  : (newValue) {
                      setState(() {
                        _selectedPayment = newValue;
                      });
                    },
              activeColor: const Color(0xFFFFDB5B),
            ),
          ],
        ),
      ),
    );
  }
}