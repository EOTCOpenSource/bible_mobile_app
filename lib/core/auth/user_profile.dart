class RemoteSettings {
  const RemoteSettings({this.isDark = false, this.fontSize = 17.0});

  final bool isDark;
  final double fontSize;

  factory RemoteSettings.fromJson(Map<String, dynamic> m) => RemoteSettings(
        isDark: (m['theme'] as String?) == 'dark',
        fontSize: (m['fontSize'] as num?)?.toDouble() ?? 17.0,
      );
}

class RemoteStreak {
  const RemoteStreak({this.current = 0, this.longest = 0});

  final int current;
  final int longest;

  factory RemoteStreak.fromJson(Map<String, dynamic> m) => RemoteStreak(
        current: (m['current'] as num?)?.toInt() ?? 0,
        longest: (m['longest'] as num?)?.toInt() ?? 0,
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.provider = 'email',
    this.remoteSettings,
    this.remoteStreak,
  });

  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String provider;
  final RemoteSettings? remoteSettings;
  final RemoteStreak? remoteStreak;

  bool get isGoogleUser => provider == 'google';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final settingsMap = json['settings'] as Map<String, dynamic>?;
    final streakMap = json['streak'] as Map<String, dynamic>?;
    return UserProfile(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      provider: json['provider'] as String? ?? 'email',
      remoteSettings:
          settingsMap != null ? RemoteSettings.fromJson(settingsMap) : null,
      remoteStreak:
          streakMap != null ? RemoteStreak.fromJson(streakMap) : null,
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatar,
    RemoteSettings? remoteSettings,
    RemoteStreak? remoteStreak,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      provider: provider,
      remoteSettings: remoteSettings ?? this.remoteSettings,
      remoteStreak: remoteStreak ?? this.remoteStreak,
    );
  }
}
