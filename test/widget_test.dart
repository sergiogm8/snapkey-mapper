// Smoke test for the real app entry point (lib/main.dart -> HomeScreen).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snapkey_mapper/main.dart';

void main() {
  const configChannel = MethodChannel('snapkey_mapper/config');
  const serviceChannel = MethodChannel('snapkey_mapper/service');

  void mockHandler(
    MethodChannel channel,
    Future<Object?> Function(MethodCall) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  setUp(() {
    mockHandler(configChannel, (call) async {
      return switch (call.method) {
        'getActionConfig' => null,
        _ => null,
      };
    });
    mockHandler(serviceChannel, (call) async {
      return switch (call.method) {
        'isServiceShouldRun' => false,
        'isServiceRunning' => false,
        'isNotificationPolicyGranted' => false,
        'isPostNotificationsGranted' => false,
        'isFullScreenIntentGranted' => false,
        'isBatteryOptimizationIgnored' => false,
        'getTriggerLog' => <Object?>[],
        _ => null,
      };
    });
  });

  tearDown(() {
    mockHandler(configChannel, (call) async => null);
    mockHandler(serviceChannel, (call) async => null);
  });

  testWidgets('Home screen loads without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SnapKeyMapperApp());
    await tester.pumpAndSettle();

    expect(find.text('SnapKey Mapper'), findsOneWidget);
    expect(find.text('Mapping is off'), findsOneWidget);
  });
}
