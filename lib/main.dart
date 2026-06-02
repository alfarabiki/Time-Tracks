import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/splash/splash_screen.dart';
import 'services/log_service.dart';
import 'services/settings_service.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi defensif — kegagalan satu pun tidak boleh menghentikan app.
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {/* abaikan */}
  try {
    await LogService.instance.init();
  } catch (_) {/* abaikan */}
  try {
    await SettingsService.instance.load();
  } catch (_) {/* abaikan */}

  // Tangkap error framework agar tidak ada stack trace ke user.
  FlutterError.onError = (details) {
    LogService.instance.log('FlutterError', detail: details.exceptionAsString());
    FlutterError.presentError(details);
  };

  runApp(const TimeProofApp());
}

class TimeProofApp extends StatelessWidget {
  const TimeProofApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      title: K.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
