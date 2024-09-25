// lib/exceptions/file_exception.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class FileException {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();
  static final Uuid _uuid = Uuid();

  // Method to generate a unique ID
  static String generateUniqueId() {
    return _uuid.v4(); // Generates a random unique ID
  }

  // Method to upload a file and return its URL
  static Future<String?> uploadFile() async {
    try {
      // Pick a file (image, video, or document)
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return null;

      // Create a unique file name
      String fileName =
          generateUniqueId() + '.' + pickedFile.name.split('.').last;

      // Upload the file to Firebase Storage
      final ref = _storage.ref().child('projects/$fileName');
      await ref.putFile(File(pickedFile.path));

      // Get the file URL
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Handle any exceptions (e.g., file picking errors, upload errors)
      print('Error uploading file: $e');
      return null;
    }
  }
}
