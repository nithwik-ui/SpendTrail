import 'dart:io' show File;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

void saveAndShareBackup(String backupString) async {
  try {
    final dbPath = await getDatabasesPath();
    final backupPath = join(dbPath, 'spendtrail_backup.stb');
    final file = File(backupPath);
    await file.writeAsString(backupString);
    await Share.shareXFiles([XFile(file.path)], text: 'SpendTrail Encrypted Backup');
  } catch (e) {
    // Fail silently
  }
}
