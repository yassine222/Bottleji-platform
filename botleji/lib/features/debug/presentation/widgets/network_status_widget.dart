import 'package:flutter/material.dart';
import 'package:botleji/core/services/network_initialization_service.dart';
import 'package:botleji/core/config/server_config.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({super.key});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  Map<String, dynamic>? _networkStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNetworkStatus();
  }

  void _loadNetworkStatus() {
    setState(() {
      _networkStatus = NetworkInitializationService.getNetworkStatus();
      _isLoading = false;
    });
  }

  Future<void> _refreshNetwork() async {
    setState(() {
      _isLoading = true;
    });
    
    await NetworkInitializationService.reinitialize();
    _loadNetworkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Network Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _refreshNetwork,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_networkStatus != null) ...[
              _buildStatusRow('Server URL', _networkStatus!['serverUrl'] ?? 'Not detected'),
              _buildStatusRow('API URL', _networkStatus!['apiUrl'] ?? 'Not detected'),
              _buildStatusRow('Detected IP', _networkStatus!['detectedIp'] ?? 'Not detected'),
              _buildStatusRow('Auto Detection', _networkStatus!['useAutoDetection'] ? 'Enabled' : 'Disabled'),
              _buildStatusRow('Tunnel Mode', _networkStatus!['useTunnel'] ? 'Enabled' : 'Disabled'),
              _buildStatusRow('Initialized', _networkStatus!['initialized'] ? 'Yes' : 'No'),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Configuration:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Auto Detection: Automatically finds the best IP address\n'
              '• Tunnel Mode: Uses Cloudflare tunnel for remote access\n'
              '• Fallback: Uses localhost if detection fails',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
