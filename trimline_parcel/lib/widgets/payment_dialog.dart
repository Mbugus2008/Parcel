import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/parcel_model.dart';

/// Reusable payment dialog extracted from `parcel_dashboard_page.dart`.
/// Call `await showPaymentDialog(context, parcel);` from any page.
Future<void> showPaymentDialog(BuildContext context, Parcel parcel) async {
  final amountController =
      TextEditingController(text: parcel.Amount_Paid?.toString() ?? '');
  final phoneController = TextEditingController(
      text: parcel.Status == ParcelStatus.pending
          ? parcel.Sender_Phone ?? ''
          : parcel.Receiver_Phone ?? '');
  String? selectedMethod;

  Future<String?> _generateQrCode(String amount, String refNo) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://api.safaricom.co.ke/mpesa/qrcode/v1/generate'), // Replace with actual API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "MerchantName": "Parcel Service",
          "RefNo": refNo,
          "Amount": double.tryParse(amount) ?? 0,
          "TrxCode": "BG",
          "CPI": "174379", // Replace with actual CPI
          "Size": "300"
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['QRCode'];
      } else {
        throw Exception('Failed to generate QR');
      }
    } catch (e) {
      throw e;
    }
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // 💙 blueish border
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.6),
              width: 1.5,
            ),
            // soft shadow for "floating" effect
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              bool isLoadingQr = false;
              String? qrCodeBase64;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Make Payment',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    style: const TextStyle(color: Colors.black),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: 'Enter amount to pay',
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelStyle: TextStyle(color: Colors.black),
                      hintStyle: TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Color(0x14000000),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0x33000000)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0x2E000000)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0x66000000)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Request Mpesa',
                        style: TextStyle(color: Colors.black)),
                    value: 'mpesa',
                    groupValue: selectedMethod,
                    onChanged: (value) =>
                        setState(() => selectedMethod = value),
                  ),
                  RadioListTile<String>(
                    title: const Text('Scan to pay',
                        style: TextStyle(color: Colors.black)),
                    value: 'scan',
                    groupValue: selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedMethod = value;
                        if (value == 'scan') {
                          isLoadingQr = true;
                          _generateQrCode(amountController.text,
                                  parcel.Document_No ?? 'Unknown')
                              .then((code) {
                            setState(() {
                              qrCodeBase64 = code;
                              isLoadingQr = false;
                            });
                          }).catchError((e) {
                            setState(() {
                              isLoadingQr = false;
                            });
                            Get.snackbar('Error', 'Failed to generate QR code',
                                snackPosition: SnackPosition.BOTTOM);
                          });
                        } else {
                          qrCodeBase64 = null;
                          isLoadingQr = false;
                        }
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Cash',
                        style: TextStyle(color: Colors.black)),
                    value: 'cash',
                    groupValue: selectedMethod,
                    onChanged: (value) =>
                        setState(() => selectedMethod = value),
                  ),
                  const SizedBox(height: 16),
                  if (selectedMethod == 'mpesa') ...[
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: Colors.black),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter Mpesa phone number',
                        labelStyle: TextStyle(color: Colors.black),
                        floatingLabelStyle: TextStyle(color: Colors.black),
                        hintStyle: TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Color(0x14000000),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0x33000000)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0x2E000000)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0x66000000)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (selectedMethod == 'scan') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Scan QR Code to Pay',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          if (isLoadingQr)
                            const CircularProgressIndicator()
                          else if (qrCodeBase64 != null)
                            Image.memory(base64Decode(qrCodeBase64!),
                                width: 150, height: 150)
                          else
                            const Text('Failed to load QR code',
                                style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final amount = amountController.text.trim();
                          final phone = phoneController.text.trim();
                          if (amount.isEmpty ||
                              double.tryParse(amount) == null ||
                              selectedMethod == null ||
                              (selectedMethod == 'mpesa' && phone.isEmpty)) {
                            Get.snackbar(
                              'Validation Error',
                              selectedMethod == 'mpesa' && phone.isEmpty
                                  ? 'Please enter phone number for Mpesa.'
                                  : 'Please enter a valid amount and select a payment method.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor:
                                  Colors.redAccent.withValues(alpha: 0.9),
                              colorText: Colors.white,
                            );
                            return;
                          }
                          Navigator.of(dialogContext).pop();
                          // Here you can add payment logic
                          Get.snackbar(
                            'Payment',
                            'Payment of $amount via $selectedMethod${selectedMethod == 'mpesa' ? ' ($phone)' : ''} processed.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor:
                                Colors.green.withValues(alpha: 0.9),
                            colorText: Colors.white,
                          );
                        },
                        child: const Text('Pay'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );

  // Dispose dialog-local controllers
  try {
    amountController.dispose();
    phoneController.dispose();
  } catch (_) {}
}
