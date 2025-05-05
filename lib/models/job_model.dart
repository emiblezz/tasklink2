class JobModel {
  final int? id;
  final String recruiterId;
  final String jobType;
  final String jobTitle;
  final String description;
  final String requirements;
  final String status;
  final DateTime? datePosted;
  final DateTime deadline;

  JobModel({
    this.id,
    required this.recruiterId,
    required this.jobType,
    required this.jobTitle,
    required this.description,
    required this.requirements,
    this.status = 'Open',
    this.datePosted,
    required this.deadline,
  });

  // Create from JSON
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['job_id'],
      recruiterId: json['recruiter_id'],
      jobType: json['job_type'],
      jobTitle: json['job_title'],
      description: json['description'],
      requirements: json['requirements'],
      status: json['status'] ?? 'Open',
      datePosted: json['date_posted'] != null
          ? DateTime.parse(json['date_posted'])
          : null,
      deadline: DateTime.parse(json['deadline']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'job_id': id,
      'recruiter_id': recruiterId,
      'job_type': jobType,
      'job_title': jobTitle,
      'description': description,
      'requirements': requirements,
      'status': status,
      if (datePosted != null) 'date_posted': datePosted!.toIso8601String(),
      'deadline': deadline.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  JobModel copyWith({
    int? id,
    String? recruiterId,
    String? jobType,
    String? jobTitle,
    String? description,
    String? requirements,
    String? status,
    DateTime? datePosted,
    DateTime? deadline,
  }) {
    return JobModel(
      id: id ?? this.id,
      recruiterId: recruiterId ?? this.recruiterId,
      jobType: jobType ?? this.jobType,
      jobTitle: jobTitle ?? this.jobTitle,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      status: status ?? this.status,
      datePosted: datePosted ?? this.datePosted,
      deadline: deadline ?? this.deadline,
    );
  }
}