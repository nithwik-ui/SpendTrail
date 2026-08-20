import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../../features/dashboard/views/budget_overview_screen.dart';

class SpendTrailHeader extends ConsumerWidget implements PreferredSizeWidget {
  final bool showProfileOnly;
  
  const SpendTrailHeader({
    super.key,
    this.showProfileOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch the specific fields we need to avoid unnecessary rebuilds
    final profilePath = ref.watch(settingsProvider.select((s) => s.profileImagePath));
    final userName = ref.watch(settingsProvider.select((s) => s.userName));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryContainer : AppColors.primary;

    // Build avatar with cached ImageProvider for performance
    Widget avatarWidget;
    if (profilePath != null) {
      final ImageProvider imageProvider;
      if (kIsWeb) {
        imageProvider = NetworkImage(profilePath);
      } else {
        imageProvider = FileImage(File(profilePath));
      }
      avatarWidget = Image(
        image: imageProvider,
        fit: BoxFit.cover,
        // Cache frames to avoid re-decoding on rebuilds
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsAvatar(userName, primaryColor, isDark),
      );
    } else {
      avatarWidget = _buildInitialsAvatar(userName, primaryColor, isDark);
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(navigationProvider.notifier).state = 3; // Switch to settings tab index 3
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : AppColors.outlineVariant.withOpacity(0.2),
                width: 1.0,
              ),
            ),
            child: ClipOval(child: avatarWidget),
          ),
        ),
      ),
      leadingWidth: 56.0,
      centerTitle: true,
      title: Text(
        'SpendTrail',
        style: AppConstants.getHeadlineMdStyle(color: primaryColor).copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(
              Icons.account_balance_wallet_rounded,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetOverviewScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build initials-based avatar fallback (no network call!)
  Widget _buildInitialsAvatar(String userName, Color primaryColor, bool isDark) {
    final initials = _getInitials(userName);
    return Container(
      color: isDark ? const Color(0xFF1A2A2C) : AppColors.primaryContainer.withOpacity(0.5),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
