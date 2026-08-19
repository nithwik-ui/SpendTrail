import 'dart:convert' show jsonEncode, jsonDecode, utf8;
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

import '../../../config/constants.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/expense.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/encryption_helper.dart';
import '../../../core/widgets/spendtrail_header.dart';
import '../../../core/utils/csv_export_stub.dart'
    if (dart.library.html) '../../../core/utils/csv_export_web.dart'
    if (dart.library.io) '../../../core/utils/csv_export_mobile.dart';
import '../../../core/utils/backup_helper_stub.dart'
    if (dart.library.html) '../../../core/utils/backup_helper_web.dart'
    if (dart.library.io) '../../../core/utils/backup_helper_mobile.dart';
import '../../../core/services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _budgetController;
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _budgetController = TextEditingController(
      text: _formatNumberWithCommas(settings.monthlyBudget.toInt()),
    );
    _nameController = TextEditingController(text: settings.userName);
    _nameFocusNode = FocusNode();
    
    // Auto-save name on focus loss
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        ref.read(settingsProvider.notifier).updateName(_nameController.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String _formatNumberWithCommas(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }

  void _onBudgetSaved(String val) {
    final double? budget = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
    if (budget != null && budget > 0) {
      ref.read(settingsProvider.notifier).updateBudget(budget);
    }
  }

  Future<void> _changeProfilePhoto() async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (image != null) {
        ref.read(settingsProvider.notifier).updateProfilePhoto(image.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick profile picture')),
      );
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildAvatarWidget(String? imagePath, String userName, Color primaryColor, Color cardBgColor) {
    if (imagePath != null) {
      if (kIsWeb) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(userName),
        );
      } else {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(userName),
        );
      }
    }
    return _buildInitialsPlaceholder(userName);
  }

  Widget _buildInitialsPlaceholder(String name) {
    final initials = _getInitials(name);
    return Container(
      color: AppColors.primary.withOpacity(0.12),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  void _exportExpensesToCsv() async {
    HapticFeedback.mediumImpact();
    final rows = await DbHelper.instance.queryAllExpenses();
    final expenses = rows.map((row) => Expense.fromMap(row)).toList();

    List<List<dynamic>> csvData = [
      ['ID', 'Amount', 'Category', 'Note', 'Date'],
    ];

    for (var exp in expenses) {
      csvData.add([
        exp.id ?? '',
        exp.amount,
        exp.category,
        exp.note ?? '',
        exp.date.toIso8601String(),
      ]);
    }

    final csvString = Csv().encode(csvData);
    saveAndShareCsv(csvString);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expenses exported successfully!')),
    );
  }

  void _exportBackup() async {
    HapticFeedback.mediumImpact();
    try {
      final rows = await DbHelper.instance.queryAllExpenses();
      final s = ref.read(settingsProvider);

      final backupData = {
        'settings': {
          'userName': s.userName,
          'monthlyBudget': s.monthlyBudget,
          'defaultCurrency': s.defaultCurrency,
          'profileImagePath': s.profileImagePath,
        },
        'expenses': rows,
      };

      final jsonString = jsonEncode(backupData);
      final encryptedString = EncryptionHelper.encrypt(jsonString);

      saveAndShareBackup(encryptedString);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup exported successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _importBackup() async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);
      if (result == null || result.isEmpty) return;

      final bytes = await result.first.readAsBytes();
      final encryptedString = utf8.decode(bytes);

      final decryptedString = EncryptionHelper.decrypt(encryptedString.trim());
      final Map<String, dynamic> backupData = jsonDecode(decryptedString);

      if (!backupData.containsKey('settings') || !backupData.containsKey('expenses')) {
        throw const FormatException('Invalid backup file format');
      }

      // 1. Restore settings state
      final s = backupData['settings'];
      await ref.read(settingsProvider.notifier).restoreSettings(
            name: s['userName'] ?? 'User',
            budget: double.tryParse(s['monthlyBudget'].toString()) ?? 12000.0,
            currency: s['defaultCurrency'] ?? 'INR',
            profilePath: s['profileImagePath'],
          );

      // Refresh Controllers
      _nameController.text = s['userName'] ?? 'User';
      _budgetController.text = _formatNumberWithCommas((double.tryParse(s['monthlyBudget'].toString()) ?? 12000.0).toInt());

      // 2. Restore DB
      final List<dynamic> expensesList = backupData['expenses'];
      final List<Map<String, dynamic>> expenses =
          expensesList.map((e) => Map<String, dynamic>.from(e)).toList();
      await DbHelper.instance.restoreBackup(expenses);

      // 3. Refresh Home Lists
      ref.read(expenseProvider.notifier).loadInitialData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup imported and restored successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  void _checkForUpdates() async {
    HapticFeedback.mediumImpact();

    // 1. Show checking dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(width: 20.0),
              Text('Checking for updates...', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );

    // Trigger update query
    final updateInfo = await ref.read(updateServiceProvider.notifier).checkForUpdates();
    
    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog
    }

    if (!mounted) return;

    if (updateInfo != null) {
      // 2. An update is available! Show confirmation dialog to install
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(updateServiceProvider);
              return AlertDialog(
                title: Text('Update Available (${updateInfo.version})', style: const TextStyle(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A new version of SpendTrail is ready. Would you like to install it now?'),
                    if (state.isDownloading) ...[
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          const SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(strokeWidth: 2.0, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12.0),
                          Text(state.downloadProgress ?? 'Downloading...'),
                        ],
                      ),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12.0),
                      Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
                actions: [
                  if (!state.isDownloading) ...[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await ref.read(updateServiceProvider.notifier).downloadAndInstallUpdate(updateInfo);
                        if (success && mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Download & Install'),
                    ),
                  ],
                ],
              );
            },
          );
        },
      );
    } else {
      final state = ref.read(updateServiceProvider);
      // Show up to date dialog or error dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(state.errorMessage != null ? 'Checking Failed' : 'Up to Date', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(state.errorMessage ?? 'You are already on the latest version of SpendTrail (v1.0.4).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = isDark ? const Color(0xFF121212) : AppColors.surfaceContainerLowest;
    final inputBgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.surfaceContainerLow;
    final borderColor = isDark ? const Color(0xFF222222) : AppColors.surfaceContainer;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const SpendTrailHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PROFILE SECTION (Local-only upload and inline editable name)
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _changeProfilePhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 84.0,
                          height: 84.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardBgColor,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _buildAvatarWidget(
                              settings.profileImagePath,
                              settings.userName,
                              primaryTextColor,
                              cardBgColor,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 12.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  // Inline Editable Name field
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Your Name',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4.0),
                      ),
                      style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      onSubmitted: (val) {
                        ref.read(settingsProvider.notifier).updateName(val.trim());
                      },
                    ),
                  ),
                  Text(
                    'Local Account (No Sync)',
                    style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // 2. PREFERENCES SECTION
            _buildSectionHeader('PREFERENCES', secondaryTextColor),
            const SizedBox(height: 8.0),

            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Budget Row
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer.withOpacity(isDark ? 0.08 : 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: AppColors.secondary,
                                  size: 18.0,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Budget',
                                      style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Target spend limit',
                                      style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Budget Input Box
                        Container(
                          width: 120.0,
                          height: 40.0,
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: inputBgColor,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Text(
                                AppConstants.defaultCurrencySymbol,
                                style: AppConstants.getBodyMdStyle(color: secondaryTextColor),
                              ),
                              const SizedBox(width: 6.0),
                              Expanded(
                                child: TextField(
                                  controller: _budgetController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onChanged: _onBudgetSaved,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(borderColor),

                  // Currency Picker
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withOpacity(isDark ? 0.08 : 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                color: AppColors.secondary,
                                size: 18.0,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              'Default Currency',
                              style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 40.0,
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          decoration: BoxDecoration(
                            color: inputBgColor,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: settings.defaultCurrency,
                              items: const [
                                DropdownMenuItem(value: 'INR', child: Text('₹ INR')),
                                DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                                DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  HapticFeedback.lightImpact();
                                  ref.read(settingsProvider.notifier).updateCurrency(val);
                                }
                              },
                              style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(borderColor),

                  // Dark Mode Toggler
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer.withOpacity(isDark ? 0.08 : 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.dark_mode_rounded,
                                  color: AppColors.secondary,
                                  size: 18.0,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dark Mode',
                                      style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'OLED True Black Theme',
                                      style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.isDarkMode,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            HapticFeedback.mediumImpact();
                            ref.read(settingsProvider.notifier).toggleDarkMode(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // 3. DATA SECTION
            _buildSectionHeader('DATA MANAGEMENT', secondaryTextColor),
            const SizedBox(height: 8.0),

            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportExpensesToCsv,
                    icon: const Icon(Icons.download_rounded, size: 18.0),
                    label: Text(
                      'Export as CSV',
                      style: AppConstants.getBodyMdStyle(color: AppColors.primary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      minimumSize: const Size(0, 48.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportBackup,
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18.0),
                          label: Text(
                            'Backup',
                            style: AppConstants.getBodyMdStyle(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            minimumSize: const Size(0, 48.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _importBackup,
                          icon: const Icon(Icons.cloud_download_rounded, size: 18.0),
                          label: Text(
                            'Import Backup',
                            style: AppConstants.getBodyMdStyle(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            minimumSize: const Size(0, 48.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // 4. APP UPDATES SECTION
            _buildSectionHeader('APP UPDATES', secondaryTextColor),
            const SizedBox(height: 8.0),

            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Version',
                        style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'v1.0.4',
                        style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _checkForUpdates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Check for Updates',
                      style: AppConstants.getLabelMdStyle(color: Colors.white).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // 5. ABOUT SECTION
            _buildSectionHeader('ABOUT', secondaryTextColor),
            const SizedBox(height: 8.0),

            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16.0), // 16px corner radius audit
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SpendTrail — Personal Expense Notebook',
                    style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Your data is stored 100% locally on your device. We collect no personal data or transaction history.',
                    style: AppConstants.getBodyMdStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48.0),

            // FOOTER WATERMARK
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Made for students with ',
                    style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                  ),
                  Icon(Icons.favorite_rounded, color: AppColors.tertiary, size: 14.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: AppConstants.getLabelSmStyle(color: textColor).copyWith(
          letterSpacing: 1.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(
      height: 1.0,
      thickness: 1.0,
      color: color.withOpacity(0.3),
    );
  }
}
