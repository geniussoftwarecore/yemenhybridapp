import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env.dart';
import 'app.dart';
import 'utils/manual_testing_checklist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await Env.load();
  
  // Print manual testing checklist in debug mode
  if (kDebugMode) {
    initializeManualTesting();
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}