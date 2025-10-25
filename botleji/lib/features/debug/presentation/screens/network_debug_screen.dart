import 'package:flutter/material.dart';
import 'package:botleji/core/services/network_initialization_service.dart';
import 'package:botleji/core/config/server_config.dart';

class NetworkDebugScreen extends StatefulWidget {
  const NetworkDebugScreen({super.key});

  @override
  State<NetworkDebugScreen> createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends State<NetworkDebugScreen> {
  Map<String, dynamic>? _networkStatus;

  @override
  void initState() {
    super.initState();
    _loadNetworkStatus();
  }

  void _loadNetworkStatus() {
    setState(() {
      _networkStatus = NetworkInitializationService.getNetworkStatus();
    });
  }

  Future<void> _reinitializeNetwork() async {
    await NetworkInitializationService.reinitialize();
    _loadNetworkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Network Configuration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _reinitializeNetwork,
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_networkStatus != null) ...[
              _buildInfoCard('Server URL', _networkStatus!['serverUrl'] ?? 'Not detected'),
              const SizedBox(height: 10),
              _buildInfoCard('API URL', _networkStatus!['apiUrl'] ?? 'Not detected'),
              const SizedBox(height: 10),
              _buildInfoCard('Detected IP', _networkStatus!['detectedIp'] ?? 'Not detected'),
              const SizedBox(height: 10),
              _buildInfoCard('Auto Detection', _networkStatus!['useAutoDetection'] ? 'Enabled' : 'Disabled'),
              const SizedBox(height: 10),
              _buildInfoCard('Tunnel Mode', _networkStatus!['useTunnel'] ? 'Enabled' : 'Disabled'),
              const SizedBox(height: 10),
              _buildInfoCard('Initialized', _networkStatus!['initialized'] ? 'Yes' : 'No'),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Loading network status...'),
            ],
            const SizedBox(height: 30),
            const Text(
              'Configuration Options:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Auto Detection: Automatically finds the best IP address\n'
              '• Tunnel Mode: Uses Cloudflare tunnel for remote access\n'
              '• Fallback: Uses localhost if detection fails',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$title:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
