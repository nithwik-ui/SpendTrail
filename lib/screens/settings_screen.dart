import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/providers.dart';
import '../providers/currency_provider.dart';
import '../services/export_service.dart';
import '../services/update_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  
  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkForUpdateSilently();
  }
  
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  Future<void> _checkForUpdateSilently() async {
    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New update available: v${updateInfo.latestVersion}'),
          action: SnackBarAction(
            label: 'Details',
            onPressed: () => _showUpdateDialog(updateInfo),
          ),
        ),
      );
    }
  }
  
  Future<void> _manualUpdateCheck() async {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final updateInfo = await UpdateService.checkForUpdate();
    
    if (!mounted) return;
    Navigator.pop(context); // pop loading
    
    if (updateInfo != null) {
      _showUpdateDialog(updateInfo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the latest version.')),
      );
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Version: ${info.currentVersion}', style: const TextStyle(color: Colors.grey)),
            Text('Latest Version: ${info.latestVersion}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (info.publishedDate.isNotEmpty)
              Text('Published: ${info.publishedDate}'),
            if (info.apkSize != null)
              Text('Size: ${(info.apkSize! / 1024 / 1024).toStringAsFixed(1)} MB'),
            const SizedBox(height: 12),
            const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(info.releaseNotes),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              UpdateService.launchUpdateUrl(info.downloadUrl);
            },
            child: const Text('Download Update'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencies = {
      '₹': 'INR (₹)',
      '\$': 'USD (\$)',
      '€': 'EUR (€)',
      '£': 'GBP (£)',
      '¥': 'JPY (¥)',
      'AED': 'AED',
      'SAR': 'SAR',
    };
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.entries.map((entry) {
              return ListTile(
                title: Text(entry.value),
                onTap: () {
                  ref.read(currencyProvider.notifier).setCurrency(entry.key);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrency = ref.watch(currencyProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Preferences'),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Theme'),
            subtitle: const Text('System Default'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Follows system theme.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            subtitle: Text('Current: $currentCurrency'),
            onTap: _showCurrencyPicker,
          ),
          
          const _SectionHeader(title: 'Data Management'),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export Data to CSV'),
            subtitle: const Text('Backup expenses as spreadsheet'),
            onTap: () async {
              final expenses = await ref.read(expensesProvider.future);
              final categories = await ref.read(categoriesProvider.future);
              await ExportService.exportToCsv(expenses, categories);
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Export Database'),
            subtitle: const Text('Backup full SQLite database'),
            onTap: () => ExportService.exportDatabase(),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Import Database'),
            subtitle: const Text('Restore from a database backup'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Warning'),
                  content: const Text('This will overwrite all current data. Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Proceed', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                final success = await ExportService.importDatabase();
                if (success && mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Success'),
                      content: const Text('Database restored! Please restart the app completely to load the new data.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                      ],
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to import database.')));
                }
              }
            },
          ),
          
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Check for Updates'),
            subtitle: Text('Current version: $_version'),
            onTap: _manualUpdateCheck,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data is stored locally on your device.')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'SpendTrail',
                applicationVersion: _version,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
