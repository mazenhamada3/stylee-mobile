import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylee/main.dart';
import 'package:stylee/providers/auth_provider.dart';

void main() {
  testWidgets('Login screen displays and accepts input', (WidgetTester tester) async {
    // Provide AuthProvider for testing
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: const StyleeApp(),
      ),
    );

    // Verify login screen widgets appear
    expect(find.text('Login with credentials'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Enter email & password
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump();

    // Tap login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Since AuthProvider is empty, expect snackbar error
    expect(find.textContaining('Login failed'), findsOneWidget);
  });
}