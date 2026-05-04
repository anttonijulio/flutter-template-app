import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:template_app/injection/locator.dart';

import 'features/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //// Firebase service
  await Firebase.initializeApp();

  //// crashlytics — forward semua uncaught error ke Firebase Crashlytics.
  //// Di debug mode Crashlytics dinonaktifkan agar tidak mencemari data produksi.
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  //// bloc cache state
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getTemporaryDirectory()).path,
    ),
  );

  //// date time localization
  await initializeDateFormatting('id_ID', null);

  //// dependencies injection
  await initLocator();

  runApp(const App());
}
