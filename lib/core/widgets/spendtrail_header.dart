import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../providers/settings_provider.dart';

class SpendTrailHeader extends ConsumerWidget implements PreferredSizeWidget {
  final bool showProfileOnly;
  
  const SpendTrailHeader({
    super.key,
    this.showProfileOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryContainer : AppColors.primary;

    // Load correct avatar widget based on storage source and platform
    Widget avatarWidget;
    if (settings.profileImagePath != null) {
      if (kIsWeb) {
        avatarWidget = Image.network(
          settings.profileImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: primaryColor),
        );
      } else {
        avatarWidget = Image.file(
          File(settings.profileImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: primaryColor),
        );
      }
    } else {
      avatarWidget = Image.network(
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBV9SiIbAVhoEIpUpSv3tnECcSDAtOQslvJFM7ssbVkdNNxvZpfa_ZPocuSoZAZsm0cE7vf8392Zgm-UU2kbibo0vP9ZNlthKH_gwM21duCPOTz_zI0HsdYK7z1l7d2BPXnl52QDIJUkXwbiqaE1nshoOrqv7ZIxMRO9QbqqVFCAQFiCrNbRYrQ4RyhEL3VBKmG654zfWSyWA85Q3nyTEIZXWGZcdYrlVEfWbtHilrBs997KjDtSp-mVQ',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: primaryColor),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      // Left-aligned circular image avatar in leading position
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : AppColors.outlineVariant.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: ClipOval(
            child: avatarWidget,
          ),
        ),
      ),
      leadingWidth: 56.0,
      // Center the title "SpendTrail" in primary color Montserrat
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
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
