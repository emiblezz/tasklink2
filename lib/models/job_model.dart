class JobModel {
  final int? id;
  final String jobTitle;
  final String companyName;
  final String jobType;
  final String location;
  final double? salary; // Make sure this is included
  final DateTime deadline;
  final DateTime? datePosted;
  final String status;
  final String? recruiterId;
  final String? companyLogo; // New field for company logo
  final List<String>? skills;
  final String? jobDescription;
  final String description;
  final String requirements;

  JobModel({
    this.id,
    required this.jobTitle,
    required this.companyName,
    required this.jobType,
    required this.location,
    this.salary,
    required this.deadline,
    this.datePosted,
    required this.status,
    this.recruiterId,
    this.companyLogo, // Add to constructor
    this.skills,
    this.jobDescription,
    required this.description,
    required this.requirements,
  });

  // Update fromJson and toJson methods
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['job_id'],
      jobTitle: json['job_title'] ?? '',
      companyName: json['company_name'] ?? '',
      jobType: json['job_type'] ?? '',
      location: json['location'] ?? '',
      salary: json['salary'] != null ? double.parse(json['salary'].toString()) : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : DateTime.now().add(const Duration(days: 30)),
      datePosted: json['date_posted'] != null
          ? DateTime.parse(json['date_posted'])
          : null,
      status: json['status'] ?? 'Open',
      recruiterId: json['recruiter_id'],
      companyLogo: json['company_logo'], // Parse from JSON
      skills: json['skills'] != null
          ? (json['skills'] is String
          ? json['skills'].split(',')
          : List<String>.from(json['skills']))
          : null,
      jobDescription: json['job_description'],
      description: json['description'] ?? '',
      requirements: json['requirements'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': id,
      'job_title': jobTitle,
      'company_name': companyName,
      'job_type': jobType,
      'location': location,
      'salary': salary,
      'deadline': deadline.toIso8601String(),
      'date_posted': datePosted?.toIso8601String(),
      'status': status,
      'recruiter_id': recruiterId,
      'company_logo': companyLogo, // Include in JSON
      'skills': skills != null ? skills!.join(',') : null,
      'job_description': jobDescription,
      'description': description,
      'requirements': requirements,
    };
  }

  // Update copyWith method too
  JobModel copyWith({
    int? id,
    String? jobTitle,
    String? companyName,
    String? jobType,
    String? location,
    double? salary,
    DateTime? deadline,
    DateTime? datePosted,
    String? status,
    String? recruiterId,
    String? companyLogo,
    List<String>? skills,
    String? jobDescription,
    String? description,
    String? requirements,
  }) {
    return JobModel(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      jobType: jobType ?? this.jobType,
      location: location ?? this.location,
      salary: salary ?? this.salary,
      deadline: deadline ?? this.deadline,
      datePosted: datePosted ?? this.datePosted,
      status: status ?? this.status,
      recruiterId: recruiterId ?? this.recruiterId,
      companyLogo: companyLogo ?? this.companyLogo,
      skills: skills ?? this.skills,
      jobDescription: jobDescription ?? this.jobDescription,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
    );
  }
}