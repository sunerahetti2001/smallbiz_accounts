import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: isSmallScreen ? 65 : 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: localizations.home,
                index: 0,
                isSmallScreen: isSmallScreen,
              ),
              _buildNavItem(
                icon: Icons.category_outlined,
                activeIcon: Icons.category,
                label: localizations.categories,
                index: 1,
                isSmallScreen: isSmallScreen,
              ),
              _buildNavItem(
                icon: Icons.compare_arrows_outlined,
                activeIcon: Icons.compare_arrows,
                label: localizations.compare,
                index: 2,
                isSmallScreen: isSmallScreen,
              ),
              _buildNavItem(
                icon: Icons.timeline_outlined,
                activeIcon: Icons.timeline,
                label: localizations.analysis,
                index: 3,
                isSmallScreen: isSmallScreen,
              ),
              _buildNavItem(
                icon: Icons.description_outlined,
                activeIcon: Icons.description,
                label: localizations.statements,
                index: 4,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSmallScreen,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 4 : 8,
          vertical: isSmallScreen ? 4 : 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}