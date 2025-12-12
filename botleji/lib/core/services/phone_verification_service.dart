import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/server_config.dart';

class PhoneVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Debug mode flag - DISABLED: Now using real Firebase Phone Auth for SMS delivery
  // Set to false to always use Firebase Phone Auth (production mode)
  static bool get _debugMode => false; // Disabled - always use real Firebase Phone Auth
  
  // Send SMS verification code
  static Future<void> sendSMSVerification({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    required VoidCallback onTimeout,
  }) async {

    try {
      // Check if Firebase Auth is initialized and wait if needed
      int retryCount = 0;
      while (_auth.app == null && retryCount < 5) {
        print('🔍 PhoneVerificationService: Firebase Auth not ready, waiting... (attempt ${retryCount + 1})');
        await Future.delayed(const Duration(milliseconds: 2000));
        retryCount++;
      }
      
      if (_auth.app == null) {
        print('🔍 PhoneVerificationService: Firebase Auth not initialized after retries');
        onError('Firebase Auth not initialized. Please restart the app completely.');
        return;
      }
      
      // Additional delay to ensure Firebase Auth is fully ready
      print('🔍 PhoneVerificationService: Firebase Auth ready, waiting additional 2 seconds...');
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Format phone number to international format
      String formattedPhone = _formatPhoneNumber(phoneNumber);
      
      print('🔍 PhoneVerificationService: Original phone number: $phoneNumber');
      print('🔍 PhoneVerificationService: Formatted phone number: $formattedPhone');
      print('🔍 PhoneVerificationService: Phone number length: ${formattedPhone.length}');
      print('🔍 PhoneVerificationService: Starting verification for: $formattedPhone');
      
      // Debug mode - bypass Firebase Auth for testing (iOS only)
      if (_debugMode) {
        print('🔍 PhoneVerificationService: DEBUG MODE (iOS) - Bypassing Firebase Auth');
        print('🔍 PhoneVerificationService: iOS Debug - Use OTP: 123456 or 847293');
        
        // Simulate SMS sent
        await Future.delayed(const Duration(milliseconds: 1000));
        onCodeSent('ios-debug-verification-id');
        return;
      }

      // iOS-specific configuration
      if (Platform.isIOS) {
        print('🔍 PhoneVerificationService: iOS detected, configuring Firebase Auth...');
        await Future.delayed(const Duration(milliseconds: 1000));
        print('🔍 PhoneVerificationService: Firebase Auth configured for iOS');
        
        // For iOS, we need to handle reCAPTCHA differently
        // Try to use app verification first, fallback to reCAPTCHA if needed
      }

      print('🔍 PhoneVerificationService: About to call verifyPhoneNumber...');
      
      // Send SMS verification
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🔍 PhoneVerificationService: Auto-verification completed');
          try {
            await _auth.signInWithCredential(credential);
            final user = _auth.currentUser;
            if (user != null) {
              final idToken = await user.getIdToken();
              if (idToken != null) {
                await _verifyWithBackend(phoneNumber, idToken);
                onCodeSent('auto-verified');
              } else {
                onError('Failed to get authentication token');
              }
            }
          } catch (e) {
            print('🔍 PhoneVerificationService: Auto-verification error: $e');
            onError('Auto-verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ PhoneVerificationService: Verification failed!');
          print('❌ PhoneVerificationService: Error code: ${e.code}');
          print('❌ PhoneVerificationService: Error message: ${e.message}');
          print('❌ PhoneVerificationService: Full error: $e');
          String errorMessage = 'SMS verification failed';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format. Please check the number and try again.';
              print('❌ PhoneVerificationService: Phone number format is invalid');
              break;
            case 'too-many-requests':
              errorMessage = 'Too many SMS requests. Please try again later.';
              print('❌ PhoneVerificationService: Rate limit exceeded - too many requests');
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please contact support or check Firebase Console billing.';
              print('❌ PhoneVerificationService: SMS quota exceeded - check Firebase Console');
              break;
            case 'missing-phone-number':
              errorMessage = 'Phone number is required.';
              print('❌ PhoneVerificationService: Phone number is missing');
              break;
            default:
              errorMessage = 'SMS verification failed: ${e.message ?? 'Unknown error'}';
              print('❌ PhoneVerificationService: Unknown error code: ${e.code}');
          }
          
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) async {
          print('✅ PhoneVerificationService: SMS code sent successfully!');
          print('✅ PhoneVerificationService: VerificationId: $verificationId');
          print('✅ PhoneVerificationService: ResendToken: $resendToken');
          print('✅ PhoneVerificationService: SMS should arrive shortly on: $formattedPhone');
          print('✅ PhoneVerificationService: If SMS doesn\'t arrive, check:');
          print('   1. Phone number is correct: $formattedPhone');
          print('   2. Carrier/SMS service is working');
          print('   3. Firebase Console → Authentication → Users for delivery status');
          print('   4. Firebase Console → Usage and Billing for SMS quota');
          
          // Store verification ID for later use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('firebase_verification_id', verificationId);
          if (resendToken != null) {
            await prefs.setInt('firebase_resend_token', resendToken);
          }
          
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('🔍 PhoneVerificationService: SMS auto-retrieval timeout');
          onTimeout();
        },
        timeout: const Duration(seconds: 300), // 5 minutes timeout
      );
    } catch (e) {
      print('🔍 PhoneVerificationService: Error sending SMS: $e');
      onError('Failed to send SMS: $e');
    }
  }





  // Verify SMS code
  static Future<bool> verifySMSCode(String phoneNumber, String smsCode) async {
    try {
      print('🔍 PhoneVerificationService: Verifying code: $smsCode for phone: $phoneNumber');
      
      // Debug mode - bypass Firebase Auth for testing (iOS only)
      if (_debugMode) {
        print('🔍 PhoneVerificationService: DEBUG MODE (iOS) - Bypassing Firebase verification');
        print('🔍 PhoneVerificationService: Debug verification - Code: $smsCode');
        
        // Hardcoded OTP for iOS testing
        if (smsCode == '123456' || smsCode == '847293') {
          print('🔍 PhoneVerificationService: Debug verification successful with code: $smsCode');
          
          // Store a debug Firebase token for phone sign-in/signup
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('firebase_phone_auth_token', 'ios-debug-token-${DateTime.now().millisecondsSinceEpoch}');
          
          // For phone sign-in/signup (not logged in yet), just return true
          final authToken = prefs.getString('auth_token');
          if (authToken == null || authToken.isEmpty) {
            print('🔍 PhoneVerificationService: iOS Debug - User not logged in, returning true for sign-in/signup');
            return true;
          }
          
          // For existing logged-in users updating phone, verify with backend
          return await _verifyWithBackend(phoneNumber, 'ios-debug-token');
        } else {
          print('🔍 PhoneVerificationService: Debug verification failed - Invalid code: $smsCode');
          print('🔍 PhoneVerificationService: iOS Debug - Use OTP: 123456 or 847293');
          return false;
        }
      }



      // Regular Firebase SMS verification
      try {
        // Get stored verification ID
        final prefs = await SharedPreferences.getInstance();
        final verificationId = prefs.getString('firebase_verification_id');
        
        if (verificationId == null) {
          print('🔍 PhoneVerificationService: No verification ID found. Please send SMS again.');
          return false;
        }

        print('🔍 PhoneVerificationService: Using stored verification ID: $verificationId');
        
        // Create credential with SMS code
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );

        // Sign in with credential
        UserCredential userCredential = await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          // Get Firebase token
          String? firebaseToken = await user.getIdToken();
          if (firebaseToken != null) {
            print('🔍 PhoneVerificationService: Firebase verification successful');
            print('🔍 PhoneVerificationService: Auth token found: YES');
            print('🔍 PhoneVerificationService: Auth token length: ${firebaseToken.length}');
            print('🔍 PhoneVerificationService: Auth token preview: ${firebaseToken.substring(0, 50)}...');

            // Store Firebase token for phone sign-in/signup
            await prefs.setString('firebase_phone_auth_token', firebaseToken);

            // Check if user is already logged in (has auth token)
            final authToken = prefs.getString('auth_token');
            if (authToken != null && authToken.isNotEmpty) {
              // User is logged in - verify with backend (existing user updating phone)
              bool backendVerification = await _verifyWithBackend(phoneNumber, firebaseToken);
              
              if (backendVerification) {
                // Clear stored verification data
                await prefs.remove('firebase_verification_id');
                await prefs.remove('firebase_resend_token');
              }
              
              return backendVerification;
            } else {
              // User is not logged in - this is for sign-in/signup
              // Just return true, token is stored for phoneLogin/phoneSignup to use
              return true;
            }
          } else {
            print('🔍 PhoneVerificationService: Failed to get Firebase token');
            return false;
          }
        } else {
          print('🔍 PhoneVerificationService: Firebase verification failed - No user');
          return false;
        }
      } catch (e) {
        print('🔍 PhoneVerificationService: Firebase verification error: $e');
        return false;
      }
    } catch (e) {
      print('🔍 PhoneVerificationService: Verification error: $e');
      return false;
    }
  }



  // Verify with backend
  static Future<bool> _verifyWithBackend(String phoneNumber, String firebaseToken) async {
    try {
      print('🔍 PhoneVerificationService: Sending verification to backend...');
      
      // Get auth token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      
      if (authToken == null || authToken.isEmpty) {
        print('🔍 PhoneVerificationService: No auth token found');
        return false;
      }
      
      print('🔍 PhoneVerificationService: Auth token found: YES');
      print('🔍 PhoneVerificationService: Auth token length: ${authToken.length}');
      print('🔍 PhoneVerificationService: Auth token preview: ${authToken.substring(0, 50)}...');
      
      final dio = Dio(BaseOptions(
        baseUrl: ServerConfig.apiBaseUrlSync,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ));

      final response = await dio.post('/auth/verify-phone', data: {
        'phoneNumber': phoneNumber,
        'firebaseToken': firebaseToken,
      });

      print('🔍 PhoneVerificationService: URL: ${dio.options.baseUrl}/auth/verify-phone');
      print('🔍 PhoneVerificationService: Phone: $phoneNumber');
      print('🔍 PhoneVerificationService: Token: ${firebaseToken.substring(0, 20)}...');
      print('🔍 PhoneVerificationService: Backend response status: ${response.statusCode}');
      print('🔍 PhoneVerificationService: Backend response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('🔍 PhoneVerificationService: Backend verification successful');
        return true;
      } else {
        print('🔍 PhoneVerificationService: Backend verification failed - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('🔍 PhoneVerificationService: Backend verification error: $e');
      return false;
    }
  }

  // Format phone number to international format
  static String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it already starts with +, return as is
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    
    // If it starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }
    
    // If it's a German number (starts with 49), add +
    if (cleaned.startsWith('49')) {
      return '+$cleaned';
    }
    
    // If it's a Tunisian number (starts with 216), add +
    if (cleaned.startsWith('216')) {
      return '+$cleaned';
    }
    
    // If it starts with 0, assume it's a local number and add country code
    // For now, we'll assume Tunisian (+216) but this could be made configurable
    if (cleaned.startsWith('0')) {
      return '+216${cleaned.substring(1)}';
    }
    
    // If it's 8 digits, assume Tunisian
    if (cleaned.length == 8) {
      return '+216$cleaned';
    }
    
    // If it's 10-11 digits, assume German
    if (cleaned.length >= 10 && cleaned.length <= 11) {
      return '+49$cleaned';
    }
    
    // Default: return as is with +
    return '+$cleaned';
  }

  // Validate phone number format
  static bool isValidPhoneNumber(String phoneNumber) {
    String formatted = _formatPhoneNumber(phoneNumber);
    // Accept any international phone number format
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(formatted);
  }

  // Get formatted phone number for display
  static String getFormattedPhoneNumber(String phoneNumber) {
    String formatted = _formatPhoneNumber(phoneNumber);
    // Format as +216 XX XXX XXX
    if (formatted.startsWith('+216') && formatted.length == 12) {
      String number = formatted.substring(4);
      return '+216 ${number.substring(0, 2)} ${number.substring(2, 5)} ${number.substring(5)}';
    }
    return formatted;
  }
}

