import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  print('🔍 Testing Authentication State...');
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check all auth-related keys
    final token = prefs.getString('auth_token');
    final authData = prefs.getString('auth_data');
    final isLoggedIn = prefs.getBool('is_logged_in');
    
    print('📱 SharedPreferences Auth State:');
    print('   Token: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');
    print('   Auth Data: ${authData != null ? 'Present' : 'null'}');
    print('   Is Logged In: $isLoggedIn');
    
    if (authData != null) {
      try {
        final userData = jsonDecode(authData);
        print('   User ID: ${userData['id']}');
        print('   User Email: ${userData['email']}');
        print('   User Roles: ${userData['roles']}');
        print('   Is Profile Complete: ${userData['isProfileComplete']}');
      } catch (e) {
        print('   Error parsing auth data: $e');
      }
    }
    
    // Check if token is valid format
    if (token != null) {
      print('   Token Format: ${token.startsWith('eyJ') ? 'Valid JWT' : 'Invalid format'}');
      print('   Token Length: ${token.length}');
    }
    
    // List all keys in SharedPreferences
    print('\n📋 All SharedPreferences Keys:');
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.contains('auth') || key.contains('token') || key.contains('user')) {
        final value = prefs.get(key);
        print('   $key: ${value != null ? 'Present' : 'null'}');
      }
    }
    
  } catch (e) {
    print('❌ Error testing auth state: $e');
  }
}
