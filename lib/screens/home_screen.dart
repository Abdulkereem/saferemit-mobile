import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'webview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoggedIn = false;
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  late AnimationController _particlesController;

  final List<_Particle> _particles = List.generate(14, (i) => _Particle(i));

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particlesController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) setState(() => _isLoggedIn = false);
  }

  void _navigateToAuth(String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          url: 'https://saferemit.finance/auth/$type',
          title: type == 'login' ? 'Sign In' : 'Sign Up',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EE),
      body: _isLoggedIn ? _buildDashboard() : _buildWelcome(),
    );
  }

  // ═══════════════════════════════════════════
  //  WELCOME SCREEN
  // ═══════════════════════════════════════════

  Widget _buildWelcome() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5F3EE), Color(0xFFFFFFFF)],
              stops: [0.0, 0.55],
            ),
          ),
        ),

        // Floating particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particlesController,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(
                progress: _particlesController.value,
                particles: _particles,
              ),
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        _buildLogo(),

                        const SizedBox(height: 44),

                        _entranceItem(
                          delay: 0.0,
                          child: const Text(
                            'Convert Gift Cards &\nCrypto to Cash Instantly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A2740),
                              height: 1.28,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _entranceItem(
                          delay: 0.18,
                          child: Text(
                            'Fast · Secure · Reliable',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),

                        const SizedBox(height: 52),

                        _entranceItem(
                          delay: 0.36,
                          child: _authButton(
                            label: 'Sign In',
                            onPressed: () => _navigateToAuth('login'),
                            filled: true,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _entranceItem(
                          delay: 0.54,
                          child: _authButton(
                            label: 'Create Account',
                            onPressed: () => _navigateToAuth('register'),
                            filled: false,
                          ),
                        ),

                        const Spacer(flex: 2),

                        _entranceItem(
                          delay: 0.72,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Text(
                              'SafeRemit Innovations Ltd',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        return Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF4C044).withOpacity(0.06 + t * 0.16),
                blurRadius: 36 + t * 28,
                spreadRadius: 6 + t * 10,
              ),
              BoxShadow(
                color: const Color(0xFF1A2740).withOpacity(0.03 + t * 0.05),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A2740).withOpacity(0.06),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget _entranceItem({required double delay, required Widget child}) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        const total = 1.4;
        const itemDur = 0.45;
        final start = delay / total;
        final raw =
            ((_entranceController.value - start) / (itemDur / total))
                .clamp(0.0, 1.0);
        final curved = Curves.easeOutCubic.transform(raw);

        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 36 * (1 - curved)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _authButton({
    required String label,
    required VoidCallback onPressed,
    required bool filled,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2740),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: const Color(0xFF1A2740).withOpacity(0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A2740),
                side: BorderSide(
                  color: const Color(0xFF1A2740).withOpacity(0.18),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════
  //  DASHBOARD VIEW (LOGGED IN)
  // ═══════════════════════════════════════════

  Widget _buildDashboard() {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FCD82).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: Color(0xFF2FCD82),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'You\'re Signed In',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2740),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open your dashboard to get started',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
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
                        backgroundColor: const Color(0xFF1A2740),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Open Dashboard',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF1A2740)),
              onPressed: _logout,
              tooltip: 'Sign Out',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  PARTICLE SYSTEM
// ═══════════════════════════════════════════════════

class _Particle {
  final int seed;
  const _Particle(this.seed);

  double get x => ((seed * 73 + 17) % 100) / 100;
  double get baseY => ((seed * 47 + 31) % 90) / 100;
  double get size => 2.5 + (seed % 5);
  int get colorIndex => seed % 4;
  double get speed => 0.25 + (seed % 8) * 0.08;
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  const _ParticlePainter({required this.progress, required this.particles});

  static const _colors = [
    Color(0xFFF4C044),
    Color(0xFF3A8DF3),
    Color(0xFF2FCD82),
    Color(0xFF1A2740),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = p.x * size.width;
      final rawY = (p.baseY - progress * p.speed) % 1.0;
      final y = (rawY < 0 ? rawY + 1.0 : rawY) * size.height;

      final paint = Paint()
        ..color = _colors[p.colorIndex].withOpacity(0.04 + (p.seed % 4) * 0.015)
        ..style = PaintingStyle.fill;

      if (p.seed % 3 == 0) {
        final path = Path()
          ..moveTo(x, y - p.size)
          ..lineTo(x + p.size, y)
          ..lineTo(x, y + p.size)
          ..lineTo(x - p.size, y)
          ..close();
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
