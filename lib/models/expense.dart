class Expense {
  final int? id;
  final double amount;
  final int categoryId;
  final DateTime date;
  final String note;

  const Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      categoryId: map['categoryId'] as int,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String? ?? '',
    );
  }
}
