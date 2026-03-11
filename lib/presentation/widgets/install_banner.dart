import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import '../../core/theme/app_colors.dart';

/// Banner that prompts the user to install HeroOS as a PWA.
///
/// Shown only when:
/// - Running on mobile web (kIsWeb + width < 900)
/// - Not already in standalone/installed mode
/// - Not previously dismissed by the user
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});

  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  bool _visible = false;
  static const _prefKey = 'pwa_banner_dismissed';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    // Don't show if already running as installed PWA
    final isStandalone =
        web.window.matchMedia('(display-mode: standalone)').matches;
    if (isStandalone) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_prefKey) ?? false;
    if (!dismissed && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) setState(() => _visible = false);
  }

  void _showInstallInstructions() {
    final ua = web.window.navigator.userAgent.toLowerCase();
    final isIos = ua.contains('iphone') || ua.contains('ipad');

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Instalar HeroOS',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          isIos
              ? 'Toca el botón Compartir (□↑) en Safari\n→ "Añadir a inicio"\n\nAbrirá sin barras del navegador.'
              : 'Abre el menú del navegador (⋮)\n→ "Instalar app" o "Añadir a inicio"\n\nAbrirá sin barras del navegador.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: AppColors.rpg),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dismiss();
            },
            child: const Text(
              'No mostrar más',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.install_mobile_outlined,
            color: AppColors.rpg,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _showInstallInstructions,
              child: const Text(
                'Instala HeroOS para la experiencia completa →',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: _dismiss,
            child: const Icon(
              Icons.close,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
