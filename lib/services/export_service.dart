import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ExportService {
  static Future<void> exportToCsv(List<Expense> expenses, List<ExpenseCategory> categories) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/spendtrail_export.csv');
      
      String csvData = "Date,Amount,Category,Note\n";
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      
      for (var expense in expenses) {
        final category = categories.firstWhere((c) => c.id == expense.categoryId, 
            orElse: () => const ExpenseCategory(name: 'Unknown', colorValue: 0, iconCodePoint: 0));
            
        final date = dateFormat.format(expense.date);
        final amount = expense.amount.toStringAsFixed(2);
        final note = expense.note.replaceAll('"', '""');
        
        csvData += "$date,$amount,\"${category.name}\",\"$note\"\n";
      }
      
      await file.writeAsString(csvData);
      
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'My SpendTrail Expense Export');
    } catch (e) {
      // Silently fail if there's an error during export
    }
  }

  static Future<void> exportDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final File dbFile = File('${directory.path}/spendtrail.db');
      
      if (await dbFile.exists()) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(dbFile.path)], text: 'My SpendTrail Database Backup');
      }
    } catch (e) {
      // Fail silently
    }
  }

  static Future<bool> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File backupFile = File(result.files.single.path!);
        
        // Check if it's a valid SQLite file (starts with "SQLite format 3\0")
        final header = await backupFile.openRead(0, 16).first;
        final headerString = String.fromCharCodes(header);
        if (headerString.startsWith('SQLite format 3')) {
          final directory = await getApplicationDocumentsDirectory();
          final File dbFile = File('${directory.path}/spendtrail.db');
          
          await backupFile.copy(dbFile.path);
          return true;
        }
      }
    } catch (e) {
      // Fail silently
    }
    return false;
  }
}
