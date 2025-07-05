import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';

class ReviewTaskerScreen extends ConsumerStatefulWidget {
  final String taskerId;
  final String taskId;
  final String taskerName;
  final String? taskerAvatarUrl;
  final double totalPaid;

  const ReviewTaskerScreen({
    super.key,
    required this.taskerId,
    required this.taskId,
    required this.taskerName,
    this.taskerAvatarUrl,
    required this.totalPaid,
  });

  @override
  ConsumerState<ReviewTaskerScreen> createState() => _ReviewTaskerScreenState();
}

class _ReviewTaskerScreenState extends ConsumerState<ReviewTaskerScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final Set<String> _selectedTags = {};

  final List<String> _availableTags = [
    'Punctuality',
    'Attention to detail',
    'Reliable',
    'Great communication',
    'Efficiency',
    'Adaptability',
    'Problem-solving',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    // TODO: Implement review submission
    // final reviewController = ref.read(reviewControllerProvider);
    // await reviewController.submitReview(
    //   taskerId: widget.taskerId,
    //   taskId: widget.taskId,
    //   rating: _rating,
    //   comment: _commentController.text,
    //   tags: _selectedTags.toList(),
    // );

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tasker Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage: widget.taskerAvatarUrl != null
                    ? NetworkImage(widget.taskerAvatarUrl!)
                    : null,
                child: widget.taskerAvatarUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                "Let's rate your tasker's service",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'How satisfied were you with the quality of\nwork provided by the tasker?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _rating > index ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 48,
                        color: _rating > index ? StyleConstants.posterColorPrimary : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Rating text
              if (_rating > 0)
                Text(
                  _rating == 5 ? 'Perfect' : 'Good',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 32),

              // What did you like section
              if (_rating > 0) ...[
                const Text(
                  'What did you like about the quality of the work?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (_) => _toggleTag(tag),
                      backgroundColor: isSelected ? StyleConstants.posterColorPrimary.withOpacity(0.1) : Colors.grey[100],
                      labelStyle: TextStyle(
                        color: isSelected ? StyleConstants.posterColorPrimary : Colors.grey[800],
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                      checkmarkColor: StyleConstants.posterColorPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Comment field
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Tell us more (Optional)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: StyleConstants.posterColorPrimary),
                    ),
                  ),
                  maxLines: 4,
                ),
              ],
              const SizedBox(height: 24),

              // Total paid
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total paid',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'RM ${widget.totalPaid.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StyleConstants.posterColorPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
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
    );
  }
} 