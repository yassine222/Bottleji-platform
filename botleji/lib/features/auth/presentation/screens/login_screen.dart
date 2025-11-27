import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:botleji/features/auth/presentation/screens/register_screen.dart';
import 'package:botleji/features/home/presentation/screens/home_screen.dart';
import '../providers/auth_provider.dart';
import 'package:botleji/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:botleji/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showAccountDisabledCard = false;
  bool _showAccountDeletedCard = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Reset the disabled/deleted card states before attempting login
    setState(() {
      _showAccountDisabledCard = false;
      _showAccountDeletedCard = false;
      _isLoading = true;
    });

    try {
      final user = await ref.read(authNotifierProvider.notifier).login(
        _emailController.text,
        _passwordController.text,
        ref,
      );

      if (!mounted) return;

      // If we get here, login was successful - user is NOT disabled
      // (backend would have thrown an error if disabled)
      // So we should NOT show the disabled card
      print('✅ Login successful - user is NOT disabled');
      
      // Ensure card is hidden (should already be false, but double-check)
      if (_showAccountDisabledCard) {
        setState(() {
          _showAccountDisabledCard = false;
        });
      }
      
      if (user != null) {
        // Add small delay to ensure WebSocket connection and state updates complete
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (!mounted) return;
        
        try {
          if (!user.isProfileComplete) {
            print('Profile incomplete, navigating to profile setup');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSetupScreen(
                  email: user.email,
                  isNewUserSetup: true, // Set to true for incomplete profiles (new users)
                ),
              ),
            );
          } else {
            print('Profile complete, navigating to home');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
        } catch (navError) {
          print('Navigation error: $navError');
          if (!mounted) return;
          // Fallback: navigate using named route
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        // Login failed - show error message
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidEmailOrPassword),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      
      // Reset disabled card state first
      setState(() {
        _showAccountDisabledCard = false;
      });
      
      // Show user-friendly error message
      String errorMessage = l10n.loginFailed;
      print('Login error details: $e');
      print('Error type: ${e.runtimeType}');

      // Extract the actual error message from the exception
      String actualErrorMessage = '';
      if (e is Exception) {
        actualErrorMessage = e.toString();
      } else {
        actualErrorMessage = e.toString();
      }
      
      // Check error message for account status - use lowercase for case-insensitive matching
      final errorString = actualErrorMessage.toLowerCase();
      print('🔍 Login error string: $errorString');
      print('🔍 Full error: $e');
      print('🔍 Error runtime type: ${e.runtimeType}');
      
      // Only show account disabled card if the error message EXACTLY matches the backend error
      // Backend throws: "Your account has been permanently disabled due to repeated violations of Bottleji's community guidelines. Please contact support: support@bottleji.com"
      // We need to check for ALL required keywords to ensure we only catch the exact error
      final hasPermanentlyDisabled = errorString.contains('permanently disabled');
      final hasRepeatedViolations = errorString.contains('repeated violations');
      final hasCommunityGuidelines = errorString.contains('community guidelines') || errorString.contains('bottleji\'s community');
      final hasSupportEmail = errorString.contains('support@bottleji.com');
      
      // Only show card if ALL keywords are present (very specific match)
      final isPermanentlyDisabled = hasPermanentlyDisabled && 
          hasRepeatedViolations && 
          hasCommunityGuidelines &&
          hasSupportEmail;
      
      print('🔍 Error detection breakdown:');
      print('   - hasPermanentlyDisabled: $hasPermanentlyDisabled');
      print('   - hasRepeatedViolations: $hasRepeatedViolations');
      print('   - hasCommunityGuidelines: $hasCommunityGuidelines');
      print('   - hasSupportEmail: $hasSupportEmail');
      print('   - isPermanentlyDisabled (ALL): $isPermanentlyDisabled');
      
      if (errorString.contains('account has been deleted by an administrator')) {
        // Show account deleted card on login screen (not popup)
        print('🔍 Detected account deleted - showing card');
        if (mounted) {
          setState(() {
            _showAccountDeletedCard = true;
          });
          // Scroll to top to show the card
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _formKey.currentContext != null) {
              Scrollable.ensureVisible(
                _formKey.currentContext!,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
        return; // Don't show SnackBar, card handles it
      } else if (isPermanentlyDisabled) {
        // Show account disabled card ONLY for permanently disabled accounts
        print('🔒 Account permanently disabled detected - showing card');
        print('🔒 Setting _showAccountDisabledCard to true');
        if (mounted) {
          setState(() {
            _showAccountDisabledCard = true;
            print('🔒 _showAccountDisabledCard set to: $_showAccountDisabledCard');
          });
          // Scroll to top to show the card
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _formKey.currentContext != null) {
              Scrollable.ensureVisible(
                _formKey.currentContext!,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
        return; // Don't show SnackBar, card handles it
      } else if (errorString.contains('invalid credentials') ||
          e.toString().contains('401') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('Invalid email or password')) {
        errorMessage = l10n.invalidEmailOrPassword;
      } else if (e.toString().contains('Connection timeout') ||
          e.toString().contains('connection timeout')) {
        errorMessage = l10n.connectionTimeout;
      } else if (e.toString().contains('Network error') ||
          e.toString().contains('Network') ||
          e.toString().contains('Connection')) {
        errorMessage = l10n.networkError;
      } else if (e.toString().contains('Timeout') ||
          e.toString().contains('timeout')) {
        errorMessage = l10n.requestTimeout;
      } else if (e.toString().contains('Server error') ||
          e.toString().contains('500')) {
        errorMessage = l10n.serverError;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void initState() {
    super.initState();
    // Ensure cards are ALWAYS hidden when screen is first loaded
    // These should only be true after a login attempt with disabled/deleted account error
    _showAccountDisabledCard = false;
    _showAccountDeletedCard = false;
    _isLoading = false;
    print('🔍 LoginScreen initState - _showAccountDisabledCard reset to: $_showAccountDisabledCard');
    print('🔍 LoginScreen initState - _showAccountDeletedCard reset to: $_showAccountDeletedCard');
    print('🔍 LoginScreen initState - Widget key: ${widget.key}');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Double-check card is ALWAYS hidden when dependencies change (unless explicitly set by login error)
    // This ensures the card doesn't persist from previous sessions
    if (_showAccountDisabledCard) {
      print('⚠️ LoginScreen didChangeDependencies - Card was true, resetting to false');
      if (mounted) {
        setState(() {
          _showAccountDisabledCard = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const appGreenColor = Color(0xFF00695C);
    print('🔍 LoginScreen build - _showAccountDisabledCard: $_showAccountDisabledCard');
    return Scaffold(
      backgroundColor: Colors.white,
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
                    // Account Deleted Card - Show first if account is deleted
                    if (_showAccountDeletedCard)
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade200.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red.shade700,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.accountDeleted,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.red.shade700,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        if (mounted) {
                                          setState(() {
                                            _showAccountDeletedCard = false;
                                            _emailController.clear();
                                            _passwordController.clear();
                                          });
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.accountDeletedMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade800,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.supportEmail,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    
                    // Account Disabled Card - Show if account is permanently disabled
                    // Only show if explicitly set to true (should only happen after login attempt with disabled account)
                    if (_showAccountDisabledCard)
                      Builder(
                        builder: (context) {
                          print('🔍 Building account disabled card widget - _showAccountDisabledCard: $_showAccountDisabledCard');
                          final l10n = AppLocalizations.of(context);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade200.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.accountDisabled,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.red.shade700,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        print('🔒 Dismissing account disabled card');
                                        print('🔒 Before dismiss - _showAccountDisabledCard: $_showAccountDisabledCard');
                                        if (mounted) {
                                          setState(() {
                                            _showAccountDisabledCard = false;
                                            _emailController.clear();
                                            _passwordController.clear();
                                          });
                                          print('🔒 After dismiss - _showAccountDisabledCard: $_showAccountDisabledCard');
                                        } else {
                                          print('🔒 Widget not mounted, cannot update state');
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.accountDisabledMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade800,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.supportEmail,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    
                    // Logo and Welcome Text
                    Image.asset(
                      'assets/images/logo_v2.png',
                      height: 200,                      
                    ),
                  const SizedBox(height: 32),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n.welcomeBack,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: appGreenColor,
                            ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n.signInToContinue,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: appGreenColor.withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          labelStyle: const TextStyle(color: appGreenColor),
                          hintText: l10n.enterYourEmail,
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterEmail;
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return l10n.pleaseEnterValidEmail;
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          labelStyle: const TextStyle(color: appGreenColor),
                          hintText: l10n.enterYourPassword,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.lock_outline, color: appGreenColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: appGreenColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
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
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterPassword;
                          }
                          if (value.length < 6) {
                            return l10n.passwordMinLength;
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(color: appGreenColor),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                                l10n.login,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.register,
                              style: const TextStyle(color: appGreenColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
