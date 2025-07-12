import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskaway/core/constants/style_constants.dart';

class OfferAcceptedSuccessScreen extends StatelessWidget {
  final double price;

  const OfferAcceptedSuccessScreen({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
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
                'You have accepted an offer at the price of MYR ${price.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can find this task under "Upcoming Task" section',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
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
