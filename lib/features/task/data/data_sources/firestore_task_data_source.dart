import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/constants/enum.dart';
import '../../../../core/constants/typedef.dart';
import '../../../../core/entities/member.dart';
import '../../../../core/service/firebase_cloud_messaging_service.dart';
import '../../../../core/service/local_notification_service.dart';
import '../../domain/entities/myday_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_list_entity.dart';
import '../models/myday_model.dart';
import '../models/task_list_model.dart';
import '../models/task_model.dart';

abstract class FireStoreTaskDataSource {
  //! TaskList
  SQuerySnapshot getAllTaskListStreamOfUser(String uid);
  Future<List<TaskListEntity>> getAllTaskListOfUser(String uid); // for loading reminder
  SDocumentSnapshot getOneTaskListStream(String lid);

  Future<void> addTaskList(TaskListEntity taskList);
  Future<void> editTaskList(TaskListEntity updatedTaskList);
  Future<void> deleteTaskList(String lid);

  Future<List<Member>> getMembers(String lid);
  Future<List<String>> getAllMemberTokens(String lid);
  Future<void> addMemberToTaskList(String lid, Member member);
  Future<void> removeMember(String lid, String uid);

  Future<int> countTaskList(String lid);

  //! MyDay
  // path: /users/{uid}/myday/{tid}
  SDocumentSnapshot getOneMyDayStream(String uid, String tid); 
  Future<void> removeMismatchInMyDay(String uid, DateTime date);
  SQuerySnapshot getAllMyDayStream(String uid); // >> [getOneTaskStream]

  Future<void> addToMyDay(String uid, MyDayEntity myDay);
  Future<void> toggleKeepInMyDay(String uid, String tid, bool isKeep);
  Future<void> removeFromMyDay(String uid, MyDayEntity myDay);

  //! Task
  SQuerySnapshot getAllTaskStream(String lid, TaskSortOptions sortBy);
  SDocumentSnapshot getOneTaskStream(String lid, String tid);
  Future<List<TaskEntity>> getAllTaskInSingleList(String lid, {bool filterCompleted = false});

  Future<void> loadAllRemindersInSingleList(String lid);

  Future<TaskEntity> getTask(String lid, String tid);
  Future<void> addTask(TaskEntity task);
  Future<void> editTask(TaskEntity updatedTask, TaskEntity oldTask);
  Future<void> deleteTask(TaskEntity task);
  Future<void> toggleTask(String tid, String lid, bool value);

  Future<void> assignTask(String lid, String tid, String email);
  Future<void> unassignTask(String lid, String tid, String email);

  // Future<MyDayEntity?> findOneMyDay(String email, String tid);
}

@Singleton(as: FireStoreTaskDataSource)
class FireStoreTaskDataSourceImpl implements FireStoreTaskDataSource {
  FireStoreTaskDataSourceImpl(this._firestore, this._localNotification, this._fcm);

  final FirebaseFirestore _firestore;
  final LocalNotificationService _localNotification;
  final FirebaseCloudMessagingService _fcm;

  @override
  SQuerySnapshot getAllTaskListStreamOfUser(String uid) {
    return _firestore
        .collection(pathToTaskLists)
        .where(Filter.or(
          Filter('creator.uid', isEqualTo: uid),
          Filter('members', arrayContains: Member.member(uid).toMap()),
        ))
        // .orderBy('listName')
        .snapshots();
  }

  @override
  Future<List<TaskListEntity>> getAllTaskListOfUser(String uid) {
    return _firestore
        .collection(pathToTaskLists)
        .where(Filter.or(
          Filter('creator.uid', isEqualTo: uid),
          Filter('members', arrayContains: Member.member(uid).toMap()),
        ))
        .get()
        .then((querySnapshot) {
      final taskLists = <TaskListEntity>[];
      for (final doc in querySnapshot.docs) {
        final model = TaskListModel.fromMap(doc.data());
        taskLists.add(model);
      }
      return taskLists;
    });
  }

  @override
  Future<void> addTaskList(TaskListEntity taskList) async {
    final collRef = _firestore.collection(pathToTaskLists);
    final lid = collRef.doc().id;
    taskList = taskList.copyWith(lid: lid);

    await collRef.doc(lid).set(TaskListModel.fromEntity(taskList).toMap());
  }

