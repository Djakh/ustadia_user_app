import 'package:flutter/cupertino.dart';

class ActivityIndicator extends StatelessWidget {
  const ActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 20, height: 20, child: CupertinoActivityIndicator());
}
