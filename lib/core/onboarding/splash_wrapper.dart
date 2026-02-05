import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../design_system/design_system.dart';
import '../i18n/i18n.dart';

/// Wrapper que maneja Splash -> Onboarding -> App
class SplashWrapper extends StatefulWidget {
  final Widget child;

  const SplashWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _showOnboarding = false;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    // Start animation
    _controller.forward();

    // Ejecutar en paralelo: verificar onboarding + delay mínimo
    // Esto reduce el tiempo de espera de 2s a 800ms (mínimo para percibir branding)
    final results = await Future.wait([
      OnboardingScreen.shouldShow(),
      Future.delayed(const Duration(milliseconds: 800)),
    ]);

    final shouldShow = results[0] as bool;

    if (mounted) {
      if (shouldShow) {
        setState(() {
          _showOnboarding = true;
          _isFirstTime = true;
        });
      } else {
        setState(() => _isFirstTime = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
      _isFirstTime = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash during initialization
    if (_isFirstTime && !_showOnboarding) {
      return _SplashScreen(
        fadeAnimation: _fadeAnimation,
        scaleAnimation: _scaleAnimation,
      );
    }

    // Show onboarding if needed
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    // Show actual app
    return widget.child;
  }
}

class _SplashScreen extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;

  const _SplashScreen({
    required this.fadeAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha((0.3 * 255).round()),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // App name
              Text(
                'JUAN TRACKER',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Tagline
              Text(
                AppTranslations.tr('splash.tagline'),
                style: AppTypography.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
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
