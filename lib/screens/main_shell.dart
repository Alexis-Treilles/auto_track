import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
import 'vehicles_screen.dart';
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
    StatsScreen(),
    VehiclesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
            _NavBtn(Icons.bar_chart_rounded, 'Stats', 1, _index, (i) => setState(() => _index = i)),
            const SizedBox(width: 48),
            _NavBtn(Icons.directions_car_rounded, 'Véhicules', 2, _index, (i) => setState(() => _index = i)),
            _NavBtn(Icons.settings_rounded, 'Paramètres', 3, _index, (i) => setState(() => _index = i)),
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
