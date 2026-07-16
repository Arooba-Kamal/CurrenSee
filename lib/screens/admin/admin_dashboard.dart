import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/trend_chart.dart';
import '../../widgets/notification_badge.dart';
import 'manage_users.dart';
import 'manage_currencies.dart';
import 'manage_rates.dart';
import 'reports.dart';
import 'analytics.dart';
import 'feedbacks.dart';
import 'admin_settings.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _currentPage = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _totalUsers = 0;
  int _totalConversions = 0;
  int _activeAlerts = 0;
  int _totalTransactions = 0;
  double _totalAmount = 0;
  
  bool _isLoading = true;
  late AnimationController _glowController;

  final List<Map<String, dynamic>> _adminPages = [
    {'key': 'dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard, 'color': Colors.blue},
    {'key': 'users', 'label': 'Manage Users', 'icon': Icons.people, 'color': Colors.green},
    {'key': 'currencies', 'label': 'Currencies', 'icon': Icons.flag, 'color': Colors.orange},
    {'key': 'rates', 'label': 'Exchange Rates', 'icon': Icons.swap_horiz, 'color': Colors.purple},
    {'key': 'reports', 'label': 'Reports', 'icon': Icons.bar_chart, 'color': Colors.red},
    {'key': 'analytics', 'label': 'Analytics', 'icon': Icons.analytics, 'color': Colors.teal},
    {'key': 'feedbacks', 'label': 'Feedbacks', 'icon': Icons.feedback, 'color': Colors.pink},
    {'key': 'settings', 'label': 'Settings', 'icon': Icons.settings, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<AuthService>();
      final users = await authService.getAllUsers();
      _totalUsers = users.length;
      
      final conversionsSnapshot = await FirebaseFirestore.instance
          .collection('conversions')
          .get();
      _totalConversions = conversionsSnapshot.docs.length;
      
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .get();
      _totalTransactions = transactionsSnapshot.docs.length;
      
      final amountSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .get();
      _totalAmount = amountSnapshot.docs.fold<double>(
        0, 
        (sum, doc) => sum + ((doc.data()['amount'] ?? 0.0) as double)
      );
      
      final alertsSnapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .where('isActive', isEqualTo: true)
          .get();
      _activeAlerts = alertsSnapshot.docs.length;
      
    } catch (e) {
      debugPrint('❌ Error loading dashboard: $e');
      _totalUsers = 0;
      _totalConversions = 0;
      _totalTransactions = 0;
      _totalAmount = 0;
      _activeAlerts = 0;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Logout error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00E5FF);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF060B13),
      drawer: _buildSidebar(),
      body: Stack(
        children: [
          // Neon Glow Background
          Positioned.fill(
            child: CustomPaint(
              painter: SharpNeonThreeCirclesPainter(),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Branding Header with Menu Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // ✅ FIXED: 3 dots (more_vert) ki jagah hamburger menu (menu) icon
                          IconButton(
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: neonCyan.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.menu, // ✅ Changed from Icons.more_vert to Icons.menu
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CurrenSee',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Admin Panel',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/alerts/notifications'),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: neonCyan.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const NotificationBadge(
                                includeAdminBroadcast: true,
                                child: Icon(
                                  Icons.notifications_active,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadDashboardData,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: neonCyan.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.sync_rounded,
                                color: Colors.white70,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Current Page Title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: neonCyan,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getCurrentPageTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: neonCyan.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: neonCyan.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: neonCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: neonCyan,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: _buildContentScreen(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    const Color neonCyan = Color(0xFF00E5FF);
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email ?? 'admin@gmail.com';
    
    return Drawer(
      backgroundColor: const Color(0xFF0A1628),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: neonCyan.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Sidebar Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A1628),
                    neonCyan.withOpacity(0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: neonCyan.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: neonCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: neonCyan.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonCyan.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFF00E5FF),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _adminPages.length,
                itemBuilder: (context, index) {
                  final page = _adminPages[index];
                  final isActive = _currentPage == page['key'];
                  final color = page['color'] as Color;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: isActive
                          ? LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.05),
                              ],
                            )
                          : null,
                      border: isActive
                          ? Border.all(
                              color: color.withOpacity(0.4),
                              width: 1,
                            )
                          : null,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: ListTile(
                      leading: AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? color.withOpacity(0.2 + _glowController.value * 0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3 + _glowController.value * 0.3),
                                        blurRadius: 10 + _glowController.value * 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              page['icon'] as IconData,
                              color: isActive ? color : Colors.white54,
                              size: 22,
                            ),
                          );
                        },
                      ),
                      title: Text(
                        page['label'] as String,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white54,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      trailing: isActive
                          ? AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.5 + _glowController.value * 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _currentPage = page['key'] as String;
                        });
                        if (_currentPage == 'dashboard') {
                          _loadDashboardData();
                        }
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            
            // Sidebar Footer - Logout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: neonCyan.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: ListTile(
                leading: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1 + _glowController.value * 0.1),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2 + _glowController.value * 0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 22,
                      ),
                    );
                  },
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF0A1628),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to logout from Admin Panel?',
                        style: TextStyle(color: Colors.white54),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentPageTitle() {
    final page = _adminPages.firstWhere(
      (p) => p['key'] == _currentPage,
      orElse: () => _adminPages.first,
    );
    return page['label'] as String;
  }

  Widget _buildContentScreen() {
    switch (_currentPage) {
      case 'dashboard': return _buildDashboardContent();
      case 'users': return const ManageUsersScreen();
      case 'currencies': return const ManageCurrenciesScreen();
      case 'rates': return const ManageRatesScreen();
      case 'reports': return const ReportsScreen();
      case 'analytics': return const AnalyticsScreen();
      case 'feedbacks': return const FeedbacksScreen();
      case 'settings': return const AdminSettingsScreen();
      default: return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF00E5FF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                _buildNeonGlassCard(
                  title: 'Total Users',
                  value: _totalUsers.toString(),
                  change: 'Active',
                  icon: Icons.person,
                  color: Colors.blue,
                ),
                _buildNeonGlassCard(
                  title: 'Conversions',
                  value: _totalConversions.toString(),
                  change: 'Today',
                  icon: Icons.swap_horiz,
                  color: Colors.orange,
                ),
                _buildNeonGlassCard(
                  title: 'Transactions',
                  value: _totalTransactions.toString(),
                  change: '\$${_totalAmount.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                _buildNeonGlassCard(
                  title: 'Active Alerts',
                  value: _activeAlerts.toString(),
                  change: 'Active',
                  icon: Icons.notifications_active,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ✅ Trend Panel
            _buildNeonGlassPanel(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversion Trend Analysis',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  SizedBox(height: 180, child: TrendChart()),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ✅ Top Currencies
            _buildNeonGlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Performing Currencies',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _currencyRow('USD', '4,250', '49.6%'),
                  _currencyRow('EUR', '2,150', '25.1%'),
                  _currencyRow('AED', '1,250', '14.6%'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ✅ Transaction Log
            _buildNeonGlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity Log',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _txnRow('1 USD → PKR', '278.50 PKR'),
                  _txnRow('50 EUR → PKR', '15,225.00 PKR'),
                  _txnRow('100 AED → PKR', '7,580.00 PKR'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonGlassCard({
    required String title, 
    required String value, 
    required String change, 
    required IconData icon,
    required Color color,
  }) {
    const Color neonCyan = Color(0xFF00E5FF);
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1526).withOpacity(0.35),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: neonCyan.withOpacity(0.3 + _glowController.value * 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonCyan.withOpacity(0.1 + _glowController.value * 0.1),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            change,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNeonGlassPanel({required Widget child}) {
    const Color neonCyan = Color(0xFF00E5FF);
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF08101C).withOpacity(0.30),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: neonCyan.withOpacity(0.2 + _glowController.value * 0.15),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonCyan.withOpacity(0.05 + _glowController.value * 0.05),
                          blurRadius: 16,
                          spreadRadius: 0,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _currencyRow(String code, String conversions, String share) {
    const Color neonCyan = Color(0xFF00E5FF);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12, 
            backgroundColor: neonCyan.withOpacity(0.12), 
            child: Text(
              code[0], 
              style: const TextStyle(
                color: neonCyan, 
                fontSize: 11, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              code, 
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            share, 
            style: const TextStyle(
              color: neonCyan, 
              fontSize: 13, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnRow(String title, String amount) {
    const Color neonCyan = Color(0xFF00E5FF);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title, 
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            amount, 
            style: const TextStyle(
              color: neonCyan, 
              fontSize: 14, 
              fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 NEON GLOW BACKGROUND PAINTER
class SharpNeonThreeCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Offset topCircleCenter = Offset(size.width * 1.05, size.height * 0.12);
    final double topCircleRadius = size.width * 0.78;
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF00E5FF).withOpacity(0.42), 
        const Color(0xFF0083B0).withOpacity(0.22), 
        Colors.transparent,
      ],
      stops: const [0.0, 0.99, 1.0], 
    ).createShader(Rect.fromCircle(center: topCircleCenter, radius: topCircleRadius));
    canvas.drawCircle(topCircleCenter, topCircleRadius, paint);

    final Offset bottomCornerCenter = Offset(size.width * 0.08, size.height * 0.98);
    final double bottomCornerRadius = size.width * 0.55;
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF00B4D8).withOpacity(0.38), 
        const Color(0xFF0077B6).withOpacity(0.20),
        Colors.transparent,
      ],
      stops: const [0.0, 0.99, 1.0],
    ).createShader(Rect.fromCircle(center: bottomCornerCenter, radius: bottomCornerRadius));
    canvas.drawCircle(bottomCornerCenter, bottomCornerRadius, paint);

    final Offset bottomUpperCenter = Offset(size.width * 0.38, size.height * 0.84);
    final double bottomUpperRadius = size.width * 0.45;
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF00E5FF).withOpacity(0.28), 
        const Color(0xFF005C7A).withOpacity(0.12),
        Colors.transparent,
      ],
      stops: const [0.0, 0.99, 1.0],
    ).createShader(Rect.fromCircle(center: bottomUpperCenter, radius: bottomUpperRadius));
    canvas.drawCircle(bottomUpperCenter, bottomUpperRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
