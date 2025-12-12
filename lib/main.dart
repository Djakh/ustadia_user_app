import 'package:flutter/material.dart';
import 'package:ustadia_user_app/app.dart';

import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const UstadiaUserApp());
}
