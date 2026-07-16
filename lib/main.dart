import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/currensee_theme.dart';
import 'core/theme/theme_provider.dart';

// Screens
import 'screens/home/home_screen.dart';
import 'screens/home/more_screen.dart';
import 'screens/home/feedback_screen.dart' as user_feedback;
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/biometric_login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/onboarding/onboarding1.dart';
import 'screens/onboarding/onboarding2.dart';
import 'screens/onboarding/onboarding3.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/manage_users.dart';
import 'screens/admin/manage_currencies.dart';
import 'screens/admin/manage_rates.dart';
import 'screens/admin/reports.dart';
import 'screens/admin/analytics.dart';
import 'screens/admin/feedbacks.dart' as admin_feedback;
import 'screens/admin/admin_settings.dart';
import 'screens/converter/convert_screen.dart';
import 'screens/converter/live_conversion_screen.dart';
import 'screens/converter/offline_conversion_screen.dart';
import 'screens/converter/qr_share_screen.dart';
import 'screens/currency/currency_list.dart';
import 'screens/currency/currency_details_screen.dart';
import 'screens/currency/currency_compare_screen.dart';
import 'screens/currency/favorite_pairs_screen.dart';
import 'screens/market/exchange_rate_chart.dart';
import 'screens/market/market_news.dart';
import 'screens/market/trends_analysis_screen.dart';
import 'screens/market/crypto_rates_screen.dart';
import 'screens/market/gold_rates_screen.dart';
import 'screens/market/ai_prediction_screen.dart';
import 'screens/history/conversion_history.dart';
import 'screens/history/transaction_details_screen.dart';
import 'screens/history/pdf_export_screen.dart';
import 'screens/alerts/rate_alerts.dart';
import 'screens/alerts/notifications_screen.dart';
import 'screens/alerts/smart_alerts_screen.dart';
import 'screens/planner/budget_planner_screen.dart';
import 'screens/planner/spending_tracker_screen.dart';
import 'screens/planner/travel_estimator_screen.dart';
import 'screens/settings/profile_screen.dart';
import 'screens/chatbot/chatbot_screen.dart';
// ✅ ADDED IMPORT
import 'screens/calculator/calculator_screen.dart'; 

import 'core/services/auth_service.dart';
import 'core/services/app_settings_service.dart';
import 'core/services/local_database.dart';
import 'core/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalDatabaseService.init();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => AppSettingsService()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: const CurrenSeeApp(),
  ));
}

class CurrenSeeApp extends StatelessWidget {
  const CurrenSeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CurrenSee',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: CurrenSeeTheme.light(),
          darkTheme: CurrenSeeTheme.dark(),
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            return PageRouteBuilder(
              settings: settings,
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, anim, secAnim) => _getScreen(settings.name),
              transitionsBuilder: (context, anim, secAnim, child) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _getScreen(String? name) {
    switch (name) {
      // ==================== HOME ====================
      case '/home': return const HomeScreen();
      case '/more': return const MoreScreen();

      // ==================== AUTH ====================
      case '/login': return const LoginScreen();
      case '/register': return const RegisterScreen();
      case '/forgot_password': return const ForgotPasswordScreen();
      case '/biometric_login': return const BiometricLoginScreen();

      // ==================== ONBOARDING ====================
      case '/onboarding': return const OnboardingScreen();
      case '/onboarding1': return const Onboarding1();
      case '/onboarding2': return const Onboarding2();
      case '/onboarding3': return const Onboarding3();

      // ==================== ADMIN ====================
      case '/admin': return const AdminDashboardScreen();
      case '/admin/users': return const ManageUsersScreen();
      case '/admin/currencies': return const ManageCurrenciesScreen();
      case '/admin/rates': return const ManageRatesScreen();
      case '/admin/reports': return const ReportsScreen();
      case '/admin/analytics': return const AnalyticsScreen();
      case '/admin/feedbacks': return const admin_feedback.FeedbacksScreen();
      case '/admin/settings': return const AdminSettingsScreen();

      // ==================== CONVERTER ====================
      case '/converter': return const ConvertScreen();
      case '/converter/live': return const LiveConversionScreen();
      case '/converter/offline': return const OfflineConversionScreen();
      case '/converter/qr': return const QRShareScreen();

      // ==================== CURRENCY ====================
      case '/currency/list': return const CurrencyListScreen();
      case '/currency/details': return const CurrencyDetailsScreen(
          currencyCode: 'USD',
          currencyName: 'United States Dollar',
          currencySymbol: '\$',
          currencyFlag: '🇺🇸',
        );
      case '/currency/compare': return const CurrencyCompareScreen();
      case '/currency/favorites': return const FavoritePairsScreen();

      // ==================== MARKET ====================
      case '/market/trends': return const TrendsAnalysisScreen();
      case '/market/chart': return const ExchangeRateChartScreen();
      case '/market/crypto': return const CryptoRatesScreen();
      case '/market/gold': return const GoldRatesScreen();
      case '/market/ai_prediction': return const AIPredictionScreen();
      case '/market/news': return const MarketNewsScreen();

      // ==================== HISTORY ====================
      case '/history': return const ConversionHistoryScreen();
      case '/history/details': return const TransactionDetailsScreen();
      case '/history/pdf': return const PDFExportScreen();

      // ==================== ALERTS ====================
      case '/alerts/notifications': return const NotificationsScreen();
      case '/alerts/rate_alerts': return const RateAlertsScreen();
      case '/alerts/smart': return const SmartAlertsScreen();
      case '/feedback': return const user_feedback.FeedbackScreen();

      // ==================== PLANNER ====================
      case '/planner/budget': return const BudgetPlannerScreen();
      case '/planner/spending': return const SpendingTrackerScreen();
      case '/planner/travel': return const TravelEstimatorScreen();

      // ==================== SETTINGS ====================
      case '/settings/profile': return const ProfileScreen();

      // ==================== UTILITY ====================
      case '/chatbot': return const ChatbotScreen();
      // ✅ ADDED ROUTE
      case '/calculator/calculator_screen': return const CalculatorScreen();

      default: return const SplashScreen();
    }
  }
}