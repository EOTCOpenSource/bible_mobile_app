class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  UserProfile copyWith({String? name, String? avatar}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      avatar: avatar ?? this.avatar,
    );
  }
}
