class Insurance {
  final String id;
  final String vehicleId;
  final String company;
  final String? contractNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double? monthlyCost;
  final double? annualCost;
  final String coverageType;
  final String? documentUrl;
  final DateTime createdAt;

  static const List<String> coverageTypes = [
    'Tiers simple', 'Tiers étendu', 'Tous risques',
  ];

  Insurance({
    required this.id,
    required this.vehicleId,
    required this.company,
    this.contractNumber,
    required this.startDate,
    required this.endDate,
    this.monthlyCost,
    this.annualCost,
    required this.coverageType,
    this.documentUrl,
    required this.createdAt,
  });

  factory Insurance.fromJson(Map<String, dynamic> j) => Insurance(
        id: j['id'],
        vehicleId: j['vehicle_id'],
        company: j['company'],
        contractNumber: j['contract_number'],
        startDate: DateTime.parse(j['start_date']),
        endDate: DateTime.parse(j['end_date']),
        monthlyCost: j['monthly_cost'] != null ? (j['monthly_cost'] as num).toDouble() : null,
        annualCost: j['annual_cost'] != null ? (j['annual_cost'] as num).toDouble() : null,
        coverageType: j['coverage_type'] ?? 'Tiers simple',
        documentUrl: j['document_url'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'company': company,
        'contract_number': contractNumber,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'monthly_cost': monthlyCost,
        'annual_cost': annualCost,
        'coverage_type': coverageType,
        'document_url': documentUrl,
      };

  bool get isActive => DateTime.now().isBefore(endDate);
  bool get isExpiringSoon => endDate.difference(DateTime.now()).inDays <= 30;
  int get daysUntilExpiry => endDate.difference(DateTime.now()).inDays;
}
