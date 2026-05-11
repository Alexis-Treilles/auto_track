import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import 'add_entry_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final alerts = p.allAlerts;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: p.loadVehicleData,
          ),
        ],
      ),
      body: p.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : alerts.isEmpty
              ? _buildEmpty(context)
              : RefreshIndicator(
                  onRefresh: p.loadVehicleData,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: alerts.length,
                    itemBuilder: (_, i) => _AlertCard(
                      alert: alerts[i],
                      onAddEntry: () => _openEntry(context, alerts[i], p),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Tout est à jour', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Aucune échéance à venir', style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: context.read<AppProvider>().loadVehicleData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Actualiser'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ]),
      );

  void _openEntry(BuildContext context, Map<String, dynamic> a, AppProvider p) {
    final type = a['type'] as String;
    final date = a['date'] as DateTime;
    final vehicleId = a['vehicleId'] as String?;

    if (vehicleId != null && p.selectedVehicle?.id != vehicleId) {
      final idx = p.vehicles.indexWhere((v) => v.id == vehicleId);
      if (idx != -1) p.selectVehicle(p.vehicles[idx]);
    }

    int tab;
    String? maintenanceType;
    DateTime? nextDate;

    if (type == 'maintenance') {
      tab = 1;
      final title = a['title'] as String;
      maintenanceType = title.contains(': ') ? title.split(': ').last : null;
      nextDate = date;
    } else if (type == 'control') {
      tab = 2;
      nextDate = date;
    } else {
      tab = 3;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEntryScreen(
        initialTab: tab,
        initialMaintenanceType: maintenanceType,
        initialDate: DateTime.now(),
        initialNextDate: nextDate,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onAddEntry;

  const _AlertCard({required this.alert, required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final urgent = alert['urgent'] as bool;
    final days = alert['days'] as int;
    final type = alert['type'] as String;
    final vehicleName = alert['vehicleName'] as String? ?? '';
    final color = urgent ? AppTheme.danger : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon(type), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              alert['title'] as String,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Row(children: [
              if (vehicleName.isNotEmpty) ...[
                const Icon(Icons.directions_car_rounded, size: 11, color: Colors.white38),
                const SizedBox(width: 3),
                Text(vehicleName, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  days == 0 ? "Aujourd'hui" : 'J-$days',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAddEntry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: AppTheme.primary, size: 18),
              Text('Saisir', style: TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),
    );
  }

  IconData _icon(String t) {
    if (t == 'maintenance') return Icons.build_rounded;
    if (t == 'control') return Icons.assignment_turned_in_rounded;
    return Icons.security_rounded;
  }
}
