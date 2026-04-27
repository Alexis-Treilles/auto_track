class Expense {
  final String id;
  final String vehicleId;
  final DateTime date;
  final String type;
  final String? description;
  final double amount;
  final String? invoiceUrl;
  final DateTime createdAt;

  static const List<String> types = [
    'Parking', 'Péage', 'Amende', 'Accessoires', 'Lavage',
    'Vignette', 'Carte grise', 'Autre',
  ];

  Expense({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.type,
    this.description,
    required this.amount,
    this.invoiceUrl,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'],
        vehicleId: j['vehicle_id'],
        date: DateTime.parse(j['date']),
        type: j['type'],
        description: j['description'],
        amount: (j['amount'] as num).toDouble(),
        invoiceUrl: j['invoice_url'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'date': date.toIso8601String().split('T')[0],
        'type': type,
        'description': description,
        'amount': amount,
        'invoice_url': invoiceUrl,
      };
}
