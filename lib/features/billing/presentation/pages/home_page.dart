import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';

import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/domain/entities/product.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      BlocBuilder<ShopBloc, ShopState>(
                        builder: (context, state) {
                          String shopName = 'Mega Mart';
                          if (state is ShopLoaded) {
                            shopName = state.shop.name.isNotEmpty 
                                ? state.shop.name 
                                : 'Mega Mart';
                          }
                          return Text(
                            shopName,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      BlocBuilder<ProductBloc, ProductState>(
                        builder: (context, state) {
                          if (state.status != ProductStatus.loaded) {
                            return IconButton(
                              icon: const Icon(Icons.notifications_none, color: Color(0xFF1E3A8A)),
                              onPressed: () {},
                            );
                          }
                          
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final expiringOrExpiredProducts = state.products.where((p) {
                            if (p.expiryDate == null) return false;
                            final expiryDate = DateTime(p.expiryDate!.year, p.expiryDate!.month, p.expiryDate!.day);
                            final difference = expiryDate.difference(today).inDays;
                            return difference <= 7;
                          }).toList();
                          
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: Color(0xFF1E3A8A), size: 28),
                                onPressed: () {
                                  _showNotificationsDialog(context, expiringOrExpiredProducts);
                                },
                              ),
                              if (expiringOrExpiredProducts.isNotEmpty)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${expiringOrExpiredProducts.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: BlocBuilder<ShopBloc, ShopState>(
                          builder: (context, state) {
                            if (state is ShopLoaded && state.shop.logoPath.isNotEmpty) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(state.shop.logoPath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.storefront_outlined, color: Color(0xFF4F46E5)),
                                ),
                              );
                            }
                            return const Icon(
                              Icons.storefront_outlined,
                              color: Color(0xFF4F46E5),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickActionCard(
                    context,
                    title: 'Start Billing',
                    icon: Icons.receipt_long_rounded,
                    onTap: () {
                      context.go('/billing');
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    title: 'Products',
                    icon: Icons.inventory_2_rounded,
                    onTap: () {
                      context.go('/products');
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    title: 'Reports',
                    icon: Icons.analytics_rounded,
                    onTap: () {
                      context.go('/reports');
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    title: 'Settings',
                    icon: Icons.settings_rounded,
                    onTap: () {
                      context.go('/settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Today's Sales Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Sales Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<BillingBloc>().add(LoadTodaySummaryEvent());
                    },
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BlocBuilder<BillingBloc, BillingState>(
                builder: (context, state) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFC026D3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TODAY\'S REVENUE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                formattedDate,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${state.todayRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            _buildMiniStat('Orders', '${state.todayOrdersCount}', Icons.receipt_long_rounded),
                            const SizedBox(width: 24),
                            _buildMiniStat('Items', '${state.todayItemsSold}', Icons.local_mall_rounded),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Offline-first Ready Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline-first Ready',
                            style: TextStyle(
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'All data is synced locally and safe.',
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                // Low Stock Alerts (New Section)
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  final lowStockProducts = state.products.where((p) => p.stock < 20).take(3).toList();
                  if (lowStockProducts.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Low Stock Alerts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/products'),
                            child: const Text('View All', style: TextStyle(color: Color(0xFF4F46E5))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...lowStockProducts.map((product) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: product.stock <= 0 ? Colors.red.shade50 : Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                product.stock <= 0 ? Icons.error_outline : Icons.warning_amber_rounded,
                                color: product.stock <= 0 ? Colors.red : Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    'Only ${product.stock} units left in stock',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey.shade400),
                          ],
                        ),
                      )).toList(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF4F46E5).withOpacity(0.1), const Color(0xFF4F46E5).withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4F46E5),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _showNotificationsDialog(BuildContext context, List<Product> products) {
    showDialog(
      context: context,
      builder: (context) {
        if (products.isEmpty) {
          return AlertDialog(
            title: const Text('Notifications'),
            content: const Text('No recent notifications.'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        return AlertDialog(
          title: const Text('Inventory Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = products[index];
                final expiryDate = DateTime(product.expiryDate!.year, product.expiryDate!.month, product.expiryDate!.day);
                final difference = expiryDate.difference(today).inDays;
                
                String status = '';
                Color statusColor = Colors.grey;
                
                if (difference < 0) {
                  status = 'Expired ${-difference} days ago';
                  statusColor = Colors.red;
                } else if (difference == 0) {
                  status = 'Expires Today';
                  statusColor = Colors.orange;
                } else {
                  status = 'Expires in $difference days';
                  statusColor = Colors.orange.shade700;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(difference < 0 ? Icons.warning_amber_rounded : Icons.history_toggle_off_rounded, color: statusColor, size: 20),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                  trailing: Text('Stock: ${product.stock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/products');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Inventory'),
            ),
          ],
        );
      },
    );
  }
}
