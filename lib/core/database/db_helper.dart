import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static const String _dbName = 'spendtrail.db';
  static const int _dbVersion = 1;

  static const String tableExpenses = 'expenses';
  static const String colId = 'id';
  static const String colAmount = 'amount';
  static const String colCategory = 'category';
  static const String colNote = 'note';
  static const String colDate = 'date'; // Stored as ISO8601 string (YYYY-MM-DD HH:MM:SS)

  static Database? _database;

  // Web Mock Storage (Prepopulated with mock data for the visual preview)
  static final List<Map<String, dynamic>> _webExpenses = [
    {
      'id': 1,
      'amount': 150.0,
      'category': 'food',
      'note': 'Chai & Samosa with friends',
      'date': DateTime.now().toIso8601String(),
    },
    {
      'id': 2,
      'amount': 450.0,
      'category': 'travel',
      'note': 'Metro card recharge',
      'date': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 3,
      'amount': 1200.0,
      'category': 'shopping',
      'note': 'Reference book for DSA',
      'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 4,
      'amount': 120.0,
      'category': 'food',
      'note': 'Juice at canteen',
      'date': DateTime.now().subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
    },
    {
      'id': 5,
      'amount': 300.0,
      'category': 'entertainment',
      'note': 'Movie ticket',
      'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    },
  ];
  static int _webIdCounter = 6;

  // Private constructor
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('sqflite database not supported on Web');
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableExpenses (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colAmount REAL NOT NULL,
        $colCategory TEXT NOT NULL,
        $colNote TEXT,
        $colDate TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Schema migration logic goes here when database version upgrades
  }

  // --- CRUD Operations ---

  Future<int> insertExpense(Map<String, dynamic> row) async {
    if (kIsWeb) {
      final newRow = Map<String, dynamic>.from(row);
      newRow[colId] = _webIdCounter++;
      _webExpenses.add(newRow);
      return newRow[colId];
    }

    final db = await database;
    return await db.insert(tableExpenses, row);
  }

  Future<List<Map<String, dynamic>>> queryAllExpenses() async {
    if (kIsWeb) {
      final list = List<Map<String, dynamic>>.from(_webExpenses);
      list.sort((a, b) => b[colDate].compareTo(a[colDate]));
      return list;
    }

    final db = await database;
    return await db.query(
      tableExpenses,
      orderBy: '$colDate DESC',
    );
  }

  Future<List<Map<String, dynamic>>> queryFilteredExpenses({
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kIsWeb) {
      var list = List<Map<String, dynamic>>.from(_webExpenses);
      
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        list = list.where((item) => item[colCategory] == categoryId).toList();
      }
      
      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        list = list.where((item) {
          final dt = DateTime.parse(item[colDate]);
          return dt.isAfter(start) || dt.isAtSameMomentAs(start);
        }).toList();
      }
      
      if (endDate != null) {
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        list = list.where((item) {
          final dt = DateTime.parse(item[colDate]);
          return dt.isBefore(end) || dt.isAtSameMomentAs(end);
        }).toList();
      }
      
      list.sort((a, b) => b[colDate].compareTo(a[colDate]));
      return list;
    }

    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      whereClauses.add('$colCategory = ?');
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      whereClauses.add('$colDate >= ?');
      final startStr = DateTime(startDate.year, startDate.month, startDate.day).toIso8601String();
      whereArgs.add(startStr);
    }

    if (endDate != null) {
      whereClauses.add('$colDate <= ?');
      final endStr = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).toIso8601String();
      whereArgs.add(endStr);
    }

    String whereString = '';
    if (whereClauses.isNotEmpty) {
      whereString = 'WHERE ${whereClauses.join(' AND ')}';
    }

    return await db.rawQuery('''
      SELECT * FROM $tableExpenses 
      $whereString
      ORDER BY $colDate DESC
    ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> queryRecentExpenses(int limit) async {
    if (kIsWeb) {
      final list = List<Map<String, dynamic>>.from(_webExpenses);
      list.sort((a, b) => b[colDate].compareTo(a[colDate]));
      return list.take(limit).toList();
    }

    final db = await database;
    return await db.query(
      tableExpenses,
      orderBy: '$colDate DESC',
      limit: limit,
    );
  }

  Future<int> updateExpense(Map<String, dynamic> row) async {
    if (kIsWeb) {
      final idx = _webExpenses.indexWhere((item) => item[colId] == row[colId]);
      if (idx != -1) {
        _webExpenses[idx] = row;
        return 1;
      }
      return 0;
    }

    final db = await database;
    int id = row[colId];
    return await db.update(
      tableExpenses,
      row,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      _webExpenses.removeWhere((item) => item[colId] == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      tableExpenses,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTodayTotalSpend() async {
    if (kIsWeb) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      double total = 0.0;
      for (var exp in _webExpenses) {
        if (exp[colDate].toString().startsWith(todayStr)) {
          total += exp[colAmount] as double;
        }
      }
      return total;
    }

    final db = await database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final result = await db.rawQuery('''
      SELECT SUM($colAmount) as total 
      FROM $tableExpenses 
      WHERE $colDate LIKE '$todayStr%'
    ''');
    
    if (result.isNotEmpty && result.first['total'] != null) {
      return double.parse(result.first['total'].toString());
    }
    return 0.0;
  }

  Future<double> getMonthTotalSpend() async {
    if (kIsWeb) {
      final monthStr = DateTime.now().toIso8601String().substring(0, 7);
      double total = 0.0;
      for (var exp in _webExpenses) {
        if (exp[colDate].toString().startsWith(monthStr)) {
          total += exp[colAmount] as double;
        }
      }
      return total;
    }

    final db = await database;
    final monthStr = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM
    final result = await db.rawQuery('''
      SELECT SUM($colAmount) as total 
      FROM $tableExpenses 
      WHERE $colDate LIKE '$monthStr%'
    ''');

    if (result.isNotEmpty && result.first['total'] != null) {
      return double.parse(result.first['total'].toString());
    }
    return 0.0;
  }

  // Restore database entries from backup
  Future<void> restoreBackup(List<Map<String, dynamic>> expenses) async {
    if (kIsWeb) {
      _webExpenses.clear();
      _webExpenses.addAll(expenses);
      _webIdCounter = expenses.isEmpty
          ? 1
          : expenses.map((e) => int.tryParse(e['id'].toString()) ?? 1).reduce((a, b) => a > b ? a : b) + 1;
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      // Clear old entries
      await txn.delete(tableExpenses);
      // Insert backup records
      for (var row in expenses) {
        await txn.insert(tableExpenses, {
          colAmount: row[colAmount],
          colCategory: row[colCategory],
          colNote: row[colNote],
          colDate: row[colDate],
        });
      }
    });
  }
}
