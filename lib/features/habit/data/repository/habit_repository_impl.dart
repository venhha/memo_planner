import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/typedef.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../authentication/domain/entities/user_entity.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/repository/habit_repository.dart';
import '../data_sources/habit_data_source.dart';

@Singleton(as: HabitRepository)
class HabitRepositoryImpl implements HabitRepository {
  const HabitRepositoryImpl(
    this._habitDataSource,
  );
  final HabitDataSource _habitDataSource;

  @override
  ResultVoid addHabit(HabitEntity habit) async {
    try {
      return Right(await _habitDataSource.addHabit(habit));
    } on ServerException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message));
    }
  }

  @override
  ResultVoid deleteHabit(HabitEntity habit) async {
    try {
      await _habitDataSource.deleteHabit(habit);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message!));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  ResultVoid updateHabit(HabitEntity habit) async {
    try {
      _habitDataSource.updateHabit(habit);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(code: e.code, message: e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  SQuerySnapshot getHabitStream(UserEntity user) {
    try {
      final habits = _habitDataSource.getHabitStream(user);
      return habits;
    } catch (e) {
      log('Summary Exception: type: ${e.runtimeType.toString()} -- ${e.toString()}');
      return const Stream.empty();
    }
  }

  @override
  ResultEither<HabitEntity> getHabitByHid(String hid) async {
    try {
      final habit = await _habitDataSource.getHabitByHid(hid);
      if (habit != null) {
        return Right(habit);
      } else {
        return const Left(ServerFailure(message: 'Habit not found'));
      }
    } on ServerException catch (e) {
      log('Specific Exception: type: ${e.runtimeType} code: "${e.code}", message: ${e.message}');
      return Left(ServerFailure(code: e.code, message: e.message));
    }
  }

  @override
  ResultEither<StreakEntity> getTopStreaks(String hid, String collectionEmailPath) async {
    try {
      final habit = await _habitDataSource.getHabitByHid(hid);
      final streaks = await _habitDataSource.getTopHabitStreakOfUser(hid, collectionEmailPath);
      final result = StreakEntity(habit: habit!, streaks: streaks);
      return Right(result);
    } on FirebaseException catch (e) {
      log('Specific Exception: type: ${e.runtimeType} code: "${e.code}", message: ${e.message}');
      return Left(ServerFailure(code: e.code, message: e.message!));
    }
  }

  @override
  SDocumentSnapshot getOneHabitStream(String hid) {
    try {
      final habits = _habitDataSource.getOneHabitStream(hid);
      return habits;
    } catch (e) {
      log('Summary Exception: type: ${e.runtimeType.toString()} -- ${e.toString()}');
      return const Stream.empty();
    }
  }
}
