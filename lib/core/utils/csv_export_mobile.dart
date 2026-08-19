import 'dart:io' show File;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

void saveAndShareCsv(String csvString) async {
  try {
    final dbPath = await getDatabasesPath();
    final csvPath = join(dbPath, 'spendtrail_export.csv');
    final file = File(csvPath);
    await file.writeAsString(csvString);
    await Share.shareXFiles([XFile(file.path)], text: 'SpendTrail CSV Export');
  } catch (e) {
    // Fail silently or handle error in UI
  }
}
