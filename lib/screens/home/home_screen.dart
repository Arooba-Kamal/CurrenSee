import 'package:flutter/material.dart';
import 'package:currensee/core/theme/theme.dart';
import 'dashboard.dart';
import 'more_screen.dart';
import 'package:currensee/screens/currency/currency_list.dart';
import '../market/market_news.dart';
import '../settings/profile_screen.dart';
import '../../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const CurrencyListScreen(),
    const MarketNewsScreen(),
    const MoreScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppTheme.navBgColor,
            border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.accentCyan,
            unselectedItemColor: AppTheme.textGrey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Markets'),
              BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), label: 'News'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'More'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}