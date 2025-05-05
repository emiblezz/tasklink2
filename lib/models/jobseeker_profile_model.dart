class JobSeekerProfileModel {
  final int? id;
  final String userId;
  final String? cv;
  final String? skills;
  final String? experience;
  final String? education;
  final String? linkedinProfile;

  JobSeekerProfileModel({
    this.id,
    required this.userId,
    this.cv,
    this.skills,
    this.experience,
    this.education,
    this.linkedinProfile,
  });

  // Create from JSON
  factory JobSeekerProfileModel.fromJson(Map<String, dynamic> json) {
    return JobSeekerProfileModel(
      id: json['profile_id'],
      userId: json['user_id'],
      cv: json['cv'],
      skills: json['skills'],
      experience: json['experience'],
      education: json['education'],
      linkedinProfile: json['linkedin_profile'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'profile_id': id,
      'user_id': userId,
      if (cv != null) 'cv': cv,
      if (skills != null) 'skills': skills,
      if (experience != null) 'experience': experience,
      if (education != null) 'education': education,
      if (linkedinProfile != null) 'linkedin_profile': linkedinProfile,
    };
  }

  // Create a copy with updated fields
  JobSeekerProfileModel copyWith({
    int? id,
    String? userId,
    String? cv,
    String? skills,
    String? experience,
    String? education,
    String? linkedinProfile,
  }) {
    return JobSeekerProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cv: cv ?? this.cv,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      linkedinProfile: linkedinProfile ?? this.linkedinProfile,
    );
  }
}