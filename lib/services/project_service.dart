// lib/services/project_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Create a new project
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final String projectId = _uuid.v4();
      final now = DateTime.now();

      final newProject = project.copyWith(
        id: projectId,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('projects')
          .doc(projectId)
          .set(newProject.toMap());

      // Add project to user's projects
      await _firestore.collection('users').doc(project.ownerId).update({
        'projectIds': FieldValue.arrayUnion([projectId]),
      });

      return newProject;
    } catch (e) {
      rethrow;
    }
  }

  // Get a project by ID
  Future<ProjectModel?> getProject(String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (doc.exists) {
        return ProjectModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get all projects for a user
  Stream<List<ProjectModel>> getUserProjects(String userId) {
    try {
      return _firestore
          .collection('projects')
          .where('ownerId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ProjectModel.fromMap(doc.data()))
                .toList();
          });
    } catch (e) {
      rethrow;
    }
  }

  // Update a project
  Future<void> updateProject(ProjectModel project) async {
    try {
      final updatedProject = project.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('projects')
          .doc(project.id)
          .update(updatedProject.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete a project
  Future<void> deleteProject(String projectId, String ownerId) async {
    try {
      // Delete project document
      await _firestore.collection('projects').doc(projectId).delete();

      // Remove project from user's projects
      await _firestore.collection('users').doc(ownerId).update({
        'projectIds': FieldValue.arrayRemove([projectId]),
      });

      // Note: You might want to also delete all documents and tasks associated with this project
      // This would require additional code to query and delete these items
    } catch (e) {
      rethrow;
    }
  }

}
