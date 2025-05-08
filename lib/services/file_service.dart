import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;

class FileService {
  // Pick CV files (PDF, DOC, DOCX)
  // Updated pickCV method for FileService class
  static Future<String?> pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return null;
      }

      final file = result.files.first;
      final fileName = file.name;
      final fileBytes = file.bytes;

      if (fileBytes == null) {
        debugPrint('Error: No file bytes available');
        return null;
      }

      // Get the current user ID
      final userId = AppConfig().supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Print debug info about the user and auth state
      final currentSession = AppConfig().supabaseClient.auth.currentSession;
      final accessToken = currentSession?.accessToken;
      debugPrint('Current user ID: $userId');
      debugPrint('Has valid session: ${currentSession != null}');
      debugPrint('Access token available: ${accessToken != null && accessToken.isNotEmpty}');

      // Create a simple storage path
      // Avoid nested folders for now to rule out permission issues
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storagePath = uniqueFileName; // Note: No folder structure, just the file name

      // Extract text content as before
      String resumeText = "";
      if (fileName.toLowerCase().endsWith('.txt')) {
        resumeText = utf8.decode(fileBytes);
      } else {
        resumeText = "Resume content for $fileName. This is a placeholder that would be replaced with actual extracted text from the backend.";
      }

      // Try to upload to Supabase Storage
      String? fileUrl;
      bool isUploaded = false;

      // First, verify we can list buckets
      try {
        final buckets = await AppConfig().supabaseClient.storage.listBuckets();
        debugPrint('Available buckets: ${buckets.map((b) => b.name).join(', ')}');

        final bucketExists = buckets.any((b) => b.name == 'resume');
        debugPrint('Resume bucket exists: $bucketExists');

        if (!bucketExists) {
          debugPrint('Warning: resume bucket not found in available buckets');
        }
      } catch (e) {
        debugPrint('Error listing buckets: $e');
      }

      try {
        // Try to upload the file
        debugPrint('Attempting to upload file to bucket: resume, path: $storagePath');
        debugPrint('File size: ${fileBytes.length} bytes');

        final uploadResponse = await AppConfig().supabaseClient.storage
            .from('resume')
            .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getContentType(fileName),
            // Specify cacheControl to make sure it's not cached incorrectly
            cacheControl: '3600',
          ),
        );

        debugPrint('Upload successful! Response: $uploadResponse');

        // Get the public URL
        fileUrl = AppConfig().supabaseClient.storage
            .from('resume')
            .getPublicUrl(storagePath);

        debugPrint('File public URL: $fileUrl');
        isUploaded = true;

        // Verify the file exists by trying to get metadata
        try {
          final fileInfo = await AppConfig().supabaseClient.storage
              .from('resume')
              .list(path: '');

          debugPrint('Files in bucket: ${fileInfo.map((f) => f.name).join(', ')}');

          final fileExists = fileInfo.any((f) => f.name == storagePath);
          debugPrint('Uploaded file found in bucket: $fileExists');
        } catch (e) {
          debugPrint('Error listing files in bucket: $e');
        }
      } catch (storageError) {
        debugPrint('❌ Storage upload error: $storageError');

        // Detailed error logging
        if (storageError is StorageException) {
          debugPrint('StorageException details: message=${storageError.message}, statusCode=${storageError.statusCode}, error=${storageError.error}');
        }

        // Fallback URL if storage fails
        fileUrl = 'https://example.com/fallback/$fileName#fallback';
      }

      // Store the text in database as before
      try {
        debugPrint('Storing resume text in database for user: $userId');
        await AppConfig().supabaseClient.from('resumes').insert({
          'applicant_id': userId,
          'text': resumeText,
          'filename': fileName,
          'uploaded_date': DateTime.now().toIso8601String(),
        });
        debugPrint('Resume text stored successfully in resumes table');

        // Update profile
        try {
          final existingProfile = await AppConfig().supabaseClient
              .from('jobseeker_profiles')
              .select('profile_id')
              .eq('user_id', userId)
              .limit(1);

          if (existingProfile.isNotEmpty) {
            debugPrint('Updating existing profile with CV: $fileUrl');
            await AppConfig().supabaseClient
                .from('jobseeker_profiles')
                .update({'cv': fileUrl})
                .eq('user_id', userId);
            debugPrint('Profile updated successfully');
          } else {
            debugPrint('Creating new profile with CV: $fileUrl');
            await AppConfig().supabaseClient
                .from('jobseeker_profiles')
                .insert({
              'user_id': userId,
              'cv': fileUrl,
              'skills': '',
              'experience': '',
              'education': '',
            });
            debugPrint('New profile created successfully');
          }
        } catch (profileError) {
          debugPrint('Error updating profile: $profileError');
        }
      } catch (e) {
        debugPrint('Error storing resume text: $e');
      }

      return fileUrl;
    } catch (e) {
      debugPrint('Error in pickCV: $e');
      return null;
    }
  }

  // Helper method to determine content type
  static String _getContentType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.toLowerCase().endsWith('.doc')) {
      return 'application/msword';
    } else if (fileName.toLowerCase().endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      return 'text/plain';
    } else {
      return 'application/octet-stream';
    }
  }
}