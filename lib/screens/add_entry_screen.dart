import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';
import '../models/technical_control.dart';
import '../models/insurance.dart';
import '../models/expense.dart';
import '../providers/app_provider.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  int _tab = 0;

  static const _tabs = [
    (Icons.local_gas_station_rounded, 'Plein'),
    (Icons.build_rounded, 'Entretien'),
    (Icons.assignment_turned_in_rounded, 'CT'),
    (Icons.security_rounded, 'Assurance'),
    (Icons.receipt_rounded, 'Dépense'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tabs.length,
            itemBuilder: (_, i) {
              final (icon, label) = _tabs[i];
              final selected = _tab == i;
              return GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, color: selected ? Colors.black : Colors.white54, size: 22),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(
                        color: selected ? Colors.black : Colors.white54,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: [
            const _FuelForm(),
            const _MaintenanceForm(),
            const _TechnicalControlForm(),
            const _InsuranceForm(),
            const _ExpenseForm(),
          ][_tab],
        ),
      ]),
    );
  }
}

// ─── FUEL ────────────────────────────────────────────────────────────────────

class _FuelForm extends StatefulWidget {
  const _FuelForm();
  @override
  State<_FuelForm> createState() => _FuelFormState();
}

class _FuelFormState extends State<_FuelForm> {
  final _formKey = GlobalKey<FormState>();
  final _km = TextEditingController();
  final _liters = TextEditingController();
  final _price = TextEditingController();
  final _station = TextEditingController();
  DateTime _date = DateTime.now();
  bool _fullTank = true;
  bool _loading = false;

  double get _total => (double.tryParse(_liters.text) ?? 0) * (double.tryParse(_price.text) ?? 0);

  @override
  void dispose() { _km.dispose(); _liters.dispose(); _price.dispose(); _station.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    try {
      final liters = double.parse(_liters.text);
      final ppl = double.parse(_price.text);
      await p.addFuelEntry(FuelEntry(
        id: const Uuid().v4(), vehicleId: p.selectedVehicle!.id, date: _date,
        km: int.parse(_km.text), liters: liters, pricePerLiter: ppl,
        totalCost: liters * ppl, station: _station.text.isEmpty ? null : _station.text,
        fullTank: _fullTank, createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.danger));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _formKey, child: Column(children: [
      _DatePick(date: _date, onChanged: (d) => setState(() => _date = d)),
      const SizedBox(height: 14),
      _Num(_km, 'Kilométrage actuel', Icons.speed_rounded, required: true),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Num(_liters, 'Litres', Icons.opacity_rounded, required: true, onChange: (_) => setState(() {}))),
        const SizedBox(width: 12),
        Expanded(child: _Num(_price, 'Prix/litre', Icons.euro_rounded, required: true, onChange: (_) => setState(() {}))),
      ]),
      const SizedBox(height: 14),
      _Txt(_station, 'Station', Icons.local_gas_station_rounded),
      const SizedBox(height: 14),
      Row(children: [
        Checkbox(value: _fullTank, onChanged: (v) => setState(() => _fullTank = v!), activeColor: AppTheme.primary),
        const Text('Plein complet', style: TextStyle(color: Colors.white70)),
      ]),
      if (_total > 0) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(color: Colors.white70)),
            Text('${_total.toStringAsFixed(2)} €', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ),
      ],
      const SizedBox(height: 24),
      _Submit(onPressed: _save, loading: _loading, label: 'Enregistrer le plein'),
    ])),
  );
}

// ─── MAINTENANCE ─────────────────────────────────────────────────────────────

class _MaintenanceForm extends StatefulWidget {
  const _MaintenanceForm();
  @override
  State<_MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<_MaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _km = TextEditingController();
  final _cost = TextEditingController();
  final _garage = TextEditingController();
  final _desc = TextEditingController();
  final _nextKm = TextEditingController();
  String _type = MaintenanceEntry.types.first;
  DateTime _date = DateTime.now();
  DateTime? _nextDate;
  bool _loading = false;

