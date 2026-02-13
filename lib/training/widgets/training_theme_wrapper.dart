import 'package:flutter/material.dart';
import '../utils/design_system.dart';

/// Wraps a child widget in the training dark theme.
///
/// Used by GoRouter routes that live outside of [TrainingShell]
/// (e.g., `/training/session`, `/training/session/detail`)
/// but still need the aggressive red dark theme.
///
/// This replaces the pattern of wrapping in Theme() via Navigator.push:
/// ```dart
/// // Before (fragile, loses theme on hot reload):
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => Theme(data: theme, child: SessionDetailScreen(...)),
/// ));
///
/// // After (GoRouter + TrainingThemeWrapper):
/// GoRoute(
///   path: '/training/session',
///   builder: (_, __) => TrainingThemeWrapper(child: TrainingSessionScreen()),
/// )
/// ```
class TrainingThemeWrapper extends StatelessWidget {
  final Widget child;
  const TrainingThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildAppTheme(),
      child: child,
    );
  }
}
