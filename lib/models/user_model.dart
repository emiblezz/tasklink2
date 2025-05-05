class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int roleId;
  final String profileStatus;
  final DateTime? dateJoined;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleId,
    required this.profileStatus,
    this.dateJoined,
  });

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? '', // Always use user_id from database
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      roleId: json['role_id'] ?? 0,
      profileStatus: json['profile_status'] ?? 'Active',
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : null,
    );
  }


  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,  // Changed from 'id' to 'user_id'
      'name': name,
      'email': email,
      'phone': phone,
      'role_id': roleId,
      'profile_status': profileStatus,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }// Convert to JSON


  // Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    int? roleId,
    String? profileStatus,
    DateTime? dateJoined,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      profileStatus: profileStatus ?? this.profileStatus,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }
}