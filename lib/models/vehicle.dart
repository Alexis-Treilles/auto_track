class Vehicle {
  final String id;
  final String userId;
  final String name;
  final String brand;
  final String model;
  final int year;
  final String plate;
  final String color;
  final String? photoUrl;
  final int initialKm;
  final int currentKm;
  final String fuelType;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    this.photoUrl,
    required this.initialKm,
    required this.currentKm,
    required this.fuelType,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'],
        userId: j['user_id'] ?? '',
        name: j['name'],
        brand: j['brand'] ?? '',
        model: j['model'] ?? '',
        year: j['year'] ?? 0,
        plate: j['plate'] ?? '',
        color: j['color'] ?? '',
        photoUrl: j['photo_url'],
        initialKm: j['initial_km'] ?? 0,
        currentKm: j['current_km'] ?? 0,
        fuelType: j['fuel_type'] ?? 'Essence',
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'brand': brand,
        'model': model,
        'year': year,
        'plate': plate,
        'color': color,
        'photo_url': photoUrl,
        'initial_km': initialKm,
        'current_km': currentKm,
        'fuel_type': fuelType,
      };

  Vehicle copyWith({int? currentKm, String? photoUrl}) => Vehicle(
        id: id,
        userId: userId,
        name: name,
        brand: brand,
        model: model,
        year: year,
        plate: plate,
        color: color,
        photoUrl: photoUrl ?? this.photoUrl,
        initialKm: initialKm,
        currentKm: currentKm ?? this.currentKm,
        fuelType: fuelType,
        createdAt: createdAt,
      );
}
