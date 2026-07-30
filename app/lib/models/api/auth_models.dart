class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
  });

  final int id;
  final String email;
  final String? fullName;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
    );
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser? user;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: json['user'] is Map<String, dynamic>
          ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.profession,
    this.preferredLanguage,
    this.defaultJurisdiction,
    this.profilePhotoUrl,
  });

  final int id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? profession;
  final String? preferredLanguage;
  final String? defaultJurisdiction;
  final String? profilePhotoUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profession: json['profession'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      defaultJurisdiction: json['defaultJurisdiction'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }
}
