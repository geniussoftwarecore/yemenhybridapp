import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/env/env.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _performHealthCheck();
  }

  _performHealthCheck() async {
    try {
      final dio = Dio();
      final baseUrl = Env.apiBaseUrl;
      
      // Enforce strict 3-second timeout using Future.any
      await Future.any([
        dio.get(
          '$baseUrl/health',
          options: Options(
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ),
        ),
        Future.delayed(const Duration(seconds: 3)),
      ]);
    } catch (e) {
      // Ignore any errors from health check
    } finally {
      // Always navigate to login regardless of health check result
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.car_repair,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Yemen Hybrid',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}