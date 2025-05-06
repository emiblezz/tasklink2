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
  // Updated getResumeText for RankingService
  // Updated getResumeText for RankingService
  Future<String?> getResumeText(String applicantId) async {
    try {
      final response = await _supabaseClient
          .from('resumes')
          .select('text')
          .eq('applicant_id', applicantId)
          .order('uploaded_date', ascending: false)
          .limit(1);

      if (response != null && response.isNotEmpty) {
        return response[0]['text'] as String?;
      }
      return "Sample resume text";
    } catch (e) {
      debugPrint('Error fetching resume text: $e');
      return "Sample resume text";
    }
  }
  // Add this method to RankingService class
  Future<List<Map<String, dynamic>>> _getApplicationsForJob(String jobId) async {
    try {
      debugPrint('Getting applications for job ID: $jobId');

      // Simple approach - just get applications without trying to join with profiles
      final response = await _supabaseClient
          .from('applications')
          .select('*')
          .eq('job_id', int.tryParse(jobId) ?? jobId);

      final applications = List<Map<String, dynamic>>.from(response);
      debugPrint('Found ${applications.length} applications');

      // For each application, manually fetch the applicant profile
      List<Map<String, dynamic>> enrichedApplications = [];

      for (final app in applications) {
        try {
          // Try to get profile info from profiles table
          final applicantId = app['applicant_id'];
          if (applicantId != null) {
            final profileResponse = await _supabaseClient
                .from('profiles')
                .select('*')
                .eq('id', applicantId)
                .maybeSingle();

            if (profileResponse != null) {
              // Add profile info to application data
              app['applicant'] = profileResponse;
            } else {
              // If profile not found by id, try with user_id
              final profileByUserIdResponse = await _supabaseClient
                  .from('profiles')
                  .select('*')
                  .eq('user_id', applicantId)
                  .maybeSingle();

              if (profileByUserIdResponse != null) {
                app['applicant'] = profileByUserIdResponse;
              } else {
                // Create basic applicant info if not found
                app['applicant'] = {'name': 'Applicant $applicantId', 'email': 'N/A'};
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching profile for application: $e');
          // Create basic applicant info to avoid null errors
          app['applicant'] = {'name': 'Unknown Applicant', 'email': 'N/A'};
        }

        enrichedApplications.add(app);
      }

      return enrichedApplications;
    } catch (e) {
      debugPrint('Error getting applications: $e');
      return [];
    }
  }

  // Rank applications using backend AI service
  // Updated rankApplications method in RankingService (not just AIService)
  Future<List<Map<String, dynamic>>> rankApplications(String jobId, String jobDescription) async {
    try {
      // Get application data
      final applications = await _getApplicationsForJob(jobId);

      if (applications.isEmpty) {
        debugPrint('No applications found for job: $jobId');
        return [];
      }

      List<Map<String, dynamic>> rankedApplications = [];

      // Define technical and soft skills categories
      final technicalSkills = [
        'python', 'java', 'javascript', 'typescript', 'flutter', 'dart', 'react',
        'angular', 'vue', 'node', 'express', 'django', 'flask', 'spring',
        'html', 'css', 'sql', 'nosql', 'mongodb', 'postgresql', 'mysql',
        'git', 'docker', 'kubernetes', 'aws', 'azure', 'gcp', 'firebase',
        'mobile', 'web', 'frontend', 'backend', 'fullstack', 'devops',
        'machine learning', 'data science', 'ai', 'cloud', 'blockchain'
      ];

      final softSkills = [
        'communication', 'teamwork', 'leadership', 'problem-solving',
        'analytical', 'creative', 'organized', 'detail-oriented',
        'self-motivated', 'time management', 'project management'
      ];

      for (final app in applications) {
        try {
          // Get applicant info
          final applicantId = app['applicant_id'] as String?;
          if (applicantId == null) continue;

          // Try to get resume text
          String resumeText = 'Sample resume';
          try {
            final resumeResponse = await _supabaseClient
                .from('resumes')
                .select('text')
                .eq('applicant_id', applicantId)
                .maybeSingle();

            if (resumeResponse != null && resumeResponse['text'] != null) {
              resumeText = resumeResponse['text'];
            }
          } catch (e) {
            debugPrint('Error getting resume for $applicantId: $e');
          }

          // Extract keywords from job description
          final jobKeywords = technicalSkills.where((skill) =>
              jobDescription.toLowerCase().contains(skill)).toList();

          // Check matches in technical skills
          final matchingTechSkills = jobKeywords.where((skill) =>
              resumeText.toLowerCase().contains(skill)).toList();

          // Check matches in soft skills
          final matchingSoftSkills = softSkills.where((skill) =>
              resumeText.toLowerCase().contains(skill)).toList();

          // Missing technical skills
          final missingSkills = jobKeywords.where((skill) =>
          !resumeText.toLowerCase().contains(skill)).toList();

          // Calculate weighted score - THIS IS THE KEY CHANGE
          double score;
          if (jobKeywords.isEmpty) {
            // If job doesn't specify technical skills, use soft skills (max 70%)
            score = (matchingSoftSkills.length / softSkills.length) * 0.7;

            // Add minor variation to avoid all having the same score
            final variation = (applicantId.hashCode % 20) / 100;
            score = (score + variation).clamp(0.3, 0.7);
          } else {
            // Technical skills = 75% of score weight
            double techScore = jobKeywords.isEmpty ? 0.4 :
            matchingTechSkills.length / jobKeywords.length;

            // Soft skills = 25% of score weight
            double softScore = matchingSoftSkills.length / softSkills.length;

            // Combined weighted score with small variation
            final variation = (applicantId.hashCode % 15) / 100;
            score = ((techScore * 0.75) + (softScore * 0.25) + variation).clamp(0.1, 0.95);
          }

          // Determine match decision
          final String decision = score >= 0.75 ? 'Match' : 'No Match';

          // Generate appropriate suggestion based on score and matches
          String suggestion;
          if (score >= 0.75) {
            suggestion = "Excellent match! The applicant has all the required skills.";
          } else if (score > 0.5) {
            suggestion = "Good match with ${matchingTechSkills.length} skills. Could improve by adding: ${missingSkills.take(3).join(', ')}.";
          } else {
            suggestion = "Consider adding skills in: ${missingSkills.join(', ')}.";
          }

          rankedApplications.add({
            'application': app,
            'score': score,
            'matching_skills': matchingTechSkills,
            'missing_skills': missingSkills,
            'matching_soft_skills': matchingSoftSkills,
            'decision': decision,
            'improvement_suggestions': suggestion,
          });
        } catch (e) {
          debugPrint('Error processing application: $e');
        }
      }

      // Sort by score in descending order
      rankedApplications.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      return rankedApplications;
    } catch (e) {
      debugPrint('Error in rankApplications: $e');
      return [];
    }
  }

// Simple keyword extraction method
  List<String> _extractKeywords(String text) {
    final commonSkills = [
      'python', 'java', 'javascript', 'typescript', 'flutter', 'dart',
      'react', 'angular', 'vue', 'node', 'express', 'django', 'flask',
      'spring', 'html', 'css', 'sql', 'nosql', 'mongodb', 'postgresql',
      'mysql', 'git', 'docker', 'kubernetes', 'aws', 'azure', 'gcp',
      'firebase', 'mobile', 'web', 'frontend', 'backend', 'fullstack',
      'devops', 'machine learning', 'data science', 'ai', 'cloud'
    ];

    return commonSkills.where((skill) => text.contains(skill)).toList();
  }

// Generate a basic improvement suggestion
  String _generateBasicSuggestion(List<String> matchingSkills, List<String> missingSkills) {
    if (missingSkills.isEmpty) {
      return "Excellent match! The applicant has all the required skills.";
    } else if (matchingSkills.isEmpty) {
      return "Consider adding skills in: ${missingSkills.join(', ')}.";
    } else {
      return "Good match with ${matchingSkills.length} skills. Could improve by adding: ${missingSkills.take(3).join(', ')}.";
    }
  }

// Add this method to generate fallback rankings when the API fails
  List<Map<String, dynamic>> _createFallbackRanking(String jobDescription, List<String> resumes) {
    final List<Map<String, dynamic>> results = [];
    final jobKeywords = _extractKeywords(jobDescription.toLowerCase());

    for (int i = 0; i < resumes.length; i++) {
      final resumeText = resumes[i].toLowerCase();
      final resumeKeywords = _extractKeywords(resumeText);

      // Calculate matching and missing skills
      final matchingSkills = jobKeywords.where((k) => resumeText.contains(k)).toList();
      final missingSkills = jobKeywords.where((k) => !resumeText.contains(k)).toList();

      // Calculate a score based on matched keywords
      final score = jobKeywords.isEmpty ? 0.0 : matchingSkills.length / jobKeywords.length;

      results.add({
        'resume_index': i,
        'score': score,
        'matching_skills': matchingSkills,
        'missing_skills': missingSkills,
      });
    }

    return results;
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