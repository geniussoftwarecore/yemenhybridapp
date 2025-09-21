import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  }

  static int get apiTimeoutMs {
    final timeoutStr = dotenv.env['API_TIMEOUT_MS'] ?? '30000';
    return int.tryParse(timeoutStr) ?? 30000;
  }

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      print('Warning: Could not load .env file, using defaults');
    }
  }
}