import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/server_config.dart';

class PhoneVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Debug mode flag - set to true to bypass Firebase Auth for testing
  static const bool _debugMode = true; // Enable debug mode to bypass reCAPTCHA issues
  
  // Email verification mode flag - disabled for phone verification context
  static const bool _useEmailVerification = false;
  
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
      
      print('🔍 PhoneVerificationService: Sending SMS to $formattedPhone');
      print('🔍 PhoneVerificationService: Starting verification for: $formattedPhone');
      
      // Debug mode - bypass Firebase Auth for testing
      if (_debugMode) {
        print('🔍 PhoneVerificationService: DEBUG MODE - Bypassing Firebase Auth');
        print('🔍 PhoneVerificationService: DEBUG MODE - Bypassing Firebase verification');
        
        // Simulate SMS sent
        await Future.delayed(const Duration(milliseconds: 1000));
        onCodeSent('debug-verification-id');
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
          print('🔍 PhoneVerificationService: Verification failed: ${e.message}');
          String errorMessage = 'SMS verification failed';
          
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many SMS requests. Please try again later.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please contact support.';
              break;
            default:
              errorMessage = 'SMS verification failed: ${e.message ?? 'Unknown error'}';
          }
          
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) async {
          print('🔍 PhoneVerificationService: SMS code sent successfully!');
          print('🔍 PhoneVerificationService: VerificationId: $verificationId');
          print('🔍 PhoneVerificationService: ResendToken: $resendToken');
          
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
      
      // Debug mode - bypass Firebase Auth for testing
      if (_debugMode) {
        print('🔍 PhoneVerificationService: DEBUG MODE - Bypassing Firebase verification');
        print('🔍 PhoneVerificationService: Debug verification - Code: $smsCode');
        
        if (smsCode == '847293') {
          print('🔍 PhoneVerificationService: Debug verification successful with code: $smsCode');
          return await _verifyWithBackend(phoneNumber, 'debug-firebase-token');
        } else {
          print('🔍 PhoneVerificationService: Debug verification failed - Invalid code: $smsCode');
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

            // Verify with backend
            bool backendVerification = await _verifyWithBackend(phoneNumber, firebaseToken);
            
            if (backendVerification) {
              // Clear stored verification data
              await prefs.remove('firebase_verification_id');
              await prefs.remove('firebase_resend_token');
            }
            
            return backendVerification;
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

