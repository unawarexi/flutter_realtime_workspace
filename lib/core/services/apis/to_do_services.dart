// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/to_do_model.dart';

// class ToDoService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<List<ToDo>> fetchToDos() async {
//     final snapshot = await _firestore.collection('todos').get();
//     return snapshot.docs.map((doc) => ToDo.fromFirestore(doc.data(), doc.id)).toList();
//   }

//   Future<void> addToDo(ToDo todo) async {
//     await _firestore.collection('todos').add(todo.toFirestore());
//   }

//   Future<void> updateToDo(String id, Map<String, dynamic> data) async {
//     await _firestore.collection('todos').doc(id).update(data);
//   }

//   Future<void> deleteToDo(String id) async {
//     await _firestore.collection('todos').doc(id).delete();
//   }
// }
