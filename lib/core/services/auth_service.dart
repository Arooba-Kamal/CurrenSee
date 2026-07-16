import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isAdmin = false;
  String? _lastLoginError;

  // Admin credentials (hardcoded)
  static const String adminEmail = 'admin@currensee.com';
  static const String adminPassword = 'Admin@123';
  static const String maintenanceMessage =
      'Sorry, app is in maintenance mode, please try later after some hours.';
  static const String _maintenanceCacheKey = 'enableMaintenance';

  User? get user => _user;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _user != null;
  String? get lastLoginError => _lastLoginError;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _isAdmin = user.email?.toLowerCase() == adminEmail.toLowerCase();
        // Save user to Firestore if not exists
        _saveUserToFirestore(user);
      } else {
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  bool _isAdminEmail(String? email) {
    return email?.trim().toLowerCase() == adminEmail.toLowerCase();
  }

  Future<bool> isMaintenanceModeEnabled() async {
    try {
      final doc =
          await _firestore.collection('settings').doc('adminSettings').get();
      final enabled = doc.data()?['enableMaintenance'] == true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_maintenanceCacheKey, enabled);

      return enabled;
    } catch (e) {
      debugPrint('Error checking maintenance mode: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_maintenanceCacheKey) ?? false;
    }
  }

  Future<bool> isCurrentUserBlockedByMaintenance() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _isAdminEmail(currentUser.email)) return false;

    return isMaintenanceModeEnabled();
  }

  // Save user to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'id': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? 'User',
          'role': _isAdminEmail(user.email) ? 'admin' : 'user',
          'phone': user.phoneNumber ?? '',
          'country': '',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'photoURL': user.photoURL ?? '',
          'lastLogin': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ User saved to Firestore: ${user.email}');
      } else {
        // Update last login
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error saving user to Firestore: $e');
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password, String role) async {
    try {
      _lastLoginError = null;
      debugPrint('🔐 AuthService.login() called');
      debugPrint('📧 Email: $email');
      debugPrint('🔑 Role: $role');

      final normalizedEmail = email.trim().toLowerCase();
      final isAdminEmail = _isAdminEmail(email);

      if (!isAdminEmail && await isMaintenanceModeEnabled()) {
        _lastLoginError = maintenanceMessage;
        debugPrint('Login blocked because maintenance mode is enabled');
        return false;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      debugPrint('✅ Firebase Auth successful');
      debugPrint('👤 User: ${userCredential.user?.email}');

      _user = userCredential.user;

      if (!isAdminEmail && await isMaintenanceModeEnabled()) {
        await _auth.signOut();
        _user = null;
        _isAdmin = false;
        _lastLoginError = maintenanceMessage;
        notifyListeners();
        debugPrint('User signed out because maintenance mode is enabled');
        return false;
      }

      // Check if admin
      if (isAdminEmail || role == 'admin') {
        if (normalizedEmail == adminEmail.toLowerCase() &&
            password.trim() == adminPassword) {
          _isAdmin = true;
          await _saveUserToFirestore(userCredential.user!);
          notifyListeners();
          debugPrint('✅ Admin login successful');
          return true;
        } else {
          // If admin login fails, sign out
          await _auth.signOut();
          _lastLoginError = 'Invalid admin credentials.';
          debugPrint('❌ Admin login failed - invalid credentials');
          return false;
        }
      }

      _isAdmin = false;
      await _saveUserToFirestore(userCredential.user!);
      await NotificationService().notifyGenericUserActivity(
        action: 'logged in',
        relatedId: userCredential.user!.uid,
      );
      notifyListeners();
      debugPrint('✅ User login successful');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      _lastLoginError = 'Login failed. Please check your credentials.';
      return false;
    } catch (e) {
      debugPrint('❌ General Error: $e');
      _lastLoginError = 'Login failed. Please try again.';
      return false;
    }
  }

  // Register new user
  Future<bool> register(String email, String password, String name) async {
    try {
      _lastLoginError = null;

      if (await isMaintenanceModeEnabled()) {
        _lastLoginError = maintenanceMessage;
        debugPrint('Registration blocked because maintenance mode is enabled');
        return false;
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name.trim());
      await userCredential.user?.reload();

      _user = userCredential.user;
      _isAdmin = false;

      // Save to Firestore
      await _saveUserToFirestore(userCredential.user!);

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Registration error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return false;
    }
  }

  // Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Reset password error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Reset password error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _isAdmin = false;
    notifyListeners();
  }

  // Check if user is admin
  bool checkIfAdmin(String email) {
    return email.toLowerCase() == adminEmail.toLowerCase();
  }

  // Delete user from Firebase Auth and Firestore
  Future<bool> deleteUser(String uid) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Note: Cannot delete user from Firebase Auth using admin SDK in client
      // For full delete, use Firebase Admin SDK in Cloud Functions
      debugPrint('✅ User deleted from Firestore: $uid');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      return false;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
      });
      debugPrint('✅ User role updated: $uid -> $newRole');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user role: $e');
      return false;
    }
  }

  // Toggle user active status
  Future<bool> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': isActive,
      });
      debugPrint('✅ User status updated: $uid -> $isActive');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user status: $e');
      return false;
    }
  }

  // Get all users from Firestore
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? 'Unknown',
          role: data['role'] ?? 'user',
          phone: data['phone'],
          country: data['country'],
          isActive: data['isActive'] ?? true,
          photoURL: data['photoURL'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting users: $e');
      return [];
    }
  }
}

// User Model
class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
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

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}
