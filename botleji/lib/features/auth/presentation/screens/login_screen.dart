import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/core/theme/app_colors.dart';
import 'package:botleji/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:botleji/features/auth/presentation/screens/register_screen.dart';
import 'package:botleji/features/home/presentation/screens/home_screen.dart';
import 'package:botleji/features/auth/presentation/screens/otp_verification_screen.dart';
import '../providers/auth_provider.dart';
import 'package:botleji/features/profile/presentation/screens/profile_setup_screen.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authNotifierProvider.notifier).login(
        _emailController.text,
        _passwordController.text,
        ref,
      );

      if (!mounted) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Show user-friendly error message
      String errorMessage = 'Login failed. Please check your credentials and try again.';
      print('Login error details: $e');
      print('Error type: ${e.runtimeType}');

      if (e.toString().contains('Account has been deleted by an administrator')) {
        // Show special dialog for deleted accounts
        _showAccountDeletedDialog();
        return; // Don't show SnackBar, dialog handles it
      } else if (e.toString().contains('Invalid credentials') ||
          e.toString().contains('401') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('Invalid email or password')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.toString().contains('Connection timeout') ||
          e.toString().contains('connection timeout')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('Network error') ||
          e.toString().contains('Network') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Timeout') ||
          e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (e.toString().contains('Server error') ||
          e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
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

  /// Show dialog for deleted accounts
  void _showAccountDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          title: const Text('Account Deleted'),
          content: const Text(
            'Your account has been deleted by an administrator.\n\n'
            'If you believe this is a mistake, please contact our support team:\n\n'
            '📧 Email: support@bottleji.com\n'
            '📱 Support Hours: 9 AM - 6 PM (GMT+1)\n\n'
            'We apologize for any inconvenience.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Clear the form
                _emailController.clear();
                _passwordController.clear();
              },
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Clear the form
                _emailController.clear();
                _passwordController.clear();
                // TODO: Open email app or support page
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please email support@bottleji.com for assistance'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Contact Support'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00695C),
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
                  // Logo and Welcome Text
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
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
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00695C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
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
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
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
