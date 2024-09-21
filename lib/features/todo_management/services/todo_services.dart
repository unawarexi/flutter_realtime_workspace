import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_realtime_workspace/features/todo_management/model/todo_model.dart';

class TodoService {
  final todoCollection = FirebaseFirestore.instance.collection("todoList");
  
  
  // Create
  void addNewTask(TodoModel model) {
    todoCollection.add(model.toMap());
  }
} 