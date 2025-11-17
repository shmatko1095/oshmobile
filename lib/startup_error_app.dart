import 'package:flutter/material.dart';

/// Root application used when startup initialization fails.
/// Shows a simple error screen with a message and hint for the user.
class StartupErrorApp extends StatelessWidget {
  final String error;

  const StartupErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSH Mobile - Startup error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Something went wrong during startup',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      // Short generic hint for end users.
                      'Please close the app and try again in a few minutes. '
                      'If the problem persists, contact support.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Error details (useful for QA / debug builds).
                    // You can hide this behind a kDebugMode check if needed.
                    Text(
                      'Technical details:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      height: 140,
                      child: SingleChildScrollView(
                        child: Text(
                          error,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
