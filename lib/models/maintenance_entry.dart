class MaintenanceEntry {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int km;
  final String type;
  final String description;
  final double cost;
  final String? garage;
  final String? invoiceUrl;
  final int? nextKm;
  final DateTime? nextDate;
  final DateTime createdAt;

  static const List<String> types = [
    'Vidange', 'Freins', 'Pneus', 'Filtres', 'Distribution',
    'Batterie', 'Amortisseurs', 'Climatisation', 'Révision complète', 'Autre',
  ];

  MaintenanceEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.km,
    required this.type,
    required this.description,
    required this.cost,
    this.garage,
    this.invoiceUrl,
    this.nextKm,
    this.nextDate,
    required this.createdAt,
  });

  factory MaintenanceEntry.fromJson(Map<String, dynamic> j) => MaintenanceEntry(
        id: j['id'],
        vehicleId: j['vehicle_id'],
        date: DateTime.parse(j['date']),
        km: j['km'],
        type: j['type'],
        description: j['description'] ?? '',
        cost: (j['cost'] as num).toDouble(),
        garage: j['garage'],
        invoiceUrl: j['invoice_url'],
        nextKm: j['next_km'],
        nextDate: j['next_date'] != null ? DateTime.parse(j['next_date']) : null,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'date': date.toIso8601String().split('T')[0],
        'km': km,
        'type': type,
        'description': description,
        'cost': cost,
        'garage': garage,
        'invoice_url': invoiceUrl,
        'next_km': nextKm,
        'next_date': nextDate?.toIso8601String().split('T')[0],
      };

  bool get hasUpcomingAlert {
    if (nextDate == null) return false;
    return nextDate!.difference(DateTime.now()).inDays <= 30;
  }
}
