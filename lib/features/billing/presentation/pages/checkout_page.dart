import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/widgets/primary_button.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/domain/entities/customer.dart';
import '../bloc/billing_bloc.dart';

import '../widgets/digital_receipt_dialog.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isPaid = true;

  void _showCustomerSelector(BuildContext context) {
    context.read<CustomerBloc>().add(LoadCustomersEvent());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Customer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/customers/add');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (value) {
                  context.read<CustomerBloc>().add(SearchCustomersEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state.status == CustomerStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.filteredCustomers.isEmpty) {
                    return const Center(child: Text('No customers found'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = state.filteredCustomers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(customer.phone),
                        onTap: () {
                          context.read<BillingBloc>().add(SelectCustomerEvent(customer));
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          context.read<BillingBloc>().add(ClearCartEvent());
          context.go('/');
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Checkout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
              onPressed: () {
                context.read<BillingBloc>().add(ClearCartEvent());
                context.go('/');
              },
            ),
          ),
          body: BlocConsumer<BillingBloc, BillingState>(
            listener: (context, state) {
              if (state.printSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Printed successfully'),
                    backgroundColor: Colors.green));
                // context.read<BillingBloc>().add(ClearCartEvent());
                // context.go('/');
              }
            },
            builder: (context, billingState) {
              return BlocBuilder<ShopBloc, ShopState>(
                  builder: (context, shopState) {
                    String upiId = '';
                    String shopName = 'Shop';

                    if (shopState is ShopLoaded) {
                      upiId = shopState.shop.upiId;
                      shopName = shopState.shop.name;
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Column(
                              children: [
                                  // Customer Selection
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'CUSTOMER',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            if (billingState.selectedCustomer != null)
                                              TextButton(
                                                onPressed: () => context.read<BillingBloc>().add(DeselectCustomerEvent()),
                                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                                child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (billingState.selectedCustomer == null)
                                          InkWell(
                                            onTap: () {
                                              _showCustomerSelector(context);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: borderColor),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.person_add_outlined, size: 20, color: Color(0xFF1E3A8A)),
                                                  SizedBox(width: 12),
                                                  Text('Select or Add Customer', style: TextStyle(color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              backgroundColor: const Color(0xFFEEF2FF),
                                              child: Text(
                                                billingState.selectedCustomer!.name[0].toUpperCase(),
                                                style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            title: Text(billingState.selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text('${billingState.selectedCustomer!.phone} • ${billingState.selectedCustomer!.points} Points'),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Table
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Table(
                                        border: const TableBorder(
                                          horizontalInside:
                                          BorderSide(color: borderColor),
                                          bottom: BorderSide(color: borderColor),
                                        ),
                                        children: [
                                          // Header row
                                          TableRow(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF8FAFC),
                                              border: Border(
                                                  bottom:
                                                  BorderSide(color: borderColor)),
                                            ),
                                            children: [
                                              _buildHeaderCell(
                                                  'Product Name', TextAlign.left),
                                              _buildHeaderCell(
                                                  'Price', TextAlign.right),
                                              _buildHeaderCell(
                                                  'Total', TextAlign.right),
                                            ],
                                          ),
                                          // Items rows
                                          ...billingState.cartItems.map((item) {
                                            return TableRow(
                                              children: [
                                                _buildDataCell(
                                                  '${item.quantity} x ${item.product.name}',
                                                  TextAlign.left,
                                                ),
                                                _buildDataCell(
                                                    '₹${item.product.price.toStringAsFixed(2)}',
                                                    TextAlign.right,
                                                    isSubtitle: true),
                                                _buildDataCell(
                                                    '₹${item.total.toStringAsFixed(2)}',
                                                    TextAlign.right,
                                                    isBold: true),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  const SizedBox(
                                      height: 120), // padding for bottom fixed bar
                                ],
                              ),
                            ),
                          ),

                        // Bottom Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(24),
                                right: Radius.circular(24)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    upiId.isNotEmpty
                                        ? Column(
                                      children: [
                                        const Text(
                                          'Scan to Pay',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: 180,
                                          height: 180,
                                          child: PrettyQrView.data(
                                            data:
                                            'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=INR',
                                          ),
                                        ),
                                      ],
                                    )
                                        : const SizedBox.shrink(),
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'GRAND TOTAL',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[400],
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          '₹${billingState.totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PrimaryButton(
                                onPressed: () {
                                  if (shopState is ShopLoaded) {
                                    final items = billingState.cartItems
                                        .map((item) => {
                                              'name': item.product.name,
                                              'qty': item.quantity,
                                              'price': item.product.price,
                                              'total': item.total,
                                              'expiryDate': item.product.expiryDate,
                                            })
                                        .toList();

                                    showDialog(
                                      context: context,
                                      builder: (context) => DigitalReceiptDialog(
                                        shopName: shopState.shop.name,
                                        address1: shopState.shop.addressLine1,
                                        address2: shopState.shop.addressLine2,
                                        phone: shopState.shop.phoneNumber,
                                        total: billingState.totalAmount,
                                        items: items,
                                        footer: shopState.shop.footerText,
                                        isPaid: _isPaid,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                            Text('Shop details not loaded'),
                                            backgroundColor: Colors.red));
                                  }
                                },
                                label: 'Preview & Complete',
                                icon: Icons.visibility_outlined,
                                backgroundColor: const Color(0xFF1E293B),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isPaid = true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _isPaid ? const Color(0xFF22C55E) : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: _isPaid ? const Color(0xFF22C55E) : Colors.grey[300]!),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'PAID',
                                              style: TextStyle(
                                                color: _isPaid ? Colors.white : Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _isPaid = false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: !_isPaid ? const Color(0xFFEF4444) : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: !_isPaid ? const Color(0xFFEF4444) : Colors.grey[300]!),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'UNPAID',
                                              style: TextStyle(
                                                color: !_isPaid ? Colors.white : Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              PrimaryButton(
                                onPressed: () {
                                  if (shopState is ShopLoaded) {
                                    context.read<BillingBloc>().add(
                                        PrintReceiptEvent(
                                            shopName: shopState.shop.name,
                                            address1: shopState.shop.addressLine1,
                                            address2: shopState.shop.addressLine2,
                                            phone: shopState.shop.phoneNumber,
                                            footer: shopState.shop.footerText,
                                            isPaid: _isPaid));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                            Text('Shop details not loaded'),
                                            backgroundColor: Colors.red));
                                  }
                                },
                                label: 'Print Receipt',
                                icon: Icons.print,
                                isLoading: billingState.isPrinting,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  });
            },
          ),
        ));
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
        ),
      ),
    );
  }
}
