import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/notifications/presentation/providers/notification_provider.dart';

class BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMode = ref.watch(userModeControllerProvider);
    final pendingCount = ref.watch(pendingDropsCountProvider);
    final userDropsCount = ref.watch(userDropsCountProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return userMode.when(
      data: (mode) => _buildFloatingNavBar(context, mode, pendingCount, userDropsCount, unreadCount),
      loading: () => _buildFloatingNavBar(context, null, 0, 0, 0),
      error: (_, __) => _buildFloatingNavBar(context, null, 0, 0, 0),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, UserMode? mode, int pendingCount, int userDropsCount, int unreadCount) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 32,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.list_outlined,
              activeIcon: Icons.list,
              label: 'Drops',
              badgeCount: mode == UserMode.collector ? pendingCount : userDropsCount,
            ),
            _buildNavItem(
              context,
              index: 2,
              icon: Icons.card_giftcard_outlined,
              activeIcon: Icons.card_giftcard,
              label: 'Rewards',
              badgeCount: unreadCount > 0 ? unreadCount : null,
            ),
            _buildNavItem(
              context,
              index: 3,
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart,
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 60,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? primaryColor : Colors.grey[600],
                  size: 24,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[600],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}