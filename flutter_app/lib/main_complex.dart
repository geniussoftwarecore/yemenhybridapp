import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/env/env.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables with 2s timeout (non-blocking)
  try {
    await Future.any([
      Env.load(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
  } catch (e) {
    if (kDebugMode) {
      print('Warning: Failed to load .env file within timeout: $e');
    }
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}