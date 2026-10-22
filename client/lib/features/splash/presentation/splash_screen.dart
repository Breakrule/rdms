import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../document_explorer/presentation/document_explorer_screen.dart';
import '../../documents/presentation/providers/document_providers.dart';
import '../../metrics/presentation/metrics_providers.dart';

/// Instant, smoothly animated Splash Screen with immediate visual presence,
/// gentle scale and breathing glow effects, eliminating blank/black startup gaps.
class SplashScreen extends ConsumerStatefulWidget {
  final Duration navDelay;
  const SplashScreen({
    super.key,
    this.navDelay = const Duration(milliseconds: 1400),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowPulse;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // Rev.2 P0.3: one `session_start` counter per app launch. Read, not
    // watched — resolving the metrics service here must not add a
    // database-backed dependency to any build() path. The write is
    // fire-and-forget and swallows its own failures, so a first launch
    // before the database exists simply records nothing.
    ref.read(metricsServiceProvider).recordSessionStart();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Subtle, gentle entrance: logo starts almost full size (0.92 -> 1.0)
    // so it is immediately legible on frame 0 without black/blank lag
    _logoScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Fade starts at 0.85 to ensure instant visibility on first paint
    _contentFade = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _glowPulse = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.forward();

    // Start navigation timer immediately
    _navTimer = Timer(widget.navDelay, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DocumentExplorerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });

    // Background session restoration (silent Google Auth restore)
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await ref.read(googleAuthServiceProvider).signInSilently();
    } catch (_) {
      // Ignored during startup
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1220)
          : const Color(0xFFF6F8FC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient matching AppTheme scaffold tokens
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF0B1220),
                        Color(0xFF111C2E),
                        Color(0xFF0F1B2F),
                      ]
                    : const [
                        Color(0xFFF6F8FC),
                        Color(0xFFEEF2F8),
                        Color(0xFFFFFFFF),
                      ],
              ),
            ),
          ),

          // Ambient Glow behind logo
          Center(
            child: AnimatedBuilder(
              animation: _glowPulse,
              builder: (context, child) {
                return Transform.scale(
                  scale: _glowPulse.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F52BA)
                              .withValues(alpha: isDark ? 0.35 : 0.20),
                          blurRadius: 70,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Central Content - Immediately Visible on Frame 0
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Immediately rendered logo with subtle scale spring
                AnimatedBuilder(
                  animation: _logoScale,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131F37).withValues(alpha: 0.90)
                              : Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF0F52BA)
                                .withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F52BA)
                                  .withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/icon.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.folder_special_rounded,
                                  size: 80,
                                  color: Color(0xFF0F52BA),
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // App Name & Subtitle - Instantly Visible
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _contentSlide,
                    child: Column(
                      children: [
                        const Text(
                          'RDMS ULTIMATE',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.5,
                            color: Color(0xFF0F52BA),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart Document Management System',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.65)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Progress Indicator & Footnote
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 140,
                          height: 3,
                          child: LinearProgressIndicator(
                            value: _controller.value,
                            backgroundColor: const Color(0xFF0F52BA)
                                .withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0F52BA),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Offline-First • Cloud Synchronized',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.40)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