  @override
  void dispose() { _km.dispose(); _cost.dispose(); _garage.dispose(); _desc.dispose(); _nextKm.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    try {
      await p.addMaintenanceEntry(MaintenanceEntry(
        id: const Uuid().v4(), vehicleId: p.selectedVehicle!.id, date: _date,
        km: int.parse(_km.text), type: _type, description: _desc.text,
        cost: double.tryParse(_cost.text) ?? 0, garage: _garage.text.isEmpty ? null : _garage.text,
        nextKm: int.tryParse(_nextKm.text), nextDate: _nextDate, createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.danger));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _formKey, child: Column(children: [
      _DatePick(date: _date, onChanged: (d) => setState(() => _date = d)),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _type, dropdownColor: AppTheme.card,
        decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.build_rounded)),
        items: MaintenanceEntry.types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setState(() => _type = v!),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Num(_km, 'Kilométrage', Icons.speed_rounded, required: true)),
        const SizedBox(width: 12),
        Expanded(child: _Num(_cost, 'Coût (€)', Icons.euro_rounded)),
      ]),
      const SizedBox(height: 14),
      _Txt(_garage, 'Garage', Icons.home_repair_service_rounded),
      const SizedBox(height: 14),
      _Txt(_desc, 'Description', Icons.notes_rounded, lines: 2),
      const Divider(color: Colors.white12, height: 28),
      const Text('Prochain entretien', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _Num(_nextKm, 'Prochain km', Icons.speed_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _DatePick(date: _nextDate, onChanged: (d) => setState(() => _nextDate = d), label: 'Prochaine date', nullable: true)),
      ]),
      const SizedBox(height: 24),
      _Submit(onPressed: _save, loading: _loading, label: 'Enregistrer'),
    ])),
  );
}

// ─── TECHNICAL CONTROL ───────────────────────────────────────────────────────

class _TechnicalControlForm extends StatefulWidget {
  const _TechnicalControlForm();
  @override
  State<_TechnicalControlForm> createState() => _TechnicalControlFormState();
}

class _TechnicalControlFormState extends State<_TechnicalControlForm> {
  final _formKey = GlobalKey<FormState>();
  final _km = TextEditingController();
  final _cost = TextEditingController();
  final _center = TextEditingController();
  String _result = TechnicalControl.results.first;
  DateTime _date = DateTime.now();
  DateTime? _nextDate;
  bool _loading = false;

  @override
  void dispose() { _km.dispose(); _cost.dispose(); _center.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    try {
      await p.addTechnicalControl(TechnicalControl(
        id: const Uuid().v4(), vehicleId: p.selectedVehicle!.id, date: _date,
        km: int.tryParse(_km.text), result: _result,
        center: _center.text.isEmpty ? null : _center.text,
        cost: double.tryParse(_cost.text) ?? 0, nextDate: _nextDate, createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.danger));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _formKey, child: Column(children: [
      _DatePick(date: _date, onChanged: (d) => setState(() => _date = d)),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _result, dropdownColor: AppTheme.card,
        decoration: const InputDecoration(labelText: 'Résultat', prefixIcon: Icon(Icons.check_circle_rounded)),
        items: TechnicalControl.results.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
        onChanged: (v) => setState(() => _result = v!),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Num(_km, 'Kilométrage', Icons.speed_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _Num(_cost, 'Coût (€)', Icons.euro_rounded)),
      ]),
      const SizedBox(height: 14),
      _Txt(_center, 'Centre de contrôle', Icons.business_rounded),
      const SizedBox(height: 14),
      _DatePick(date: _nextDate, onChanged: (d) => setState(() => _nextDate = d), label: 'Prochain contrôle', nullable: true),
      const SizedBox(height: 24),
      _Submit(onPressed: _save, loading: _loading, label: 'Enregistrer'),
    ])),
  );
}

// ─── INSURANCE ───────────────────────────────────────────────────────────────

class _InsuranceForm extends StatefulWidget {
  const _InsuranceForm();
  @override
  State<_InsuranceForm> createState() => _InsuranceFormState();
}

