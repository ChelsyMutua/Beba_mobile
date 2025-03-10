import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({super.key});

  @override
  _ScanTicketScreenState createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose(); // Properly release camera
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrController) {
    if (controller == null) {
      setState(() {
        controller = qrController;
      });

      // Reduce delay for a faster start
      Future.delayed(const Duration(milliseconds: 200), () {
        controller!.resumeCamera();
      });

      controller!.scannedDataStream.listen((scanData) async {
        if (scanData.code != null) {
          controller!.pauseCamera(); // Pause camera to prevent double scans

          await _processScannedData(scanData.code!);

          // Reduce resume delay for faster scanning
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              controller!.resumeCamera();
            }
          });
        }
      });
    }
  }

  void _showMessage(String message) {
  debugPrint("📢 Log: $message");

  // Show message in the UI using SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: message.startsWith("✅") ? Colors.green : Colors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}

  void _closeModal() {
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      Navigator.pop(context);
    }
  });
}
Future<void> _processScannedData(String scannedData) async {
  try {
    debugPrint("📢 Raw Scanned Data: $scannedData");

    final Map<String, dynamic> qrData = jsonDecode(scannedData);
    final String orderId = qrData['order_id'].toString();
    final String ticketId = qrData['ticket_id'].toString();

    debugPrint("✅ Extracted Order ID: $orderId");
    debugPrint("✅ Extracted Ticket ID: $ticketId");

    final response = await http.patch(
      Uri.parse("https://backendcode-production-6e08.up.railway.app/api/orders/scan-ticket"),
      headers: {
        "Content-Type": "application/json",
        "x-api-key": "34a17966ce9f9a7f8b27ef35007c57051660ce144ab919b768a65e5aea26fb17",
      },
      body: jsonEncode({
        "order_id": orderId,
        "ticket_id": ticketId,
      }),
    );

    debugPrint("⏱️  API Response Status: ${response.statusCode}");
    debugPrint("⏱️  API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      // ✅ Ticket scanned successfully → Show message & close modal
      final responseBody = jsonDecode(response.body);
      _showMessage("✅ ${responseBody['message']}");
      _closeModal();
    } else if (response.statusCode == 400) {
      // ❌ Ticket already used → Show message & close modal
      final responseBody = jsonDecode(response.body);
      if (responseBody['message'] == "This ticket has already been used!") {
        _showMessage("❌ This ticket has already been used!");
        _closeModal();
      } else {
        _showMessage("❌ Error: ${responseBody['message']}");
      }
    } else {
      _showMessage("❌ Unexpected error occurred.");
    }
  } catch (e) {
    _showMessage("❌ Error scanning ticket: $e");
    debugPrint("🚨 Error details: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // Almost full-screen modal
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Align the QR code within the frame to scan",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  // Set a faster auto focus interval if supported
                  // (Check your plugin version and documentation for exact usage)
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.green,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: MediaQuery.of(context).size.width * 0.75,
                  ),
                  // You might be able to pass autoFocusInterval here if supported:
                  // autoFocusInterval: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Cancel Scanning",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
