import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  }

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}