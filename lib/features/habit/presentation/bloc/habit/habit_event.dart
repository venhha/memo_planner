part of 'habit_bloc.dart';

sealed class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object> get props => [];
}

final class HabitStartedEvent extends HabitEvent {
  HabitStartedEvent();
  final DateTime currentDate = DateTime.now();

  @override
  List<Object> get props => [currentDate];
}

final class HabitAddEvent extends HabitEvent {
  const HabitAddEvent({required this.habit});
  final HabitEntity habit;

  @override
  List<Object> get props => [habit];
}

final class HabitAddInstanceEvent extends HabitEvent {
  const HabitAddInstanceEvent({required this.habit, required this.date});
  final HabitEntity habit;
  final DateTime date;

  @override
  List<Object> get props => [habit, date];
}

final class HabitUpdateEvent extends HabitEvent {
  const HabitUpdateEvent({required this.habit});
  final HabitEntity habit;

  @override
  List<Object> get props => [habit];
}

final class HabitDeleteEvent extends HabitEvent {
  const HabitDeleteEvent({required this.habit});
  final HabitEntity habit;

  @override
  List<Object> get props => [habit];
}