import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/task_controller.dart';

// Provider to track current step in task creation process
final createTaskStepProvider = StateProvider<int>((ref) => 0);

// Provider to store task data during creation process
final createTaskDataProvider = StateProvider<Map<String, dynamic>>((ref) => {
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
  'images': <File>[],
});

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers for form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset step to 0 when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createTaskStepProvider.notifier).state = 0;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Handle final submission of the task
  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = ref.read(currentUserProvider)!;
      final taskData = ref.read(createTaskDataProvider);
      
      await ref.read(taskControllerProvider).createTask(
        title: taskData['title'],
        description: taskData['description'],
        category: taskData['category'],
        price: taskData['price'],
        location: taskData['location'],
        scheduledTime: taskData['scheduledTime'],
        posterId: user.id,
        dateOption: taskData['dateOption'],
        needsSpecificTime: taskData['needsSpecificTime'],
        timeOfDay: taskData['timeOfDay'],
        locationType: taskData['locationType'],
        providesMaterials: taskData['providesMaterials'],
        images: taskData['images'],
      );

      if (mounted) {
        // Show task posted success screen instead of popping
        ref.read(createTaskStepProvider.notifier).state = 4;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create task: ${e.toString()}';
      });
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to next step if current step is valid
  void _goToNextStep() async {
    final currentStep = ref.read(createTaskStepProvider);
    
    // Validate current step if it has a form
    if (currentStep < _formKeys.length && 
        _formKeys[currentStep].currentState != null && 
        !_formKeys[currentStep].currentState!.validate()) {
      return;
    }
    
    // Save data from current step
    _saveCurrentStepData(currentStep);
    
    // Move to next step
    if (currentStep < 3) {
      ref.read(createTaskStepProvider.notifier).state = currentStep + 1;
    } else {
      // Submit the form if on the last step
      await _handleSubmit();
    }
  }

  // Go back to previous step
  void _goToPreviousStep() {
    final currentStep = ref.read(createTaskStepProvider);
    if (currentStep > 0) {
      ref.read(createTaskStepProvider.notifier).state = currentStep - 1;
    } else {
      // If on first step, go back to previous screen
      context.pop();
    }
  }

  // Save data from current step to provider
  void _saveCurrentStepData(int step) {
    final taskData = Map<String, dynamic>.from(ref.read(createTaskDataProvider));
    
    switch (step) {
      case 0: // Category and Title/Description step
        taskData['title'] = _titleController.text;
        taskData['description'] = _descriptionController.text;
        // Category is saved directly when selected
        break;
      case 1: // Date and time step
        // Date/time is saved when selected
        break;
      case 2: // Location and budget step
        taskData['location'] = _locationController.text;
        if (_priceController.text.isNotEmpty) {
          taskData['price'] = double.tryParse(_priceController.text) ?? 0.0;
        }
        // Save location type and materials provision
        taskData['locationType'] = taskData['locationType'] ?? 'Physical';
        taskData['providesMaterials'] = taskData['providesMaterials'] ?? false;
        // Images are saved directly when selected
        break;
      case 3: // Confirmation step
        // No data to save in confirmation step
        break;
    }
    
    ref.read(createTaskDataProvider.notifier).state = taskData;
  }

  // Load data into form fields when step changes
  void _loadStepData(int step) {
    final taskData = ref.read(createTaskDataProvider);
    
    switch (step) {
      case 0: // Category and Title/Description step
        _titleController.text = taskData['title'] ?? '';
        _descriptionController.text = taskData['description'] ?? '';
        break;
      case 2: // Location and budget step
        _locationController.text = taskData['location'] ?? '';
        _priceController.text = taskData['price'] > 0 
            ? taskData['price'].toString() 
            : '';
        break;
      default:
        break;
    }
  }

  // Select date and time for the task
  Future<void> _selectDateTime() async {
    final taskData = Map<String, dynamic>.from(ref.read(createTaskDataProvider));
    final currentDateTime = taskData['scheduledTime'] ?? DateTime.now().add(const Duration(days: 1));
    
    final date = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentDateTime),
    );
    if (time == null) return;

    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    
    taskData['scheduledTime'] = newDateTime;
    ref.read(createTaskDataProvider.notifier).state = taskData;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = ref.watch(createTaskStepProvider);
    final taskData = ref.watch(createTaskDataProvider);
    
    // Load data when step changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStepData(currentStep);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C5CE7), // Purple color from other screens
        foregroundColor: Colors.white,
        title: const Text(
          'Post a Task',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: currentStep == 4 ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToPreviousStep,
        ),
      ),
      body: Column(
        children: [
          // Step indicator - only show if not on success screen
          if (currentStep != 4)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= currentStep 
                          ? const Color(0xFF6C5CE7) // Purple color from other screens
                          : Colors.grey.shade300,
                      border: index == currentStep 
                          ? Border.all(color: const Color(0xFF6C5CE7), width: 2) // Purple color from other screens
                          : null,
                    ),
                  );
                }),
              ),
            ),
          
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(currentStep, theme),
            ),
          ),
          
          // Continue button or Go to My Tasks button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7), // Purple color from other screens
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : currentStep == 4 
                    ? () => context.go('/tasks') // Navigate to tasks screen
                    : _goToNextStep,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(currentStep == 4 
                        ? 'Go to My Tasks'
                        : currentStep == 3 ? 'Post Task' : 'Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build content for each step
  Widget _buildStepContent(int step, ThemeData theme) {
    switch (step) {
      case 0:
        return _buildCategoryAndTitleStep(theme);
      case 1:
        return _buildDateTimeStep(theme);
      case 2:
        return _buildLocationBudgetStep(theme);
      case 3:
        return _buildConfirmationStep(theme);
      case 4:
        return _buildTaskPostedScreen(theme);
      default:
        return const SizedBox.shrink();
    }
  }
  
  // Task posted success screen
  Widget _buildTaskPostedScreen(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        // Success checkmark icon
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF6C5CE7),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your task is posted',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        const Text(
          'Here\'s what\'s next:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 24),
        _buildNextStep(1, 'Taskers will make offers'),
        const SizedBox(height: 16),
        _buildNextStep(2, 'Accept an offer'),
        const SizedBox(height: 16),
        _buildNextStep(3, 'Chat and get your task done!'),
        const Spacer(),
      ],
    );
  }
  
  // Helper widget to build next step item
  Widget _buildNextStep(int stepNumber, String text) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF2D3A8C),
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // Step 1: Category and Title/Description
  Widget _buildCategoryAndTitleStep(ThemeData theme) {
    final taskData = ref.watch(createTaskDataProvider);
    final selectedCategory = taskData['category'];
    
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Category selection
          _buildCategoryOption('painting', 'Painting', selectedCategory, theme),
          const SizedBox(height: 24),
          
          // Title field
          const Text(
            'Start with a title',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'In a few words, what do you need done?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Paint my gate',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Description field
          const Text(
            'Describe the task',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Summarize the key details',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'I am looking to hire a professional painter',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Category option widget
  Widget _buildCategoryOption(String value, String label, String selectedValue, ThemeData theme) {
    final isSelected = value == selectedValue;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          final taskData = Map<String, dynamic>.from(ref.read(createTaskDataProvider));
          taskData['category'] = value;
          ref.read(createTaskDataProvider.notifier).state = taskData;
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 4: Confirmation step
  Widget _buildConfirmationStep(ThemeData theme) {
    final taskData = ref.watch(createTaskDataProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ready to post your task?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Post the task when you\'re ready',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        
        // Task details list
        _buildTaskDetailItem(
          Icons.category_outlined,
          taskData['category'] ?? 'None',
          onEdit: () => ref.read(createTaskStepProvider.notifier).state = 0,
        ),
        _buildTaskDetailItem(
          Icons.title_outlined,
          taskData['title'] ?? 'No title',
          onEdit: () => ref.read(createTaskStepProvider.notifier).state = 0,
        ),
        _buildTaskDetailItem(
          Icons.description_outlined,
          taskData['description'] ?? 'No description',
          onEdit: () => ref.read(createTaskStepProvider.notifier).state = 0,
        ),
        _buildTaskDetailItem(
          Icons.calendar_today_outlined,
          'Before ${DateFormat('EEEE, d MMMM').format(taskData['scheduledTime'] ?? DateTime.now())}',
          onEdit: () => ref.read(createTaskStepProvider.notifier).state = 1,
        ),
        if (taskData['needsSpecificTime'] == true && taskData['timeOfDay'] != null)
          _buildTaskDetailItem(
            Icons.access_time_outlined,
            _getTimeOfDayText(taskData['timeOfDay']),
            onEdit: () => ref.read(createTaskStepProvider.notifier).state = 1,
          ),
        _buildTaskDetailItem(
          Icons.location_on_outlined,
          taskData['location'] ?? 'No location',
          onEdit: () => ref.read(createTaskStepProvider.notifier).state = 2,
        ),
        _buildTaskDetailItem(
          Icons.attach_money_outlined,
          'MYR ${taskData['price'] ?? '0'}${taskData['providesMaterials'] == true ? ' (Only paints are provided)' : ''}',
          onEdit: () => ref.read(createTaskStepProvider.notifier).state = 2,
        ),
      ],
    );
  }
  
  // Helper widget to build task detail item with edit button
  Widget _buildTaskDetailItem(IconData icon, String text, {required VoidCallback onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: onEdit,
            color: const Color(0xFF6C5CE7),
          ),
        ],
      ),
    );
  }

  // Helper method to get the time of day text
  String _getTimeOfDayText(String timeOfDay) {
    switch (timeOfDay) {
      case 'morning':
        return 'Morning (8AM - 12PM)';
      case 'afternoon':
        return 'Afternoon (12PM - 5PM)';
      case 'evening':
        return 'Evening (5PM - 8PM)';
      case 'night':
        return 'Night (After 8PM)';
      default:
        return 'Not specified';
    }
  }

  // Step 3: Date and time selection
  Widget _buildDateTimeStep(ThemeData theme) {
    final taskData = ref.watch(createTaskDataProvider);
    final scheduledTime = taskData['scheduledTime'] as DateTime;
    final dateFormat = DateFormat('EEEE, d MMMM');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a date & time',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'When do you need this task to be done?',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        
        // Date options
        _buildDateOption('on_date', 'On date', theme, 
          dateText: taskData['dateOption'] == 'on_date' ? 'On ${dateFormat.format(scheduledTime)}' : null),
        const SizedBox(height: 12),
        _buildDateOption('before_date', 'Before date', theme, 
          dateText: taskData['beforeDateText'] ?? 'Before ${dateFormat.format(scheduledTime)}'),
        const SizedBox(height: 12),
        _buildDateOption('any_day', 'Any day', theme),
        
        const SizedBox(height: 24),
        
        // Time of day checkbox
        Row(
          children: [
            Checkbox(
              value: taskData['needsSpecificTime'] ?? false,
              onChanged: (value) {
                final updatedData = Map<String, dynamic>.from(taskData);
                updatedData['needsSpecificTime'] = value;
                // Reset timeOfDay if unchecking
                if (value == false) {
                  updatedData['timeOfDay'] = null;
                }
                ref.read(createTaskDataProvider.notifier).state = updatedData;
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: const Color(0xFF6C5CE7),
            ),
            const Text('I need a certain time of the day'),
          ],
        ),
        
        // Time selection grid - only show when checkbox is checked
        if (taskData['needsSpecificTime'] == true) ...[  
          const SizedBox(height: 24),
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
      ],
    );
  }

  // Time option widget for the grid
  Widget _buildTimeOption(String value, String label, String timeRange, IconData icon) {
    final taskData = ref.watch(createTaskDataProvider);
    final isSelected = taskData['timeOfDay'] == value;
    
    return InkWell(
      onTap: () {
        final updatedData = Map<String, dynamic>.from(taskData);
        updatedData['timeOfDay'] = value;
        ref.read(createTaskDataProvider.notifier).state = updatedData;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
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
                  color: const Color(0xFF6C5CE7),
                ),
                const SizedBox(width: 8),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Date option widget
  Widget _buildDateOption(String value, String label, ThemeData theme, {String? dateText}) {
    final taskData = ref.watch(createTaskDataProvider);
    final isSelected = taskData['dateOption'] == value;
    
    return InkWell(
      onTap: () {
        final updatedData = Map<String, dynamic>.from(taskData);
        updatedData['dateOption'] = value;
        ref.read(createTaskDataProvider.notifier).state = updatedData;
        
        // Show date picker for 'on_date' and 'before_date' options
        if (value == 'on_date' || value == 'before_date') {
          _showDatePicker(context, value == 'before_date');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7).withOpacity(0.1) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF6C5CE7), width: 2)
              : null,
        ),
        child: Text(
          dateText ?? label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.black,
          ),
        ),
      ),
    );
  }
  
  // Show date picker dialog
  Future<void> _showDatePicker(BuildContext context, bool isEndDate) async {
    final taskData = ref.read(createTaskDataProvider);
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
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
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
      
      // Update the date text for the 'before_date' option
      if (isEndDate) {
        final dateFormat = DateFormat('EEEE, d MMMM');
        updatedData['beforeDateText'] = 'Before ${dateFormat.format(pickedDate)}';
      }
      
      ref.read(createTaskDataProvider.notifier).state = updatedData;
    }
  }

  // Step 4: Location and budget
  Widget _buildLocationBudgetStep(ThemeData theme) {
    final taskData = ref.watch(createTaskDataProvider);
    
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set your location',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Where do you need this task to be done?',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Location type selection (Physical or Online)
          Row(
            children: [
              Expanded(
                child: _buildLocationType('physical', 'Physical', 'This task requires in-person help', Icons.place_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLocationType('online', 'Online', 'Can be done remotely', Icons.language),
              ),
            ],
          ),
          
          // Postcode input - only show for physical tasks
          if (taskData['locationType'] == 'physical') ...[  
            const SizedBox(height: 24),
            const Text(
              'Postcode',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Please enter your postcode',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (taskData['locationType'] == 'physical' && (value == null || value.isEmpty)) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
          ],
          
          const SizedBox(height: 24),
          const Text(
            'Snap a photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help taskers understand of what needs to be done.\nAdd up to 5 photos.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: _pickImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              if (taskData['images'] != null && (taskData['images'] as List).isNotEmpty)
                ...(taskData['images'] as List).map((image) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(image),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Enter your budget',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Don't worry, you can always negotiate the final price later.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              hintText: '1000',
              prefixText: 'MYR ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a budget';
              }
              final price = double.tryParse(value);
              if (price == null) {
                return 'Please enter a valid number';
              }
              if (price <= 0) {
                return 'Budget must be greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: taskData['providesMaterials'] ?? false,
                onChanged: (value) {
                  final updatedData = Map<String, dynamic>.from(taskData);
                  updatedData['providesMaterials'] = value;
                  ref.read(createTaskDataProvider.notifier).state = updatedData;
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: const Color(0xFF6C5CE7),
              ),
              const Text('I will provide the required material(s)'),
            ],
          ),
        ],
      ),
    );
  }
  
  // Location type selection widget
  Widget _buildLocationType(String value, String label, String description, IconData icon) {
    final taskData = ref.watch(createTaskDataProvider);
    final isSelected = taskData['locationType'] == value;
    
    return InkWell(
      onTap: () {
        final updatedData = Map<String, dynamic>.from(taskData);
        updatedData['locationType'] = value;
        ref.read(createTaskDataProvider.notifier).state = updatedData;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF6C5CE7),
            ),
            const SizedBox(height: 8),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Image picker functionality
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      
      final taskData = Map<String, dynamic>.from(ref.read(createTaskDataProvider));
      final images = taskData['images'] as List? ?? [];
      
      // Limit to 5 images
      if (images.length >= 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only add up to 5 images')),
          );
        }
        return;
      }
      
      final imageFile = File(pickedFile.path);
      images.add(imageFile);
      
      taskData['images'] = images;
      ref.read(createTaskDataProvider.notifier).state = taskData;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }
  
  // Remove image from the list
  void _removeImage(File image) {
    final taskData = Map<String, dynamic>.from(ref.read(createTaskDataProvider));
    final images = taskData['images'] as List;
    images.remove(image);
    
    taskData['images'] = images;
    ref.read(createTaskDataProvider.notifier).state = taskData;
  }
}