import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../providers/auth_provider.dart';
import 'package:botleji/l10n/app_localizations.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OTPVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _timeLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    
    if (mounted) {
      _timer?.cancel();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ref.read(authNotifierProvider.notifier).verifyOtp(
        widget.email,
        _otpController.text,
      );

      if (!mounted) return;

      response.when(
        success: (user, token, message) async {
          print('OTP verification success - User: $user, Token: $token, Message: $message');
          if (token != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message ?? AppLocalizations.of(context).otpVerifiedSuccessfully)),
            );
            // Add a small delay to ensure auth state is updated before navigation
            print('OTP verified successfully - user is now logged in');
            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.pushReplacementNamed(context, '/');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).invalidVerificationResponse),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        error: (message, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).resendOtp(widget.email);

      if (!mounted) return;

      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).otpResentSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const appGreenColor = Color(0xFF00695C);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: appGreenColor, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Main content
            Expanded(
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
                          AppLocalizations.of(context).verifyYourEmail,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: appGreenColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).pleaseEnterOtpSentToEmail,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: appGreenColor.withOpacity(0.7),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Directionality(
                          textDirection: TextDirection.ltr, // Force LTR for OTP codes
                          child: PinCodeTextField(
                            appContext: context,
                            length: 6,
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            cursorColor: appGreenColor,
                            textStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(12),
                              fieldHeight: 50,
                              fieldWidth: 40,
                              activeFillColor: Theme.of(context).colorScheme.surface,
                              selectedFillColor: appGreenColor.withOpacity(0.1),
                              inactiveFillColor: Theme.of(context).colorScheme.surface,
                              activeColor: appGreenColor,
                              selectedColor: appGreenColor,
                              inactiveColor: appGreenColor.withOpacity(0.5),
                              borderWidth: 1,
                            ),
                            enableActiveFill: true,
                            onChanged: (value) {},
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: appGreenColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context).verifyOtp,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _canResend ? _resendOtp : null,
                          child: Text(
                            _canResend
                              ? AppLocalizations.of(context).resendOtp
                              : AppLocalizations.of(context).resendOtpIn(_timeLeft),
                            style: TextStyle(
                              color: _canResend ? appGreenColor : Colors.grey,
                              fontWeight: _canResend ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 