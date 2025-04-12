// lib/services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload a file from bytes (for web)
  Future<String> uploadFileFromBytes({
    required Uint8List bytes,
    required String path,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final storageRef = _storage.ref().child(
        '$path/${_getUniqueName(fileName)}',
      );

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'fileName': fileName},
      );

      final uploadTask = storageRef.putData(bytes, metadata);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Upload a file from file path (for mobile)
  Future<String> uploadFile({
    required File file,
    required String path,
    String? contentType,
  }) async {
    try {
      final String fileName = file.path.split('/').last;
      final storageRef = _storage.ref().child(
        '$path/${_getUniqueName(fileName)}',
      );

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'fileName': fileName},
      );

      final uploadTask = storageRef.putFile(file, metadata);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Delete a file
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  // Helper to create unique filenames
  String _getUniqueName(String fileName) {
    final String extension = fileName.split('.').last;
    return '${_uuid.v4()}.$extension';
  }

  // Get directory contents (list files in a specific path)
  Future<List<Reference>> listFiles(String path) async {
    try {
      final result = await _storage.ref().child(path).listAll();
      return result.items;
    } catch (e) {
      rethrow;
    }
  }

  // Get file metadata
  Future<Map<String, dynamic>> getFileMetadata(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      final metadata = await ref.getMetadata();

      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'createdTime': metadata.timeCreated,
        'updatedTime': metadata.updated,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      rethrow;
    }
  }
}
