import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'responsive.dart';

/// Muestra un Dialog en web y un ModalBottomSheet en móvil.
/// El [child] debe gestionar su propio scroll si el contenido es largo.
Future<T?> showAdaptiveModal<T>(
  BuildContext context,
  Widget child,
) {
  if (context.isWeb) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child,
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => child,
  );
}
