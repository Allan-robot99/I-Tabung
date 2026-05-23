import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_tabung/features/auth/view/role_selection_page.dart';

void main() {
  testWidgets('renders role selection page', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: RoleSelectionPage())));
    expect(find.text('START'), findsOneWidget);
  });
}

