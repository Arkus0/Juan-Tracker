import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/design_system.dart';
import '../i18n/i18n.dart';
import '../widgets/widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
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
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Total de páginas: 1 (idioma) + 5 (contenido) = 6
  static const _totalPages = 6;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
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

  // ignore: unused_element
  static Future<bool> needsContextualOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('contextual_onboarding_needed') == true;
  }

  // ignore: unused_element
  static Future<void> markContextualOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('contextual_onboarding_needed', false);
  }

  /// Construye las páginas de contenido traducidas
  List<_OnboardingPageData> _buildPages() {
    final t = ref.tr;
    return [
      _OnboardingPageData(
        title: t('onboarding.welcome.title'),
        subtitle: t('onboarding.welcome.subtitle'),
        icon: Icons.fitness_center_rounded,
        color: AppColors.primary,
        description: t('onboarding.welcome.description'),
      ),
      _OnboardingPageData(
        title: t('onboarding.nutrition.title'),
        subtitle: t('onboarding.nutrition.subtitle'),
        icon: Icons.restaurant_menu_rounded,
        color: AppColors.success,
        description: t('onboarding.nutrition.description'),
      ),
      _OnboardingPageData(
        title: t('onboarding.training.title'),
        subtitle: t('onboarding.training.subtitle'),
        icon: Icons.fitness_center_rounded,
        color: AppColors.ironRed,
        description: t('onboarding.training.description'),
      ),
      _OnboardingPageData(
        title: t('onboarding.coach.title'),
        subtitle: t('onboarding.coach.subtitle'),
        icon: Icons.auto_graph_rounded,
        color: AppColors.info,
        description: t('onboarding.coach.description'),
      ),
      _OnboardingPageData(
        title: t('onboarding.profile.title'),
        subtitle: t('onboarding.profile.subtitle'),
        icon: Icons.person_rounded,
        color: AppColors.secondary,
        description: t('onboarding.profile.description'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;
    final pages = _buildPages();

    // Skip visible desde la página 2 (después de idioma y bienvenida)
    final canSkip = _currentPage >= 2;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button - visible tras página de idioma + bienvenida
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AnimatedOpacity(
                  opacity: canSkip ? 1.0 : 0.0,
                  duration: AppDurations.fast,
                  child: TextButton(
                    onPressed: canSkip ? _completeOnboarding : null,
                    child: Text(
                      t('common.skip'),
                      style: AppTypography.labelLarge.copyWith(
                        color: canSkip
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
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  // Página 0: selector de idioma
                  if (index == 0) {
                    return _LanguageSelectionPage();
                  }
                  // Páginas 1-5: contenido de onboarding
                  return _OnboardingPage(data: pages[index - 1]);
                },
              ),
            ),

            // Indicators
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
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
                label: _currentPage == _totalPages - 1
                    ? t('common.start')
                    : t('common.next'),
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

/// Página de selección de idioma (primera página del onboarding)
class _LanguageSelectionPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha((0.3 * 255).round()),
                  AppColors.primary.withAlpha((0.1 * 255).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.primary.withAlpha((0.3 * 255).round()),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.language_rounded,
              size: 72,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Text(
            t('onboarding.selectLanguage'),
            style: AppTypography.headlineMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t('onboarding.selectLanguageSubtitle'),
            style: AppTypography.bodyLarge.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Selector de idioma
          const LanguageSelector(),
        ],
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
