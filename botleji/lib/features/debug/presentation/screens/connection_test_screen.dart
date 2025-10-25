import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:botleji/core/config/server_config.dart';
import 'package:botleji/core/services/network_initialization_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  String _testResults = '';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _runConnectionTests();
  }

  Future<void> _runConnectionTests() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Starting connection tests...\n\n';
    });

    try {
      // Test 1: Check network initialization
      _testResults += '1. Network Initialization Status:\n';
      final networkStatus = NetworkInitializationService.getNetworkStatus();
      _testResults += '   Initialized: ${networkStatus['initialized']}\n';
      _testResults += '   Server URL: ${networkStatus['serverUrl']}\n';
      _testResults += '   API URL: ${networkStatus['apiUrl']}\n';
      _testResults += '   Detected IP: ${networkStatus['detectedIp']}\n\n';

      // Test 2: Test server configuration
      _testResults += '2. Server Configuration:\n';
      _testResults += '   Sync API URL: ${ServerConfig.apiBaseUrlSync}\n';
      _testResults += '   Current Detected IP: ${ServerConfig.currentDetectedIp}\n\n';

      // Test 3: Test basic connectivity
      _testResults += '3. Basic Connectivity Test:\n';
      final dio = Dio();
      try {
        final response = await dio.get(
          '${ServerConfig.apiBaseUrlSync}/auth/profile',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        _testResults += '   ✅ Connection successful!\n';
        _testResults += '   Status Code: ${response.statusCode}\n';
        _testResults += '   Response: ${response.data}\n\n';
      } catch (e) {
        _testResults += '   ❌ Connection failed: $e\n\n';
      }

      // Test 4: Test login endpoint
      _testResults += '4. Login Endpoint Test:\n';
      try {
        final response = await dio.post(
          '${ServerConfig.apiBaseUrlSync}/auth/login',
          data: {
            'email': 'test@example.com',
            'password': 'testpassword',
          },
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        _testResults += '   ✅ Login endpoint accessible!\n';
        _testResults += '   Status Code: ${response.statusCode}\n';
        _testResults += '   Response: ${response.data}\n\n';
      } catch (e) {
        _testResults += '   ❌ Login endpoint failed: $e\n\n';
      }

      // Test 5: Test with different IPs
      _testResults += '5. Testing Different IPs:\n';
      final testIPs = [
        'localhost',
        '127.0.0.1',
        '192.168.1.100',
        '192.168.0.100',
        '10.0.0.100',
      ];

      for (final ip in testIPs) {
        try {
          final testUrl = 'http://$ip:3000/api/auth/profile';
          _testResults += '   Testing $testUrl...\n';
          
          final response = await dio.get(
            testUrl,
            options: Options(
              sendTimeout: const Duration(seconds: 2),
              receiveTimeout: const Duration(seconds: 2),
            ),
          );
          _testResults += '   ✅ $ip works! Status: ${response.statusCode}\n';
        } catch (e) {
          _testResults += '   ❌ $ip failed: ${e.toString().split('\n')[0]}\n';
        }
      }

    } catch (e) {
      _testResults += '❌ Test failed: $e\n';
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isTesting ? null : _runConnectionTests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isTesting) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
            Text(
              _testResults,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isTesting ? null : _runConnectionTests,
              child: const Text('Run Tests Again'),
            ),
          ],
        ),
      ),
    );
  }
}
