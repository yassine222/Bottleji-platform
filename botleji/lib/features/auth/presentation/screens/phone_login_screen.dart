import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../providers/auth_provider.dart';
import 'package:botleji/core/services/phone_verification_service.dart';
import 'package:botleji/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:botleji/features/home/presentation/screens/home_screen.dart';
import 'package:botleji/l10n/app_localizations.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  
  String? _verificationId;
  String _countryCode = '+1'; // Default country code
  String _completePhoneNumber = '';
  bool _isCodeSent = false;
  bool _isLoading = false;
  bool _isSendingSMS = false;
  bool _isVerifyingCode = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendSMS() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSendingSMS = true;
    });

    try {
      // Use the complete phone number with country code
      final phoneNumber = _completePhoneNumber.isNotEmpty 
          ? _completePhoneNumber 
          : '$_countryCode${_phoneController.text.trim()}';
      
      await PhoneVerificationService.sendSMSVerification(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isCodeSent = true;
            _isSendingSMS = false;
            _resendCountdown = 60;
          });
          _startResendTimer();
        },
        onError: (error) {
          setState(() {
            _isSendingSMS = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onTimeout: () {
          setState(() {
            _isSendingSMS = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isSendingSMS = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    if (_smsCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseEnterOTP),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    try {
      // Use the complete phone number with country code
      final phoneNumber = _completePhoneNumber.isNotEmpty 
          ? _completePhoneNumber 
          : '$_countryCode${_phoneController.text.trim()}';
      final smsCode = _smsCodeController.text.trim();
      
      final isVerified = await PhoneVerificationService.verifySMSCode(phoneNumber, smsCode);
      
      if (!mounted) return;

      if (isVerified) {
        // Get Firebase token from PhoneVerificationService
        // The service should have stored it after verification
        final prefs = await SharedPreferences.getInstance();
        final firebaseToken = prefs.getString('firebase_phone_auth_token');
        
        if (firebaseToken == null) {
          throw Exception('Firebase token not found');
        }

        // Try login first (user might already exist)
        try {
          final user = await ref.read(authNotifierProvider.notifier).phoneLogin(
            phoneNumber,
            firebaseToken,
            ref,
          );

          if (!mounted) return;

          if (user != null) {
            // Login successful - navigate based on profile completion
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (!mounted) return;
            
            if (!user.isProfileComplete) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSetupScreen(
                    email: user.email ?? '',
                    isNewUserSetup: true,
                    phoneNumber: phoneNumber,
                    isPhoneVerified: true,
                  ),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            }
            return;
          }
        } catch (e) {
          // Login failed - might be new user, try signup
          if (e.toString().contains('not registered') || 
              e.toString().contains('not found')) {
            // User doesn't exist - sign up
            final newUser = await ref.read(authNotifierProvider.notifier).phoneSignup(
              phoneNumber,
              firebaseToken,
              ref,
            );

            if (!mounted) return;

            if (newUser != null) {
              // Signup successful - navigate to profile setup
              await Future.delayed(const Duration(milliseconds: 300));
              
              if (!mounted) return;
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSetupScreen(
                    email: newUser.email ?? '',
                    isNewUserSetup: true,
                    phoneNumber: phoneNumber,
                    isPhoneVerified: true,
                  ),
                ),
              );
              return;
            }
          } else {
            // Other error - show it
            rethrow;
          }
        }
      } else {
        setState(() {
          _isVerifyingCode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).invalidOTP),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifyingCode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const appGreenColor = Color(0xFF00695C);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo_v2-no-background.png',
                    height: 200,
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    l10n.signInWithPhone,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appGreenColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.enterPhoneNumberToReceiveOTP,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: appGreenColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Phone Number Field with Country Code
                  IntlPhoneField(
                    controller: _phoneController,
                    enabled: !_isCodeSent,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: l10n.phoneNumber,
                      labelStyle: const TextStyle(color: appGreenColor),
                      hintText: l10n.enterYourPhoneNumber,
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: appGreenColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: appGreenColor.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: appGreenColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    initialCountryCode: 'US', // Default country, will auto-detect from device
                    onChanged: (phone) {
                      _countryCode = phone.countryCode;
                      _completePhoneNumber = phone.completeNumber;
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return l10n.pleaseEnterPhoneNumber;
                      }
                      if (!PhoneVerificationService.isValidPhoneNumber(phone.completeNumber)) {
                        return l10n.pleaseEnterValidPhoneNumber;
                      }
                      return null;
                    },
                    dropdownIcon: Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    flagsButtonPadding: const EdgeInsets.only(left: 12),
                    dropdownTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!_isCodeSent)
                    // Send SMS Button
                    ElevatedButton(
                      onPressed: _isSendingSMS ? null : _sendSMS,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appGreenColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSendingSMS
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              l10n.sendOTP,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                  if (_isCodeSent) ...[
                    // iOS Debug Mode Hint
                    if (Platform.isIOS)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'iOS Debug Mode: Use OTP 123456 or 847293',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // OTP Code Field
                    TextFormField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.enterOTP,
                        labelStyle: const TextStyle(color: appGreenColor),
                        hintText: Platform.isIOS ? '123456' : '000000',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 24,
                          letterSpacing: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: appGreenColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: appGreenColor.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: appGreenColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      maxLength: 6,
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    ElevatedButton(
                      onPressed: _isVerifyingCode ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appGreenColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifyingCode
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              l10n.verify,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Resend OTP
                    if (_resendCountdown > 0)
                      Center(
                        child: Text(
                          '${l10n.resendOTPIn} $_resendCountdown ${l10n.seconds}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isCodeSent = false;
                            _smsCodeController.clear();
                            _verificationId = null;
                          });
                        },
                        child: Text(l10n.resendOTP),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

