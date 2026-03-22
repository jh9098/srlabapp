class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.allowedPaths,
    required this.nickname,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role;
  final List<String> allowedPaths;
  final String nickname;
  final String fullName;
  final String gender;
  final String birthDate;
  final String phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  bool get isAdmin => role == 'admin';
}
