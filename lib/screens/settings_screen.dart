import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import 'add_vehicle_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User profile card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.userMetadata?['full_name'] ?? 'Mon compte',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          _header('Véhicules'),
          ...p.vehicles.map((v) => _VehicleTile(name: v.name, subtitle: '${v.brand} ${v.model} • ${v.plate}', photoUrl: v.photoUrl)),
          _AddTile(label: 'Ajouter un véhicule', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()))),
          const SizedBox(height: 24),

          _header('Application'),
          _Tile(icon: Icons.info_outline_rounded, label: 'Version', trailing: '1.0.0', color: AppTheme.secondary),
          _Tile(icon: Icons.storage_rounded, label: 'Base de données', trailing: 'Supabase', color: Colors.green),
          _Tile(
            icon: Icons.refresh_rounded, label: 'Synchroniser', color: AppTheme.secondary,
            onTap: () async {
              await p.loadVehicleData();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Données synchronisées')));
            },
          ),
          const SizedBox(height: 24),

          _header('Compte'),
          _Tile(
            icon: Icons.logout_rounded, label: 'Se déconnecter', color: AppTheme.danger,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Voulez-vous vous déconnecter ?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }
}

class _VehicleTile extends StatelessWidget {
  final String name, subtitle;
  final String? photoUrl;
  const _VehicleTile({required this.name, required this.subtitle, this.photoUrl});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: photoUrl != null
            ? Image.network(photoUrl!, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultIcon())
            : _defaultIcon(),
      ),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ),
  );

  Widget _defaultIcon() => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 22),
  );
}

class _AddTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color color;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, required this.color, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: trailing != null ? Text(trailing!, style: const TextStyle(color: Colors.white38)) : onTap != null ? const Icon(Icons.chevron_right_rounded, color: Colors.white38) : null,
    ),
  );
}
