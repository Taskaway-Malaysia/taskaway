import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_providers.dart';
import '../controllers/task_controller.dart' show taskStreamProvider;
import 'task_card.dart';

class TaskListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(filteredTasksProvider).when(
      data: (taskList) => SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: taskList.isEmpty
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Text('No tasks found'),
                ),
              )
            : SliverList.separated(
                itemCount: taskList.length,
                itemBuilder: (context, index) {
                  final task = taskList[index];
                  return TaskCard(task: task);
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
      ),
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(taskStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 