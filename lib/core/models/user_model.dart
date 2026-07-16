// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin' or 'user'
  final String? phone;
  final String? country;
  final bool isActive;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.country,
    this.isActive = true,
    this.photoURL,
    required this.createdAt,
    this.lastLogin,
  });

  // ✅ FROM FIRESTORE
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'User',
      role: data['role'] ?? 'user',
      phone: data['phone'],
      country: data['country'],
      isActive: data['isActive'] ?? true,
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  // ✅ FROM MAP (Existing)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      phone: map['phone'],
      country: map['country'],
      isActive: map['isActive'] ?? true,
      photoURL: map['photoURL'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  // ✅ TO MAP
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'country': country,
      'isActive': isActive,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  // ✅ TO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'country': country,
      'isActive': isActive,
      'photoURL': photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  // ✅ COPY WITH
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? country,
    bool? isActive,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      isActive: isActive ?? this.isActive,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
  bool get isActiveUser => isActive;

  // ✅ DISPLAY NAME
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  // ✅ INITIALS
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // ✅ FORMATTED DATE
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedLastLogin {
    if (lastLogin == null) return 'Never';
    return '${lastLogin!.day}/${lastLogin!.month}/${lastLogin!.year}';
  }
}