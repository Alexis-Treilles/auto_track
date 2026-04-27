class FuelEntry {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int km;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final String? station;
  final bool fullTank;
  final DateTime createdAt;

  FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.km,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    this.station,
    required this.fullTank,
    required this.createdAt,
  });

  factory FuelEntry.fromJson(Map<String, dynamic> j) => FuelEntry(
        id: j['id'],
        vehicleId: j['vehicle_id'],
        date: DateTime.parse(j['date']),
        km: j['km'],
        liters: (j['liters'] as num).toDouble(),
        pricePerLiter: (j['price_per_liter'] as num).toDouble(),
        totalCost: (j['total_cost'] as num).toDouble(),
        station: j['station'],
        fullTank: j['full_tank'] ?? true,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'date': date.toIso8601String().split('T')[0],
        'km': km,
        'liters': liters,
        'price_per_liter': pricePerLiter,
        'total_cost': totalCost,
        'station': station,
        'full_tank': fullTank,
      };

  double get consumption100km => liters / km * 100;
}
