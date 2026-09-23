import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Compress and upload a student photo to Supabase Storage.
  /// Returns (downloadUrl, errorMessage).
  Future<(String?, String?)> uploadStudentPhoto({
    required File imageFile,
    required String makerUid,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);
      // Validate size before compression (5 MB limit)
      final size = await imageFile.length();
      if (size > AppConstants.maxPhotoSizeBytes) {
        return (null, 'Student photo must be 5 MB or smaller.');
      }

      // Compress image
      onProgress?.call(0.3);
      final compressed = await _compressImage(imageFile);
      final uploadFile = compressed ?? imageFile;

      // Unique storage path: {makerUid}/{timestamp}_photo.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$makerUid/${timestamp}_photo.jpg';

      onProgress?.call(0.6);
      await _client.storage
          .from(SupabaseConfig.studentPhotosBucket)
          .upload(
            path,
            uploadFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      onProgress?.call(0.9);
      // Get public URL
      final publicUrl = _client.storage
          .from(SupabaseConfig.studentPhotosBucket)
          .getPublicUrl(path);

      onProgress?.call(1.0);
      return (publicUrl, null);
    } on StorageException catch (e) {
      return (null, 'Photo upload failed: ${e.message}');
    } catch (e) {
      return (null, 'Failed to upload photo. Please check your connection.\n$e');
    }
  }

  /// Delete a photo from Supabase Storage by its public URL.
  Future<void> deletePhotoByUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      // Extract path after bucket name
      final parts = uri.pathSegments;
      final bucketIndex = parts.indexOf(SupabaseConfig.studentPhotosBucket);
      if (bucketIndex != -1 && bucketIndex + 1 < parts.length) {
        final filePath = parts.sublist(bucketIndex + 1).join('/');
        await _client.storage
            .from(SupabaseConfig.studentPhotosBucket)
            .remove([filePath]);
      }
    } catch (_) {
      // Non-critical cleanup
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );
      return result != null ? File(result.path) : null;
    } catch (_) {
      return null;
    }
  }
}
