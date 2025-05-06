class ApplicationModel {
  final int? id;
  final int jobId;
  final String applicantId;
  final String applicationStatus;
  final DateTime? dateApplied;

  ApplicationModel({
    this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicationStatus,
    this.dateApplied,
  });

  // Ensure this method correctly updates the status
  ApplicationModel copyWith({
    int? id,
    int? jobId,
    String? applicantId,
    String? applicationStatus,
    DateTime? dateApplied,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicantId: applicantId ?? this.applicantId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      dateApplied: dateApplied ?? this.dateApplied,
    );
  }

  // Ensure this correctly maps between database and model
  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['application_id'] ?? json['id'],
      jobId: json['job_id'],
      applicantId: json['applicant_id'],
      applicationStatus: json['application_status'] ?? 'Pending',
      dateApplied: json['date_applied'] != null
          ? DateTime.parse(json['date_applied'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application_id': id,
      'job_id': jobId,
      'applicant_id': applicantId,
      'application_status': applicationStatus,
      'date_applied': dateApplied?.toIso8601String(),
    };
  }
}