import 'package:get_it/get_it.dart';
import 'package:template_app/core/services/downloader/download_service.dart';

final locator = GetIt.instance;

Future<void> initLocator() async {
  ////! ======================
  ////! DOWNLOADER
  ////! ======================
  final downloadService = DownloadService();
  await downloadService.init();
  locator.registerSingleton(downloadService);
}
