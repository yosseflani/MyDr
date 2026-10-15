import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/features/appointments/appointments_screen.dart';
import 'package:mydr/features/dashboard/dashboard_screen.dart';
import 'package:mydr/features/family/family_screen.dart';
import 'package:mydr/features/symptoms/symptoms_screen.dart';

/// Main navigation shell with a bottom [NavigationBar].
///
/// Tabs are kept alive in an [IndexedStack] so each one preserves its
/// scroll position and state when switching between tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const int _symptomsTabIndex = 3;

  late final List<_ShellTab> _tabs = [
    _ShellTab(
      label: AppStrings.tabHome,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      screen: DashboardScreen(
        onShowAllSymptoms: () => _onTabSelected(_symptomsTabIndex),
      ),
    ),
    const _ShellTab(
      label: AppStrings.tabFamily,
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      screen: FamilyScreen(),
    ),
    const _ShellTab(
      label: AppStrings.tabAppointments,
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      screen: AppointmentsScreen(),
    ),
    const _ShellTab(
      label: AppStrings.tabSymptoms,
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
      screen: SymptomsScreen(),
    ),
  ];

  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final tab in _tabs) tab.screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
