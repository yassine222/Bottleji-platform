import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../providers/auth_provider.dart';
import 'new_password_screen.dart';
import 'package:botleji/l10n/app_localizations.dart';

class ResetPasswordOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordOtpScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends ConsumerState<ResetPasswordOtpScreen> {
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
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _timeLeft = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6 || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final response = await ref.read(authNotifierProvider.notifier).verifyPasswordReset(
        email: widget.email,
        otp: _otpController.text,
      );

      if (!mounted) return;

      response.when(
        success: (user, token, message) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(
                email: widget.email,
                otp: _otpController.text,
              ),
            ),
          );
        },
        error: (message, _) {
          if (!mounted) return;
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
      await ref.read(authNotifierProvider.notifier).requestPasswordReset(
        widget.email,
      );

      if (!mounted) return;

      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).resetCodeResentSuccessfully)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo_v2-no-background.png',
                        height: 200,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        AppLocalizations.of(context).enterResetCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: appGreenColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).weHaveSentResetCodeTo(widget.email),
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
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          cursorColor: appGreenColor,
                          animationType: AnimationType.fade,
                          textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeFillColor: Theme.of(context).colorScheme.surface,
                            inactiveFillColor: Theme.of(context).colorScheme.surface,
                            selectedFillColor: appGreenColor.withOpacity(0.1),
                            activeColor: appGreenColor,
                            inactiveColor: appGreenColor.withOpacity(0.5),
                            selectedColor: appGreenColor,
                            borderWidth: 1,
                          ),
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          onCompleted: (_) => _verifyOtp(),
                          beforeTextPaste: (text) {
                            if (text == null) return false;
                            return RegExp(r'^[0-9]+$').hasMatch(text);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...(_isLoading
                          ? [
                              const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(appGreenColor),
                                ),
                              ),
                            ]
                          : [
                              ElevatedButton(
                                onPressed: _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: appGreenColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  AppLocalizations.of(context).verify,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).didntReceiveCode,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _canResend ? _resendOtp : null,
                                    child: Text(
                                      _canResend 
                                          ? AppLocalizations.of(context).resend 
                                          : AppLocalizations.of(context).resendIn(_timeLeft),
                                      style: TextStyle(
                                        color: _canResend ? appGreenColor : Colors.grey,
                                        fontWeight: _canResend ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ]),
                    ],
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