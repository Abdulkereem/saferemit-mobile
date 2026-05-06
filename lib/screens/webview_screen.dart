import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../services/auth_service.dart';
import 'error_screen.dart';

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
  ErrorType _errorType = ErrorType.generic;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
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
          if (message.message == 'signInWithGoogle') {
            await _handleNativeGoogleSignIn();
          }
        },
      )
      ..setOnConsoleMessage((message) {
        // Log all console messages to see what's happening
        debugPrint('WebView Console: ${message.message}');
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🌐 WebView: Loading $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('✅ WebView: Loaded $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }

            // Inject JavaScript for Google OAuth button
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
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
                '❌ WebView Error: Code=${error.errorCode}, Desc=${error.description}, MainFrame=${error.isForMainFrame}');
            // Only handle MAIN FRAME errors (not images, scripts, etc.)
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;

                  // Categorize error
                  if (error.errorCode == -2 || error.errorCode == -105) {
                    _errorType = ErrorType.noInternet;
                  } else if (error.errorCode == -8) {
                    _errorType = ErrorType.timeout;
                  } else if (error.errorCode == -6) {
                    _errorType = ErrorType.serverDown;
                  } else {
                    _errorType = ErrorType.generic;
                  }
                });
              }
            }
          },
        ),
      );

    // Platform-specific configuration
    if (_controller.platform is AndroidWebViewController) {
      // ENABLE debugging to see what's happening
      AndroidWebViewController.enableDebugging(true);
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

    // Load URL
    _controller.loadRequest(
      Uri.parse(widget.url),
      headers: {'Cache-Control': 'no-cache'},
    );
  }

  Future<void> _handleNativeGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = AuthService();
      final result = await authService.signInWithGoogle();

      if (result['success']) {
        final token = result['token'];
        await _controller.runJavaScript('''
          localStorage.setItem('auth_token', '$token');
          window.location.href = '/dashboard';
        ''');
      } else {
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _hasError
            ? ErrorScreen(
                errorType: _errorType,
                onRetry: _retry,
                showBackButton: true,
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading) _buildLoadingOverlay(),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset(
            'assets/images/logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
