import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/shell_controller.dart';
import '../../core/theme/app_colors.dart';
import 'zen_glass.dart';

/// Zen sidebar for web layout.
///
/// The sidebar is a permanent navigation element, we use ZenGlass for it.
class ZenSidebar extends StatelessWidget {
  const ZenSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();

    final destinations = [
      const _SidebarDest('Hoy', Icons.today_outlined),
      const _SidebarDest('Misiones', Icons.task_alt_outlined),
      const _SidebarDest('Hábitos', Icons.repeat_outlined),
      const _SidebarDest('Finanzas', Icons.account_balance_wallet_outlined),
      const _SidebarDest('Descanso', Icons.nightlight_round),
      const _SidebarDest('Notas', Icons.note_alt_outlined),
      const _SidebarDest('Perfil', Icons.person_outline),
    ];

    final bool isCollapsed = shell.isSidebarCollapsed;

    return ZenGlass(
      borderRadius: 0,
      child: NavigationRail(
        extended: !isCollapsed && !shell.isWriting,
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.setTab,
        backgroundColor: Colors.transparent,
        unselectedIconTheme: const IconThemeData(
          color: Colors.white30,
          size: 22,
        ),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
        unselectedLabelTextStyle: const TextStyle(
          color: Colors.white30,
          fontSize: 13,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        indicatorColor: Colors.white10,
        destinations: destinations.map((d) {
          return NavigationRailDestination(
            icon: Tooltip(
              message: d.label,
              child: _SidebarIcon(icon: d.icon, isSelected: false),
            ),
            selectedIcon: Tooltip(
              message: d.label,
              child: _SidebarIcon(icon: d.icon, isSelected: true),
            ),
            label: Text(d.label),
          );
        }).toList(),
      ),
    );
  }
}

class _SidebarDest {
  final String label;
  final IconData icon;
  const _SidebarDest(this.label, this.icon);
}

class _SidebarIcon extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  const _SidebarIcon({required this.icon, required this.isSelected});

  @override
  State<_SidebarIcon> createState() => _SidebarIconState();
}

class _SidebarIconState extends State<_SidebarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: widget.isSelected ? 1.0 : (_isHovered ? 0.9 : 0.4),
        child: Icon(widget.icon),
      ),
    );
  }
}
