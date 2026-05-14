import 'package:billing_app/features/billing/presentation/pages/hhhomepage.dart';
import 'package:go_router/go_router.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/billing/presentation/pages/reports_page.dart';
import '../../features/customer/presentation/pages/customer_list_page.dart';
import '../../features/customer/presentation/pages/add_customer_page.dart';
import '../../features/customer/domain/entities/customer.dart';
import '../../features/product/domain/entities/product.dart';
import '../../core/presentation/pages/main_shell_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/billing',
              builder: (context, state) => const originalHomePage(),
            ),
            GoRoute(
              path: '/checkout',
              builder: (context, state) => const CheckoutPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/customers',
              builder: (context, state) => const CustomerListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerPage(),
    ),
    GoRoute(
      path: '/customers/add',
      builder: (context, state) => const AddCustomerPage(),
    ),
    GoRoute(
      path: '/customers/edit',
      builder: (context, state) {
        final customer = state.extra as Customer?;
        return AddCustomerPage(customer: customer);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: '/products/add',
      builder: (context, state) => const AddProductPage(),
    ),
    GoRoute(
      path: '/products/edit/:id',
      builder: (context, state) {
        final product = state.extra as Product?;
        if (product == null) {
          // If we land here without extra (e.g. deep link), go back to products for now.
          return const ProductListPage();
        }
        return EditProductPage(product: product);
      },
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsPage(),
    ),
  ],
);
