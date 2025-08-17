import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';
import 'package:taskaway/features/messages/controllers/message_controller.dart';

class OfferAcceptedSuccessScreen extends ConsumerWidget {
  final double price;
  final String? taskId;

  const OfferAcceptedSuccessScreen({
    super.key, 
    required this.price,
    this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My tasks'),
        automaticallyImplyLeading: false, // To remove back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle,
                color: StyleConstants.primaryColor,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Offer Accepted & Payment Secured',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully accepted an offer for MYR ${price.toStringAsFixed(2)} and your payment has been authorized and secured.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // Payment Secured badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.green.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Secured',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can find this task under "Upcoming Task" section and start communicating with your tasker.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              // Message Tasker button
              if (taskId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final messageController = ref.read(messageControllerProvider);
                        final channel = await messageController.getChannelByTaskId(taskId!);
                        
                        if (channel != null && context.mounted) {
                          await context.push('/home/chat/${channel.id}');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting conversation...')),
                          );
                          // Navigate to task details where they can use the message button
                          context.go('/home/browse/$taskId');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to open chat: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message Tasker'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/home/tasks'); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StyleConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Go to upcoming tasks'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
