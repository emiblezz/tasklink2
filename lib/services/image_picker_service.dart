import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tasklink2/config/app_config.dart';

class ImagePickerService {
  // Pick image files using the latest file_picker API
  static Future<String?> pickCompanyLogo() async {
    try {
      // Check if the user is authenticated first
      final currentUser = AppConfig().supabaseClient.auth.currentUser;
      if (currentUser == null) {
        debugPrint('Error: User not authenticated');
        return null;
      }

      const bucketName = 'company.assets';

      // Use the latest FilePicker API
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('No image selected');
        return null;
      }

      final file = result.files.first;

      // If no path (web platform), return null
      if (file.path == null) {
        debugPrint('File path is null (web platform?)');
        return null;
      }

      // Create file from path
      final imageFile = File(file.path!);
      final fileName = file.name;

      // Generate a unique path to avoid collisions
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final companyName = fileName.split('.').first; // Use filename as fallback company name
      final uniqueFileName = '${companyName}_$timestamp.${fileName.split('.').last}';

      // Include the user ID in the path for better organization and security
      final userId = currentUser.id;
      final filePath = 'company_logos/$userId/$uniqueFileName';

      // Upload to Supabase storage
      try {
        debugPrint('Attempting to upload file to $bucketName/$filePath');

        await AppConfig().supabaseClient
            .storage
            .from(bucketName)
            .upload(filePath, imageFile);

        // Get the public URL
        final urlResponse = await AppConfig().supabaseClient
            .storage
            .from(bucketName)
            .getPublicUrl(filePath);

        debugPrint('Logo uploaded successfully: $urlResponse');
        return urlResponse;
      } catch (uploadError) {
        debugPrint('Error uploading company logo: $uploadError');
        return null;
      }
    } catch (e) {
      debugPrint('Exception in image picker: $e');
      return null;
    }
  }
}