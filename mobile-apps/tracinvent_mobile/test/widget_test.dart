import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:tracinvent_mobile/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const TracInventMobileApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Dashboard'), findsWidgets);
  });
}
