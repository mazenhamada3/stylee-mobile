import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.child, required this.location});

  int get _idx {
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNav(currentIndex: _idx, cartCount: cartCount, onTap: (i) {
        switch (i) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/search');
            break;
          case 2:
            context.go('/cart');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      }),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final void Function(int) onTap;

  const AppBottomNav({required this.currentIndex, required this.cartCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.black,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'HOME', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.search, activeIcon: Icons.search, label: 'SEARCH', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'CART', index: 2, current: currentIndex, onTap: onTap, badge: cartCount),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'PROFILE', index: 3, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final int badge;
  final void Function(int) onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final color = active ? AppTheme.white : AppTheme.grey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
                      child: Text('$badge', style: const TextStyle(color: AppTheme.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w400, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}