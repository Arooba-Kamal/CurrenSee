import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:currensee/core/services/app_settings_service.dart';
import 'package:currensee/core/services/auth_service.dart';
import 'package:currensee/core/theme/theme_provider.dart';
import 'package:currensee/main.dart';

void main() {
  testWidgets('CurrenSee app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => AppSettingsService()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const CurrenSeeApp(),
      ),
    );

    await tester.pump();

    expect(find.text('CurrenSee'), findsOneWidget);
    expect(find.text('Smart Currency Converter'), findsOneWidget);
  });
}
