class WordMatchModel {
  final String resumeWord;
  final String jobWord;
  final double score;

  WordMatchModel({
    required this.resumeWord,
    required this.jobWord,
    required this.score
  });

  factory WordMatchModel.fromJson(Map<String, dynamic> json) {
    return WordMatchModel(
      resumeWord: json['resume_word'] ?? '',
      jobWord: json['best_job_word'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resume_word': resumeWord,
      'best_job_word': jobWord,
      'score': score,
    };
  }
}

class ResumeMatchResultModel {
  final String id;
  final String jobId;
  final String applicantId;
  final DateTime matchDate;
  final double similarityScore;
  final String decision;
  final List<WordMatchModel> wordMatches;
  final String? feedback;
  final String? improvementSuggestions;

  ResumeMatchResultModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.matchDate,
    required this.similarityScore,
    required this.decision,
    required this.wordMatches,
    this.feedback,
    this.improvementSuggestions,
  });

  factory ResumeMatchResultModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> wordMatchesJson = json['word_matches'] ?? [];

    return ResumeMatchResultModel(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      applicantId: json['applicant_id'] ?? '',
      matchDate: json['match_date'] != null
          ? DateTime.parse(json['match_date'])
          : DateTime.now(),
      similarityScore: (json['similarity_score'] ?? 0.0).toDouble(),
      decision: json['decision'] ?? 'No Match',
      wordMatches: wordMatchesJson
          .map((match) => WordMatchModel.fromJson(match))
          .toList(),
      feedback: json['feedback'],
      improvementSuggestions: json['improvement_suggestions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'applicant_id': applicantId,
      'match_date': matchDate.toIso8601String(),
      'similarity_score': similarityScore,
      'decision': decision,
      'word_matches': wordMatches.map((match) => match.toJson()).toList(),
      'feedback': feedback,
      'improvement_suggestions': improvementSuggestions,
    };
  }

  // Create a simplified map for storing in database
  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'job_id': jobId,
      'applicant_id': applicantId,
      'match_date': matchDate.toIso8601String(),
      'similarity_score': similarityScore,
      'decision': decision,
      'feedback': feedback,
      'improvement_suggestions': improvementSuggestions,
      // Store only top 20 word matches to keep the DB record size reasonable
      'word_matches': wordMatches.take(20).map((match) => match.toJson()).toList(),
    };
  }

  // Generate improvement suggestions based on match results
  static String generateImprovementSuggestions(
      double score,
      List<WordMatchModel> wordMatches,
      Map<String, dynamic> rawApiResponse
      ) {
    List<String> suggestions = [];

    // Suggestion based on overall score
    if (score < 0.6) {
      suggestions.add("Your resume has a low match score with this job. Consider revising your resume to better align with the job requirements.");
    } else if (score < 0.75) {
      suggestions.add("Your resume is moderately matched to this job. Some targeted improvements could increase your chances.");
    }

    // Get words with low match scores
    final poorMatches = wordMatches
        .where((match) => match.score < 0.6)
        .take(5)
        .map((match) => "${match.resumeWord} -> ${match.jobWord}")
        .toList();

    if (poorMatches.isNotEmpty) {
      suggestions.add("Consider clarifying these terms in your resume: ${poorMatches.join(', ')}");
    }

    // If we have missing skills data (from your original ranking logic)
    if (rawApiResponse.containsKey('missing_skills')) {
      final missingSkills = rawApiResponse['missing_skills'];
      if (missingSkills is List && missingSkills.isNotEmpty) {
        suggestions.add("Consider adding these skills to your profile if you have them: ${missingSkills.take(5).join(', ')}");
      }
    }

    if (suggestions.isEmpty) {
      return "Your resume is well-matched to this job. No specific improvements needed.";
    }

    return suggestions.join("\n\n");
  }
}