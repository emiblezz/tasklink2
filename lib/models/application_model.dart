// In application_model.dart
class ApplicationModel {
  final int? id;
  final int jobId;
  final String applicantId;
  final String applicationStatus;
  final DateTime? dateApplied;
  final String? recruiterFeedback;
  final double? matchScore;

  ApplicationModel({
    this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicationStatus,
    this.dateApplied,
    this.recruiterFeedback,
    this.matchScore,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['application_id'],
      jobId: json['job_id'],
      applicantId: json['applicant_id'],
      applicationStatus: json['application_status'] ?? 'Pending',
      dateApplied: json['date_applied'] != null
          ? DateTime.parse(json['date_applied'])
          : null,
      recruiterFeedback: json['recruiter_feedback'],
      matchScore: json['match_score'] != null
          ? double.parse(json['match_score'].toString())
          : null,
    );
  }

  ApplicationModel copyWith({
    int? id,
    int? jobId,
    String? applicantId,
    String? applicationStatus,
    DateTime? dateApplied,
    String? recruiterFeedback,
    double? matchScore,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicantId: applicantId ?? this.applicantId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      dateApplied: dateApplied ?? this.dateApplied,
      recruiterFeedback: recruiterFeedback ?? this.recruiterFeedback,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}