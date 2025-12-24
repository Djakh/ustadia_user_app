import 'package:flutter/cupertino.dart';

class SizeConfig {
  static late double screenHeight;
  static late double screenWidth;

  static late double heightPercent1;
  static late double widthPercent1;
  static late double rh; // rounded blockSizeVertical to one
  static late double rw; // rounded blockSizeHorizontal to one

  void init(BuildContext context, BoxConstraints constraints) {
    final padding = MediaQuery.of(context).padding;

    screenWidth = constraints.maxWidth;
    screenHeight = constraints.maxHeight - padding.top - padding.bottom; // Exclude SafeArea

    print("Adjusted height (without SafeArea) is $screenHeight");
    print("width is $screenWidth");

    heightPercent1 = screenHeight * 0.01;
    widthPercent1 = screenWidth * 0.01;

    rh = heightPercent1 / 9.26;
    rw = widthPercent1 / 4.28;
  }
}
