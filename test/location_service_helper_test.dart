import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gms_location_settings_dialog/gms_location_settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gms_location_settings_dialog/settings');

  late GmsLocationSettingsDialog sut;

  setUp(() {
    sut = GmsLocationSettingsDialog();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockChannel(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  group('show', () {
    test('returns true when native side returns true', () async {
      mockChannel((_) async => true);

      final result = await sut.show();

      expect(result, isTrue);
    });

    test('returns false when native side returns false', () async {
      mockChannel((_) async => false);

      final result = await sut.show();

      expect(result, isFalse);
    });

    test('returns false when native side returns null', () async {
      mockChannel((_) async => null);

      final result = await sut.show();

      expect(result, isFalse);
    });

    test('calls the correct method name on the channel', () async {
      String? capturedMethod;
      mockChannel((call) async {
        capturedMethod = call.method;
        return true;
      });

      await sut.show();

      expect(capturedMethod, equals('show'));
    });

    test('returns false on PlatformException', () async {
      mockChannel(
        (_) async => throw PlatformException(
          code: 'ALREADY_PENDING',
          message: 'A dialog is already showing',
        ),
      );

      final result = await sut.show();

      expect(result, isFalse);
    });

    test('returns false on MissingPluginException', () async {
      mockChannel((_) async => throw MissingPluginException());

      final result = await sut.show();

      expect(result, isFalse);
    });
  });
}
