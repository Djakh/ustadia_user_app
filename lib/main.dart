import 'package:flutter/material.dart';
import 'package:ustadia_user_app/app.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  // ignore: avoid_print
  print('accessToken: ${sl<AuthLocalDataSource>().getAccessToken()}');
  runApp(const UstadiaUserApp());
}