class _InsuranceFormState extends State<_InsuranceForm> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contract = TextEditingController();
  final _monthly = TextEditingController();
  final _annual = TextEditingController();
  String _coverage = Insurance.coverageTypes.first;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  bool _loading = false;

  @override
  void dispose() { _company.dispose(); _contract.dispose(); _monthly.dispose(); _annual.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    try {
      await p.addInsurance(Insurance(
        id: const Uuid().v4(), vehicleId: p.selectedVehicle!.id,
        company: _company.text.trim(), contractNumber: _contract.text.isEmpty ? null : _contract.text,
        startDate: _startDate, endDate: _endDate,
        monthlyCost: double.tryParse(_monthly.text), annualCost: double.tryParse(_annual.text),
        coverageType: _coverage, createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.danger));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _formKey, child: Column(children: [
      _Txt(_company, "Compagnie d'assurance", Icons.business_rounded, required: true),
      const SizedBox(height: 14),
      _Txt(_contract, 'N° contrat', Icons.pin_rounded),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _coverage, dropdownColor: AppTheme.card,
        decoration: const InputDecoration(labelText: 'Type de couverture', prefixIcon: Icon(Icons.shield_rounded)),
        items: Insurance.coverageTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _coverage = v!),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Num(_monthly, 'Mensualité (€)', Icons.calendar_view_month_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _Num(_annual, 'Annuel (€)', Icons.calendar_today_rounded)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _DatePick(date: _startDate, onChanged: (d) => setState(() => _startDate = d), label: 'Début')),
        const SizedBox(width: 12),
        Expanded(child: _DatePick(date: _endDate, onChanged: (d) => setState(() => _endDate = d), label: 'Fin')),
      ]),
      const SizedBox(height: 24),
      _Submit(onPressed: _save, loading: _loading, label: 'Enregistrer'),
    ])),
  );
}

// ─── EXPENSE ─────────────────────────────────────────────────────────────────

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm();
  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  String _type = Expense.types.first;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() { _amount.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final p = context.read<AppProvider>();
    try {
      await p.addExpense(Expense(
        id: const Uuid().v4(), vehicleId: p.selectedVehicle!.id, date: _date,
        type: _type, description: _desc.text.isEmpty ? null : _desc.text,
        amount: double.parse(_amount.text), createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.danger));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(key: _formKey, child: Column(children: [
      _DatePick(date: _date, onChanged: (d) => setState(() => _date = d)),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _type, dropdownColor: AppTheme.card,
        decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.receipt_rounded)),
        items: Expense.types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: (v) => setState(() => _type = v!),
      ),
      const SizedBox(height: 14),
      _Num(_amount, 'Montant (€)', Icons.euro_rounded, required: true),
      const SizedBox(height: 14),
      _Txt(_desc, 'Description', Icons.notes_rounded, lines: 2),
      const SizedBox(height: 24),
      _Submit(onPressed: _save, loading: _loading, label: 'Enregistrer'),
    ])),
  );
}

// ─── SHARED WIDGETS ──────────────────────────────────────────────────────────

class _DatePick extends StatelessWidget {
  final DateTime? date;
  final void Function(DateTime) onChanged;
  final String label;
  final bool nullable;

  const _DatePick({required this.date, required this.onChanged, this.label = 'Date', this.nullable = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date ?? DateTime.now(),
        firstDate: DateTime(2000), lastDate: DateTime(2100),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primary)),
          child: child!,
        ),
      );
      if (picked != null) onChanged(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(
            date != null ? DateFormat('dd/MM/yyyy').format(date!) : 'Non défini',
            style: TextStyle(color: date != null ? Colors.white : Colors.white38, fontWeight: FontWeight.w500),
          ),
        ])),
      ]),
    ),
  );
}

class _Num extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool required;
  final void Function(String)? onChange;

  const _Num(this.ctrl, this.label, this.icon, {this.required = false, this.onChange});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: const TextStyle(color: Colors.white),
    onChanged: onChange,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: required ? (v) => (v?.isEmpty ?? true) ? 'Requis' : null : null,
  );
}

class _Txt extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool required;
  final int lines;

  const _Txt(this.ctrl, this.label, this.icon, {this.required = false, this.lines = 1});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, maxLines: lines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    validator: required ? (v) => (v?.isEmpty ?? true) ? 'Requis' : null : null,
  );
}

class _Submit extends StatelessWidget {
  final VoidCallback onPressed;
  final bool loading;
  final String label;

  const _Submit({required this.onPressed, required this.loading, required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
          : Text(label),
    ),
  );
}
