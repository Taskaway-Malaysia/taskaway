import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for current mode (TASKER or POSTER)
final userModeProvider = StateProvider<UserMode>((ref) => UserMode.tasker);

enum UserMode { tasker, poster }

class TaskerPosterToggle extends ConsumerWidget {
  final Function(UserMode)? onModeChanged;

  const TaskerPosterToggle({super.key, this.onModeChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(userModeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeButton(
            context,
            ref,
            mode: UserMode.tasker,
            label: 'TASKER',
            isSelected: currentMode == UserMode.tasker,
          ),
          const SizedBox(width: 20),
          _buildModeButton(
            context,
            ref,
            mode: UserMode.poster,
            label: 'POSTER',
            isSelected: currentMode == UserMode.poster,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    WidgetRef ref, {
    required UserMode mode,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(userModeProvider.notifier).state = mode;
        onModeChanged?.call(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFFFC333) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: isSelected ? const Color(0xFF000000) : const Color(0xFF788494),
          ),
        ),
      ),
    );
  }
}