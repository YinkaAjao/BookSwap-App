import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.isEmailVerified,
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'isEmailVerified': isEmailVerified,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'],
        email: json['email'],
        displayName: json['displayName'],
        isEmailVerified: json['isEmailVerified'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt'])
            : null,
      );

  // Convert Firebase User to AppUser
  factory AppUser.fromFirebaseUser(User user) => AppUser(
        uid: user.uid,
        email: user.email!,
        displayName: user.displayName ?? user.email!.split('@')[0],
        isEmailVerified: user.emailVerified,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: user.metadata.lastSignInTime,
      );
}