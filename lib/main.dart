import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:template_app/core/services/injection/locator.dart';

import 'features/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //// firebase — run `flutterfire configure` to generate firebase_options.dart,
  //// then replace with: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
  await Firebase.initializeApp();

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
