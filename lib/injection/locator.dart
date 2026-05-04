import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/datasource/api/dio_client.dart';
import 'package:template_app/core/services/datasource/local_storage/local_storage.dart';
import 'package:template_app/core/services/datasource/socket/socket_client.dart';
import 'package:template_app/core/services/caching/cache_manager.dart';
import 'package:template_app/core/services/firebase/crashlytics_service.dart';
import 'package:template_app/core/services/firebase/firebase_messaging_service.dart';
import 'package:template_app/core/services/firebase/remote_config_service.dart';
import 'package:template_app/core/services/files/file_picker_service.dart';
import 'package:template_app/core/services/files/media_picker_service.dart';
import 'package:template_app/core/services/location/location_service.dart';
import 'package:template_app/core/services/notification/notification_dispatcher.dart';
import 'package:template_app/core/services/notification/notification_service.dart';
import 'package:template_app/features/auth/datasource/auth_secure_storage.dart';
import 'package:template_app/features/auth/notifier/auth_notifier.dart';
import 'package:template_app/features/chat/notification/chat_notification_handler.dart';
import 'package:template_app/router/app_router.dart';

final locator = GetIt.instance;

// ⚠️  PERINGATAN — JANGAN UBAH URUTAN REGISTRASI TANPA MEMBACA INI
//
// Urutan di dalam initLocator() adalah KONTRAK EKSPLISIT, bukan gaya penulisan.
// Setiap service hanya boleh dipanggil SETELAH semua dependensinya terdaftar.
//
// Aturan kritis:
//   1. LocalStorage HARUS pertama — dipakai oleh AuthSecureStorage.
//   2. AuthSecureStorage HARUS sebelum AuthNotifier — karena AuthNotifier
//      menerima AuthSecureStorage sebagai dependensi.
//   3. AuthNotifier.init() HARUS selesai sebelum AppRouter terdaftar — router
//      membaca AuthNotifier.isAuthenticated saat pertama kali dipakai; jika
//      init() belum selesai, token dari secure storage belum termuat dan
//      redirect auth akan salah.
//   4. AuthSecureStorage.clearIfFreshInstall() HARUS dipanggil sebelum
//      AuthNotifier.init() — agar token stale dari Keychain iOS (yang tidak
//      terhapus saat uninstall) sudah dibersihkan sebelum dibaca.
//
// Risiko umum jika urutan diubah:
//   - GetIt akan melempar StateError "Object not registered" saat runtime.
//   - Circular dependency menyebabkan stack overflow saat resolusi lazy singleton.
//   - Auth state terbaca sebelum secure storage di-init → user bypass login.
Future<void> initLocator() async {
  //// ======================
  //// CRASHLYTICS
  //// ======================
  locator.registerSingleton(CrashlyticsService());

  //// ======================
  //// LOCAL STORAGE
  //// ======================
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton(LocalStorage(prefs));
  locator.registerLazySingleton(() => CacheManager(locator()));

  //// ======================
  //// AUTH
  //// ======================
  final authSecureStorage = AuthSecureStorage(locator());
  await authSecureStorage.clearIfFreshInstall();
  locator.registerSingleton(authSecureStorage);

  final authNotifier = AuthNotifier(locator(), locator());
  await authNotifier.init();
  locator.registerSingleton(authNotifier);

  //// ======================
  //// REMOTE DATASOURCE SERVICES
  //// ======================
  locator.registerLazySingleton(() => DioClient(Connectivity(), locator()));
  locator.registerLazySingleton(() => SocketClient());
  locator.registerLazySingleton(() => AppRouter(locator()));

  //// ======================
  //// NOTIFICATION
  //// ======================
  final dispatcher = NotificationDispatcher();

  // --- Register one handler per feature ---
  dispatcher.register(ChatNotificationHandler(locator()));
  // dispatcher.register(OrderNotificationHandler(locator()));
  // dispatcher.register(PromoNotificationHandler(locator()));

  final notificationService = NotificationService();
  await notificationService.initialize(onTap: dispatcher.dispatch);

  final fcmService = FirebaseMessagingService(notificationService, dispatcher);
  await fcmService.initialize();

  locator.registerSingleton(dispatcher);
  locator.registerSingleton(notificationService);
  locator.registerSingleton(fcmService);

  //// ======================
  //// LOCATION
  //// ======================
  locator.registerLazySingleton(() => LocationService());

  //// ======================
  //// FILES
  //// ======================
  locator.registerLazySingleton(() => MediaPickerService());
  locator.registerLazySingleton(() => FilePickerService());

  //// ======================
  //// FIREBASE REMOTE CONFIG
  //// ======================
  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.initialize();
  locator.registerSingleton(remoteConfigService);
}
