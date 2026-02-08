import 'package:flutter/material.dart';
import 'package:ustadia_user_app/app.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseMessagingService.initialize();
  await initDependencies();
  runApp(const UstadiaUserApp());
}
