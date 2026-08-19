class Expense {
  final int? id;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
  });

  // Map to DB structure
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
    };
  }

  // Map from DB structure
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }

  // copyWith helper
  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}
