class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.provider = 'email',
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String provider;

  bool get isGoogleUser => provider == 'google';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      provider: json['provider'] as String? ?? 'email',
    );
  }

  UserProfile copyWith({String? name, String? email, String? avatar}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      provider: provider,
    );
  }
}