  @override
  Future<void> editTaskList(TaskListEntity updatedTaskList) async {
    return _firestore
        .collection(pathToTaskLists)
        .doc(updatedTaskList.lid)
        .update(TaskListModel.fromEntity(updatedTaskList).toMap());
  }

  @override
  Future<void> deleteTaskList(String lid) async {
    // get taskListRef
    final docRef = _firestore.collection(pathToTaskLists).doc(lid);
    await docRef.delete();

    //? can call the deleteTask method but it will do some extra work
    //remove all tasks in: /task-lists/ {lid} /tasks/ {tid}
    final tasks = await docRef.collection(pathToTasks).get();
    for (final task in tasks.docs) {
      // cancel notification
      final model = TaskModel.fromMap(task.data());
      if (model.reminders?.useDefault == true) {
        await _localNotification.I.cancel(model.reminders!.rid!);
      }
      // delete task reference
      await task.reference.delete();
    }
  }

  @override
  Future<void> addMemberToTaskList(String lid, Member member) async {
    _firestore.collection(pathToTaskLists).doc(lid).update({
      'members': FieldValue.arrayUnion([member.toMap()])
    });
  }

  @override
  Future<void> removeMember(String lid, String uid) async {
    _firestore.collection(pathToTaskLists).doc(lid).update({
      'members': FieldValue.arrayRemove([Member.member(uid).toMap()])
    });

    // remove member from every task that assigned to him/her
    final tasks = await _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).get();
    for (final task in tasks.docs) {
      final model = TaskModel.fromMap(task.data());

      if (model.assignedMembers!.isEmpty) continue;

      if (model.assignedMembers!.contains(uid)) {
        // remove member (by uid) from assignedMembers
        model.assignedMembers!.remove(uid);
        await task.reference.update(model.toMap());
      }
    }
  }

  @override
  SDocumentSnapshot getOneTaskListStream(String lid) {
    return _firestore.collection(pathToTaskLists).doc(lid).snapshots();
  }

  @override
  SQuerySnapshot getAllTaskStream(String lid, TaskSortOptions sortBy) {
    // return _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).orderBy('created').snapshots();
    switch (sortBy) {
      case TaskSortOptions.none:
        return _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).snapshots();
      case TaskSortOptions.createdDate:
        return _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).orderBy('created').snapshots();
      case TaskSortOptions.name:
        return _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).orderBy('taskName').snapshots();
      case TaskSortOptions.dueDate:
        return _firestore
            .collection(pathToTaskLists)
            .doc(lid)
            .collection(pathToTasks)
            .orderBy('dueDate', descending: false)
            .snapshots();
      case TaskSortOptions.priority:
        return _firestore
            .collection(pathToTaskLists)
            .doc(lid)
            .collection(pathToTasks)
            .orderBy('priority', descending: true)
            .snapshots();
      default:
        return _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).snapshots();
    }
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    final collRef = _firestore.collection(pathToTaskLists).doc(task.lid).collection(pathToTasks);
    final tid = collRef.doc().id;
    final taskModel = TaskModel.fromEntity(task.copyWith(tid: tid));

    await collRef.doc(tid).set(taskModel.toMap()).then(
      (_) async {
        // set schedule notification for task
        if (task.reminders?.useDefault == true) {
          _localNotification.setScheduleNotificationFromTask(task);

          // done: send notification to assigned members and all their devices to add reminder
          final data = {
            'type': kFCMAddOrUpdateReminder,
            'task': taskModel.toJson(),
          };

          final tokens = await getAllMemberTokens(task.lid!);
          _fcm.sendDataMessageToMultipleDevices(tokens: tokens, data: data);
        }
      },
    );
  }

  @override
  Future<void> deleteTask(TaskEntity task) async {
    await _firestore.collection(pathToTaskLists).doc(task.lid).collection(pathToTasks).doc(task.tid).delete().then((value) async {
      // TEST: send notification to assigned members and all their devices to cancel reminder
      if (task.reminders?.useDefault == true) {
        await _localNotification.I.cancel(task.reminders!.rid!);

        final data = {
          'type': kFCMDeleteReminder,
          'rid': task.reminders!.rid.toString(),
        };

        final tokens = await getAllMemberTokens(task.lid!);
        _fcm.sendDataMessageToMultipleDevices(tokens: tokens, data: data);
      }
    });
  }

  @override
  Future<void> editTask(TaskEntity updatedTask, TaskEntity oldTask) async {
    final docRef = _firestore.collection(pathToTaskLists).doc(updatedTask.lid).collection(pathToTasks).doc(updatedTask.tid);

    await docRef.update(TaskModel.fromEntity(updatedTask).toMap()).then(
      (_) async {
        if (updatedTask.reminders?.useDefault == true) {
          // -- newTask: have reminder, old?
          if (oldTask.reminders?.useDefault == true) {
            // -- old: have reminder, new: have reminder >> update schedule notification with same rid
            // > oldTask have the same reminder time with updatedTask >> ignore
            if (oldTask.reminders!.scheduledTime!.isAtSameMomentAs(updatedTask.reminders!.scheduledTime!)) return;

            // > update with same rid but different time
            await _localNotification.setScheduleNotificationFromTask(updatedTask);
            // done: send notification to assigned members and all their devices to edit reminder
            final data = {
              'type': kFCMAddOrUpdateReminder, // >> in this case, update
              'task': TaskModel.fromEntity(updatedTask).toJson(),
            };
            final tokens = await getAllMemberTokens(updatedTask.lid!);
            _fcm.sendDataMessageToMultipleDevices(tokens: tokens, data: data);
          } else {
            // --new: have reminder, old: NO reminder >> set new schedule notification
            await _localNotification.setScheduleNotificationFromTask(updatedTask);
            // done: send notification to assigned members and all their devices to add new reminder
            final data = {
              'type': kFCMAddOrUpdateReminder, // >> in this case, add
              'task': TaskModel.fromEntity(updatedTask).toJson(),
            };
            final tokens = await getAllMemberTokens(updatedTask.lid!);
            _fcm.sendDataMessageToMultipleDevices(tokens: tokens, data: data);
          }
        } else {
          if (oldTask.reminders == null) return;
          // new: no reminder, old: have reminder >> cancel old schedule notification
          if (oldTask.reminders?.rid != null) await _localNotification.I.cancel(oldTask.reminders!.rid!);
          // done: send notification to assigned members and all their devices to remove old reminder
          final data = {
            'type': kFCMDeleteReminder, // >> in this case, delete old reminder
            'rid': oldTask.reminders!.rid.toString(),
          };
          final tokens = await getAllMemberTokens(updatedTask.lid!);
          _fcm.sendDataMessageToMultipleDevices(tokens: tokens, data: data);
        }
      },
    );
  }

  @override
  Future<TaskEntity> getTask(String lid, String tid) async {
    final docRef = _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).doc(tid);
    final doc = await docRef.get();
    return TaskModel.fromMap(doc.data()!);
  }

  @override
  Future<void> toggleTask(String tid, String lid, bool value) async {
    final docRef = _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).doc(tid);
    await docRef.update({'completed': value});
  }

  @override
  SDocumentSnapshot getOneTaskStream(String lid, String tid) {
    return _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).doc(tid).snapshots();
  }

  @override
  Future<void> assignTask(String lid, String tid, String email) async {
    final docRef = _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).doc(tid);
    return await docRef.update({
      'assignedMembers': FieldValue.arrayUnion([email])
    });
  }

  @override
  Future<void> unassignTask(String lid, String tid, String email) async {
    final docRef = _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).doc(tid);
    return await docRef.update({
      'assignedMembers': FieldValue.arrayRemove([email])
    });
  }

  @override
  Future<int> countTaskList(String lid) async {
    final result = await _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks).count().get();
    return result.count ?? -1;
  }

  @override
  Future<void> addToMyDay(String uid, MyDayEntity myDay) async {
    final collRef = _firestore.collection(pathToUsers).doc(uid).collection(pathToMyDay);
    await collRef.doc(myDay.tid).set(MyDayModel.fromEntity(myDay).toMap());
  }

  @override
  Future<void> removeFromMyDay(String uid, MyDayEntity myDay) async {
    return await _firestore.collection(pathToUsers).doc(uid).collection(pathToMyDay).doc(myDay.tid).delete();
  }

  @override
  SDocumentSnapshot getOneMyDayStream(String uid, String tid) {
    return _firestore.collection(pathToUsers).doc(uid).collection(pathToMyDay).doc(tid).snapshots();
  }

  @override
  Future<void> toggleKeepInMyDay(String uid, String tid, bool isKeep) async {
    return await _firestore.collection(pathToUsers).doc(uid).collection(pathToMyDay).doc(tid).update({
      'keep': isKeep,
    });
  }

  // @override
  // Future<MyDayEntity?> findOneMyDay(String email, String tid) async {
  //   return await _firestore.collection(pathToUsers).doc(email).collection(pathToMyDay).doc(tid).get().then(
  //     (value) {
  //       if (value.data() == null) return null;
  //       return MyDayModel.fromMap(value.data()!);
  //     },
  //   );
  // }

  @override
  Future<void> removeMismatchInMyDay(String uid, DateTime date) async {
    final collRef = _firestore.collection(pathToUsers).doc(uid).collection(pathToMyDay);
    collRef.get().then((querySnapshot) {
      for (var docSnapshot in querySnapshot.docs) {
        final map = docSnapshot.data();
        // if keep set to true or created date is today, skip
        if (map['keep'] == true || map['created'] == Timestamp.fromDate(date)) continue;
        docSnapshot.reference.delete();
      }
    }, onError: (e) => log('removeMismatchInMyDay Exception: type: ${e.runtimeType.toString()} -- ${e.toString()}'));
  }

  @override
  SQuerySnapshot getAllMyDayStream(String uid) {
    final collRef = _firestore.collection(pathToUsers).doc(uid).collection(pathToMyDay);
    return collRef.snapshots();
  }

  @override
  Future<List<Member>> getMembers(String lid) {
    return _firestore.collection(pathToTaskLists).doc(lid).get().then((value) {
      return TaskListModel.fromMap(value.data()!).members!;
    });
  }

  @override
  Future<List<String>> getAllMemberTokens(String lid, {bool excludeCurrentDevice = true}) async {
    final tokens = <String>[];
    final members = getMembers(lid);
    return members.then((memberEmails) async {
      for (final member in memberEmails) {
        await _firestore.collection(pathToUsers).doc(member.uid).get().then((value) {
          final List<String> userTokens = (value.data()?['tokens'] as List<dynamic>).map((token) => token as String).toList();

          tokens.addAll(userTokens);
        });
      }
      if (excludeCurrentDevice) tokens.removeWhere((token) => token == _fcm.currentFCMToken);
      log('getAllMemberTokens: $tokens');
      return tokens;
    });
  }

  @override
  Future<List<TaskEntity>> getAllTaskInSingleList(String lid, {bool filterCompleted = false}) async {
    final collRef = _firestore.collection(pathToTaskLists).doc(lid).collection(pathToTasks);
    if (filterCompleted) {
      final filteredQuery = collRef.where('completed', isEqualTo: false);
      return await filteredQuery.get().then(
        (querySnapshot) {
          if (querySnapshot.docs.isEmpty) return [];
          final tasks = <TaskEntity>[];
          for (final doc in querySnapshot.docs) {
            final model = TaskModel.fromMap(doc.data());
            tasks.add(model);
          }
          return tasks;
        },
      );
    }
    return await collRef.get().then(
      (querySnapshot) {
        if (querySnapshot.docs.isEmpty) return [];
        final tasks = <TaskEntity>[];
        for (final doc in querySnapshot.docs) {
          final model = TaskModel.fromMap(doc.data());
          tasks.add(model);
        }
        return tasks;
      },
    );
  }

  @override
  Future<void> loadAllRemindersInSingleList(String lid) async {
    final tasks = await getAllTaskInSingleList(lid, filterCompleted: true);
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.reminders?.useDefault == true) {
        if (task.reminders!.scheduledTime!.isBefore(now)) continue;
        _localNotification.setScheduleNotificationFromTask(task);
      }
    }
  }
}
