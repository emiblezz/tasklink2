import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/services/ai_services.dart';



// This class is no longer extending ChangeNotifier
class RankingService {
  final SupabaseClient _supabaseClient;
  final AIService _aiService;

  RankingService({
    required SupabaseClient supabaseClient,
    required AIService aiService,
  })  : _supabaseClient = supabaseClient,
        _aiService = aiService;

  // Get resume text for an applicant
  Future<String?> getResumeText(String applicantId) async {
    try {
      final response = await _supabaseClient
          .from('resumes')
          .select('text')
          .eq('applicant_id', applicantId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return response['text'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching resume text: $e');
      return null;
    }
  }

  // Rank applications using backend AI service
  Future<List<Map<String, dynamic>>> rankApplications(String jobId, String jobDescription) async {
    try {
      // Get application data - you may need to modify this to match your database schema
      final applications = await _getApplicationsForJob(jobId);

      if (applications.isEmpty) {
        debugPrint('No applications found for job: $jobId');
        return [];
      }

      // Get resume texts for each applicant
      List<String> resumeTexts = [];
      List<Map<String, dynamic>> applicationData = [];

      for (var app in applications) {
        final applicantId = app['applicant_id'] as String?;
        if (applicantId != null) {
          final resumeText = await getResumeText(applicantId);
          if (resumeText != null) {
            resumeTexts.add(resumeText);
            applicationData.add(app);
          }
        }
      }

      if (resumeTexts.isEmpty) {
        debugPrint('No resume texts found for applications');
        return [];
      }

      // Call AI service to rank resumes
      final rankingResults = await _aiService.rankResumesByJob(jobDescription, resumeTexts);

      // Combine ranking results with application data
      List<Map<String, dynamic>> rankedApplications = [];
      for (int i = 0; i < rankingResults.length; i++) {
        final result = rankingResults[i];
        final resumeIndex = result['resume_index'] as int? ?? i;

        if (resumeIndex < applicationData.length) {
          rankedApplications.add({
            'application': applicationData[resumeIndex],
            'score': result['score'],
            'matching_skills': result['matching_skills'] ?? [],
            'missing_skills': result['missing_skills'] ?? [],
          });
        }
      }

      // Store ranking results
      await _storeRankingResults(jobId, rankedApplications);

      return rankedApplications;
    } catch (e) {
      debugPrint('Error in rankApplications: $e');
      return [];
    }
  }

  // Get applications for a job (simplified version)
  Future<List<Map<String, dynamic>>> _getApplicationsForJob(String jobId) async {
    try {
      // This implementation will depend on your actual database schema
      // Here's a placeholder version that assumes you have an applications table
      final response = await _supabaseClient
          .from('applications')
          .select('*')
          .eq('job_id', jobId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting applications: $e');

      // Return dummy data for testing when the applications table doesn't exist yet
      return [
        {
          'id': 'app1',
          'job_id': jobId,
          'applicant_id': '12345',
          'status': 'pending',
          'applicant': {
            'full_name': 'John Doe',
            'email': 'john@example.com',
          }
        },
        {
          'id': 'app2',
          'job_id': jobId,
          'applicant_id': '67890',
          'status': 'pending',
          'applicant': {
            'full_name': 'Jane Smith',
            'email': 'jane@example.com',
          }
        }
      ];
    }
  }

  // Store ranking results
  Future<void> _storeRankingResults(String jobId, List<Map<String, dynamic>> rankedApplications) async {
    try {
      // Delete existing ranking results
      await _supabaseClient
          .from('ranking_results')
          .delete()
          .eq('job_id', jobId);

      // Insert new ranking results
      for (var app in rankedApplications) {
        final appData = app['application'] as Map<String, dynamic>;
        await _supabaseClient.from('ranking_results').insert({
          'job_id': jobId,
          'application_id': appData['id'],
          'applicant_id': appData['applicant_id'],
          'score': app['score'],
          'matching_skills': app['matching_skills'],
          'missing_skills': app['missing_skills'],
        });
      }
    } catch (e) {
      debugPrint('Error storing ranking results: $e');
      // Continue even if storing fails
    }
  }
}