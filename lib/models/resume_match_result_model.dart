class ResumeMatchResultModel {
  final String id;
  final String jobId;
  final String applicantId;
  final DateTime matchDate;
  final double similarityScore;
  final String decision;
  final List<WordMatchModel> wordMatches;
  final String improvementSuggestions;

  ResumeMatchResultModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.matchDate,
    required this.similarityScore,
    required this.decision,
    required this.wordMatches,
    required this.improvementSuggestions,
  });

  factory ResumeMatchResultModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> wordMatchesJson = json['word_matches'] ?? [];
    final List<WordMatchModel> wordMatches = wordMatchesJson
        .map((match) => WordMatchModel.fromJson(match))
        .toList();

    return ResumeMatchResultModel(
      id: json['id'],
      jobId: json['job_id'],
      applicantId: json['applicant_id'],
      matchDate: DateTime.parse(json['match_date']),
      similarityScore: json['similarity_score'] ?? 0.0,
      decision: json['decision'] ?? getDecisionFromScore(json['similarity_score'] ?? 0.0),
      wordMatches: wordMatches,
      improvementSuggestions: json['improvement_suggestions'] ??
          generateImprovementSuggestions(json['similarity_score'] ?? 0.0, wordMatches, json),
    );
  }

  Map<String, dynamic> toDbJson() {
    return {
      'id': id,
      'job_id': jobId,
      'applicant_id': applicantId,
      'match_date': matchDate.toIso8601String(),
      'similarity_score': similarityScore,
      'decision': decision,
      'word_matches': wordMatches.map((wm) => wm.toJson()).toList(),
      'improvement_suggestions': improvementSuggestions,
    };
  }

  // Updated method to generate improvement suggestions based on new scoring tiers
  static String generateImprovementSuggestions(
      double score, List<WordMatchModel> wordMatches, Map<String, dynamic> matchResult) {

    final missingSkills = matchResult['missing_skills'] ?? [];

    if (score >= 0.80) {
      return "Excellent candidate with all key skills and experience required.";
    } else if (score >= 0.65) {
      return "Good candidate with most key skills. ${missingSkills.isNotEmpty ? 'Could improve by adding: ${missingSkills.take(3).join(', ')}.' : ''}";
    } else if (score >= 0.50) {
      return "Has some relevant skills but lacks key requirements. Consider adding: ${missingSkills.take(4).join(', ')}.";
    } else {
      return "Not a good match for this role. Missing critical skills: ${missingSkills.take(5).join(', ')}.";
    }
  }

  // Helper method to get decision from score
  static String getDecisionFromScore(double score) {
    if (score >= 0.80) return "Strong Match";
    if (score >= 0.65) return "Good Match";
    if (score >= 0.50) return "Potential Match";
    return "No Match";
  }
}

class WordMatchModel {
  final String resumeWord;
  final String jobWord;
  final double score;

  WordMatchModel({
    required this.resumeWord,
    required this.jobWord,
    required this.score,
  });

  factory WordMatchModel.fromJson(Map<String, dynamic> json) {
    return WordMatchModel(
      resumeWord: json['resume_word'] ?? '',
      jobWord: json['best_job_word'] ?? json['job_word'] ?? '',
      score: json['score'] ?? 0.0,
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