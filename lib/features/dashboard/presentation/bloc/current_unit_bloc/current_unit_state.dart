import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/dashboard/data/models/current_unit_model.dart';

@immutable
class CurrentUnitState {
  final Status status;
  final CurrentUnitModel? unit;
  final String? errorMessage;

  const CurrentUnitState({
    this.status = Status.initial,
    this.unit,
    this.errorMessage,
  });

  CurrentUnitState copyWith({
    Status? status,
    CurrentUnitModel? unit,
    String? errorMessage,
  }) =>
      CurrentUnitState(
        status: status ?? this.status,
        unit: unit ?? this.unit,
        errorMessage: errorMessage,
      );
}
