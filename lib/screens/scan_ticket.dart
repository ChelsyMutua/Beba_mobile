import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({super.key});

  @override
  _ScanTicketScreenState createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedResult;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController qrController) {
    setState(() {
      controller = qrController;
    });

    controller?.scannedDataStream.listen((scanData) {
      setState(() {
        scannedResult = scanData.code;
      });

      if (scannedResult != null) {
        Navigator.pop(context, scannedResult); // Close modal after scanning
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.9, // Almost full-screen modal
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
                ),
                Image.asset(
                  "assets/images/qr_frame.png", // Custom QR frame overlay
                  width: 200,
                ),
              ],
            ),
          ),
          // Slider(
          //   value: 1.0,
          //   min: 0.5,
          //   max: 1.5,
          //   onChanged: (value) {
          //     controller?.setZoomFactor(value);
          //   },
          // ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30), // Moves button up
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Custom button color
                foregroundColor: Colors.white, // Text color
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
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
