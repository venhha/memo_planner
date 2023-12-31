import 'package:flutter/material.dart';

import '../../../../config/dependency_injection.dart';
import '../../../authentication/domain/repository/authentication_repository.dart';
import '../../domain/entities/task_entity.dart';

class AssignedMembers extends StatelessWidget {
  const AssignedMembers({
    super.key,
    required this.task,
    this.height = 48.0,
  });
  final TaskEntity task;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: task.assignedMembers!.length,
        itemBuilder: (context, index) => FutureBuilder(
          future: di<AuthenticationRepository>().getUserByEmail(task.assignedMembers![index]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final member = snapshot.data!;
              return Builder(
                builder: (context) {
                  if (member.photoURL != null) {
                    return CircleAvatar(
                      maxRadius: height / 2,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage: NetworkImage(member.photoURL!),
                    );
                  } else {
                    // use the first letter of email instead
                    return CircleAvatar(
                      maxRadius: height / 2,
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.person),
                    );
                  }
                },
              );
            } else {
              // return Text(task.assignedMembers![index]);
              return CircleAvatar(
                maxRadius: height / 2,
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.person),
              );
            }
          },
        ),
      ),
    );
  }
}
