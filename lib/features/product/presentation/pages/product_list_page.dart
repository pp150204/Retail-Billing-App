import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'price_asc', 'price_desc', 'stock_asc', 'stock_desc'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.sort, color: Color(0xFF1F2937)),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search inventory...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                ),
                style: const TextStyle(fontSize: 16),
              )
            : const Text(
                'Inventory',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1F2937),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF4B5563),
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: Color(0xFF4B5563)),
            onPressed: () => _showSortDialog(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.transparent, // Using custom styling instead of default indicator
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All Products'),
                Tab(text: 'Low Stock'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList(context, filterLowStock: false),
          _buildProductList(context, filterLowStock: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/add'),
        backgroundColor: const Color(0xFF10B981),
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, {required bool filterLowStock}) {
    return BlocConsumer<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state.status == ProductStatus.success && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!), backgroundColor: Colors.green),
          );
        } else if (state.status == ProductStatus.error && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ProductStatus.loading && state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.products.isEmpty) {
          if (state.status == ProductStatus.error) {
            return Center(child: Text('Error: \${state.message}'));
          }
          return const Center(child: Text('No products found. Add some!', style: TextStyle(color: Colors.grey)));
        }

        var filteredProducts = state.products.where((product) {
          final matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
              product.barcode.toLowerCase().contains(_searchQuery);
          final matchesStock = !filterLowStock || product.stock < 20;
          return matchesSearch && matchesStock;
        }).toList();

        // Sort products
        switch (_sortBy) {
          case 'name':
            filteredProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            break;
          case 'price_asc':
            filteredProducts.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'price_desc':
            filteredProducts.sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'stock_asc':
            filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
            break;
          case 'stock_desc':
            filteredProducts.sort((a, b) => b.stock.compareTo(a.stock));
            break;
        }

        final totalProducts = state.products.length;
        final lowStockCount = state.products.where((p) => p.stock < 20).length;
        final totalValue = state.products.fold(0.0, (sum, p) => sum + (p.price * p.stock));

        return Column(
          children: [
            // Stats Summary
            if (!filterLowStock && !_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard('Total Products', '$totalProducts', Icons.inventory_2_rounded, const Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      _buildStatCard('Low Stock', '$lowStockCount', Icons.warning_amber_rounded, const Color(0xFFF59E0B)),
                      const SizedBox(width: 12),
                      _buildStatCard('Total Value', '₹${totalValue.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),
            
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _isSearching ? 'No results for "$_searchQuery"' : 'No products found',
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isOutOfStock = product.stock <= 0;
                        final isLowStock = !isOutOfStock && product.stock < 20;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Product Image Placeholder
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey.shade50, Colors.grey.shade100],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.local_mall_outlined,
                                    color: const Color(0xFF4F46E5).withOpacity(0.4),
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1F2937),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (product.expiryDate != null) ...[
                                          const SizedBox(width: 12),
                                          Icon(Icons.event_note_rounded, size: 14, color: Colors.grey.shade400),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Exp: ${DateFormat('MMM yyyy').format(product.expiryDate!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          'SKU: ${product.barcode}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock 
                                                ? const Color(0xFFFEF2F2) 
                                                : isLowStock 
                                                    ? const Color(0xFFFFF7ED) 
                                                    : const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isOutOfStock 
                                                ? 'Out of stock' 
                                                : 'Stock: ${product.stock}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isOutOfStock 
                                                  ? const Color(0xFFEF4444) 
                                                  : isLowStock 
                                                      ? const Color(0xFFF59E0B) 
                                                      : const Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₹${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            _buildActionButton(
                                              icon: Icons.edit_outlined,
                                              color: Colors.blue.shade700,
                                              onTap: () => context.push('/products/edit/${product.id}', extra: product),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildActionButton(
                                              icon: Icons.delete_outline_rounded,
                                              color: Colors.red.shade700,
                                              onTap: () => _confirmDelete(context, product),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort Products By',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Name (A-Z)', 'name', Icons.sort_by_alpha_rounded),
              _buildSortOption('Price (Low to High)', 'price_asc', Icons.arrow_upward_rounded),
              _buildSortOption('Price (High to Low)', 'price_desc', Icons.arrow_downward_rounded),
              _buildSortOption('Stock (Low to High)', 'stock_asc', Icons.trending_down_rounded),
              _buildSortOption('Stock (High to Low)', 'stock_desc', Icons.trending_up_rounded),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF4B5563),
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (innerContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete ${product.name}?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(innerContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                context.read<ProductBloc>().add(DeleteProduct(product.id));
                Navigator.pop(innerContext);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
