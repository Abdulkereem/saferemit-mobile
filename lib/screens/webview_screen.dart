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
  bool _initialLoadDone = false; // after first page finishes, suppress loader
  bool _hasError = false;
  ErrorType _errorType = ErrorType.generic;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
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
                // Only show the splash overlay for the very first load.
                // Internal dashboard navigation should feel instant.
                if (!_initialLoadDone) _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            debugPrint('✅ WebView: Loaded $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _initialLoadDone = true;
              });
            }

            // Ensure native styling is applied (belt-and-suspenders alongside inline CSS detection)
            _controller.runJavaScript('''
              (function() {
                document.documentElement.classList.add('wv');

                // Force system font if CSS class wasn't applied before first paint
                if (!document.getElementById('_wv_style')) {
                  var s = document.createElement('style');
                  s.id = '_wv_style';
                  s.textContent = [
                    'html.wv,html.wv body{font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display","SF Pro Text","Roboto","Google Sans",system-ui,sans-serif!important}',
                    'html.wv ::-webkit-scrollbar{display:none}',
                    'html.wv *{scrollbar-width:none;-webkit-touch-callout:none}',
                    'html.wv :not(input):not(textarea):not([contenteditable]){-webkit-user-select:none;user-select:none}',
                    'html.wv input,html.wv textarea{-webkit-user-select:text;user-select:text}',
                    'html.wv input,html.wv textarea,html.wv select,html.wv button{-webkit-appearance:none;appearance:none;font-family:inherit}'
                  ].join('');
                  document.head.appendChild(s);
                }
              })();
            ''');

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

      if (result['success'] == true) {
        final sessionToken = result['session_token'] as String? ?? '';

        if (sessionToken.isEmpty) {
          throw Exception('No session token returned from server');
        }

        // Navigate the WebView to the handoff route. The server sets the
        // Flask session cookie on this response (WebView context), logging
        // the user in, then redirects them to the dashboard.
        await _controller.runJavaScript(
          "window.location.href = '/auth/mobile-session/$sessionToken';",
        );
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
                  // Pad WebView so system bars (status + nav) don't cover web content
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: WebViewWidget(controller: _controller),
                  ),
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
