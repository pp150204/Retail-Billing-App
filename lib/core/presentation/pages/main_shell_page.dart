import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class MainShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellPage({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  );
                }
                return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              backgroundColor: Colors.white,
              elevation: 0,
              height: 65,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF2B4D9D)),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_cart_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.shopping_cart_rounded, color: Color(0xFF2B4D9D)),
                  label: 'Cart',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.inventory_2_rounded, color: Color(0xFF2B4D9D)),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: Colors.grey),
                  selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF2B4D9D)),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
