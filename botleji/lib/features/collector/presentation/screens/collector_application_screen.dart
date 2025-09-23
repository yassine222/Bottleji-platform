import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:botleji/core/theme/app_colors.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/collector/controllers/collector_application_controller.dart';
import 'package:firebase_storage/firebase_storage.dart';

const appGreenColor = Color(0xFF00695C);

class CollectorApplicationScreen extends ConsumerStatefulWidget {
  const CollectorApplicationScreen({super.key});

  @override
  ConsumerState<CollectorApplicationScreen> createState() => _CollectorApplicationScreenState();
}

class _CollectorApplicationScreenState extends ConsumerState<CollectorApplicationScreen> {
  int _currentStep = 0;
  File? _idCardPhoto;
  File? _idCardBackPhoto;
  File? _passportMainPagePhoto;
  File? _selfieWithIdPhoto;
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Add ScrollController for step navigation
  final ScrollController _scrollController = ScrollController();

  // ID Card Information Controllers
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _idCardTypeController = TextEditingController();
  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _idCardIssuingAuthorityController = TextEditingController();
  DateTime? _idCardExpiryDate;
  DateTime? _passportIssueDate;
  DateTime? _passportExpiryDate;

  final List<String> _steps = [
    'Welcome',
    'ID Verification',
    'Selfie with ID',
    'Review & Submit',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingApplication();
  }

