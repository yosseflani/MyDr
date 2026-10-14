import 'package:flutter/material.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';

void main() {
  runApp(MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())));
}
