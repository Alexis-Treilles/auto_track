import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/vehicle.dart';
import '../providers/app_provider.dart';
import 'add_vehicle_screen.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Véhicules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddVehicleScreen())),
          ),
        ],
      ),
      body: p.vehicles.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.directions_car_outlined, size: 80, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('Aucun véhicule', style: TextStyle(color: Colors.white54, fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AddVehicleScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un véhicule'),
                ),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: p.vehicles.length,
              itemBuilder: (_, i) {
                final v = p.vehicles[i];
                final selected = p.selectedVehicle?.id == v.id;
                return _VehicleCard(vehicle: v, selected: selected, onTap: () => p.selectVehicle(v));
              },
            ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleCard({required this.vehicle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 1.5),
        ),
        child: Column(children: [
          // Photo header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: v.photoUrl != null
                ? Image.network(
                    v.photoUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(v.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Actif', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                  Text('${v.brand} ${v.model} • ${v.year}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(v.plate, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _chip(Icons.speed_rounded, '${v.currentKm} km', AppTheme.primary),
                _chip(Icons.local_gas_station_rounded, v.fuelType, AppTheme.secondary),
                _chip(Icons.palette_rounded, v.color, Colors.purple),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
    width: double.infinity, height: 160,
    color: const Color(0xFF1A1A2E),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.directions_car_rounded, size: 48, color: AppTheme.primary),
      const SizedBox(height: 8),
      Text('${vehicle.brand} ${vehicle.model}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
    ]),
  );

  Widget _chip(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
  ]);
}
