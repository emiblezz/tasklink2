import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/config/app_config.dart';
import 'package:tasklink2/models/resume_match_result_model.dart';
import 'package:tasklink2/services/ai_services.dart';
import 'package:uuid/uuid.dart';

class ResumeMatchService {
  final SupabaseClient _supabaseClient;
  final AIService _aiService;

  ResumeMatchService({
    SupabaseClient? supabaseClient,
    AIService? aiService,
  }) : _supabaseClient = supabaseClient ?? AppConfig().supabaseClient,
        _aiService = aiService ?? AIService(baseUrl: AppConfig.backendUrl);

  // Match a resume against a job description and store the result
  Future<ResumeMatchResultModel?> matchAndStoreResult({
    required String jobId,
    required String applicantId,
    required String resumeText,
    required String jobDescription,
    double threshold = 0.75,
  }) async {
    try {
      // Match the resume using the AI service
      final matchResult = await _aiService.matchResumeToJob(
        jobDescription: jobDescription,
        resume: resumeText,
        threshold: threshold,
      );

      if (matchResult == null) {
        debugPrint('Match result is null');
        return null;
      }

      // Create a unique ID for this match result
      final id = const Uuid().v4();
      final now = DateTime.now();

      // Convert API response to our model
      final List<dynamic> wordMatchesJson = matchResult['word_matches'] ?? [];
      final List<WordMatchModel> wordMatches = wordMatchesJson
          .map((match) => WordMatchModel.fromJson(match))
          .toList();

      // Generate improvement suggestions
      final improvementSuggestions = ResumeMatchResultModel.generateImprovementSuggestions(
          matchResult['similarity_score'] ?? 0.0,
          wordMatches,
          matchResult
      );

      // Create model
      final resultModel = ResumeMatchResultModel(
        id: id,
        jobId: jobId,
        applicantId: applicantId,
        matchDate: now,
        similarityScore: matchResult['similarity_score'] ?? 0.0,
        decision: matchResult['decision'] ?? 'No Match',
        wordMatches: wordMatches,
        improvementSuggestions: improvementSuggestions,
      );

      // Store in database
      await _storeMatchResult(resultModel);

      return resultModel;
    } catch (e) {
      debugPrint('Error in matchAndStoreResult: $e');
      return null;
    }
  }

  // Store match result in database
  Future<void> _storeMatchResult(ResumeMatchResultModel result) async {
    try {
      // First check if we already have a result for this job and applicant
      final existingResult = await _supabaseClient
          .from('resume_match_results')
          .select()
          .eq('job_id', result.jobId)
          .eq('applicant_id', result.applicantId)
          .maybeSingle();

      if (existingResult != null) {
        // Update existing record
        await _supabaseClient
            .from('resume_match_results')
            .update(result.toDbJson())
            .eq('id', existingResult['id']);
      } else {
        // Insert new record
        await _supabaseClient
            .from('resume_match_results')
            .insert(result.toDbJson());
      }
    } catch (e) {
      debugPrint('Error storing match result: $e');
      // Continue even if storage fails
    }
  }

  // Get match result for a specific job and applicant
  Future<ResumeMatchResultModel?> getMatchResult({
    required String jobId,
    required String applicantId,
  }) async {
    try {
      final result = await _supabaseClient
          .from('resume_match_results')
          .select()
          .eq('job_id', jobId)
          .eq('applicant_id', applicantId)
          .maybeSingle();

      if (result != null) {
        return ResumeMatchResultModel.fromJson(result);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting match result: $e');
      return null;
    }
  }

  // Get all match results for a job
  Future<List<ResumeMatchResultModel>> getMatchResultsForJob(String jobId) async {
    try {
      final results = await _supabaseClient
          .from('resume_match_results')
          .select()
          .eq('job_id', jobId)
          .order('similarity_score', ascending: false);

      return (results as List)
          .map((result) => ResumeMatchResultModel.fromJson(result))
          .toList();
    } catch (e) {
      debugPrint('Error getting match results for job: $e');
      return [];
    }
  }

  // Get all match results for an applicant
  Future<List<ResumeMatchResultModel>> getMatchResultsForApplicant(String applicantId) async {
    try {
      final results = await _supabaseClient
          .from('resume_match_results')
          .select()
          .eq('applicant_id', applicantId)
          .order('match_date', ascending: false);

      return (results as List)
          .map((result) => ResumeMatchResultModel.fromJson(result))
          .toList();
    } catch (e) {
      debugPrint('Error getting match results for applicant: $e');
      return [];
    }
  }
}