class CustomerPoItemRow {
  final String description;
  final double quantity;
  final String unit;
  final double rate;

  const CustomerPoItemRow({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
  });

  double get amount => quantity * rate;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
    };
  }
}
