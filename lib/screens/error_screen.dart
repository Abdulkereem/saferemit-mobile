import 'package:flutter/material.dart';

enum ErrorType {
  noInternet,
  serverDown,
  timeout,
  notFound,
  accessDenied,
  generic,
}

class ErrorScreen extends StatelessWidget {
  final ErrorType errorType;
  final String? customMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final bool showBackButton;

  const ErrorScreen({
    super.key,
    this.errorType = ErrorType.generic,
    this.customMessage,
    this.onRetry,
    this.onGoBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final errorInfo = _getErrorInfo();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F3EE),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated error icon
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: errorInfo['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            errorInfo['icon'],
                            size: 60,
                            color: errorInfo['color'],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Error title
                  Text(
                    errorInfo['title'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A52),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Error message
                  Text(
                    customMessage ?? errorInfo['message'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Retry button (if callback provided)
                  if (onRetry != null)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 24),
                        label: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A52),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                  if (onRetry != null) const SizedBox(height: 16),

                  // Go back button
                  if (showBackButton)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: onGoBack ??
                            () {
                              Navigator.of(context).pop();
                            },
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        label: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A3A52),
                          side: const BorderSide(
                            color: Color(0xFF1A3A52),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Help text
                  Text(
                    'If the problem persists, please contact support',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getErrorInfo() {
    switch (errorType) {
      case ErrorType.noInternet:
        return {
          'icon': Icons.wifi_off_rounded,
          'color': Colors.orange.shade400,
          'title': 'No Internet Connection',
          'message': 'Please check your network connection and try again.',
        };

      case ErrorType.serverDown:
        return {
          'icon': Icons.cloud_off_rounded,
          'color': Colors.red.shade400,
          'title': 'Service Unavailable',
          'message':
              'SafeRemit is temporarily unavailable. Our team is working on it.',
        };

      case ErrorType.timeout:
        return {
          'icon': Icons.access_time_rounded,
          'color': Colors.orange.shade400,
          'title': 'Connection Timeout',
          'message':
              'The request took too long. Please check your internet and try again.',
        };

      case ErrorType.notFound:
        return {
          'icon': Icons.search_off_rounded,
          'color': Colors.blue.shade400,
          'title': 'Page Not Found',
          'message':
              'The page you\'re looking for doesn\'t exist. Please go back and try again.',
        };

      case ErrorType.accessDenied:
        return {
          'icon': Icons.lock_outline_rounded,
          'color': Colors.red.shade400,
          'title': 'Access Denied',
          'message':
              'You don\'t have permission to access this page. Please log in again.',
        };

      case ErrorType.generic:
      default:
        return {
          'icon': Icons.error_outline_rounded,
          'color': Colors.red.shade400,
          'title': 'Something Went Wrong',
          'message':
              'An unexpected error occurred. Please try again or contact support.',
        };
    }
  }
}
