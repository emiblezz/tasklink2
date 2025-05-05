// In application_model.dart
class ApplicationModel {
  final int? id;
  final int jobId;
  final String applicantId;
  final DateTime? dateApplied;
  final String applicationStatus;

  ApplicationModel({
    this.id,
    required this.jobId,
    required this.applicantId,
    this.dateApplied,
    this.applicationStatus = 'Pending',
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] ?? json['application_id'],  // Handle both column names
      jobId: json['job_id'],
      applicantId: json['applicant_id'],
      dateApplied: json['date_applied'] != null
          ? DateTime.parse(json['date_applied'])
          : null,
      applicationStatus: json['status'] ?? json['application_status'] ?? 'Pending',  // Handle both column names
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'job_id': jobId,
      'applicant_id': applicantId,
      'date_applied': dateApplied?.toIso8601String(),
    };

    // Only include ID if it's not null
    if (id != null) {
      // Try to match the database schema
      data['application_id'] = id;
    }

    // Add status with both possible column names to ensure at least one works
    data['status'] = applicationStatus;
    data['application_status'] = applicationStatus;

    return data;
  }

  ApplicationModel copyWith({
    int? id,
    int? jobId,
    String? applicantId,
    DateTime? dateApplied,
    String? applicationStatus,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicantId: applicantId ?? this.applicantId,
      dateApplied: dateApplied ?? this.dateApplied,
      applicationStatus: applicationStatus ?? this.applicationStatus,
    );
  }
}