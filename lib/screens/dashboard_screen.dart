import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoTrack'),
        actions: [
          if (p.vehicles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                onSelected: (id) {
                  p.selectVehicle(p.vehicles.firstWhere((v) => v.id == id));
                },
                itemBuilder: (_) => p.vehicles
                    .map((v) => PopupMenuItem(value: v.id, child: Text(v.name)))
                    .toList(),
                child: Row(children: [
                  const Icon(Icons.directions_car, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(p.selectedVehicle?.name ?? 'Véhicule',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  const Icon(Icons.expand_more, color: AppTheme.primary),
                ]),
              ),
            ),
        ],
      ),
      body: p.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : p.vehicles.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: p.loadVehicleData,
                  color: AppTheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _hero(p),
                      const SizedBox(height: 16),
                      if (p.alerts.isNotEmpty) ...[
                        _title('Alertes'),
                        ...p.alerts.map((a) => _alertCard(a)),
                        const SizedBox(height: 16),
                      ],
                      _title('Ce mois-ci'),
                      _grid(p),
                      const SizedBox(height: 16),
                      _title('Activité récente'),
                      ..._recent(p),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _empty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.directions_car_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Aucun véhicule', style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Appuyez sur + pour commencer', style: TextStyle(color: Colors.white38)),
        ]),
      );

  Widget _hero(AppProvider p) {
    final v = p.selectedVehicle!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${v.brand} ${v.model} • ${v.year}',
                  style: const TextStyle(color: Colors.white54)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
            ),
            child: Text(v.plate,
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kilométrage', style: TextStyle(color: Colors.white38, fontSize: 11)),
            Text('${NumberFormat('#,###').format(v.currentKm)} km',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Carburant', style: TextStyle(color: Colors.white38, fontSize: 11)),
            Text(v.fuelType,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Couleur', style: TextStyle(color: Colors.white38, fontSize: 11)),
            Text(v.color,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        ]),
      ]),
    );
  }

  Widget _alertCard(Map<String, dynamic> a) {
    final urgent = a['urgent'] as bool;
    final days = a['days'] as int;
    final color = urgent ? AppTheme.danger : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(_aIcon(a['type'] as String), color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(a['title'] as String, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: Text('J-$days', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  IconData _aIcon(String t) {
    if (t == 'maintenance') return Icons.build_rounded;
    if (t == 'control') return Icons.assignment_turned_in_rounded;
    return Icons.security_rounded;
  }

  Widget _grid(AppProvider p) {
    final s = p.stats;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard('Carburant', '${(s['fuel_cost_month'] as double? ?? 0).toStringAsFixed(2)} €', Icons.local_gas_station_rounded, AppTheme.primary),
        _statCard('Entretien', '${(s['maintenance_cost_month'] as double? ?? 0).toStringAsFixed(2)} €', Icons.build_rounded, AppTheme.secondary),
        _statCard('Dépenses', '${(s['expenses_cost_month'] as double? ?? 0).toStringAsFixed(2)} €', Icons.receipt_rounded, Colors.purple),
        _statCard('Total', '${(s['total_cost_month'] as double? ?? 0).toStringAsFixed(2)} €', Icons.account_balance_wallet_rounded, AppTheme.danger),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
          ],
        ),
      );

  List<Widget> _recent(AppProvider p) {
    final items = <Map<String, dynamic>>[];
    for (final e in p.fuelEntries.take(3)) {
      items.add({
        'icon': Icons.local_gas_station_rounded,
        'color': AppTheme.primary,
        'title': 'Plein ${e.liters.toStringAsFixed(1)}L',
        'subtitle': '${e.km} km',
        'amount': e.totalCost,
        'date': e.date,
      });
    }
    for (final e in p.maintenanceEntries.take(2)) {
      items.add({
        'icon': Icons.build_rounded,
        'color': AppTheme.secondary,
        'title': e.type,
        'subtitle': '${e.km} km',
        'amount': e.cost,
        'date': e.date,
      });
    }
    items.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    if (items.isEmpty) {
      return [const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucune activité', style: TextStyle(color: Colors.white38))))];
    }
    return items.take(5).map((item) {
      final color = item['color'] as Color;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(item['icon'] as IconData, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            Text(item['subtitle'] as String, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${(item['amount'] as double).toStringAsFixed(2)} €', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(DateFormat('dd/MM').format(item['date'] as DateTime), style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ]),
      );
    }).toList();
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      );
}
