class RecruiterProfileModel {
  final String userId;
  final String? companyName;
  final String? companyDescription;
  final String? website;
  final String? industry;
  final String? location;
  final String? logoUrl;

  RecruiterProfileModel({
    required this.userId,
    this.companyName,
    this.companyDescription,
    this.website,
    this.industry,
    this.location,
    this.logoUrl,
  });

  // Create a copy with modified fields
  RecruiterProfileModel copyWith({
    String? userId,
    String? companyName,
    String? companyDescription,
    String? website,
    String? industry,
    String? location,
    String? logoUrl,
  }) {
    return RecruiterProfileModel(
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      companyDescription: companyDescription ?? this.companyDescription,
      website: website ?? this.website,
      industry: industry ?? this.industry,
      location: location ?? this.location,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  // Convert model to JSON map
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'company_name': companyName,
      'company_description': companyDescription,
      'website': website,
      'industry': industry,
      'location': location,
      'logo_url': logoUrl,
    };
  }

  // Create model from JSON map
  factory RecruiterProfileModel.fromJson(Map<String, dynamic> json) {
    return RecruiterProfileModel(
      userId: json['user_id'],
      companyName: json['company_name'],
      companyDescription: json['company_description'],
      website: json['website'],
      industry: json['industry'],
      location: json['location'],
      logoUrl: json['logo_url'],
    );
  }
}