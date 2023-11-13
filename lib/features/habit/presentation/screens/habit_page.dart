import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../authentication/presentation/bloc/bloc/authentication_bloc.dart';
import '../bloc/habit/habit_bloc.dart';
import '../widgets/widgets.dart';

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  DateTime _now = DateTime.now();
  late EasyInfiniteDateTimelineController _controller;
  late TextEditingController _searchController;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = EasyInfiniteDateTimelineController();
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar.buildAppBar(
        context: context,
        title: 'Habit',
      ),
      drawer: const AppNavigationDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/habit/add');
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
          builder: (context, state) {
            if (state.status == AuthenticationStatus.authenticated) {
              return BlocBuilder<HabitBloc, HabitState>(
                builder: (context, state) {
                  if (state is HabitLoaded) {
                    return Column(
                      children: [
                        habitSearchBar(
                          context,
                          controller: _searchController,
                          onChange: () {
                            setState(() {
                              searchQuery = _searchController.text;
                            });
                          },
                          onCancel: () {
                            setState(() {
                              _searchController.clear();
                              searchQuery = '';
                              FocusScope.of(context).unfocus();
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        EasyInfiniteDateTimeLine(
                          controller: _controller,
                          activeColor: Colors.green.shade300,
                          dayProps: const EasyDayProps(
                            activeDayStyle: DayStyle(
                              borderRadius: 28,
                            ),
                            todayStyle: DayStyle(),
                            borderColor: Colors.black12,
                            todayHighlightColor: Colors.green,
                          ),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2026),
                          focusDate: _now,
                          onDateChange: (selectedDate) {
                            setState(() {
                              _now = selectedDate;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: const TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search habit',
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _now = DateTime.now();
                                setState(() {
                                  _controller.animateToDate(
                                    _now,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.decelerate,
                                  );
                                });
                              },
                              child: const Icon(Icons.today),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        HabitList(
                          focusDate: _now,
                          habitStream: state.habitStream,
                          query: searchQuery,
                        ),
                      ],
                    );
                  } else if (state is HabitLoading) {
                    return const LoadingScreen();
                  } else {
                    return const MessageScreen(
                      message: 'Some thing went wrong [e04]',
                    );
                  }
                },
              );
            } else {
              return Center(
                child: ElevatedButton(
                    onPressed: () {
                      context.go('/authentication');
                    },
                    child: const Text('Login')),
              );
            }
          },
        ),
      ),
    );
  }
}

Widget habitSearchBar(
  BuildContext context, {
  required TextEditingController controller,
  required Function onChange,
  required Function onCancel,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0),
    child: SearchBar(
        controller: controller,
        padding: const MaterialStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0)),
        onTap: () {},
        onChanged: (_) {
          debugPrint('searching $_');
          onChange();
        },
        leading: const Icon(Icons.search),
        trailing: [
          IconButton(
            onPressed: () {
              onCancel();
            },
            icon: const Icon(Icons.close),
          ),
        ]),
  );
}
