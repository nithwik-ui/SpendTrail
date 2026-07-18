class ExpenseCategory {
  final int? id;
  final String name;
  final int iconCodePoint; 
  final int colorValue;

  const ExpenseCategory({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
    );
  }
}
