class ServerConfig {
  // Development mode: use tunnel for fast connection, local IP for slow WiFi
  static const bool useTunnel = false; // Set to false if you want to use local IP
  
  // Cloudflare tunnel URL (fast, reliable)
  static const String tunnelUrl = 'https://circuits-institutions-holds-axis.trycloudflare.com';
  
  // Local network IP (slow WiFi fallback)
  static const String serverIp = '172.20.10.12';
  static const String serverPort = '3000';
  
  // Base URLs - choose based on useTunnel flag
  static String get serverUrl => useTunnel ? tunnelUrl : 'http://$serverIp:$serverPort';
  static String get apiBaseUrl => '$serverUrl/api';
  
  // Socket URL for real-time notifications
  static String get socketUrl => serverUrl;
}
