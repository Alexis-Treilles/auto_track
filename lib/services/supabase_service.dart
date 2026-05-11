import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';
import '../models/technical_control.dart';
import '../models/insurance.dart';
import '../models/expense.dart';
import '../models/document.dart';
import '../models/maintenance_part.dart';

class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  Future<List<Vehicle>> getVehicles() async {
    final res = await _db.from('vehicles').select().order('created_at');
    return (res as List).map((j) => Vehicle.fromJson(j)).toList();
  }

  Future<Vehicle> createVehicle(Vehicle v) async {
    final res = await _db.from('vehicles').insert(v.toJson()).select().single();
    return Vehicle.fromJson(res);
  }

  Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    await _db.from('vehicles').update(data).eq('id', id);
  }

  Future<void> deleteVehicle(String id) async {
    await _db.from('vehicles').delete().eq('id', id);
  }

  Future<List<FuelEntry>> getFuelEntries(String vehicleId) async {
    final res = await _db
        .from('fuel_entries')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);
    return (res as List).map((j) => FuelEntry.fromJson(j)).toList();
  }

  Future<FuelEntry> createFuelEntry(FuelEntry e) async {
    final res = await _db.from('fuel_entries').insert(e.toJson()).select().single();
    await _db.from('vehicles').update({'current_km': e.km}).eq('id', e.vehicleId);
    return FuelEntry.fromJson(res);
  }

  Future<List<MaintenanceEntry>> getMaintenanceEntries(String vehicleId) async {
    final res = await _db
        .from('maintenance_entries')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);
    return (res as List).map((j) => MaintenanceEntry.fromJson(j)).toList();
  }

  Future<MaintenanceEntry> createMaintenanceEntry(MaintenanceEntry e) async {
    final res = await _db.from('maintenance_entries').insert(e.toJson()).select().single();
    await _db.from('vehicles').update({'current_km': e.km}).eq('id', e.vehicleId);
    return MaintenanceEntry.fromJson(res);
  }

  Future<List<TechnicalControl>> getTechnicalControls(String vehicleId) async {
    final res = await _db
        .from('technical_controls')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);
    return (res as List).map((j) => TechnicalControl.fromJson(j)).toList();
  }

  Future<TechnicalControl> createTechnicalControl(TechnicalControl e) async {
    final res = await _db.from('technical_controls').insert(e.toJson()).select().single();
    return TechnicalControl.fromJson(res);
  }

  Future<List<Insurance>> getInsurances(String vehicleId) async {
    final res = await _db
        .from('insurance')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('end_date', ascending: false);
    return (res as List).map((j) => Insurance.fromJson(j)).toList();
  }

  Future<Insurance> createInsurance(Insurance e) async {
    final res = await _db.from('insurance').insert(e.toJson()).select().single();
    return Insurance.fromJson(res);
  }

  Future<List<Expense>> getExpenses(String vehicleId) async {
    final res = await _db
        .from('expenses')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('date', ascending: false);
    return (res as List).map((j) => Expense.fromJson(j)).toList();
  }

  Future<Expense> createExpense(Expense e) async {
    final res = await _db.from('expenses').insert(e.toJson()).select().single();
    return Expense.fromJson(res);
  }

  Future<Map<String, dynamic>> getVehicleStats(String vehicleId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

    final fuelMonth = await _db
        .from('fuel_entries').select('total_cost, liters, km')
        .eq('vehicle_id', vehicleId).gte('date', monthStart);
    final maintMonth = await _db
        .from('maintenance_entries').select('cost')
        .eq('vehicle_id', vehicleId).gte('date', monthStart);
    final expMonth = await _db
        .from('expenses').select('amount')
        .eq('vehicle_id', vehicleId).gte('date', monthStart);

    final fuelTotal = (fuelMonth as List).fold<double>(0, (s, e) => s + (e['total_cost'] as num));
    final fuelLiters = (fuelMonth).fold<double>(0, (s, e) => s + (e['liters'] as num));
    final maintTotal = (maintMonth as List).fold<double>(0, (s, e) => s + (e['cost'] as num));
    final expTotal = (expMonth as List).fold<double>(0, (s, e) => s + (e['amount'] as num));

    return {
      'fuel_cost_month': fuelTotal,
      'fuel_liters_month': fuelLiters,
      'maintenance_cost_month': maintTotal,
      'expenses_cost_month': expTotal,
      'total_cost_month': fuelTotal + maintTotal + expTotal,
    };
  }

  Future<List<Map<String, dynamic>>> getMileageHistory(String vehicleId) async {
    final res = await _db
        .from('fuel_entries').select('date, km')
        .eq('vehicle_id', vehicleId).order('date');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAlerts(String vehicleId) async {
    final alerts = <Map<String, dynamic>>[];
    final now = DateTime.now();

    final maint = await getMaintenanceEntries(vehicleId);
    for (final m in maint) {
      if (m.nextDate != null && m.nextDate!.isAfter(now)) {
        final days = m.nextDate!.difference(now).inDays;
        if (days <= 30) {
          alerts.add({'type': 'maintenance', 'title': 'Entretien: ${m.type}', 'days': days, 'date': m.nextDate, 'urgent': days <= 7, 'vehicleId': vehicleId});
        }
      }
    }
    final controls = await getTechnicalControls(vehicleId);
    for (final c in controls) {
      if (c.nextDate != null && c.nextDate!.isAfter(now)) {
        final days = c.nextDate!.difference(now).inDays;
        if (days <= 60) {
          alerts.add({'type': 'control', 'title': 'Controle Technique', 'days': days, 'date': c.nextDate, 'urgent': days <= 14, 'vehicleId': vehicleId});
        }
      }
    }
    final insurances = await getInsurances(vehicleId);
    for (final i in insurances) {
      if (i.isActive) {
        final days = i.daysUntilExpiry;
        if (days <= 30) {
          alerts.add({'type': 'insurance', 'title': 'Assurance: ${i.company}', 'days': days, 'date': i.endDate, 'urgent': days <= 7, 'vehicleId': vehicleId});
        }
      }
    }
    alerts.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
    return alerts;
  }

  Future<List<MaintenancePart>> getParts(String maintenanceId) async {
    try {
      final res = await _db.from('maintenance_parts').select()
          .eq('maintenance_id', maintenanceId);
      return (res as List).map((j) => MaintenancePart.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Document>> getDocuments(String entryType, String entryId) async {
    try {
      final res = await _db.from('documents').select()
          .eq('entry_type', entryType).eq('entry_id', entryId).order('created_at');
      return (res as List).map((j) => Document.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllAlerts(List<Vehicle> vehicles) async {
    final all = <Map<String, dynamic>>[];
    for (final v in vehicles) {
      final alerts = await getAlerts(v.id);
      for (final a in alerts) {
        all.add({...a, 'vehicleName': v.name});
      }
    }
    all.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
    return all;
  }
}
