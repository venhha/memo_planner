import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memo_planner/core/utils/helpers.dart';
import 'package:memo_planner/core/widgets/message_screen.dart';
import 'package:memo_planner/features/habit/presentation/screens/habit_page.dart';

import '../../../../core/constants/typedef.dart';
import '../../../../core/widgets/loading_screen.dart';
import '../../data/models/habit_model.dart';
import '../../domain/entities/rrule.dart';
import 'widgets.dart';

class HabitList extends StatelessWidget {
  const HabitList({
    super.key,
    required this.habitStream,
    required this.focusDate,
    required this.currentFilter,
    this.query = '',
  });

  final SQuerySnapshot habitStream;
  final DateTime focusDate;
  final String query;
  final FilterOptions currentFilter;

  @override
  Widget build(BuildContext context) {
    debugPrint('HabitList.build:\n query:$query\n currentFilter:$currentFilter\n focusDate:$focusDate');
    return StreamBuilder(
      stream: habitStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            final habits = snapshot.data!.docs;
            if (habits.isEmpty) {
              return const EmptyHabit();
            }

            // filter by query that user type
            final filteredHabits = habits.where((element) {
              final habit = HabitModel.fromDocument(element.data());
              return habit.summary!.contains(query);
            }).toList();

            // sort by name
            if (currentFilter == FilterOptions.name) {
              filteredHabits.sort((a, b) {
                final habitA = HabitModel.fromDocument(a.data());
                final habitB = HabitModel.fromDocument(b.data());
                return habitA.summary!.compareTo(habitB.summary!);
              });
            } else if (currentFilter == FilterOptions.time) {
              // sort by start time
              filteredHabits.sort((a, b) {
                final habitA = HabitModel.fromDocument(a.data());
                final habitB = HabitModel.fromDocument(b.data());
                return compareDateTimeByTime(habitA.start!, habitB.start!);
                // return habitA.start!.compareTo(habitB.start!);
              });
            }

            return FilterHabitList(habits: filteredHabits, focusDate: focusDate);
          } else if (snapshot.hasError) {
            return MessageScreen(message: snapshot.error.toString());
          } else {
            return const MessageScreen(message: 'No data found');
          }
        } else {
          return const LoadingScreen();
        }
      },
    );
  }
}

class FilterHabitList extends StatefulWidget {
  const FilterHabitList({
    super.key,
    required this.habits,
    required this.focusDate,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> habits;
  final DateTime focusDate;

  @override
  State<FilterHabitList> createState() => _FilterHabitListState();
}

class _FilterHabitListState extends State<FilterHabitList> {
  @override
  Widget build(BuildContext context) {
    final progressingHabits = widget.habits.where((element) {
      final habitModel = HabitModel.fromDocument(element.data());
      return isTodayHabit(
        startOfHabit: habitModel.start!,
        recurrence: habitModel.recurrence!,
        focusDate: widget.focusDate,
      );
    }).toList();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: progressingHabits.length,
          itemBuilder: (context, index) {
            final habitMap = progressingHabits[index].data();
            var habit = HabitModel.fromDocument(habitMap);
            return HabitItem(
              habit: habit,
              focusDate: widget.focusDate,
            );
          },
        ),
      ),
    );
  }
}



bool isTodayHabit({required DateTime startOfHabit, required String recurrence, required DateTime focusDate}) {
  final rule = RRule.fromString(recurrence); // read rrule from string
  var endOfHabit = rule.until != null ? convertStringToDateTime(rule.until!) : null;

  //! no endOfHabit
  // - daily habit >> startOfHabit <= focusDate
  // - weekly habit >> startOfHabit <= focusDate && focusDate is in rule.byDay
  if (endOfHabit == null) {
    if (rule.freq == FREQ.daily) {
      return startOfHabit.isBefore(focusDate) || compareDateTimeByDay(startOfHabit, focusDate) == 0;
    } else if (rule.freq == FREQ.weekly) {
      return startOfHabit.isBefore(focusDate) && rule.isMatchingWeekDate(focusDate);
    } else {
      return false;
    }
  }
  // - daily habit (with endOfHabit rrule.until) >> startOfHabit <= focusDate && endOfHabit >= focusDate
  // - weekly habit (with endOfHabit rrule.until) >> startOfHabit <= focusDate && endOfHabit >= focusDate && focusDate is in rule.byDay
  //! has endOfHabit
  else {
    if (rule.freq == FREQ.daily) {
      return isInRange(startOfHabit: startOfHabit, endOfHabit: endOfHabit, focusDate: focusDate);
    } else if (rule.freq == FREQ.weekly) {
      return isInRange(startOfHabit: startOfHabit, endOfHabit: endOfHabit, focusDate: focusDate) &&
          rule.isMatchingWeekDate(focusDate);
    } else {
      return false;
    }
  }
}

bool isInRange({
  required DateTime startOfHabit,
  required DateTime? endOfHabit,
  required DateTime focusDate,
}) {
  return endOfHabit == null
      ? startOfHabit.isBefore(focusDate) || compareDateTimeByDay(startOfHabit, focusDate) == 0
      // startOfHabit may contain hh:mm -> cannot use isAtSameMomentAs
      : startOfHabit.isBefore(focusDate) && endOfHabit.isAfter(focusDate) ||
          compareDateTimeByDay(endOfHabit, focusDate) == 0 || // end date equal to focus date
          compareDateTimeByDay(startOfHabit, focusDate) == 0; // start date equal to focus date
}

// bool isInProgress(DateTime start, DateTime end, DateTime focusDate) {
//   return (start.isBefore(focusDate) && end.isAfter(focusDate)) ||
//       (end.isAtSameMomentAs(focusDate)) ||
//       (start.isAtSameMomentAs(focusDate));
// }

/// - startOfHabit: [habit.start]
/// - endOfHabit: [habit.recurrence_UNTIL]
// bool isInRange({
//   required DateTime startOfHabit,
//   required DateTime? endOfHabit,
//   required DateTime focusDate,
// }) {
//   if (endOfHabit != null) {
//     return (startOfHabit.isBefore(focusDate) && endOfHabit.isAfter(focusDate)) ||
//         compareDateTimeByDay(endOfHabit, focusDate) == 0 || // end date equal to focus date
//         compareDateTimeByDay(startOfHabit, focusDate) == 0; // start date equal to focus date
//   } else {
//     return (startOfHabit.isBefore(focusDate)) || compareDateTimeByDay(startOfHabit, focusDate) == 0;
//   }
// }