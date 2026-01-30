import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Botón para volver a Home (EntryScreen) desde cualquier pantalla
/// Muestra el logo de Juan Tracker con efecto de tarjeta/reborde
class HomeButton extends StatelessWidget {
  final double size;
  final VoidCallback? onPressed;

  const HomeButton({
    super.key,
    this.size = 44,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => context.go('/entry'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary,
                colors.primary.withAlpha((0.7 * 255).round()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.onPrimary.withAlpha((0.3 * 255).round()),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withAlpha((0.4 * 255).round()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.track_changes_rounded,
            color: colors.onPrimary,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// AppBar con logo de Home integrado
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showHomeButton;
  final PreferredSizeWidget? bottom;

  const HomeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showHomeButton = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: showHomeButton
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: HomeButton(),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
