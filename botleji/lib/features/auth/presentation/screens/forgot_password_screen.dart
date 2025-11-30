import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'reset_password_otp_screen.dart';
import 'package:botleji/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ref
          .read(authNotifierProvider.notifier)
          .requestPasswordReset(_emailController.text);

      if (!mounted) return;

      response.when(
        success: (user, token, message) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordOtpScreen(
                email: _emailController.text,
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message ?? AppLocalizations.of(context).resetCodeSentToEmail)),
          );
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
                          height:200,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          AppLocalizations.of(context).resetPassword,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: appGreenColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).enterEmailToReceiveResetCode,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: appGreenColor.withOpacity(0.7),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).email,
                            labelStyle: const TextStyle(color: appGreenColor),
                            hintText: AppLocalizations.of(context).enterYourEmail,
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            prefixIcon: const Icon(Icons.email_outlined, color: appGreenColor),
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
                          validator: (value) {
                            final l10n = AppLocalizations.of(context);
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterEmail;
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return l10n.pleaseEnterValidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRequestReset,
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
                                  AppLocalizations.of(context).sendResetCode,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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