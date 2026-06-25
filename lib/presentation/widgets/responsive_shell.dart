import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../viewmodels/shell_controller.dart';
import 'zen_sidebar.dart';

class ResponsiveShell extends StatelessWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();

    if (context.isWeb) {
      return Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const OmniboxIntent(),
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB): const ToggleSidebarIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            OmniboxIntent: CallbackAction<OmniboxIntent>(
              onInvoke: (intent) {
                _showGlobalOmnibox(context);
                return null;
              },
            ),
            ToggleSidebarIntent: CallbackAction<ToggleSidebarIntent>(
              onInvoke: (intent) {
                shell.toggleSidebar();
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: AppColors.scaffold,
              body: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: shell.isWriting ? 0 : (shell.isSidebarCollapsed ? 64 : 240),
                    child: const ZenSidebar(),
                  ),
                  if (!shell.isWriting)
                    const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: child,
    );
  }

  void _showGlobalOmnibox(BuildContext context) {
    // Show the desktop floating omnibox dialog
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return const _DesktopOmniboxDialog();
      },
    );
  }
}

class _DesktopOmniboxDialog extends StatelessWidget {
  const _DesktopOmniboxDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: const ColorFilter.mode(Colors.black38, BlendMode.darken),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: AppColors.habits,
                  decoration: const InputDecoration(
                    hintText: 'Captura rápida asistida por IA...',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OmniboxIntent extends Intent {
  const OmniboxIntent();
}

class ToggleSidebarIntent extends Intent {
  const ToggleSidebarIntent();
}
