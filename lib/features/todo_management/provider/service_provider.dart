import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_realtime_workspace/features/todo_management/model/todo_model.dart';
import 'package:flutter_realtime_workspace/features/todo_management/services/todo_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceProvider = StateProvider<TodoService>((ref) {
  return TodoService();
});


final fetchStreamProvider = StreamProvider<List<TodoModel>>((ref) async* {
  final getData = FirebaseFirestore.instance
      .collection("todoList")
      .snapshots()
      .map((event) =>
      event.docs.map((snapshot) => TodoModel.fromSnapshot(snapshot))
          .toList());
  yield* getData;
}
);