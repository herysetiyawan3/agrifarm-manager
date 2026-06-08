import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file from local path to Firebase Storage
  static Future<String> uploadImage({
    required String localPath,
    required String folder,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child(folder).child(fileName);
      final uploadTask = ref.putFile(File(localPath));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal mengupload gambar: ${e.toString()}');
    }
  }
}
