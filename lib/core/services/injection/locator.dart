import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/datasource/api/dio_client.dart';
import 'package:template_app/core/services/datasource/local_storage/local_storage.dart';
import 'package:template_app/core/services/datasource/socket/socket_client.dart';
import 'package:template_app/core/services/caching/cache_manager.dart';
import 'package:template_app/core/services/firebase/firebase_messaging_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:template_app/core/services/files/file_picker_service.dart';
import 'package:template_app/core/services/files/media_picker_service.dart';
import 'package:template_app/core/services/location/location_service.dart';
import 'package:template_app/core/services/notification/notification_dispatcher.dart';
import 'package:template_app/core/services/notification/notification_service.dart';
import 'package:template_app/features/auth/notifier/auth_notifier.dart';
import 'package:template_app/features/chat/notification/chat_notification_handler.dart';
import 'package:template_app/router/app_router.dart';

final locator = GetIt.instance;

Future<void> initLocator() async {
  //// ======================
  //// LOCAL STORAGE
  //// ======================
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton(LocalStorage(prefs));
  locator.registerLazySingleton(() => CacheManager(locator()));

  //// ======================
  //// ROUTER
  //// ======================
  locator.registerLazySingleton(() => AuthNotifier(locator()));

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
  //// MEDIA
  //// ======================
  locator.registerLazySingleton(() => MediaPickerService(ImagePicker()));
  locator.registerLazySingleton(() => FilePickerService());
}
