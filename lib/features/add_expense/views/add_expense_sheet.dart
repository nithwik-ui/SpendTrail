import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../core/models/expense.dart';
import '../../../core/providers/expense_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  String _amount = '0';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedCategoryId = AppConstants.categories.first.id;

  void _onKeyPress(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == 'C') {
        _amount = '0';
      } else if (value == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) {
          _amount += '.';
        }
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          if (_amount.length < 8) {
            _amount += value;
          }
        }
      }
    });
  }

  void _saveExpense() {
    HapticFeedback.mediumImpact();
    final double? parsedAmount = double.tryParse(_amount);
    if (parsedAmount == null || parsedAmount <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount',
            style: AppConstants.getLabelMdStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.tertiary,
        ),
      );
      return;
    }

    final newExpense = Expense(
      amount: parsedAmount,
      category: _selectedCategoryId,
      note: _note.trim().isEmpty ? null : _note.trim(),
      date: _selectedDate,
    );

    // Optimistic write
    ref.read(expenseProvider.notifier).addExpense(newExpense);

    Navigator.of(context).pop();
  }

  Future<void> _selectDate() async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surfaceContainerLowest,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = isDark ? AppColors.darkCard : AppColors.surfaceContainerLowest;
    final inputBgColor = isDark ? AppColors.darkBg : AppColors.surfaceContainerLow;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.surfaceContainer;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)), // rounded-t-32px from HTML
      ),
      padding: EdgeInsets.only(
        top: 12.0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TOP HEADER (Task-focused Close)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close cross button
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: secondaryTextColor, size: 22.0),
                    ),
                  ),
                  Text(
                    'New Expense',
                    style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 40.0), // Spacer
                ],
              ),
            ),
            
            // 2. AMOUNT DISPLAY CANVAS
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 2.0),
                        child: Text(
                          AppConstants.defaultCurrencySymbol,
                          style: AppConstants.getHeadlineMdStyle(color: secondaryTextColor).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _amount,
                          style: AppConstants.getDisplayCurrencyStyle(color: primaryTextColor).copyWith(
                            fontSize: 64.0, // 64px from HTML
                            fontWeight: FontWeight.bold,
                            letterSpacing: -2.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).animate(target: _amount != '0' ? 1.0 : 0.0)
                         .scale(duration: 150.ms, curve: Curves.easeOutCubic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  // Date Chip Below Amount
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16.0, color: secondaryTextColor),
                          const SizedBox(width: 6.0),
                          Text(
                            _isSameDay(_selectedDate, DateTime.now())
                                ? 'Today'
                                : '${_selectedDate.day}/${_selectedDate.month}',
                            style: AppConstants.getLabelMdStyle(color: secondaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. HORIZONTAL CATEGORY PICKER
            SizedBox(
              height: 88.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: AppConstants.categories.length,
                itemBuilder: (context, index) {
                  final cat = AppConstants.categories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56.0,
                            height: 56.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primary : inputBgColor,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.2),
                                        blurRadius: 12.0,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              cat.icon,
                              color: isSelected ? Colors.white : secondaryTextColor,
                              size: 24.0,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            cat.name.split(' ').first,
                            style: AppConstants.getLabelSmStyle(
                              color: isSelected ? primaryTextColor : secondaryTextColor,
                            ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12.0),

            // 4. UNDERLINE NOTE INPUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: secondaryTextColor.withOpacity(0.5), size: 24.0),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        hintStyle: AppConstants.getBodyLgStyle(color: secondaryTextColor.withOpacity(0.5)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor, width: 1.0),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      style: AppConstants.getBodyLgStyle(color: primaryTextColor),
                      onChanged: (val) => _note = val,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // 5. NUMPAD CONTAINER SHELL (white container rounded-t-32px)
            Container(
              color: cardBgColor,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Numpad Keys Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
                      final key = keys[index];
                      
                      return InkWell(
                        onTap: () => _onKeyPress(key),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          alignment: Alignment.center,
                          child: key == '⌫'
                              ? Icon(Icons.backspace_rounded, color: secondaryTextColor, size: 22.0)
                              : Text(
                                  key,
                                  style: AppConstants.getHeadlineMdStyle(color: primaryTextColor).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12.0),
                  // Save Button
                  ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 52.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.0), // pill button
                      ),
                      shadowColor: AppColors.primary.withOpacity(0.25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save Expense',
                          style: AppConstants.getHeadlineSmStyle(color: Colors.white).copyWith(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Icon(Icons.check_rounded, size: 20.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
