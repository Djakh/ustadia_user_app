import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  Widget view(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text('Coming soon'.tr(), style: Style.headline5w7(context))],
      );

  @override
  Widget build(BuildContext context) => view(context);
}
