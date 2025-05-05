class RoleModel {
  final int id;
  final String name;

  RoleModel({
    required this.id,
    required this.name,
  });

  // Create from JSON
  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['role_id'] ?? json['id'] ?? 0,
      name: json['role_name'] ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': name,
    };
  }
}