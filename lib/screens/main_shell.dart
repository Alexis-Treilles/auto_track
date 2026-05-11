import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
import 'notifications_screen.dart';
import 'add_entry_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    NotificationsScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final alertCount = p.allAlerts.length;

    return Scaffold(
      body: _screens[_index],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBtn(Icons.dashboard_rounded, 'Tableau', 0, _index, (i) => setState(() => _index = i)),
            _NavBadge(Icons.notifications_rounded, 'Alertes', 1, _index, (i) => setState(() => _index = i), alertCount),
            const SizedBox(width: 48),
            _NavBtn(Icons.bar_chart_rounded, 'Stats', 2, _index, (i) => setState(() => _index = i)),
            _NavBtn(Icons.person_rounded, 'Compte', 3, _index, (i) => setState(() => _index = i)),
          ],
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    final p = context.read<AppProvider>();
    if (p.vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoutez un véhicule d\'abord'), backgroundColor: Colors.orange));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEntryScreen(),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final void Function(int) onTap;

  const _NavBtn(this.icon, this.label, this.index, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? AppTheme.primary : Colors.white38, size: 24),
          Text(label, style: TextStyle(color: sel ? AppTheme.primary : Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _NavBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, current;
  final void Function(int) onTap;
  final int count;

  const _NavBadge(this.icon, this.label, this.index, this.current, this.onTap, this.count);

  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    final color = sel ? AppTheme.primary : Colors.white38;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 24),
              if (count > 0)
                Positioned(
                  top: -4, right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ]),
      ),
    );
  }
}
