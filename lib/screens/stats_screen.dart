import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: p.selectedVehicle == null
          ? const Center(child: Text('Sélectionnez un véhicule', style: TextStyle(color: Colors.white54)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MileageChart(p),
                const SizedBox(height: 20),
                _FuelConsumptionChart(p),
                const SizedBox(height: 20),
                _ExpensePieChart(p),
                const SizedBox(height: 20),
                _MaintenanceHistory(p),
                const SizedBox(height: 20),
                _InsuranceCard(p),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _MileageChart extends StatelessWidget {
  final AppProvider p;
  const _MileageChart(this.p);

  @override
  Widget build(BuildContext context) {
    final entries = p.fuelEntries.reversed.toList();
    if (entries.isEmpty) {
      return _Empty('Kilométrage', Icons.speed_rounded, 'Aucun plein enregistré');
    }
    final spots = entries.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.km.toDouble())).toList();
    return _Card(
      title: 'Évolution kilométrage', icon: Icons.speed_rounded, color: AppTheme.primary,
      child: SizedBox(height: 180, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: Colors.white10, strokeWidth: 1)),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 52, getTitlesWidget: (v, _) => Text(NumberFormat('#,###').format(v.toInt()), style: const TextStyle(color: Colors.white38, fontSize: 9)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i >= 0 && i < entries.length && i % (entries.length > 6 ? 2 : 1) == 0) {
              return Text(DateFormat('MM/yy').format(entries[i].date), style: const TextStyle(color: Colors.white38, fontSize: 9));
            }
            return const SizedBox();
          })),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: AppTheme.primary, barWidth: 2.5, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)))],
      ))),
    );
  }
}

class _FuelConsumptionChart extends StatelessWidget {
  final AppProvider p;
  const _FuelConsumptionChart(this.p);

  @override
  Widget build(BuildContext context) {
    final entries = p.fuelEntries.reversed.toList();
    if (entries.length < 2) return _Empty('Consommation', Icons.local_gas_station_rounded, 'Besoin d\'au moins 2 pleins');
    final bars = <BarChartGroupData>[];
    for (int i = 1; i < entries.length && i <= 10; i++) {
      final dist = entries[i].km - entries[i - 1].km;
      if (dist > 0) {
        final conso = entries[i].liters / dist * 100;
        bars.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: conso, color: AppTheme.secondary, width: 14, borderRadius: BorderRadius.circular(4))]));
      }
    }
    if (bars.isEmpty) return const SizedBox();
    return _Card(
      title: 'Consommation (L/100km)', icon: Icons.local_gas_station_rounded, color: AppTheme.secondary,
      child: SizedBox(height: 160, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: bars,
        barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (g, gi, rod, ri) => BarTooltipItem('${rod.toY.toStringAsFixed(1)} L', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ))),
    );
  }
}

class _ExpensePieChart extends StatelessWidget {
  final AppProvider p;
  const _ExpensePieChart(this.p);

  @override
  Widget build(BuildContext context) {
    final fuel = p.stats['fuel_cost_month'] as double? ?? 0;
    final maint = p.stats['maintenance_cost_month'] as double? ?? 0;
    final exp = p.stats['expenses_cost_month'] as double? ?? 0;
    final total = fuel + maint + exp;
    if (total == 0) return _Empty('Répartition dépenses', Icons.pie_chart_rounded, 'Aucune dépense ce mois');
    final sections = [
      if (fuel > 0) PieChartSectionData(value: fuel, color: AppTheme.primary, title: 'Carburant\n${(fuel / total * 100).toStringAsFixed(0)}%', radius: 70, titleStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
      if (maint > 0) PieChartSectionData(value: maint, color: AppTheme.secondary, title: 'Entretien\n${(maint / total * 100).toStringAsFixed(0)}%', radius: 70, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      if (exp > 0) PieChartSectionData(value: exp, color: Colors.purple, title: 'Divers\n${(exp / total * 100).toStringAsFixed(0)}%', radius: 70, titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    ];
    return _Card(
      title: 'Répartition ce mois', icon: Icons.pie_chart_rounded, color: Colors.purple,
      child: SizedBox(height: 200, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 3))),
    );
  }
}

class _MaintenanceHistory extends StatelessWidget {
  final AppProvider p;
  const _MaintenanceHistory(this.p);

  @override
  Widget build(BuildContext context) {
    final entries = p.maintenanceEntries.take(5).toList();
    return _Card(
      title: 'Historique entretiens', icon: Icons.build_rounded, color: AppTheme.secondary,
      child: entries.isEmpty
          ? const Padding(padding: EdgeInsets.all(20), child: Text('Aucun entretien', style: TextStyle(color: Colors.white38), textAlign: TextAlign.center))
          : Column(children: entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.build_rounded, color: AppTheme.secondary, size: 14)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                Text('${e.km} km • ${DateFormat('dd/MM/yyyy').format(e.date)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ])),
              Text('${e.cost.toStringAsFixed(0)} €', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          )).toList()),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  final AppProvider p;
  const _InsuranceCard(this.p);

  @override
  Widget build(BuildContext context) {
    final active = p.insurances.where((i) => i.isActive).toList();
    return _Card(
      title: 'Assurances actives', icon: Icons.security_rounded, color: Colors.teal,
      child: active.isEmpty
          ? const Padding(padding: EdgeInsets.all(20), child: Text('Aucune assurance', style: TextStyle(color: Colors.white38), textAlign: TextAlign.center))
          : Column(children: active.map((ins) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              const Icon(Icons.security_rounded, color: Colors.teal, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ins.company, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(ins.coverageType, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Expire', style: TextStyle(color: Colors.white38, fontSize: 11)),
                Text(DateFormat('dd/MM/yyyy').format(ins.endDate),
                    style: TextStyle(color: ins.isExpiringSoon ? AppTheme.danger : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ]),
          )).toList()),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
      const SizedBox(height: 16),
      child,
    ]),
  );
}

class _Empty extends StatelessWidget {
  final String title, message;
  final IconData icon;
  const _Empty(this.title, this.icon, this.message);

  @override
  Widget build(BuildContext context) => _Card(
    title: title, icon: icon, color: Colors.white38,
    child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(message, style: const TextStyle(color: Colors.white38)))),
  );
}
