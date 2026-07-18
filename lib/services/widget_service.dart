import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class WidgetService {
  static Future<void> updateWidget(List<Expense> expenses, {String currency = '₹'}) async {
    final now = DateTime.now();
    double total = 0;
    for (var e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month && e.date.day == now.day) {
        total += e.amount;
      }
    }

    final currencyFormat = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final totalString = currencyFormat.format(total);

    await HomeWidget.saveWidgetData<String>('monthly_total', totalString);
    await HomeWidget.updateWidget(
      name: 'SpendTrailWidgetProvider',
      androidName: 'SpendTrailWidgetProvider',
    );
  }
}
