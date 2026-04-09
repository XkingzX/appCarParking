import 'package:flutter/material.dart';

class ScannerPage extends StatelessWidget {
  final bool isCheckIn;
  
  const ScannerPage({Key? key, required this.isCheckIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isCheckIn ? 'Quét xe vào' : 'Quét xe ra'),
        backgroundColor: isCheckIn ? Colors.blue : Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            // Placeholder cho widget mobile_scanner
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text('Camera đang hoạt động...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hoặc', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Nhập mã vé thủ công
                      },
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Nhập mã vé thủ công'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
