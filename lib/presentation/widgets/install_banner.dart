import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import 'install_banner_stub.dart'
    if (dart.library.js_interop) 'install_banner_web.dart';

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
  static final _prefKey = 'pwa_banner_dismissed';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    // Don't show if already running as installed PWA
    final isStandalone = getStandaloneMode();
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
    // ponytail: isIos detection only matters on web, guard here
    final isIos = kIsWeb
        ? getUserAgent().contains('iphone') || getUserAgent().contains('ipad')
        : false;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Instalar HeroOS',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          isIos
              ? 'Toca el botón Compartir (□↑) en Safari\n→ "Añadir a inicio"\n\nAbrirá sin barras del navegador.'
              : 'Abre el menú del navegador (⋮)\n→ "Instalar app" o "Añadir a inicio"\n\nAbrirá sin barras del navegador.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido', style: TextStyle(color: AppColors.habits)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dismiss();
            },
            child: Text(
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
    if (!_visible) return SizedBox.shrink();

    return Container(
      height: 40,
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.install_mobile_outlined,
            color: AppColors.habits,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _showInstallInstructions,
              child: Text(
                'Instala HeroOS para la experiencia completa →',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onTap: _dismiss,
            child: Icon(Icons.close, color: AppColors.textSecondary, size: 16),
          ),
        ],
      ),
    );
  }
}
