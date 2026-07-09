import 'package:cloud_firestore/cloud_firestore.dart';

/// Account role, chosen at sign-up; drives the navigation shell and permissions.
enum UserRole { student, startup }

extension UserRoleX on UserRole {
  String get label => this == UserRole.student ? 'Student' : 'Startup';
  String get asString => name; // 'student' | 'startup'
  static UserRole fromString(String? v) =>
      v == 'startup' ? UserRole.startup : UserRole.student;
}

/// Mirrors a document in the `users/{uid}` collection.
class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final String? photoUrl;
  final String headline; // e.g. "Software Engineering Student, Year 3"
  final String bio;
  final List<String> skills;
  final bool isAdmin; // gate for the startup-verification console
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.photoUrl,
    this.headline = '',
    this.bio = '',
    this.skills = const [],
    this.isAdmin = false,
    this.createdAt,
  });

  bool get isStudent => role == UserRole.student;
  bool get isStartup => role == UserRole.startup;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      fullName: d['fullName'] as String? ?? '',
      role: UserRoleX.fromString(d['role'] as String?),
      photoUrl: d['photoUrl'] as String?,
      headline: d['headline'] as String? ?? '',
      bio: d['bio'] as String? ?? '',
      skills: List<String>.from(d['skills'] as List? ?? const []),
      isAdmin: d['isAdmin'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'fullName': fullName,
        'role': role.asString,
        'photoUrl': photoUrl,
        'headline': headline,
        'bio': bio,
        'skills': skills,
        'isAdmin': isAdmin,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  AppUser copyWith({
    String? fullName,
    String? photoUrl,
    String? headline,
    String? bio,
    List<String>? skills,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role,
      photoUrl: photoUrl ?? this.photoUrl,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      isAdmin: isAdmin,
      createdAt: createdAt,
    );
  }
}
