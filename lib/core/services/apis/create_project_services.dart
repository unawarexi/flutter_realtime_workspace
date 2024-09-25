// lib/services/project_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_realtime_workspace/features/project_management/domain/models/create_project_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'projects'; // Firestore collection name

  // Create a new project
  Future<bool> createProject(Project project) async {
    try {
      await _firestore.collection(collection).add(project.toMap());
      return true; // Return true if the project is created successfully
    } catch (e) {
      print('Error creating project: $e'); // Log the error for debugging
      return false; // Return false if there is an error
    }
  }

  // Get a list of projects
  Future<List<Project>> getProjects() async {
    QuerySnapshot snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.map((doc) {
      return Project.fromMap(
          {...doc.data() as Map<String, dynamic>, 'id': doc.id});
    }).toList();
  }

  // Update an existing project
  Future<void> updateProject(Project project) async {
    await _firestore
        .collection(collection)
        .doc(project.id)
        .update(project.toMap());
  }

  // Delete a project
  Future<void> deleteProject(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }
}
