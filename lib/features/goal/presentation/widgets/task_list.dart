import 'package:flutter/material.dart';
import 'package:memo_planner/core/widgets/message_screen.dart';
import 'package:memo_planner/features/goal/presentation/widgets/empty_task_view.dart';

import '../../domain/entities/task_entity.dart';
import 'task_item.dart';

class TaskList extends StatelessWidget {
  const TaskList(
    this.tasks, {
    super.key,
  });

  final List<TaskEntity> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const EmptyTaskView();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return TaskItem(task: tasks[index]);
      },
    );
  }
}