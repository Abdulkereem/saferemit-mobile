import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../services/auth_service.dart';

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

class _WebViewScreenState extends State<WebViewScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _debugMessage = ''; // For debugging
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeWebView();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterGoogleAuth',
        onMessageReceived: (JavaScriptMessage message) async {
          // Handle native Google Sign-In when button is clicked in WebView
          if (message.message == 'signInWithGoogle') {
            await _handleNativeGoogleSignIn();
          }
        },
      )
      ..addJavaScriptChannel(
        'FlutterAuth',
        onMessageReceived: (JavaScriptMessage message) async {
          // Just log the message, don't close WebView
          setState(() {
            _debugMessage = 'Received: ${message.message}';
          });

          // User should stay in WebView to see the web dashboard
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _debugMessage = 'Loading...';
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _debugMessage = 'Page loaded: $url';
            });

            // Inject JavaScript to intercept Google OAuth button clicks
            _controller.runJavaScript('''
              (function() {
                var googleBtn = document.getElementById('googleOAuthBtn');
                if (googleBtn) {
                  googleBtn.onclick = function(e) {
                    e.preventDefault();
                    FlutterGoogleAuth.postMessage('signInWithGoogle');
                    return false;
                  };
                }
              })();
            ''');

            // DON'T close WebView - let user stay in the web dashboard!
            // The WebView IS the dashboard - user should see the full webapp
          },
          onWebResourceError: (WebResourceError error) {
            // Intercept ALL errors and show custom Flutter error screen
            // Never show browser error pages

            // Only handle main frame errors (not images, scripts, etc.)
            if (error.isForMainFrame ?? false) {
              setState(() {
                _isLoading = false;
                _hasError = true;

                // Categorize errors and show appropriate messages
                if (error.errorCode == -2) {
                  // ERR_INTERNET_DISCONNECTED
                  _errorMessage =
                      'No internet connection. Please check your network and try again.';
                } else if (error.errorCode == -6) {
                  // ERR_CONNECTION_REFUSED
                  _errorMessage =
                      'Unable to connect to SafeRemit. Please try again later.';
                } else if (error.errorCode == -8) {
                  // ERR_TIMED_OUT
                  _errorMessage =
                      'Connection timed out. Please check your internet and try again.';
                } else if (error.errorCode == -105) {
                  // ERR_NAME_NOT_RESOLVED
                  _errorMessage =
                      'Cannot reach SafeRemit servers. Please check your internet connection.';
                } else if (error.errorCode >= 400 && error.errorCode < 500) {
                  // Client errors (404, 403, etc.)
                  _errorMessage =
                      'Page not found. Please try again or contact support.';
                } else if (error.errorCode >= 500) {
                  // Server errors
                  _errorMessage =
                      'SafeRemit is temporarily unavailable. Please try again in a few moments.';
                } else {
                  // Generic error
                  _errorMessage =
                      'Something went wrong. Please check your connection and try again.';
                }
              });
            }
          },
          onHttpError: (HttpResponseError error) {
            // Handle HTTP errors (404, 500, etc.)
            if (error.response?.statusCode != null) {
              final statusCode = error.response!.statusCode!;

              setState(() {
                _isLoading = false;
                _hasError = true;

                if (statusCode >= 500) {
                  _errorMessage =
                      'SafeRemit is temporarily unavailable. Our team is working on it.';
                } else if (statusCode == 404) {
                  _errorMessage =
                      'Page not found. Please go back and try again.';
                } else if (statusCode == 403) {
                  _errorMessage = 'Access denied. Please log in again.';
                } else {
                  _errorMessage = 'Unable to load page. Please try again.';
                }
              });
            }
          },
        ),
      );

    // Platform-specific configuration
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (_controller.platform as AndroidWebViewController)
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return const GeolocationPermissionsResponse(
              allow: true,
              retain: true,
            );
          },
        );
    }

    // Suppress WebView's default error pages
    // We handle all errors with custom Flutter screens
    _controller.setOnConsoleMessage((message) {
      // Optionally log console messages for debugging
      // print('WebView Console: ${message.message}');
    });

    // Load URL
    _controller.loadRequest(
      Uri.parse(widget.url),
      headers: {
        'Cache-Control': 'no-cache',
      },
    );
  }

  Future<void> _handleNativeGoogleSignIn() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      final authService = AuthService();
      final result = await authService.signInWithGoogle();

      if (result['success']) {
        // Store session token
        final token = result['token'];

        // Inject session into WebView and redirect to dashboard
        await _controller.runJavaScript('''
          localStorage.setItem('auth_token', '$token');
          window.location.href = '/dashboard';
        ''');

        // Success callback
        widget.onAuthSuccess?.call();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Google Sign-In failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.reload();
  }

  @override
  void dispose() {
    // Restore status bar when leaving WebView
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _hasError ? _buildErrorScreen() : _buildWebView(),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo (Breathing effect)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),

            // Debug message
            if (_debugMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _debugMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5F3EE),
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
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 60,
                          color: Colors.red.shade400,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Error title
                const Text(
                  'Connection Problem',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A52),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Error message
                Text(
                  _errorMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _retry,
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

                const SizedBox(height: 16),

                // Go back button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
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
    );
  }
}
