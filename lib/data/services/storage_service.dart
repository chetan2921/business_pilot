import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/supabase_config.dart';

/// Service for uploading files to Supabase Storage
class StorageService {
  StorageService._();
  static final StorageService _instance = StorageService._();
  static StorageService get instance => _instance;

  SupabaseClient get _client => SupabaseConfig.client;
  static const String _receiptsBucket = 'receipts';
  static const _uuid = Uuid();

  /// Upload receipt image and return public URL
  Future<String?> uploadReceipt(File file) async {
    try {
      final userId = SupabaseConfig.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      final extension = file.path.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$extension';
      final path = '$userId/$fileName';

      // Upload file
      await _client.storage
          .from(_receiptsBucket)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final url = _client.storage.from(_receiptsBucket).getPublicUrl(path);
      return url;
    } catch (e) {
      // ignore: avoid_print
      print('Upload error: $e');
      return null;
    }
  }

  /// Delete receipt image
  Future<bool> deleteReceipt(String url) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_receiptsBucket);
      if (bucketIndex == -1) return false;

      final path = pathSegments.sublist(bucketIndex + 1).join('/');
      await _client.storage.from(_receiptsBucket).remove([path]);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Delete error: $e');
      return false;
    }
  }
}
