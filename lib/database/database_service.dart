import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spendtrail.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  iconCodePoint $integerType,
  colorValue $integerType
)
''');

    await db.execute('''
CREATE TABLE expenses (
  id $idType,
  amount $realType,
  categoryId $integerType,
  date $textType,
  note $textType,
  FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
)
''');

    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_categoryId ON expenses(categoryId)');
    await db.execute('CREATE INDEX idx_expenses_amount ON expenses(amount)');

    await _seedCategories(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_categoryId ON expenses(categoryId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_amount ON expenses(amount)');
      await _seedCategories(db);
    }
  }

  Future _seedCategories(Database db) async {
    final allCategories = [
      ExpenseCategory(name: 'Food', iconCodePoint: Icons.restaurant.codePoint, colorValue: 0xFFD84315),
      ExpenseCategory(name: 'Groceries', iconCodePoint: Icons.local_grocery_store.codePoint, colorValue: 0xFF2E7D32),
      ExpenseCategory(name: 'Transport', iconCodePoint: Icons.directions_bus.codePoint, colorValue: 0xFF0277BD),
      ExpenseCategory(name: 'Fuel', iconCodePoint: Icons.local_gas_station.codePoint, colorValue: 0xFF455A64),
      ExpenseCategory(name: 'Shopping', iconCodePoint: Icons.shopping_bag.codePoint, colorValue: 0xFFAD1457),
      ExpenseCategory(name: 'Bills', iconCodePoint: Icons.receipt.codePoint, colorValue: 0xFFE64A19),
      ExpenseCategory(name: 'Rent', iconCodePoint: Icons.house.codePoint, colorValue: 0xFF00695C),
      ExpenseCategory(name: 'Entertainment', iconCodePoint: Icons.movie.codePoint, colorValue: 0xFF6A1B9A),
      ExpenseCategory(name: 'Health', iconCodePoint: Icons.medical_services.codePoint, colorValue: 0xFFC62828),
      ExpenseCategory(name: 'Education', iconCodePoint: Icons.school.codePoint, colorValue: 0xFF1565C0),
      ExpenseCategory(name: 'Travel', iconCodePoint: Icons.flight.codePoint, colorValue: 0xFF00838F),
      ExpenseCategory(name: 'Salary', iconCodePoint: Icons.attach_money.codePoint, colorValue: 0xFF283593),
      ExpenseCategory(name: 'Investment', iconCodePoint: Icons.trending_up.codePoint, colorValue: 0xFF37474F),
      ExpenseCategory(name: 'Gift', iconCodePoint: Icons.card_giftcard.codePoint, colorValue: 0xFFD81B60),
      ExpenseCategory(name: 'Other', iconCodePoint: Icons.category.codePoint, colorValue: 0xFF616161),
    ];

    final existingMaps = await db.query('categories');
    final existingNames = existingMaps.map((m) => m['name'] as String).toSet();

    for (var category in allCategories) {
      if (!existingNames.contains(category.name)) {
        await db.insert('categories', category.toMap());
      }
    }
  }

  Future<ExpenseCategory> createCategory(ExpenseCategory category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap());
    return ExpenseCategory(
      id: id,
      name: category.name,
      iconCodePoint: category.iconCodePoint,
      colorValue: category.colorValue,
    );
  }

  Future<List<ExpenseCategory>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((json) => ExpenseCategory.fromMap(json)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert('expenses', expense.toMap());
    return Expense(
      id: id,
      amount: expense.amount,
      categoryId: expense.categoryId,
      date: expense.date,
      note: expense.note,
    );
  }

  Future<List<Expense>> readAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }
  
  Future<List<Expense>> searchExpenses(String query) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT e.* FROM expenses e
      INNER JOIN categories c ON e.categoryId = c.id
      WHERE e.note LIKE ? OR c.name LIKE ? OR e.amount LIKE ?
      ORDER BY e.date DESC
    ''', ['%$query%', '%$query%', '%$query%']);
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
