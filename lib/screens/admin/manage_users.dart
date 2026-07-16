import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_service.dart';


class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? phone;
  final String? country;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.phone,
    this.country,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => role.toLowerCase() == 'user';

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'User',
      role: data['role'] ?? 'user',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      phone: data['phone'] ?? '',
      country: data['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': lastLogin != null ? FieldValue.serverTimestamp() : null,
      'phone': phone ?? '',
      'country': country ?? '',
    };
  }
}

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterRole = 'all';
  String _errorMessage = '';

  final TextEditingController _addNameController = TextEditingController();
  final TextEditingController _addEmailController = TextEditingController();
  final TextEditingController _addPasswordController = TextEditingController();
  final TextEditingController _addPhoneController = TextEditingController();
  String _selectedRole = 'user';
  bool _isAddingUser = false;
  bool _showAddUserForm = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Please login to view users';
          _isLoading = false;
        });
        return;
      }

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        _users = usersSnapshot.docs.map((doc) {
          return UserModel.fromMap(doc.id, doc.data());
        }).toList();
      } else {
        final isAdmin = currentUser.email?.toLowerCase() == 'admin@gmail.com' ||
                        currentUser.email?.toLowerCase() == 'admin@currensee.com';
        
        final adminUser = UserModel(
          id: currentUser.uid,
          email: currentUser.email ?? 'admin@gmail.com',
          name: currentUser.displayName ?? (isAdmin ? 'Admin' : 'User'),
          role: isAdmin ? 'admin' : 'user',
          isActive: true,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(adminUser.toMap());
        
        _users = [adminUser];
      }

      _filteredUsers = List.from(_users);
      _applyFilters();

    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final isAdmin = currentUser.email?.toLowerCase() == 'admin@gmail.com' ||
                        currentUser.email?.toLowerCase() == 'admin@currensee.com';
        _users = [
          UserModel(
            id: currentUser.uid,
            email: currentUser.email ?? '',
            name: currentUser.displayName ?? (isAdmin ? 'Admin' : 'User'),
            role: isAdmin ? 'admin' : 'user',
            isActive: true,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          ),
        ];
        _filteredUsers = List.from(_users);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = _searchQuery.isEmpty ||
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesRole = _filterRole == 'all' ||
            (_filterRole == 'admin' && user.isAdmin) ||
            (_filterRole == 'user' && user.isUser);
        
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _applyFilters();
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      _filterRole = value;
      _applyFilters();
    }
  }

  Future<void> _addUser() async {
    if (_addNameController.text.isEmpty ||
        _addEmailController.text.isEmpty ||
        _addPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAddingUser = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _addEmailController.text.trim(),
            password: _addPasswordController.text.trim(),
          );

      await userCredential.user?.updateDisplayName(_addNameController.text.trim());

      final userData = {
        'email': _addEmailController.text.trim(),
        'name': _addNameController.text.trim(),
        'role': _selectedRole,
        'isActive': true,
        'phone': _addPhoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      // ✅ NOTIFICATION: Send to user
      await NotificationService().sendNotification(
        userId: userCredential.user!.uid,
        title: 'Account Created by Admin 📋',
        message: 'Your account has been created by admin. Welcome to CurrenSee!',
        type: 'approved',
      );

      _addNameController.clear();
      _addEmailController.clear();
      _addPasswordController.clear();
      _addPhoneController.clear();
      setState(() => _showAddUserForm = false);

      await _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ User added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isAddingUser = false);
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'isActive': !user.isActive,
      });

      final updatedStatus = user.isActive ? 'deactivated' : 'activated';
      await NotificationService().notifyAdminActionForUser(
        userId: user.id,
        title: 'Account $updatedStatus',
        message: 'Your CurrenSee account has been $updatedStatus by admin.',
        type: user.isActive ? 'rejected' : 'approved',
        relatedId: user.id,
      );

      setState(() {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = UserModel(
            id: _users[index].id,
            email: _users[index].email,
            name: _users[index].name,
            role: _users[index].role,
            isActive: !_users[index].isActive,
            createdAt: _users[index].createdAt,
            lastLogin: _users[index].lastLogin,
            phone: _users[index].phone,
            country: _users[index].country,
          );
        }
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ User $updatedStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      _users.firstWhere((u) => u.id == userId, orElse: () => throw Exception('User not found'));

      await NotificationService().notifyAdminActionForUser(
        userId: userId,
        title: 'Account Removed',
        message: 'Your CurrenSee account has been removed by admin.',
        type: 'user_deleted',
        relatedId: userId,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();

      setState(() {
        _users.removeWhere((u) => u.id == userId);
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ User deleted from Firestore'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1120),
        title: Text(
          user.name,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Email', user.email),
            _detailRow('Role', user.role.toUpperCase()),
            _detailRow('Status', user.isActive ? 'Active' : 'Inactive'),
            _detailRow('Phone', user.phone ?? 'Not set'),
            _detailRow('Country', user.country ?? 'Not set'),
            _detailRow('Joined', _formatDate(user.createdAt)),
            if (user.lastLogin != null)
              _detailRow('Last Login', _formatDate(user.lastLogin!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00E5FF);
    final activeUsers = _filteredUsers.where((u) => u.isActive).length;
    final adminUsers = _filteredUsers.where((u) => u.isAdmin).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF060B13),
              const Color(0xFF0A1628),
              const Color(0xFF0B1120),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _showAddUserForm = !_showAddUserForm);
                        },
                        icon: Icon(
                          _showAddUserForm ? Icons.close : Icons.add,
                          color: Colors.black,
                          size: 18,
                        ),
                        label: Text(
                          _showAddUserForm ? 'Close' : 'Add User',
                          style: const TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonCyan,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh, color: Colors.black, size: 16),
                        label: const Text('Refresh', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonCyan,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add User Form
              if (_showAddUserForm)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: neonCyan.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _addNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name *',
                                    labelStyle: TextStyle(color: Colors.white54),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _addEmailController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email *',
                                    labelStyle: TextStyle(color: Colors.white54),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _addPasswordController,
                                  style: const TextStyle(color: Colors.white),
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password *',
                                    labelStyle: TextStyle(color: Colors.white54),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _addPhoneController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone (Optional)',
                                    labelStyle: TextStyle(color: Colors.white54),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Role:',
                                style: TextStyle(color: Colors.white54),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButton<String>(
                                  value: _selectedRole,
                                  dropdownColor: const Color(0xFF0B1120),
                                  style: const TextStyle(color: Colors.white),
                                  items: const [
                                    DropdownMenuItem(value: 'user', child: Text('User')),
                                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedRole = value);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isAddingUser ? null : _addUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: neonCyan,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isAddingUser
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Text(
                                          'Create User',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Total Users', _users.length.toString(), '👥'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard('Active', activeUsers.toString(), '🟢'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard('Admins', adminUsers.toString(), '🛡️'),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Users List - FIXED OVERFLOW
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.55,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search users...',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: _filterRole,
                              dropdownColor: const Color(0xFF0B1120),
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Users')),
                                DropdownMenuItem(value: 'admin', child: Text('Admins')),
                                DropdownMenuItem(value: 'user', child: Text('Users')),
                              ],
                              onChanged: _onFilterChanged,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Users List
                        Expanded(
                          child: _isLoading                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                                  ),
                                )
                              : _errorMessage.isNotEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.red.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _errorMessage,
                                            style: const TextStyle(color: Colors.white54),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: _loadUsers,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: neonCyan,
                                              foregroundColor: Colors.black,
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : _filteredUsers.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.people_outline, color: Colors.white24, size: 48),
                                              const SizedBox(height: 16),
                                              Text(
                                                _searchQuery.isEmpty && _filterRole == 'all'
                                                    ? 'No users found'
                                                    : 'No users match your search',
                                                style: const TextStyle(color: Colors.white54),
                                              ),
                                              if (_searchQuery.isNotEmpty || _filterRole != 'all')
                                                TextButton(
                                                  onPressed: () {
                                                    _searchQuery = '';
                                                    _filterRole = 'all';
                                                    _applyFilters();
                                                  },
                                                  child: const Text(
                                                    'Clear filters',
                                                    style: TextStyle(color: Color(0xFF00E5FF)),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _filteredUsers.length,
                                          itemBuilder: (context, index) {
                                            final user = _filteredUsers[index];
                                            return Column(
                                              children: [
                                                _buildUserRow(user),
                                                if (index < _filteredUsers.length - 1)
                                                  const Divider(color: Colors.white12),
                                              ],
                                            );
                                          },
                                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FIXED: User Row - No Overflow
  Widget _buildUserRow(UserModel user) {
    final statusColor = user.isActive ? Colors.green : Colors.red;
    final statusIcon = user.isActive ? Icons.check_circle : Icons.cancel;
    final isAdmin = user.isAdmin;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isAdmin ? const Color(0xFF8A2BE2) : Colors.white.withOpacity(0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          
          // User Info - Takes remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8A2BE2).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Flexible(
                  child: Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          
          // Status and Actions - Fixed width with Wrap
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            children: [
              Icon(statusIcon, color: statusColor, size: 14),
              Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: statusColor, fontSize: 9),
              ),
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white60, size: 16),
                onPressed: () => _showUserDetails(user),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                iconSize: 16,
              ),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: user.isActive,
                  onChanged: (_) => _toggleUserStatus(user),
                  activeColor: const Color(0xFF00E5FF),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
