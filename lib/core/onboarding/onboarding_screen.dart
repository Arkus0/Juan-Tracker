import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/design_system.dart';
import '../widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') != true;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Bienvenido a Juan Tracker',
      subtitle: 'Tu compañero definitivo para nutrición y entrenamiento',
      icon: Icons.fitness_center_rounded,
      color: AppColors.primary,
      description: 'Todo lo que necesitas para alcanzar tus objetivos fitness en una sola app.',
    ),
    _OnboardingPageData(
      title: 'Nutrición Inteligente',
      subtitle: 'Diario de alimentos simplificado',
      icon: Icons.restaurant_menu_rounded,
      color: AppColors.success,
      description: 'Registra tus comidas fácilmente, calcula macros automáticamente y sigue tu progreso.',
    ),
    _OnboardingPageData(
      title: 'Entrenamiento Efectivo',
      subtitle: 'Rutinas y seguimiento de fuerza',
      icon: Icons.fitness_center_rounded,
      color: AppColors.ironRed,
      description: 'Crea rutinas personalizadas, sigue tus series y analiza tu progreso.',
    ),
    _OnboardingPageData(
      title: 'Coach Adaptativo',
      subtitle: 'Ajustes automáticos basados en datos',
      icon: Icons.auto_graph_rounded,
      color: AppColors.info,
      description: 'Nuestro sistema ajusta tus objetivos semanalmente basándose en tu progreso real.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    await OnboardingScreen.markCompleted();
    // Guardar preferencia de onboarding contextual (UX-001)
    await _markContextualOnboardingNeeded();
    widget.onComplete();
  }

  /// Marca que se debe mostrar onboarding contextual tras saltar
  Future<void> _markContextualOnboardingNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('contextual_onboarding_needed', true);
  }

  /// Verifica si se necesita onboarding contextual
  static Future<bool> needsContextualOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('contextual_onboarding_needed') == true;
  }

  /// Marca el onboarding contextual como completado
  static Future<void> markContextualOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('contextual_onboarding_needed', false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button - solo visible tras la 2ª página (UX-001)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AnimatedOpacity(
                  opacity: _currentPage >= 1 ? 1.0 : 0.0,
                  duration: AppDurations.fast,
                  child: TextButton(
                    onPressed: _currentPage >= 1 ? _completeOnboarding : null,
                    child: Text(
                      'Saltar',
                      style: AppTypography.labelLarge.copyWith(
                        color: _currentPage >= 1 
                            ? colors.onSurfaceVariant 
                            : colors.onSurfaceVariant.withAlpha((0.3 * 255).round()),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: _pages[index]);
                },
              ),
            ),

            // Indicators
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: AppDurations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.primary
                          : colors.onSurfaceVariant.withAlpha((0.3 * 255).round()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Next/Start button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton.primary(
                label: _currentPage == _pages.length - 1
                    ? 'COMENZAR'
                    : 'SIGUIENTE',
                onPressed: _nextPage,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  data.color.withAlpha((0.3 * 255).round()),
                  data.color.withAlpha((0.1 * 255).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: data.color.withAlpha((0.3 * 255).round()),
                width: 2,
              ),
            ),
            child: Icon(
              data.icon,
              size: 72,
              color: data.color,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Subtitle
          Text(
            data.subtitle.toUpperCase(),
            style: AppTypography.labelLarge.copyWith(
              color: data.color,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            data.title,
            style: AppTypography.headlineMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            data.description,
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
