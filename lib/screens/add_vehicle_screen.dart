import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../models/vehicle.dart';
import '../providers/app_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: '2020');
  final _plate = TextEditingController();
  final _color = TextEditingController();
  final _initialKm = TextEditingController(text: '0');
  String _fuelType = 'Essence';
  bool _loading = false;
  Uint8List? _imageBytes;
  String? _imageName;

  static const _fuelTypes = ['Essence', 'Diesel', 'Électrique', 'Hybride', 'GPL'];

  @override
  void dispose() {
    _name.dispose(); _brand.dispose(); _model.dispose();
    _year.dispose(); _plate.dispose(); _color.dispose(); _initialKm.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 900,
      imageQuality: 80,
    );
    if (result == null) return;
    final bytes = await result.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = result.name;
    });
  }

  Future<String?> _uploadPhoto(String vehicleId) async {
    if (_imageBytes == null) return null;
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final ext = _imageName?.split('.').last ?? 'jpg';
    final path = '$userId/$vehicleId.$ext';
    try {
      await Supabase.instance.client.storage
          .from('vehicle-photos')
          .uploadBinary(path, _imageBytes!, fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'));
      final url = Supabase.instance.client.storage
          .from('vehicle-photos')
          .getPublicUrl(path);
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final vehicleId = const Uuid().v4();
      final photoUrl = await _uploadPhoto(vehicleId);
      final km = int.tryParse(_initialKm.text) ?? 0;
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final vehicle = Vehicle(
        id: vehicleId,
        userId: userId,
        name: _name.text.trim(),
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text) ?? 2020,
        plate: _plate.text.trim().toUpperCase(),
        color: _color.text.trim(),
        photoUrl: photoUrl,
        initialKm: km,
        currentKm: km,
        fuelType: _fuelType,
        createdAt: DateTime.now(),
      );
      await context.read<AppProvider>().addVehicle(vehicle);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.danger));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau véhicule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Photo picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imageBytes != null ? AppTheme.primary : Colors.white12,
                    width: _imageBytes != null ? 2 : 1,
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 48, color: Colors.white24),
                        const SizedBox(height: 8),
                        const Text('Ajouter une photo', style: TextStyle(color: Colors.white38)),
                        const Text('Optionnel', style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ]),
              ),
            ),
            if (_imageBytes != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() { _imageBytes = null; _imageName = null; }),
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 16),
                label: const Text('Supprimer la photo', style: TextStyle(color: AppTheme.danger, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 20),
            _field(_name, 'Nom du véhicule', Icons.label_rounded, required: true),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field(_brand, 'Marque', Icons.business_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _field(_model, 'Modèle', Icons.directions_car_rounded)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field(_year, 'Année', Icons.calendar_today_rounded, numeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_plate, 'Immatriculation', Icons.pin_rounded)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field(_color, 'Couleur', Icons.palette_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _field(_initialKm, 'Kilométrage', Icons.speed_rounded, numeric: true)),
            ]),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _fuelType,
              dropdownColor: AppTheme.card,
              decoration: const InputDecoration(labelText: 'Carburant', prefixIcon: Icon(Icons.local_gas_station_rounded)),
              items: _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) => setState(() => _fuelType = v!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Enregistrer le véhicule'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, bool numeric = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: required ? (v) => (v?.isEmpty ?? true) ? 'Requis' : null : null,
    );
  }
}
