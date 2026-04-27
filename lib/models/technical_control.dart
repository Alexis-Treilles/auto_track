class TechnicalControl {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int? km;
  final String result;
  final String? center;
  final double cost;
  final String? documentUrl;
  final DateTime? nextDate;
  final DateTime createdAt;

  static const List<String> results = ['Favorable', 'Défavorable mineur', 'Défavorable majeur'];

  TechnicalControl({
    required this.id,
    required this.vehicleId,
    required this.date,
    this.km,
    required this.result,
    this.center,
    required this.cost,
    this.documentUrl,
    this.nextDate,
    required this.createdAt,
  });

  factory TechnicalControl.fromJson(Map<String, dynamic> j) => TechnicalControl(
        id: j['id'],
        vehicleId: j['vehicle_id'],
        date: DateTime.parse(j['date']),
        km: j['km'],
        result: j['result'] ?? 'Favorable',
        center: j['center'],
        cost: (j['cost'] as num).toDouble(),
        documentUrl: j['document_url'],
        nextDate: j['next_date'] != null ? DateTime.parse(j['next_date']) : null,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'date': date.toIso8601String().split('T')[0],
        'km': km,
        'result': result,
        'center': center,
        'cost': cost,
        'document_url': documentUrl,
        'next_date': nextDate?.toIso8601String().split('T')[0],
      };

  bool get isFavorable => result == 'Favorable';
  bool get isExpiringSoon =>
      nextDate != null && nextDate!.difference(DateTime.now()).inDays <= 60;
}
