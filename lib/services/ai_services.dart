import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIService {
  final String baseUrl;

  AIService({required this.baseUrl});

  // Rank resumes using TFIDF
  Future<List<Map<String, dynamic>>> rankResumesByJob(String jobDescription, List<String> resumes) async {
    try {
      // First try to use the backend API
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/ranking_tfidf'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'job_description': jobDescription,
            'resumes': resumes,
            'type': 'job'
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('Ranking response: ${response.body}');
          final data = jsonDecode(response.body);

          // Handle different response formats
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          } else if (data['rankings'] != null && data['rankings'] is List) {
            return List<Map<String, dynamic>>.from(data['rankings']);
          }
        }

        // If we got here, the API call didn't return valid data
        throw Exception('Invalid response from ranking API');
      } catch (e) {
        debugPrint('Error calling backend API: $e');
        // Fall back to local simple ranking if backend API fails
        return _fallbackRanking(jobDescription, resumes);
      }
    } catch (e) {
      debugPrint('Error in ranking: $e');
      // Final fallback
      return _fallbackRanking(jobDescription, resumes);
    }
  }

  // Simple fallback ranking algorithm that works locally
  List<Map<String, dynamic>> _fallbackRanking(String jobDescription, List<String> resumes) {
    final List<Map<String, dynamic>> results = [];

    // Extract keywords from job description (very basic approach)
    final keywords = _extractKeywords(jobDescription.toLowerCase());
    debugPrint('Keywords from job description: $keywords');

    // Score each resume
    for (int i = 0; i < resumes.length; i++) {
      final resumeText = resumes[i].toLowerCase();
      final resumeKeywords = _extractKeywords(resumeText);

      // Calculate matching and missing skills
      final matchingSkills = keywords.where((k) => resumeKeywords.contains(k)).toList();
      final missingSkills = keywords.where((k) => !resumeKeywords.contains(k)).toList();

      // Calculate a simple score based on keyword matches
      final score = keywords.isEmpty ? 0.5 : matchingSkills.length / keywords.length;

      results.add({
        'resume_index': i,
        'score': score,
        'matching_skills': matchingSkills,
        'missing_skills': missingSkills,
      });
    }

    // Sort by score in descending order
    results.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return results;
  }

  // Match resume against job description using hosted backend
  Future<Map<String, dynamic>?> matchResumeToJob({
    required String jobDescription,
    required String resume,
    double threshold = 0.75
  }) async {
    try {
      debugPrint('Matching resume against job description with hosted backend...');

      final url = Uri.parse('https://bse25-34-fyp-backend.onrender.com/match');

      // Create request body
      final requestBody = jsonEncode({
        'job_description': jobDescription,
        'resume': resume,
        'threshold': threshold
      });

      debugPrint('Sending request to $url');

      // Set headers for JSON
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Make the POST request
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );

      // Check for successful response
      if (response.statusCode == 200) {
        debugPrint('Received successful response from resume matcher API');
        return jsonDecode(response.body);
      } else {
        debugPrint('Error from resume matcher API: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception in matchResumeToJob: $e');
      return null;
    }
  }

  // Very basic keyword extraction (skills and technologies)
  List<String> _extractKeywords(String text) {
    // List of common technical skills and keywords
    final commonSkills = [
      'python', 'java', 'javascript', 'typescript', 'flutter', 'dart', 'react',
      'angular', 'vue', 'node', 'express', 'django', 'flask', 'spring',
      'html', 'css', 'sql', 'nosql', 'mongodb', 'postgresql', 'mysql',
      'git', 'docker', 'kubernetes', 'aws', 'azure', 'gcp', 'firebase',
      'mobile', 'web', 'frontend', 'backend', 'fullstack', 'devops',
      'machine learning', 'data science', 'ai', 'cloud', 'blockchain',
      'agile', 'scrum', 'jira', 'team lead', 'project management',
    ];

    // Extract skills that appear in the text
    final foundSkills = commonSkills.where((skill) => text.contains(skill)).toList();

    return foundSkills;
  }

  // Rank applications using Gemini (simplified version that falls back to TF-IDF)
  Future<List<Map<String, dynamic>>> rankApplicationsWithGemini(String jobDescription, List<String> resumes) async {
    // For now, just use the TF-IDF method as a fallback
    return rankResumesByJob(jobDescription, resumes);
  }

  // Get skill recommendations (simplified version)
  Future<Map<String, dynamic>> getSkillRecommendations(String userSkills, List<String> jobSkills) async {
    try {
      // First try to use the backend API
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/recommendations'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_skills': userSkills,
            'job_skills': jobSkills
          }),
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }

        throw Exception('Invalid response from recommendations API');
      } catch (e) {
        debugPrint('Error calling recommendations API: $e');
        // Fall back to local simple recommendations
        return _fallbackRecommendations(userSkills, jobSkills);
      }
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      return _fallbackRecommendations(userSkills, jobSkills);
    }
  }

  // Simple fallback recommendations
  Map<String, dynamic> _fallbackRecommendations(String userSkills, List<String> jobSkills) {
    final userSkillsList = userSkills.toLowerCase().split(',').map((s) => s.trim()).toList();

    // Find skills that are in the job but not in the user's skills
    final recommendations = jobSkills
        .where((skill) => !userSkillsList.any((userSkill) =>
    userSkill == skill.toLowerCase() ||
        skill.toLowerCase().contains(userSkill) ||
        userSkill.contains(skill.toLowerCase())))
        .toList();

    return {
      'recommendations': recommendations.take(5).toList(),
      'score': userSkillsList.isEmpty ? 0.0 :
      jobSkills.isEmpty ? 1.0 :
      (jobSkills.length - recommendations.length) / jobSkills.length
    };
  }
}