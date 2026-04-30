import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback? onAuthSuccess;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.onAuthSuccess,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkInternetAndLoad();
  }

  Future<void> _checkInternetAndLoad() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check internet connectivity
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _initializeWebView();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No internet connection';
      });
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Check if user successfully logged in or registered
            // If URL contains /dashboard, it means auth was successful
            if (url.contains('/dashboard')) {
              widget.onAuthSuccess?.call();
              Navigator.of(context).pop();
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Handle network errors
            if (error.errorCode == -2 || // ERR_CACHE_MISS
                error.errorCode == -6 || // ERR_CONNECTION_REFUSED
                error.errorCode == -7 || // ERR_CONNECTION_TIMED_OUT
                error.errorCode == -105) {
              // ERR_NAME_NOT_RESOLVED
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage =
                    'Unable to connect. Please check your internet connection.';
              });
            } else {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = 'Something went wrong. Please try again.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _checkInternetAndLoad();
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _hasError ? _buildErrorScreen() : _buildWebView(),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                Icons.wifi_off_rounded,
                size: 100,
                color: Colors.grey[400],
              ),

              const SizedBox(height: 32),

              // Error title
              Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Error message
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Retry button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _checkInternetAndLoad,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A52),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Go back button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
