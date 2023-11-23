import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../authentication/presentation/bloc/authentication/authentication_bloc.dart';
import 'target_screen/target_screen.dart';
import 'task_screen/task_screen.dart';

class GoalPage extends StatelessWidget {
  const GoalPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        if (state.status == AuthenticationStatus.authenticated) {
          return DefaultTabController(
            initialIndex: initialIndex,
            length: 2,
            child: Scaffold(
              drawer: const AppNavigationDrawer(),
              appBar: MyAppBar.goalAppBar(
                context: context,
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Task'), // index 0
                    Tab(text: 'Target'), // index 1
                  ],
                ),
              ),
              body: const TabBarView(
                children: <Widget>[
                  TaskScreen(),
                  TargetScreen(),
                ],
              ),
            ),
          );
        } else {
          return MessageScreenWithAction.unauthenticated(() {context.go('/authentication'); });
        }
      },
    );
  }
}
