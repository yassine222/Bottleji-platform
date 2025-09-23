class ServerConfig {
  // Change this IP address when you need to connect to a different server
  static const String serverIp = '172.20.10.12';
  static const String serverPort = '3000';
  
  // Base URLs - these are automatically generated from the IP and port above
  static String get serverUrl => 'http://$serverIp:$serverPort';
  static String get apiBaseUrl => '$serverUrl/api';
  
  // Socket URL for real-time notifications
  static String get socketUrl => serverUrl;
}
