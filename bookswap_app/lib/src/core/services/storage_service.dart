import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  // Upload book cover image
  Future<String> uploadBookImage(File imageFile, String bookId) async {
    try {
      final ref = _storage.ref().child('book_covers/$bookId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete book image
  Future<void> deleteBookImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Log error but don't throw - image deletion shouldn't block book deletion
      print('Failed to delete image: $e');
    }
  }
}