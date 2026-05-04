import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class Log {
  Log._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static bool get _enabled => kDebugMode || kProfileMode;

  static String _format(dynamic message, String? label) {
    if (label == null || label.isEmpty) return '$message';
    return '[$label] $message';
  }

  static void t(
    dynamic message, {
    String? label,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _logger.t(_format(message, label), error: error, stackTrace: stackTrace);
    }
  }

  static void d(
    dynamic message, {
    String? label,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _logger.d(_format(message, label), error: error, stackTrace: stackTrace);
    }
  }

  static void i(
    dynamic message, {
    String? label,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _logger.i(_format(message, label), error: error, stackTrace: stackTrace);
    }
  }

  static void w(
    dynamic message, {
    String? label,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _logger.w(_format(message, label), error: error, stackTrace: stackTrace);
    }
  }

  static void e(
    dynamic message, {
    String? label,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _logger.e(_format(message, label), error: error, stackTrace: stackTrace);
    }
  }

  static void f(
    dynamic message, {
    String? label,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_enabled) {
      _logger.f(_format(message, label), error: error, stackTrace: stackTrace);
    }
  }
}
