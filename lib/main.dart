import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:ustadia_user_app/app.dart';
import 'package:ustadia_user_app/core/widgets/app_restart.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await FirebaseMessagingService.initialize();
  Hardware.instance.setAutomaticConfigurationEnabled(enable: false);
  await initDependencies();
  runApp(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('uz')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: true,
      saveLocale: true,
      child: const AppRestart(child: UstadiaUserApp())));
}
