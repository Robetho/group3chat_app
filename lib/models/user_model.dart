import 'package:cloud_firestore/cloud_firestore.dart';
//test comment
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final DateTime createdAt;
  final DateTime lastSeen;
  final String fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.createdAt,
    required this.lastSeen,
    required this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'fcmToken': fcmToken,
    };
  }

  // **REVERT: Weka tena constructor 2 parameters**
  factory UserModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    // Use documentId if uid is empty in map
    final uid = map['uid']?.toString().isNotEmpty == true
        ? map['uid']
        : documentId ?? '';

    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
      fcmToken: map['fcmToken'] ?? '',
    );
  }
}