  @override
  void dispose() {
    _idCardNumberController.dispose();
    _idCardTypeController.dispose();
    _passportNumberController.dispose();
    _idCardIssuingAuthorityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingApplication() async {
    try {
      // Check if user has an existing application
      final userAsync = ref.read(authNotifierProvider);
      final user = userAsync.value;
      
      if (user?.collectorApplicationStatus == CollectorApplicationStatus.rejected) {
        print('🔍 CollectorApplicationScreen: Loading existing rejected application for editing...');
        
        // Load the existing application data
        await ref.read(collectorApplicationControllerProvider.notifier).getMyApplication();
        final applicationAsync = ref.read(collectorApplicationControllerProvider);
        final application = applicationAsync.value;
        
        if (application != null) {
          print('🔍 CollectorApplicationScreen: Found existing application, populating form...');
          _populateFormWithExistingData(application);
        }
      }
    } catch (e) {
      print('🔍 CollectorApplicationScreen: Error loading existing application: $e');
    }
  }

  void _populateFormWithExistingData(dynamic application) {
    // Populate form fields with existing application data
    if (application.idCardNumber != null) {
      _idCardNumberController.text = application.idCardNumber;
    }
    if (application.idCardType != null) {
      _idCardTypeController.text = application.idCardType;
    }
    if (application.idCardIssuingAuthority != null) {
      _idCardIssuingAuthorityController.text = application.idCardIssuingAuthority;
    }
    if (application.idCardExpiryDate != null) {
      _idCardExpiryDate = DateTime.parse(application.idCardExpiryDate);
    }
    if (application.passportIssueDate != null) {
      _passportIssueDate = DateTime.parse(application.passportIssueDate);
    }
    if (application.passportExpiryDate != null) {
      _passportExpiryDate = DateTime.parse(application.passportExpiryDate);
    }
    
    print('🔍 CollectorApplicationScreen: Form populated with existing data');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Become a Collector',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(_steps.length, (index) {
                    final isActive = index == _currentStep;
                    final isCompleted = index < _currentStep;
                    
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted 
                                    ? appGreenColor 
                                    : isActive 
                                        ? appGreenColor.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.3),
                                border: isActive 
                                    ? Border.all(color: appGreenColor, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive ? appGreenColor : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _steps[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive || isCompleted ? appGreenColor : Colors.grey,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),);
                  }),
                ),
              ),
              
              // Content
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildIdVerificationStep();
      case 2:
        return _buildSelfieStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Welcome illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: appGreenColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco,
              size: 100,
              color: appGreenColor,
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Welcome to the Collector Program!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: appGreenColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Join our community of eco-conscious collectors and help make a difference in recycling.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Benefits
          _buildBenefitItem(
            icon: Icons.monetization_on,
            title: 'Earn Money',
            description: 'Get paid for every bottle and can you collect',
          ),
          const SizedBox(height: 16),
          
          _buildBenefitItem(
            icon: Icons.location_on,
            title: 'Flexible Hours',
            description: 'Collect whenever and wherever you want',
          ),
          const SizedBox(height: 16),
          
          _buildBenefitItem(
            icon: Icons.eco,
            title: 'Help the Environment',
            description: 'Contribute to a cleaner, greener world',
          ),
          const SizedBox(height: 32),
          
          // Requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Requirements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Must be 18 years or older\n• Valid National ID Card\n• Clear photos of ID and selfie\n• Good standing in the community',
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Next button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _nextStep(),
              style: FilledButton.styleFrom(
                backgroundColor: appGreenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appGreenColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: appGreenColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdVerificationStep() {
    final isPassport = _idCardTypeController.text == 'Passport';
    
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'ID Card Verification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: appGreenColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Please provide your ${isPassport ? 'passport' : 'ID card'} information and take clear photos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // ID Card Information Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isPassport ? 'Passport' : 'ID Card'} Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appGreenColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // ID Card Type
                DropdownButtonFormField<String>(
                  value: _idCardTypeController.text.isNotEmpty ? _idCardTypeController.text : null,
                  decoration: InputDecoration(
                    labelText: 'ID Card Type',
                    hintText: 'Select your ID card type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.credit_card),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'National ID',
                      child: Text('National ID'),
                    ),
                    DropdownMenuItem(
                      value: 'Passport',
                      child: Text('Passport'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _idCardTypeController.text = value;
                      setState(() {});
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an ID card type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Dynamic fields based on selection
                if (isPassport) ...[
                  // Passport Number
                  TextFormField(
                    controller: _passportNumberController,
                    decoration: InputDecoration(
                      labelText: 'Passport Number',
                      hintText: 'Enter your passport number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Passport Issue Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _passportIssueDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _passportIssueDate != null
                                  ? 'Issue Date: ${_passportIssueDate!.day}/${_passportIssueDate!.month}/${_passportIssueDate!.year}'
                                  : 'Select Issue Date',
                              style: TextStyle(
                                color: _passportIssueDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Passport Expiry Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (date != null) {
                        setState(() {
                          _passportExpiryDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _passportExpiryDate != null
                                  ? 'Expiry Date: ${_passportExpiryDate!.day}/${_passportExpiryDate!.month}/${_passportExpiryDate!.year}'
                                  : 'Select Expiry Date',
                              style: TextStyle(
                                color: _passportExpiryDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Issuing Authority
                  TextFormField(
                    controller: _idCardIssuingAuthorityController,
                    decoration: InputDecoration(
                      labelText: 'Issuing Authority',
                      hintText: 'e.g., Ministry of Foreign Affairs',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.account_balance),
                    ),
                  ),
                ] else ...[
                  // ID Card Number (for National ID)
                  TextFormField(
                    controller: _idCardNumberController,
                    maxLength: 8,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'ID Card Number',
                      hintText: '12345678',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ID card number is required';
                      }
                      if (value.length != 8) {
                        return 'ID card number must be 8 digits';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'ID card number must contain only digits';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Photo Section
          Text(
            '${isPassport ? 'Passport' : 'ID Card'} Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: appGreenColor,
            ),
          ),
          const SizedBox(height: 16),
          
          if (isPassport) ...[
            // Passport Main Page Photo
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _passportMainPagePhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _passportMainPagePhoto!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Passport Main Page Photo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take photo of the main page with your details',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            
            // Passport Camera button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _takePassportMainPagePhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_passportMainPagePhoto != null ? 'Retake Photo' : 'Take Passport Main Page Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: appGreenColor,
                  side: BorderSide(color: appGreenColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            // ID Card Front Photo
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _idCardPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _idCardPhoto!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ID Card Front Photo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take photo of the front of your ID card',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            
            // ID Card Front Camera button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _takeIdCardPhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_idCardPhoto != null ? 'Retake Front Photo' : 'Take ID Card Front Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: appGreenColor,
                  side: BorderSide(color: appGreenColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ID Card Back Photo
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _idCardBackPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _idCardBackPhoto!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ID Card Back Photo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take photo of the back of your ID card',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            
            // ID Card Back Camera button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _takeIdCardBackPhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_idCardBackPhoto != null ? 'Retake Back Photo' : 'Take ID Card Back Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: appGreenColor,
                  side: BorderSide(color: appGreenColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          
          // Next button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canProceedToNextStep() ? _nextStep : null,
              style: FilledButton.styleFrom(
                backgroundColor: appGreenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    // For ID verification step, require photo and basic info
    if (_currentStep == 1) {
      final isPassport = _idCardTypeController.text == 'Passport';
      if (isPassport) {
        return _passportMainPagePhoto != null && 
               _passportNumberController.text.isNotEmpty &&
               _passportIssueDate != null &&
               _passportExpiryDate != null &&
               _idCardIssuingAuthorityController.text.isNotEmpty;
      } else {
        return _idCardPhoto != null && 
               _idCardNumberController.text.isNotEmpty;
      }
    }
    return true;
  }

  Widget _buildSelfieStep() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Selfie with ID Card',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: appGreenColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Please take a selfie while holding your ID card next to your face',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Selfie preview
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _selfieWithIdPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selfieWithIdPhoto!,
                      fit: BoxFit.cover,
                    ),
                )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.face,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Selfie Photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          
          // Camera button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _takeSelfiePhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_selfieWithIdPhoto != null ? 'Retake Photo' : 'Take Selfie'),
              style: OutlinedButton.styleFrom(
                foregroundColor: appGreenColor,
                side: BorderSide(color: appGreenColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Next button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selfieWithIdPhoto != null ? _nextStep : null,
              style: FilledButton.styleFrom(
                backgroundColor: appGreenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final isPassport = _idCardTypeController.text == 'Passport';
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: appGreenColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Please review your application before submitting',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // ID Card Information Review
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID Card Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appGreenColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildReviewItem('ID Type', _idCardTypeController.text),
                _buildReviewItem('ID Number', _idCardNumberController.text),
                if (isPassport) ...[
                  _buildReviewItem('Issuing Authority', _idCardIssuingAuthorityController.text.isNotEmpty 
                      ? _idCardIssuingAuthorityController.text 
                      : 'Not provided'),
                  _buildReviewItem('Expiry Date', _idCardExpiryDate != null 
                      ? '${_idCardExpiryDate!.day}/${_idCardExpiryDate!.month}/${_idCardExpiryDate!.year}'
                      : 'Not provided'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Photos review
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'ID Card',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: appGreenColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _idCardPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _idCardPhoto!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.credit_card, size: 32),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Selfie',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: appGreenColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _selfieWithIdPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selfieWithIdPhoto!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.face, size: 32),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Terms and conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Your application will be reviewed by our team\n• Review typically takes 1-3 business days\n• You\'ll receive a notification once reviewed\n• If approved, you can start collecting immediately',
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: FilledButton.styleFrom(
                backgroundColor: appGreenColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Submitting...'),
                      ],
                    )
                  : const Text(
                      'Submit Application',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      // Scroll to top when navigating to next step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      // Scroll to top when navigating to previous step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _takeIdCardPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _idCardPhoto = File(photo.path);
      });
    }
  }

  Future<void> _takeIdCardBackPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _idCardBackPhoto = File(photo.path);
      });
    }
  }

  Future<void> _takePassportMainPagePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _passportMainPagePhoto = File(photo.path);
      });
    }
  }

  Future<void> _takeSelfiePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        _selfieWithIdPhoto = File(photo.path);
      });
    }
  }

  Future<void> _submitApplication() async {
    if (_idCardPhoto == null || _selfieWithIdPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take both photos before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate required fields
    final isPassport = _idCardTypeController.text == 'Passport';
    if (isPassport) {
      if (_passportMainPagePhoto == null || _passportNumberController.text.isEmpty || _passportIssueDate == null || _passportExpiryDate == null || _idCardIssuingAuthorityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required passport information'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_idCardNumberController.text.isEmpty || _idCardTypeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required ID card information (ID number and type)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload photos to Firebase Storage
      final idCardPhotoUrl = await _uploadImageToFirebase(_idCardPhoto!);
      final selfiePhotoUrl = await _uploadImageToFirebase(_selfieWithIdPhoto!);

      // Check if we're editing an existing application or creating a new one
      final userAsync = ref.read(authNotifierProvider);
      final user = userAsync.value;
      final isEditing = user?.collectorApplicationStatus == CollectorApplicationStatus.rejected;
      
      if (isEditing) {
        print('🔍 CollectorApplicationScreen: Updating existing application...');
        await ref.read(collectorApplicationControllerProvider.notifier).updateApplication(
          idCardPhoto: idCardPhotoUrl,
          selfieWithIdPhoto: selfiePhotoUrl,
          idCardNumber: isPassport ? _passportNumberController.text : _idCardNumberController.text,
          idCardType: _idCardTypeController.text,
          idCardExpiryDate: isPassport ? _idCardExpiryDate : null,
          idCardIssuingAuthority: isPassport ? _idCardIssuingAuthorityController.text : null,
          passportIssueDate: _passportIssueDate,
          passportExpiryDate: _passportExpiryDate,
          passportMainPagePhoto: _passportMainPagePhoto != null ? await _uploadImageToFirebase(_passportMainPagePhoto!) : null,
          idCardBackPhoto: _idCardBackPhoto != null ? await _uploadImageToFirebase(_idCardBackPhoto!) : null,
        );
      } else {
        print('🔍 CollectorApplicationScreen: Creating new application...');
        await ref.read(collectorApplicationControllerProvider.notifier).createApplication(
          idCardPhoto: idCardPhotoUrl,
          selfieWithIdPhoto: selfiePhotoUrl,
          idCardNumber: isPassport ? _passportNumberController.text : _idCardNumberController.text,
          idCardType: _idCardTypeController.text,
          idCardExpiryDate: isPassport ? _idCardExpiryDate : null,
          idCardIssuingAuthority: isPassport ? _idCardIssuingAuthorityController.text : null,
          passportIssueDate: _passportIssueDate,
          passportExpiryDate: _passportExpiryDate,
          passportMainPagePhoto: _passportMainPagePhoto != null ? await _uploadImageToFirebase(_passportMainPagePhoto!) : null,
          idCardBackPhoto: _idCardBackPhoto != null ? await _uploadImageToFirebase(_idCardBackPhoto!) : null,
        );
      }
      print('🔍 CollectorApplicationScreen: Application submitted successfully!');

      // Get the created application to include its ID in tracking
      await ref.read(collectorApplicationControllerProvider.notifier).getMyApplication();
      final applicationAsync = ref.read(collectorApplicationControllerProvider);
      final createdApplication = applicationAsync.value;
      
      // Activity tracking removed

      // Force refresh user data to update application status
      print('🔍 CollectorApplicationScreen: Refreshing user data...');
      await ref.read(authNotifierProvider.notifier).refreshUserData();
      print('🔍 CollectorApplicationScreen: User data refreshed');

      // Also sync application status from database
      print('🔍 CollectorApplicationScreen: Syncing application status...');
      await ref.read(authNotifierProvider.notifier).syncApplicationStatusFromDatabase();
      print('🔍 CollectorApplicationScreen: Application status synced');

      // Add a small delay to ensure state updates are processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Force a rebuild of the auth provider to ensure UI updates
      ref.invalidate(authNotifierProvider);
      print('🔍 CollectorApplicationScreen: Auth provider invalidated');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Application updated successfully!' : 'Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      // Activity tracking removed
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'collector_applications/${timestamp}_${imageFile.path.split('/').last}';
      
      // Get reference to the file
      final fileRef = FirebaseStorage.instance.ref().child(fileName);
      
      // Set metadata for better caching
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': imageFile.path},
      );
      
      // Upload the file
      await fileRef.putFile(imageFile, metadata);
      
      // Get the download URL
      final url = await fileRef.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
} 