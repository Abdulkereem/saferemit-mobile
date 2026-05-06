import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'webview_screen.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoggedIn = false;
  late AnimationController _orbitController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _orbitController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    setState(() {
      _isLoggedIn = false;
    });
  }

  void _navigateToAuth(String type) {
    // Open WebView directly - user will login and stay in WebView
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          url: 'https://saferemit.finance/auth/$type',
          title: type == 'login' ? 'Sign In' : 'Sign Up',
          onAuthSuccess: () async {
            // This callback is not really needed anymore
            // User stays in WebView after login
          },
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3A52)),
        ),
      ),
    );

    final result = await _authService.signInWithGoogle();

    // Hide loading
    if (mounted) Navigator.of(context).pop();

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      setState(() {
        _isLoggedIn = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Sign in failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeRemit'),
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: _isLoggedIn ? _buildDashboard() : _buildWelcome(),
    );
  }

  Widget _buildWelcome() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5F3EE),
            const Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Orbiting Logo with Icons
              SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Orbiting icons
                    AnimatedBuilder(
                      animation: _orbitController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Bitcoin
                            _buildOrbitingIcon(
                              '₿',
                              0,
                              _orbitController.value,
                              const Color(0xFFF7931A),
                            ),
                            // Ethereum
                            _buildOrbitingIcon(
                              'Ξ',
                              1,
                              _orbitController.value,
                              const Color(0xFF627EEA),
                            ),
                            // USDT
                            _buildOrbitingIcon(
                              '\$',
                              2,
                              _orbitController.value,
                              const Color(0xFF26A17B),
                            ),
                            // Gift Card
                            _buildOrbitingIcon(
                              '🎁',
                              3,
                              _orbitController.value,
                              const Color(0xFFE85D5D),
                            ),
                            // Amazon
                            _buildOrbitingIcon(
                              'A',
                              4,
                              _orbitController.value,
                              const Color(0xFFFF9900),
                            ),
                            // iTunes
                            _buildOrbitingIcon(
                              '♪',
                              5,
                              _orbitController.value,
                              const Color(0xFFFA243C),
                            ),
                          ],
                        );
                      },
                    ),

                    // Center Logo with scale animation
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1A3A52).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Welcome text with animation
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: const Text(
                  'Welcome to SafeRemit',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A52),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Description with animation
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'Convert your gift cards and crypto to cash instantly',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 60),

              // Google Sign In button
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 900),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 24,
                      height: 24,
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A3A52),
                      side: const BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign In button with animation
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1000),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _navigateToAuth('login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A52),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: const Color(0xFF1A3A52).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Up button with animation
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1200),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () => _navigateToAuth('register'),
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
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),

            const SizedBox(height: 32),

            const Text(
              'You\'re Logged In!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text(
              'Dashboard features coming soon...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 48),

            // Open Dashboard button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WebViewScreen(
                        url: 'https://saferemit.finance/dashboard',
                        title: 'Dashboard',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Open Dashboard',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitingIcon(
      String icon, int index, double progress, Color color) {
    final double angle = (progress * 2 * math.pi) + (index * math.pi / 3);
    final double radius = 120;
    final double x = radius * math.cos(angle);
    final double y = radius * math.sin(angle);

    // Map index to Font Awesome icon
    IconData iconData;
    switch (index) {
      case 0:
        iconData = FontAwesomeIcons.bitcoin; // Bitcoin
        break;
      case 1:
        iconData = FontAwesomeIcons.ethereum; // Ethereum
        break;
      case 2:
        iconData = FontAwesomeIcons.dollarSign; // USDT
        break;
      case 3:
        iconData = FontAwesomeIcons.amazon; // Amazon
        break;
      case 4:
        iconData = FontAwesomeIcons.apple; // Apple/iTunes
        break;
      case 5:
        iconData = FontAwesomeIcons.steam; // Steam
        break;
      default:
        iconData = FontAwesomeIcons.gift;
    }

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: FaIcon(
            iconData,
            size: 24,
            color: color,
          ),
        ),
      ),
    );
  }
}
