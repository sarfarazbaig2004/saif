import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:QUIK/auth/login/login_screen.dart';
import 'package:QUIK/auth/login/login_workspace_preview.dart';
import 'package:QUIK/core/theme/app_theme.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, {required Size size}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: buildQuikTheme(), home: const LoginScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desktop login renders the split layout without overflow', (
    tester,
  ) async {
    await pumpLogin(tester, size: const Size(1440, 900));

    expect(find.byType(LoginDashboardBackdrop), findsOne);
    expect(find.text('Welcome back'), findsOne);
    expect(find.text('Sign In'), findsOne);
    expect(find.text('Join Company'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile login remains accessible without overflow', (
    tester,
  ) async {
    await pumpLogin(tester, size: const Size(390, 844));

    expect(find.text('QUIK ERP'), findsOne);
    expect(find.text('Welcome back'), findsOne);
    expect(find.text('Sign In'), findsOne);
    expect(tester.takeException(), isNull);
  });
}
