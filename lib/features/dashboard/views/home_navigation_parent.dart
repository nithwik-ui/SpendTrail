import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/constants.dart';
import 'dashboard_screen.dart';
import '../../history/views/history_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../analytics/views/analytics_screen.dart';

class HomeNavigationParent extends StatefulWidget {
  const HomeNavigationParent({super.key});

  @override
  State<HomeNavigationParent> createState() => _HomeNavigationParentState();
}

class _HomeNavigationParentState extends State<HomeNavigationParent> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    
    // Tactile haptic feedback on tab change
    HapticFeedback.lightImpact();
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final barBg = isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.surfaceContainer;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(
            top: BorderSide(color: borderColor, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home', activeColor, inactiveColor),
                _buildNavItem(1, Icons.analytics_rounded, 'Analytics', activeColor, inactiveColor),
                _buildNavItem(2, Icons.receipt_long_rounded, 'History', activeColor, inactiveColor),
                _buildNavItem(3, Icons.settings_rounded, 'Settings', activeColor, inactiveColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor, Color inactiveColor) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with active pill highlight
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondaryContainer.withOpacity(0.4) : Colors.transparent,
                borderRadius: BorderRadius.circular(16.0), // rounded-lg
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : inactiveColor,
                size: 24.0,
              ),
            ),
            const SizedBox(height: 3.0),
            Text(
              label,
              style: AppConstants.getLabelSmStyle(
                color: isSelected ? AppColors.primary : inactiveColor,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


