import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';
import '../models/technical_control.dart';
import '../models/insurance.dart';
import '../models/expense.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  final _svc = SupabaseService();

  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  List<FuelEntry> _fuelEntries = [];
  List<MaintenanceEntry> _maintenanceEntries = [];
  List<TechnicalControl> _technicalControls = [];
  List<Insurance> _insurances = [];
  List<Expense> _expenses = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _allAlerts = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  String? _error;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;
  List<FuelEntry> get fuelEntries => _fuelEntries;
  List<MaintenanceEntry> get maintenanceEntries => _maintenanceEntries;
  List<TechnicalControl> get technicalControls => _technicalControls;
  List<Insurance> get insurances => _insurances;
  List<Expense> get expenses => _expenses;
  List<Map<String, dynamic>> get alerts => _alerts;
  List<Map<String, dynamic>> get allAlerts => _allAlerts;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  SupabaseService get svc => _svc;
  int get notificationCount => _allAlerts.where((a) => a['urgent'] == true).length;

  Future<void> loadVehicles() async {
    _loading = true;
    notifyListeners();
    try {
      _vehicles = await _svc.getVehicles();
      if (_vehicles.isNotEmpty) {
        if (_selectedVehicle == null) _selectedVehicle = _vehicles.first;
        await Future.wait([loadVehicleData(), _loadAllAlerts()]);
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void selectVehicle(Vehicle v) {
    _selectedVehicle = v;
    notifyListeners();
    loadVehicleData();
  }

  Future<void> loadVehicleData() async {
    if (_selectedVehicle == null) return;
    final id = _selectedVehicle!.id;
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _svc.getFuelEntries(id),
        _svc.getMaintenanceEntries(id),
        _svc.getTechnicalControls(id),
        _svc.getInsurances(id),
        _svc.getExpenses(id),
        _svc.getAlerts(id),
        _svc.getVehicleStats(id),
      ]);
      _fuelEntries = results[0] as List<FuelEntry>;
      _maintenanceEntries = results[1] as List<MaintenanceEntry>;
      _technicalControls = results[2] as List<TechnicalControl>;
      _insurances = results[3] as List<Insurance>;
      _expenses = results[4] as List<Expense>;
      _alerts = results[5] as List<Map<String, dynamic>>;
      _stats = results[6] as Map<String, dynamic>;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void clear() {
    _vehicles = [];
    _selectedVehicle = null;
    _fuelEntries = [];
    _maintenanceEntries = [];
    _technicalControls = [];
    _insurances = [];
    _expenses = [];
    _alerts = [];
    _stats = {};
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle v) async {
    final created = await _svc.createVehicle(v);
    _vehicles.add(created);
    if (_vehicles.length == 1) {
      _selectedVehicle = created;
      await loadVehicleData();
    }
    notifyListeners();
  }

  Future<void> updateVehicle(Vehicle v) async {
    await _svc.updateVehicle(v.id, v.toJson());
    final idx = _vehicles.indexWhere((x) => x.id == v.id);
    if (idx != -1) _vehicles[idx] = v;
    if (_selectedVehicle?.id == v.id) _selectedVehicle = v;
    notifyListeners();
  }

  Future<void> deleteVehicle(String id) async {
    await _svc.deleteVehicle(id);
    _vehicles.removeWhere((v) => v.id == id);
    if (_selectedVehicle?.id == id) {
      _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
      if (_selectedVehicle != null) await loadVehicleData();
    }
    notifyListeners();
  }

  Future<void> addFuelEntry(FuelEntry e) async {
    final created = await _svc.createFuelEntry(e);
    _fuelEntries.insert(0, created);
    final idx = _vehicles.indexWhere((v) => v.id == e.vehicleId);
    if (idx != -1) _vehicles[idx] = _vehicles[idx].copyWith(currentKm: e.km);
    if (_selectedVehicle?.id == e.vehicleId) {
      _selectedVehicle = _selectedVehicle!.copyWith(currentKm: e.km);
    }
    await _refreshStats();
    notifyListeners();
  }

  Future<void> addMaintenanceEntry(MaintenanceEntry e) async {
    final created = await _svc.createMaintenanceEntry(e);
    _maintenanceEntries.insert(0, created);
    await _refreshStats();
    notifyListeners();
  }

  Future<void> addTechnicalControl(TechnicalControl e) async {
    final created = await _svc.createTechnicalControl(e);
    _technicalControls.insert(0, created);
    notifyListeners();
  }

  Future<void> addInsurance(Insurance e) async {
    final created = await _svc.createInsurance(e);
    _insurances.insert(0, created);
    notifyListeners();
  }

  Future<void> addExpense(Expense e) async {
    final created = await _svc.createExpense(e);
    _expenses.insert(0, created);
    await _refreshStats();
    notifyListeners();
  }

  Future<void> _loadAllAlerts() async {
    if (_vehicles.isEmpty) return;
    try {
      _allAlerts = await _svc.getAllAlerts(_vehicles);
    } catch (_) {
      _allAlerts = [];
    }
    notifyListeners();
  }

  Future<void> _refreshStats() async {
    if (_selectedVehicle == null) return;
    _stats = await _svc.getVehicleStats(_selectedVehicle!.id);
    _alerts = await _svc.getAlerts(_selectedVehicle!.id);
    await _loadAllAlerts();
  }
}
