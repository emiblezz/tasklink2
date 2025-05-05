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
  static Future<String?> pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: true, // Ensures we get the file data directly
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

      // Don't try to create the bucket programmatically

      // Use plain text for simplicity if you don't have the backend extract_text endpoint yet
      String resumeText = "";

      if (fileName.toLowerCase().endsWith('.txt')) {
        // For text files, we can extract the content directly
        resumeText = utf8.decode(fileBytes);
      } else {
        // For other files, use a placeholder text until backend is fully implemented
        resumeText = "Resume content for $fileName. This is a placeholder that would be replaced with actual extracted text from the backend.";
      }

      // Try to upload to Supabase Storage
      String? fileUrl;
      bool isUploaded = false;

      try {
        // Upload file to storage
        final storagePath = '$userId/$fileName';
        debugPrint('Uploading to storage path: $storagePath');

        final uploadResponse = await AppConfig().supabaseClient.storage
            .from('resumes')
            .uploadBinary(
          storagePath,
          fileBytes,
          fileOptions: FileOptions(
            contentType: _getContentType(fileName),
          ),
        );

        debugPrint('Upload successful: $uploadResponse');

        // Get the public URL
        fileUrl = AppConfig().supabaseClient.storage
            .from('resumes')
            .getPublicUrl(storagePath);

        debugPrint('File public URL: $fileUrl');
        isUploaded = true;
      } catch (storageError) {
        debugPrint('Storage upload error: $storageError');
        // Continue with local processing even if storage fails
        fileUrl = 'https://example.com/fallback/$fileName#fallback';
      }

      // Store the text in Supabase database
      try {
        debugPrint('Storing resume text in database for user: $userId');
        await AppConfig().supabaseClient.from('resumes').insert({
          'applicant_id': userId,
          'text': resumeText,
          'filename': fileName,
          'uploaded_date': DateTime.now().toIso8601String(),
        });
        debugPrint('Resume text stored successfully');
      } catch (e) {
        debugPrint('Error storing resume text: $e');
        // Continue even if storing fails
      }

      // Return the URL (or fallback URL) to be stored in the user profile
      return fileUrl;
    } catch (e) {
      debugPrint('Error picking file: $e');
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