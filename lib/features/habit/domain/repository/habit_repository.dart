import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/typedef.dart';
import '../../../authentication/domain/entities/user_entity.dart';
import '../entities/habit_entity.dart';
import '../entities/streak_entity.dart';

abstract class HabitRepository {
  Stream<QuerySnapshot> getHabitStream(UserEntity user);
  ResultEither<HabitEntity> getHabitByHid(String hid);
  ResultVoid addHabit(HabitEntity habit);
  ResultVoid updateHabit(HabitEntity habit);
  ResultVoid deleteHabit(HabitEntity habit);

  ResultEither<StreakEntity> getTopStreaks(String hid);
}
