// lib/services/storage_service.dart — v2.1
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ── Profile photo ─────────────────────────────────────────

  Future<String?> uploadProfilePhoto(String uid) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked == null) return null;

      final ref = _storage.ref('profile_photos/$uid.jpg');
      // Use readAsBytes() on all platforms — avoids dart:io File on web.
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('uploadProfilePhoto error: $e');
      return null;
    }
  }

  // ── Resume / CV upload ────────────────────────────────────

  Future<String?> uploadResumeFile(String uid) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // request bytes on ALL platforms — no dart:io File needed
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;

      // Guard: bytes must be populated (withData:true should guarantee this).
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        debugPrint('uploadResumeFile: picked file has no bytes');
        return null;
      }

      final ext = (file.extension ?? 'pdf').toLowerCase();
      final contentType = ext == 'pdf' ? 'application/pdf' : 'application/msword';

      final ref = _storage.ref('resumes/$uid/resume.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('uploadResumeFile error: $e');
      return null;
    }
  }

  // ── Profile photo delete ──────────────────────────────────

  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _storage.ref('profile_photos/$uid.jpg').delete();
    } catch (e) {
      debugPrint('deleteProfilePhoto error: $e');
    }
  }
}
