import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String photoUrl;
  final String address;
  final String role; // 'Owner', 'Mandor', 'Worker'
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.photoUrl,
    required this.address,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? 'Worker', // Default role is Worker
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'address': address,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? address,
    String? role,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
