import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../bloc/billing_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DigitalReceiptDialog extends StatelessWidget {
  final String shopName;
  final String address1;
  final String address2;
  final String phone;
  final String footer;
  final double total;
  final List<Map<String, dynamic>> items;
  final bool isPaid;

  const DigitalReceiptDialog({
    super.key,
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
    required this.total,
    required this.items,
    this.isPaid = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenshotController = ScreenshotController();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Screenshot(
            controller: screenshotController,
            child: Container(
              width: 350,
              color: Colors.white, // Ensure white background for screenshot
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24), // Adjusted padding for top icons
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Receipt Header
                  Text(
                    shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(address1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(address2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('PH: $phone', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const Divider(height: 32),
                  
                  // Receipt Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('DATE: ${dateFormat.format(now)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const Text('CASHIER: DEMO', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 32),
    
                  // Cart Items
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('${item['name']}', style: const TextStyle(fontSize: 12)),
                            ),
                            Expanded(
                              child: Text('${item['qty']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                            ),
                            Expanded(
                              child: Text('₹${item['price']}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                            ),
                            Expanded(
                              child: Text('₹${item['total']}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 32),
    
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isPaid ? Colors.green : Colors.red),
                    ),
                    child: Text(
                      isPaid ? 'PAID' : 'UNPAID',
                      style: TextStyle(
                        color: isPaid ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
    
                  Text(footer, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                  const SizedBox(height: 24),
    
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            context.read<BillingBloc>().add(CompleteTransactionEvent(isPaid: isPaid));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction completed digitally!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: const Text('Confirm & Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Top Left Cross Icon
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Top Right Share Icon
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.share, color: Colors.green[700], size: 20),
                onPressed: () async {
                  final image = await screenshotController.capture();
                  if (image != null) {
                    final directory = await getApplicationDocumentsDirectory();
                    final imagePath = await File('${directory.path}/receipt.png').create();
                    await imagePath.writeAsBytes(image);
                    
                    await Share.shareXFiles([XFile(imagePath.path)], text: 'Receipt from $shopName');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
