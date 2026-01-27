import 'package:flutter/material.dart';

@immutable
sealed class CurrentUnitEvent {
  const CurrentUnitEvent();
}

class CurrentUnitRequested extends CurrentUnitEvent {
  const CurrentUnitRequested();
}
