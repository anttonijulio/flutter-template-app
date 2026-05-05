import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/services/location/location_service_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('template_app/location_service');

  late LocationServiceHelper sut;

  setUp(() {
    sut = LocationServiceHelper();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockChannel(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  group('requestService', () {
    test('returns true when native side returns true', () async {
      mockChannel((call) async => true);

      final result = await sut.requestService();

      expect(result, isTrue);
    });

    test('returns false when native side returns false', () async {
      mockChannel((call) async => false);

      final result = await sut.requestService();

      expect(result, isFalse);
    });

    test('returns false when native side returns null', () async {
      mockChannel((call) async => null);

      final result = await sut.requestService();

      expect(result, isFalse);
    });

    test('calls the correct method name on the channel', () async {
      String? capturedMethod;
      mockChannel((call) async {
        capturedMethod = call.method;
        return true;
      });

      await sut.requestService();

      expect(capturedMethod, equals('requestService'));
    });

    test('returns false on PlatformException', () async {
      mockChannel(
        (_) async => throw PlatformException(
          code: 'ALREADY_PENDING',
          message: 'A request is already in progress',
        ),
      );

      final result = await sut.requestService();

      expect(result, isFalse);
    });

    test('returns false on MissingPluginException', () async {
      mockChannel((_) async => throw MissingPluginException());

      final result = await sut.requestService();

      expect(result, isFalse);
    });
  });
}
