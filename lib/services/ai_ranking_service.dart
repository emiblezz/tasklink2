import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Model for individual word match
class WordMatch {
  final String resumeWord;
  final String bestJobWord;
  final double score;

  WordMatch({
    required this.resumeWord,
    required this.bestJobWord,
    required this.score,
  });

  factory WordMatch.fromJson(Map<String, dynamic> json) {
    return WordMatch(
      resumeWord: json['resume_word'],
      bestJobWord: json['best_job_word'],
      score: (json['score'] as num).toDouble(),
    );
  }
}

/// Model for the similarity response
class SimilarityResponse {
  final double similarityScore;
  final String decision;
  final List<WordMatch> wordMatches;

  SimilarityResponse({
    required this.similarityScore,
    required this.decision,
    required this.wordMatches,
  });

  factory SimilarityResponse.fromJson(Map<String, dynamic> json) {
    return SimilarityResponse(
      similarityScore: (json['similarity_score'] as num).toDouble(),
      decision: json['decision'],
      wordMatches: (json['word_matches'] as List)
          .map((item) => WordMatch.fromJson(item))
          .toList(),
    );
  }
}

/// Service to call the similarity endpoint
class SimilarityService {
  final String baseUrl;

  SimilarityService({required this.baseUrl});

  Future<SimilarityResponse> checkSimilarity({
    required String resume,
    required String jobDescription,
    required double threshold,
  }) async {
    final url = Uri.parse('$baseUrl/match');

    print(url);
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'resume': resume,
      'job_description': jobDescription,
      'threshold': threshold,
    });

    final response = await http.post(url, headers: headers, body: body);

    print("response: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SimilarityResponse.fromJson(jsonResponse);
    } else {
      print("body: ${response.body}");
      throw Exception('Failed to get similarity score: ${response.body} code: ${response.statusCode}');
    }
  }

  Future<SimilarityResponse> checkFileSimilarity({
    required String resume,
    required String jobDescription,
    required double threshold,
  }) async {
    final url = Uri.parse('$baseUrl/match_resume_file');

    print(url);
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'resume': resume,
      'job_description': jobDescription,
      'threshold': threshold,
    });

    final response = await http.post(url, headers: headers, body: body);

    print("response: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SimilarityResponse.fromJson(jsonResponse);
    } else {
      print("body: ${response.body}");
      throw Exception('Failed to get similarity score: ${response.body} code: ${response.statusCode}');
    }
  }
}
