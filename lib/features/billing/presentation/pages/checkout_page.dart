import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/domain/entities/customer.dart';
import '../bloc/billing_bloc.dart';
import '../widgets/customer_picker_bottom_sheet.dart';
import '../widgets/digital_receipt_dialog.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isPaid = true;

  void _showCustomerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerPickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Checkout',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            leading: IconButton(
              icon: Icon(Icons.chevron_left_rounded,
                  size: 28, color: AppTheme.primaryColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          backgroundColor: const Color(0xFFF8FAFC),
          body: BlocConsumer<BillingBloc, BillingState>(
            listener: (context, state) {
              if (state.printSuccess) {
                // Navigate back to the very start of the billing flow
                context.go('/');
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

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for FAB/Buttons
                      child: Column(
                        children: [
                          // 1. Customer Selection
                          _buildCustomerSection(context, billingState),
                          const SizedBox(height: 20),

                          // 2. Order Summary Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'ORDER SUMMARY',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Product Table
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Table(
                                border: const TableBorder(
                                  horizontalInside: BorderSide(color: borderColor),
                                ),
                                children: [
                                  // Header row
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8FAFC),
                                      border: Border(bottom: BorderSide(color: borderColor)),
                                    ),
                                    children: [
                                      _buildHeaderCell('Product', TextAlign.left),
                                      _buildHeaderCell('Price', TextAlign.right),
                                      _buildHeaderCell('Total', TextAlign.right),
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
                                          isSubtitle: true,
                                        ),
                                        _buildDataCell(
                                          '₹${item.total.toStringAsFixed(2)}',
                                          TextAlign.right,
                                          isBold: true,
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 4. Payment Status (Paid/Unpaid)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.payments_rounded, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'PAYMENT STATUS',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPaymentStatusButton(
                                  'PAID',
                                  _isPaid,
                                  const Color(0xFF22C55E),
                                  () => setState(() => _isPaid = true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPaymentStatusButton(
                                  'UNPAID',
                                  !_isPaid,
                                  const Color(0xFFEF4444),
                                  () => setState(() => _isPaid = false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 5. Scan & Pay Section (QR)
                          if (upiId.isNotEmpty && _isPaid) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SCAN TO PAY',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 15,
                                        )
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: 180,
                                      height: 180,
                                      child: PrettyQrView.data(
                                        data: 'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=INR',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Scan this QR with any UPI app',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 6. Grand Total
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E293B).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GRAND TOTAL',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.6),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Inclusive of all taxes',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₹${billingState.totalAmount.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          // 7. Primary Action
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
                                    customerName: billingState.selectedCustomer?.name,
                                    customerPhone: billingState.selectedCustomer?.phone,
                                    upiId: upiId,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Shop details not loaded'),
                                        backgroundColor: Colors.red));
                              }
                            },
                            label: 'Save & Preview Receipt',
                            icon: Icons.receipt_long_rounded,
                            backgroundColor: const Color(0xFF1E293B),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  });
            },
          ),
        ));
  }

  Widget _buildPaymentStatusButton(String text, bool isSelected, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? activeColor : Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection(BuildContext context, BillingState state) {
    final hasCustomer = state.selectedCustomer != null;
    final potentialPoints = (state.totalAmount / 100).floor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUSTOMER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 1,
                ),
              ),
              if (hasCustomer)
                GestureDetector(
                  onTap: () => context.read<BillingBloc>().add(DeselectCustomerEvent()),
                  child: Text(
                    'Remove',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasCustomer)
            _buildSelectedCustomerTile(context, state.selectedCustomer!, potentialPoints)
          else
            _buildLinkCustomerTile(context, potentialPoints),
        ],
      ),
    );
  }

  Widget _buildSelectedCustomerTile(BuildContext context, Customer customer, int potentialPoints) {
    return InkWell(
      onTap: () => _showCustomerPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${customer.phone} • ${customer.points} Points',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (potentialPoints > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+$potentialPoints',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFD97706),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinkCustomerTile(BuildContext context, int potentialPoints) {
    return InkWell(
      onTap: () => _showCustomerPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select or Add Customer',
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            if (potentialPoints > 0)
              Text(
                'Earn $potentialPoints pts',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: GoogleFonts.inter(
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
        style: GoogleFonts.inter(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
