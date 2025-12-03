// Add these dependencies to your pubspec.yaml:
// flutter_google_places: ^0.3.0
// google_maps_webservice: ^0.0.20-nullsafety.5
//
// Then run: flutter pub get

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:google_maps_webservice/places.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/data/models/user_data.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/phone_verification_service.dart';
import 'package:botleji/l10n/app_localizations.dart';


const kGoogleApiKey = "AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E";
const appGreenColor = Color(0xFF00695C);

final GoogleMapsPlaces _globalPlaces = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isNewUserSetup;
  final String? phoneNumber;
  final bool isPhoneVerified;
  
  const ProfileSetupScreen({
    required this.email, 
    this.isNewUserSetup = false,
    this.phoneNumber,
    this.isPhoneVerified = false,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  
  String _phoneCountryCode = '+1';
  String _completePhoneNumber = '';
  String _initialPhoneCountryCode = 'US';
  
  // Phone verification fields
  final _smsCodeController = TextEditingController();
  String? _verificationId;
  bool _isPhoneVerified = false;
  bool _isSendingSMS = false;
  bool _isVerifyingCode = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _fieldsInitialized = false; // Flag to track if fields have been initialized
  
  // Track original values to detect changes
  String? _originalName;
  String? _originalPhone;
  String? _originalAddress;
  String? _originalProfilePhoto;
  
  // Track if phone number has been modified
  bool _isPhoneModified = false;
  bool _hasPhoneBeenCleared = false;
  
  // Track if address has been cleared
  bool _hasAddressBeenCleared = false;
  

  
  File? _profilePhotoFile;
  bool _isLoading = false;
  bool _isInitializing = true;
  GoogleMapsPlaces? _places;
  
  // Address search state
  List<Prediction> _addressSuggestions = [];
  bool _isLoadingAddressSuggestions = false;
  String? _addressSearchError;
  Timer? _addressSearchDebounce;

  @override
  void initState() {
    super.initState();
    
    // Remove phone controller listener to prevent deletion conflicts
    // We'll handle modification detection differently
    
    // Add focus listener to clear phone number when user starts editing
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus && !_hasPhoneBeenCleared) {
        // Clear the field and reset state
        _phoneController.clear();
        setState(() {
          _hasPhoneBeenCleared = true;
          _isPhoneModified = true; // Set to true since user is starting to edit
          _originalPhone = ''; // Reset original phone to empty since we cleared the field
        });
      }
    });
    
    // Add listener to address controller to detect when it's cleared
    _addressController.addListener(() {
      if (_addressController.text.isEmpty && _originalAddress != null && _originalAddress!.isNotEmpty) {
        // User has cleared the address field
        if (!_hasAddressBeenCleared) {
          setState(() {
            _hasAddressBeenCleared = true;
          });
        }
      } else if (_addressController.text.isNotEmpty) {
        // Address has been entered, reset the cleared flag
        if (_hasAddressBeenCleared) {
          setState(() {
            _hasAddressBeenCleared = false;
          });
        }
      }
    });
    
    _initializeScreen();
  }



  Future<void> _initializeScreen() async {
    try {
      // Only detect country code from device locale if it's a new user setup
      // For existing users, we'll extract it from their phone number in the build method
      if (widget.isNewUserSetup) {
        _detectPhoneCountryCode();
      }
      
      // Initialize phone number if provided and already verified (from phone sign-in)
      if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty && widget.isPhoneVerified) {
        // Extract country code and local number from full phone number
        final fullPhone = widget.phoneNumber!;
        final components = _extractPhoneComponents(fullPhone);
        if (components['countryCode']!.isNotEmpty) {
          _phoneCountryCode = components['countryCode']!;
          _phoneController.text = components['localNumber']!;
          _initialPhoneCountryCode = _getCountryFromCode(_phoneCountryCode);
          print('📱 ProfileSetupScreen: Extracted country code from phone: $_phoneCountryCode -> $_initialPhoneCountryCode, local: ${components['localNumber']}');
        } else {
          // Fallback: use as-is
          _phoneController.text = fullPhone;
        }
        _isPhoneVerified = true;
        _originalPhone = widget.phoneNumber!;
        _completePhoneNumber = widget.phoneNumber!;
        print('📱 ProfileSetupScreen: Phone number initialized from phone sign-in: ${widget.phoneNumber}');
      }
      
      // Initialize email field
      // For phone sign-in users, email might be empty or a temp email
      // For email sign-in users, email is already set
      _emailController.text = widget.email;
      if (widget.email.startsWith('phone_') && widget.email.endsWith('@bottleji.temp')) {
        // Phone sign-in user - clear temp email, allow them to add real email
        _emailController.clear();
      }
      
      // Don't initialize original values here - they will be set in the build method
      // based on whether it's a new user setup or existing user
      
      await _requestPermissions();
      // Use the global instance if available, otherwise create a new one
      _places = _globalPlaces;
      
      // Test the API with a simple request
      final response = await _places?.autocomplete(
        'test',
        language: "en",
        components: [Component(Component.country, "tn")],
      );
      print('Google Places API test response status: ${response?.status}');
      
      if (response?.status != "OK") {
        print('Warning: Google Places API test failed with status: ${response?.status}');
        // Create a new instance if the test fails
        _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
      }
    } catch (e) {
      print('Error initializing screen: $e');
      // Create a new instance on error
      _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _detectPhoneCountryCode() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split('_');
      if (parts.length >= 2) {
        final countryCode = parts.last.toUpperCase();
        if (countryCode.length == 2) {
          _initialPhoneCountryCode = countryCode;
          print('🌍 ProfileSetupScreen: Detected country code: $_initialPhoneCountryCode');
          return;
        }
      }
      _initialPhoneCountryCode = 'US';
    } catch (e) {
      _initialPhoneCountryCode = 'US';
    }
  }

  /// Extract country code and local number from a full phone number
  /// Returns a map with 'countryCode' and 'localNumber'
  Map<String, String> _extractPhoneComponents(String phoneNumber) {
    if (!phoneNumber.startsWith('+')) {
      return {'countryCode': '', 'localNumber': phoneNumber};
    }
    
    // List of known country codes (sorted by length, longest first to match correctly)
    final countryCodes = [
      '+1', '+7', '+20', '+27', '+30', '+31', '+32', '+33', '+34', '+36', '+39',
      '+40', '+41', '+43', '+44', '+45', '+46', '+47', '+48', '+49', '+51', '+52',
      '+53', '+54', '+55', '+56', '+57', '+58', '+60', '+61', '+62', '+63', '+64',
      '+65', '+66', '+81', '+82', '+84', '+86', '+90', '+91', '+92', '+93', '+94',
      '+95', '+98', '+212', '+213', '+216', '+218', '+220', '+221', '+222', '+223',
      '+224', '+225', '+226', '+227', '+228', '+229', '+230', '+231', '+232', '+233',
      '+234', '+235', '+236', '+237', '+238', '+239', '+240', '+241', '+242', '+243',
      '+244', '+245', '+246', '+248', '+249', '+250', '+251', '+252', '+253', '+254',
      '+255', '+256', '+257', '+258', '+260', '+261', '+262', '+263', '+264', '+265',
      '+266', '+267', '+268', '+269', '+290', '+291', '+297', '+298', '+299', '+350',
      '+351', '+352', '+353', '+354', '+355', '+356', '+357', '+358', '+359', '+370',
      '+371', '+372', '+373', '+374', '+375', '+376', '+377', '+378', '+380', '+381',
      '+382', '+383', '+385', '+386', '+387', '+389', '+420', '+421', '+423', '+500',
      '+501', '+502', '+503', '+504', '+505', '+506', '+507', '+508', '+509', '+590',
      '+591', '+592', '+593', '+594', '+595', '+596', '+597', '+598', '+599', '+670',
      '+672', '+673', '+674', '+675', '+676', '+677', '+678', '+679', '+680', '+681',
      '+682', '+683', '+685', '+686', '+687', '+688', '+689', '+690', '+691', '+692',
      '+850', '+852', '+853', '+855', '+856', '+880', '+886', '+960', '+961', '+962',
      '+963', '+964', '+965', '+966', '+967', '+968', '+970', '+971', '+972', '+973',
      '+974', '+975', '+976', '+977', '+992', '+993', '+994', '+995', '+996', '+998',
    ];
    
    // Try to match country codes from longest to shortest
    for (final code in countryCodes) {
      if (phoneNumber.startsWith(code)) {
        final localNumber = phoneNumber.substring(code.length).replaceAll(RegExp(r'[^0-9]'), '');
        return {'countryCode': code, 'localNumber': localNumber};
      }
    }
    
    // Fallback: try to extract 1-3 digits as country code
    final match = RegExp(r'^\+(\d{1,3})(.+)').firstMatch(phoneNumber);
    if (match != null) {
      final countryCode = '+${match.group(1)}';
      final localNumber = match.group(2)!.replaceAll(RegExp(r'[^0-9]'), '');
      return {'countryCode': countryCode, 'localNumber': localNumber};
    }
    
    return {'countryCode': '', 'localNumber': phoneNumber};
  }

  String _getCountryFromCode(String code) {
    // Common country code mappings
    final codeMap = {
      '+1': 'US', '+216': 'TN', '+33': 'FR', '+49': 'DE', 
      '+44': 'GB', '+212': 'MA', '+213': 'DZ', '+966': 'SA',
      '+20': 'EG', '+27': 'ZA', '+30': 'GR', '+31': 'NL',
      '+32': 'BE', '+34': 'ES', '+39': 'IT', '+40': 'RO',
      '+41': 'CH', '+43': 'AT', '+45': 'DK', '+46': 'SE',
      '+47': 'NO', '+48': 'PL', '+51': 'PE', '+52': 'MX',
      '+54': 'AR', '+55': 'BR', '+60': 'MY', '+61': 'AU',
      '+62': 'ID', '+63': 'PH', '+64': 'NZ', '+65': 'SG',
      '+66': 'TH', '+81': 'JP', '+82': 'KR', '+84': 'VN',
      '+86': 'CN', '+90': 'TR', '+91': 'IN', '+92': 'PK',
      '+93': 'AF', '+94': 'LK', '+95': 'MM', '+98': 'IR',
      '+7': 'RU', '+36': 'HU', '+53': 'CU', '+56': 'CL',
      '+57': 'CO', '+58': 'VE', '+218': 'LY', '+220': 'GM',
      '+221': 'SN', '+222': 'MR', '+223': 'ML', '+224': 'GN',
      '+225': 'CI', '+226': 'BF', '+227': 'NE', '+228': 'TG',
      '+229': 'BJ', '+230': 'MU', '+231': 'LR', '+232': 'SL',
      '+233': 'GH', '+234': 'NG', '+235': 'TD', '+236': 'CF',
      '+237': 'CM', '+238': 'CV', '+239': 'ST', '+240': 'GQ',
      '+241': 'GA', '+242': 'CG', '+243': 'CD', '+244': 'AO',
      '+245': 'GW', '+246': 'IO', '+248': 'SC', '+249': 'SD',
      '+250': 'RW', '+251': 'ET', '+252': 'SO', '+253': 'DJ',
      '+254': 'KE', '+255': 'TZ', '+256': 'UG', '+257': 'BI',
      '+258': 'MZ', '+260': 'ZM', '+261': 'MG', '+262': 'RE',
      '+263': 'ZW', '+264': 'NA', '+265': 'MW', '+266': 'LS',
      '+267': 'BW', '+268': 'SZ', '+269': 'KM', '+290': 'SH',
      '+291': 'ER', '+297': 'AW', '+298': 'FO', '+299': 'GL',
      '+350': 'GI', '+351': 'PT', '+352': 'LU', '+353': 'IE',
      '+354': 'IS', '+355': 'AL', '+356': 'MT', '+357': 'CY',
      '+358': 'FI', '+359': 'BG', '+370': 'LT', '+371': 'LV',
      '+372': 'EE', '+373': 'MD', '+374': 'AM', '+375': 'BY',
      '+376': 'AD', '+377': 'MC', '+378': 'SM', '+380': 'UA',
      '+381': 'RS', '+382': 'ME', '+383': 'XK', '+385': 'HR',
      '+386': 'SI', '+387': 'BA', '+389': 'MK', '+420': 'CZ',
      '+421': 'SK', '+423': 'LI', '+500': 'FK', '+501': 'BZ',
      '+502': 'GT', '+503': 'SV', '+504': 'HN', '+505': 'NI',
      '+506': 'CR', '+507': 'PA', '+508': 'PM', '+509': 'HT',
      '+590': 'BL', '+591': 'BO', '+592': 'GY', '+593': 'EC',
      '+594': 'GF', '+595': 'PY', '+596': 'MQ', '+597': 'SR',
      '+598': 'UY', '+599': 'CW', '+670': 'TL', '+672': 'AQ',
      '+673': 'BN', '+674': 'NR', '+675': 'PG', '+676': 'TO',
      '+677': 'SB', '+678': 'VU', '+679': 'FJ', '+680': 'PW',
      '+681': 'WF', '+682': 'CK', '+683': 'NU', '+685': 'WS',
      '+686': 'KI', '+687': 'NC', '+688': 'TV', '+689': 'PF',
      '+690': 'TK', '+691': 'FM', '+692': 'MH', '+850': 'KP',
      '+852': 'HK', '+853': 'MO', '+855': 'KH', '+856': 'LA',
      '+880': 'BD', '+886': 'TW', '+960': 'MV', '+961': 'LB',
      '+962': 'JO', '+963': 'SY', '+964': 'IQ', '+965': 'KW',
      '+967': 'YE', '+968': 'OM', '+970': 'PS', '+971': 'AE',
      '+972': 'IL', '+973': 'BH', '+974': 'QA', '+975': 'BT',
      '+976': 'MN', '+977': 'NP', '+992': 'TJ', '+993': 'TM',
      '+994': 'AZ', '+995': 'GE', '+996': 'KG', '+998': 'UZ',
    };
    return codeMap[code] ?? 'US';
  }

  @override
  void dispose() {
    // Don't dispose the global instance
    if (_places != _globalPlaces) {
      _places?.dispose();
    }
    _resendTimer?.cancel();
    _addressSearchDebounce?.cancel();
    _phoneFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Send SMS verification code
  Future<void> _sendSMSVerification() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseEnterPhoneNumberFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!PhoneVerificationService.isValidPhoneNumber(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseEnterValidPhoneNumber),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSendingSMS = true;
    });

    try {
      await PhoneVerificationService.sendSMSVerification(
        phoneNumber: _phoneController.text,
        onCodeSent: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isSendingSMS = false;
            _resendCountdown = 60; // 60 seconds cooldown
          });
          _startResendTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS verification code sent!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (String error) {
          setState(() {
            _isSendingSMS = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending SMS: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onTimeout: () {
          setState(() {
            _isSendingSMS = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS verification timed out. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isSendingSMS = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Verify SMS code
  Future<void> _verifySMSCode() async {
    if (_smsCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please send SMS verification first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    try {
      bool isVerified = await PhoneVerificationService.verifySMSCode(
        _phoneController.text,
        _smsCodeController.text,
      );

      setState(() {
        _isVerifyingCode = false;
      });

      if (isVerified) {
        setState(() {
          _isPhoneVerified = true;
        });
        _resendTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).phoneNumberVerifiedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid verification code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifyingCode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Start resend timer
  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // Helper method to determine if phone is verified
  bool _isPhoneVerifiedStatus(UserData? user) {
    // If phone was already verified from phone sign-in, it's verified
    if (widget.isPhoneVerified && widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      if (_phoneController.text == widget.phoneNumber || _phoneController.text.isEmpty) {
        return true; // Phone is verified from sign-in
      }
    }
    
    // If user is actively editing the phone field, show as needs verification
    if (_isPhoneModified || (_hasPhoneBeenCleared && _originalPhone != null && _originalPhone!.isNotEmpty)) {
      return false; // Show as needs verification
    }
    
    // Check if the user has a phone number and it's verified
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      return user.isPhoneVerified == true;
    }
    return false;
  }

  // Helper method to get the appropriate verification message
  String _getPhoneVerificationMessage(UserData? user) {
    final l10n = AppLocalizations.of(context);
    // If user is actively editing the phone field
    if (_isPhoneModified || (_hasPhoneBeenCleared && _originalPhone != null && _originalPhone!.isNotEmpty)) {
      return l10n.phoneNumberNeedsVerification;
    }
    
    // Check if the user has a phone number and it's verified
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      return user.isPhoneVerified == true ? l10n.phoneNumberVerified : l10n.phoneNumberNotVerified;
    }
    return l10n.phoneNumberNotVerified;
  }

  // Helper method to determine if verification UI should be shown
  bool _shouldShowVerificationUI(UserData? user) {
    // Don't show verification UI if phone is already verified from phone sign-in
    if (widget.isPhoneVerified && widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      if (_phoneController.text == widget.phoneNumber || _phoneController.text.isEmpty) {
        return false; // Phone already verified, don't show verification UI
      }
    }
    
    // Show verification UI if:
    // 1. Phone has been modified (user is changing it)
    // 2. Phone is not verified and there's a phone number
    return _isPhoneModified || 
           (user?.phoneNumber != null && 
            user!.phoneNumber!.isNotEmpty && 
            user.isPhoneVerified != true);
  }

  // Resend SMS code
  Future<void> _resendSMS() async {
    if (_resendCountdown > 0) return;
    await _sendSMSVerification();
  }

  Future<void> _requestPermissions() async {
    try {
      // Request photo library permission
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied) {
        final result = await Permission.photos.request();
        if (result.isDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo library permission is required to select a profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Request camera permission
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to take profile pictures'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Request location permission
      final locationStatus = await Permission.location.status;
      if (locationStatus.isDenied) {
        final result = await Permission.location.request();
        if (result.isDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).locationPermissionRequired),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Check for permanently denied permissions
      if (photosStatus.isPermanentlyDenied || cameraStatus.isPermanentlyDenied) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permissions Required'),
              content: const Text(
                'Some permissions are permanently denied. Please enable them in your device settings to use all features of the app.',
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () {
                    openAppSettings();
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      print('Starting image picker process...');
      
      // Request both permissions upfront
      print('Requesting photo library permission...');
      final photosResult = await Permission.photos.request();
      print('Photo library permission status: ${photosResult.name}');
      
      print('Requesting camera permission...');
      final cameraResult = await Permission.camera.request();
      print('Camera permission status: ${cameraResult.name}');

      if (photosResult.isDenied || cameraResult.isDenied) {
        print('Permissions denied');
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text('Please allow access to both camera and photo library to continue.'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Try Again'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
        );
        return;
      }

      print('Permissions granted, showing source selection dialog');
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
      if (source == null) {
        print('No source selected');
        return;
      }

      print('Selected source: ${source.name}');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        print('File picked successfully');
        final File imageFile = File(pickedFile.path);
        if (!await imageFile.exists()) {
          throw Exception('Selected image file does not exist');
        }

        final fileSize = await imageFile.length();
        File finalImageFile = imageFile;
        
        if (fileSize > 1024 * 1024) {
          print('Compressing large image...');
          finalImageFile = await _compressImage(imageFile);
        }

        if (mounted) {
          setState(() {
            _profilePhotoFile = finalImageFile;
          });
        print('Image set successfully');
      }
      } else {
        print('No file picked');
      }
    } catch (e) {
      print('Error in _pickImage: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error picking image: ${e.toString()}'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
        ),
      );
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      print('Starting image compression...');
      final bytes = await file.readAsBytes();
      print('Image bytes read: ${bytes.length}');
      
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        print('Failed to decode image');
        return file;
      }

      print('Original image size: ${image.width}x${image.height}');
      
      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (image.width > 400 || image.height > 400) {
        if (image.width > image.height) {
          newWidth = 400;
          newHeight = (400 * image.height / image.width).round();
        } else {
          newHeight = 400;
          newWidth = (400 * image.width / image.height).round();
        }
      }

      print('Resizing to: ${newWidth}x${newHeight}');
      
      final resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
      
      final compressed = img.encodeJpg(resized, quality: 70);
      print('Compressed image size: ${compressed.length} bytes');
      
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);
      
      print('Compressed image saved to: ${tempFile.path}');
      return tempFile;
    } catch (e) {
      print('Error compressing image: $e');
      return file;
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      setState(() => _isLoading = true);
      
      print('Starting Firebase upload...');
      print('File path: ${imageFile.path}');
      print('File exists: ${await imageFile.exists()}');
      print('File size: ${await imageFile.length()} bytes');
      
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.jpg';
      print('File name: $fileName');
      
      // Get a reference to the storage location
      final storageRef = FirebaseStorage.instance;
      final profilePhotosRef = storageRef.ref().child('profile_photos');
      
      // Ensure the profile_photos directory exists
      try {
        print('Checking profile_photos directory...');
        await profilePhotosRef.listAll();
        print('profile_photos directory exists');
      } catch (e) {
        print('Creating profile_photos directory...');
        // Create a dummy file to ensure the directory exists
        await profilePhotosRef.child('.placeholder').putString('');
        print('profile_photos directory created');
      }
      
      // Get reference to the file
      final fileRef = profilePhotosRef.child(fileName);
      print('Full upload path: ${fileRef.fullPath}');
      
      // Set metadata for better caching
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': imageFile.path},
      );
      
      print('Starting upload task...');
      final uploadTask = await fileRef.putFile(imageFile, metadata);
      print('Upload task completed. Bytes transferred: ${uploadTask.bytesTransferred}');
      
      print('Getting download URL...');
      final url = await fileRef.getDownloadURL();
      print('Download URL obtained: $url');
      
      return url;
    } catch (e, stackTrace) {
      print('Firebase upload error: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = 'Error uploading image';
      if (e is FirebaseException) {
        errorMessage = 'Firebase error: ${e.message}';
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    // For new users, ensure all required fields are filled
    if (widget.isNewUserSetup) {
      if (_fullNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pleaseEnterYourFullName),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Only require phone if not already verified from phone sign-in
      if (!(widget.isPhoneVerified && widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty)) {
        if (_phoneController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).pleaseEnterYourPhoneNumber),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pleaseEnterYourAddress),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validate email if provided (for phone sign-in users)
      final isPhoneSignInUser = widget.email.startsWith('phone_') && widget.email.endsWith('@bottleji.temp');
      if (isPhoneSignInUser && _emailController.text.isNotEmpty) {
        // Email validation will be done on backend, but we can do basic format check here
        if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).pleaseEnterValidEmail),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }
    
    // Check phone verification for new users or when phone is changed and not empty
    // Skip if phone is already verified from phone sign-in
    if (!widget.isPhoneVerified && (widget.isNewUserSetup || (_isPhoneModified && _phoneController.text.isNotEmpty))) {
      if (!_isPhoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pleaseVerifyYourPhoneNumber),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    setState(() => _isLoading = true);
    try {
      // Determine which fields have changed
      final changedFields = <String, dynamic>{};
      
      // Check if name changed
      if (_fullNameController.text != _originalName) {
        changedFields['name'] = _fullNameController.text;
        print('Name changed from "$_originalName" to "${_fullNameController.text}"');
      }
      
      // Check if email changed (for phone sign-in users only)
      // For email/password users, email cannot be changed
      final isPhoneSignInUser = (widget.email.startsWith('phone_') && widget.email.endsWith('@bottleji.temp')) || 
                                 (user?.registeredWithPhone == true);
      
      // Only allow email changes for phone sign-in users
      if (isPhoneSignInUser && _emailController.text.isNotEmpty && _emailController.text != widget.email) {
        changedFields['email'] = _emailController.text;
        print('Email changed from "${widget.email}" to "${_emailController.text}"');
      } else if (!isPhoneSignInUser && _emailController.text != widget.email && _emailController.text.isNotEmpty) {
        // Email/password user trying to change email - show error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email cannot be changed for email/password accounts'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Check if phone changed and is not empty, OR if phone is already verified from phone sign-in (need to include it)
      if (_isPhoneModified && _phoneController.text.isNotEmpty) {
        // Use the complete phone number with country code from IntlPhoneField
        final fullPhoneNumber = _completePhoneNumber.isNotEmpty 
            ? _completePhoneNumber 
            : '$_phoneCountryCode${_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}';
        changedFields['phone'] = fullPhoneNumber;
        print('Phone changed from "$_originalPhone" to "$fullPhoneNumber"');
      } else if (widget.isPhoneVerified && widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
        // Phone is already verified from phone sign-in, include it in the profile setup
        changedFields['phone'] = widget.phoneNumber!;
        print('Phone already verified from phone sign-in: ${widget.phoneNumber}');
      }
      
      // Check if address changed
      if (_addressController.text != _originalAddress) {
        changedFields['address'] = _addressController.text;
        print('Address changed from "$_originalAddress" to "${_addressController.text}"');
      }
      
      // Check if profile photo changed
      String? newProfilePhotoUrl;
      if (_profilePhotoFile != null) {
        print('Uploading profile image to Firebase...');
        newProfilePhotoUrl = await _uploadImageToFirebase(_profilePhotoFile!);
        if (newProfilePhotoUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).failedToUploadImage('Unknown error')),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
        print('Profile image uploaded successfully. URL: $newProfilePhotoUrl');
        
        if (newProfilePhotoUrl != _originalProfilePhoto) {
          changedFields['profilePhoto'] = newProfilePhotoUrl;
          print('Profile photo changed from "$_originalProfilePhoto" to "$newProfilePhotoUrl"');
        }
      }
      
      // If no fields changed, show message and return
      if (changedFields.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).noChangesDetected),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      print('Changed fields: $changedFields');
      
      // Use the appropriate method based on whether it's a new user setup or existing user update
      try {
        if (widget.isNewUserSetup) {
          // For new users, use setupProfile which sets isProfileComplete to true
          await ref.read(authNotifierProvider.notifier).setupProfile(
            email: changedFields['email'] ?? (isPhoneSignInUser ? _emailController.text : null),
            name: changedFields['name'] ?? _originalName,
            phone: changedFields['phone'] ?? _originalPhone,
            address: changedFields['address'] ?? _originalAddress,
            profilePhoto: changedFields['profilePhoto'] ?? _originalProfilePhoto,
          );
        } else {
          // For existing users, use updateProfile
        await ref.read(authNotifierProvider.notifier).updateProfile(
          email: changedFields['email'],
          name: changedFields['name'] ?? _originalName,
          phone: changedFields['phone'] ?? _originalPhone,
          address: changedFields['address'] ?? _originalAddress,
          profilePhoto: changedFields['profilePhoto'] ?? _originalProfilePhoto,
        );
        }
        
        print('Profile updated successfully via provider');
        
        // Track successful profile update
        final userAsync = ref.read(authNotifierProvider);
        final user = userAsync.value;
        if (user != null) {
          // Activity tracking removed
        }
        
        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isNewUserSetup 
                ? AppLocalizations.of(context).profileSetupCompletedSuccessfully
                : AppLocalizations.of(context).profileUpdatedSuccessfully),
            backgroundColor: Colors.green,
            duration: Duration(seconds: widget.isNewUserSetup ? 3 : 2),
          ),
        );
        
        // Refresh the provider state to ensure Account page sees latest user data
        await ref.refresh(authNotifierProvider);
        
        // Add a small delay to ensure the auth state is properly updated
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check the updated auth state
        final updatedAuthState = ref.read(authNotifierProvider);
        print('Profile setup - Updated auth state: $updatedAuthState');
        print('Profile setup - User ID after update: ${updatedAuthState.value?.id}');
        
        // For new users, navigate to the main app after profile setup
        if (widget.isNewUserSetup) {
          // Navigate to home screen and clear the navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        } else {
          // For existing users, navigate back to the previous screen (Account screen)
        Navigator.pop(context);
        }
      } catch (e) {
        print('Error updating profile via provider: $e');
        
        // Track failed profile update
        final userAsync = ref.read(authNotifierProvider);
        final user = userAsync.value;
        if (user != null) {
          // Activity tracking removed
        }
        
        if (!mounted) return;
        
        String errorMessage = 'Failed to update profile: $e';
        // Check if error is about email already taken
        if (e.toString().contains('Email already registered') || 
            e.toString().contains('already associated with another account')) {
          errorMessage = 'This email is already associated with another account. Please use a different email address.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error in _saveProfile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    // Cancel previous debounce timer
    _addressSearchDebounce?.cancel();
    
    // Clear suggestions if query is empty
    if (query.isEmpty) {
      setState(() {
        _addressSuggestions = [];
        _addressSearchError = null;
        _isLoadingAddressSuggestions = false;
      });
      return;
    }
    
    // Debounce the search to avoid too many API calls
    _addressSearchDebounce = Timer(const Duration(milliseconds: 500), () async {
      // Use the global instance if available, otherwise create a new one
      if (_places == null) {
        _places = _globalPlaces;
      }

      // Test the API before searching
      try {
        final testResponse = await _places?.autocomplete(
          'test',
          language: "en",
          components: [Component(Component.country, "tn")],
        );
        if (testResponse?.status != "OK") {
          _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
        }
      } catch (e) {
        _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
      }

      if (!mounted) return;
      
      setState(() {
        _isLoadingAddressSuggestions = true;
        _addressSearchError = null;
      });

      try {
        final response = await _places?.autocomplete(
          query,
          language: "en",
          components: [Component(Component.country, "tn")],
        );

        if (!mounted) return;

        if (response?.status == "OK") {
          setState(() {
            _addressSuggestions = response?.predictions ?? [];
            _addressSearchError = null;
            _isLoadingAddressSuggestions = false;
          });
        } else {
          setState(() {
            _addressSearchError = AppLocalizations.of(context).noResultsFound;
            _addressSuggestions = [];
            _isLoadingAddressSuggestions = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _addressSearchError = AppLocalizations.of(context).errorFetchingSuggestions(e.toString());
          _addressSuggestions = [];
          _isLoadingAddressSuggestions = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final userAsync = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    
    return userAsync.when(
      data: (user) {

        
        if (user != null) {
          // Store original values for change detection
          if (widget.isNewUserSetup) {
            // For new users, set original values to null/empty
            _originalName = null;
            _originalPhone = null;
            _originalAddress = null;
            _originalProfilePhoto = null;
          } else {
            // For existing users, store their current values
            _originalName = user.name;
            _originalPhone = user.phoneNumber;
            _originalAddress = user.address;
            _originalProfilePhoto = user.profilePhoto;
          }
          
          // Only populate form fields if it's NOT a new user setup
          // New users should see empty forms
          if (!widget.isNewUserSetup) {
            // Only update controllers if they are empty (prevents overwriting user edits)
            if (_fullNameController.text.isEmpty) {
              _fullNameController.text = user.name ?? '';
            }
            if (_phoneController.text.isEmpty) {
              // Extract local number from full phone number (remove country code)
              String phoneNumber = user.phoneNumber ?? '';
              if (phoneNumber.isNotEmpty) {
                final components = _extractPhoneComponents(phoneNumber);
                if (components['countryCode']!.isNotEmpty) {
                  _phoneCountryCode = components['countryCode']!;
                  _phoneController.text = components['localNumber']!;
                  // Extract country code from user's existing phone number (not device locale)
                  _initialPhoneCountryCode = _getCountryFromCode(_phoneCountryCode);
                  _completePhoneNumber = phoneNumber; // Store complete number
                  print('📱 ProfileSetupScreen: Extracted country code from existing user phone: ${components['countryCode']} -> $_initialPhoneCountryCode, local: ${components['localNumber']}');
                } else {
                  // Fallback: just use the number as-is
                  _phoneController.text = phoneNumber;
                }
              }
              // Reset the cleared flag when phone number is loaded
              _hasPhoneBeenCleared = false;
            }
            if (_addressController.text.isEmpty && !_hasAddressBeenCleared) {
              _addressController.text = user.address ?? '';
            }
          } else {
            // For new user setup, only clear fields if they haven't been initialized yet
            if (!_fieldsInitialized) {
            _fullNameController.clear();
            _phoneController.clear();
            _addressController.clear();
              _fieldsInitialized = true; // Mark fields as initialized
            }
          }
        }

        // Check if profile is completed (has name, phone, and address)
        // final isProfileCompleted = user?.name != null && 
        //                          user!.name!.isNotEmpty && 
        //                          user.phoneNumber != null && 
        //                          user.phoneNumber!.isNotEmpty &&
        //                          user.address != null &&
        //                          user.address!.isNotEmpty;

        // Determine the title based on context
        final l10n = AppLocalizations.of(context);
        final screenTitle = widget.isNewUserSetup 
            ? l10n.completeYourProfile 
            : l10n.editProfile;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            leading: widget.isNewUserSetup ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                // Silently logout without confirmation dialog
                  // Clear only auth-related SharedPreferences, preserve onboarding flags
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('auth_token');
                  await prefs.remove('auth_data');
                  await prefs.setBool('is_logged_in', false);
                  
                  // Logout from auth provider
                  await ref.read(authNotifierProvider.notifier).logout(ref);
                  
                  // Navigate to login screen
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                }
              },
            ) : null,
            title: Text(
              screenTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF00695C),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [],
          ),
          body: Stack(
            children: [
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Photo Section
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(context).profilePhoto,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: appGreenColor,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: appGreenColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: appGreenColor.withOpacity(0.1),
                                    backgroundImage: _profilePhotoFile != null
                                        ? FileImage(_profilePhotoFile!)
                                        : (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                                            ? NetworkImage(user.profilePhoto!)
                                            : null),
                                    child: _profilePhotoFile == null && (user?.profilePhoto == null || (user?.profilePhoto?.isEmpty ?? true))
                                        ? Icon(
                                            Icons.camera_alt,
                                            size: 40,
                                            color: appGreenColor,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context).tapToChangePhoto,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form Fields Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).personalInformation,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Full Name Field
                              _buildFormField(
                                controller: _fullNameController,
                                label: AppLocalizations.of(context).fullName,
                                icon: Icons.person_outline,
                                validator: (v) {
                                  final l10n = AppLocalizations.of(context);
                                  // Always validate as required for new users
                                  if (widget.isNewUserSetup) {
                                    return v == null || v.isEmpty ? l10n.fullNameRequired : null;
                                  }
                                  // For existing users, only validate if the name has changed
                                  if (_fullNameController.text != _originalName) {
                                    return v == null || v.isEmpty ? l10n.fullNameRequired : null;
                                  }
                                  return null; // Skip validation if name hasn't changed
                                },
                                iconColor: appGreenColor,
                              ),
                              const SizedBox(height: 20),
                              
                              // Email Field
                              // For phone sign-in users: editable (can add email)
                              // For email sign-in users: read-only (can't change)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: appGreenColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.email_outlined,
                                          color: appGreenColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppLocalizations.of(context).email,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      // Email verification badge
                                      if (!widget.isNewUserSetup && user?.email != null && user!.email!.isNotEmpty && !user.email!.startsWith('phone_'))
                                        Builder(
                                          builder: (context) {
                                            final isEmailVerified = (user!.isEmailVerified ?? false);
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isEmailVerified
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isEmailVerified
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isEmailVerified
                                                        ? Icons.verified
                                                        : Icons.warning_amber_rounded,
                                                    size: 14,
                                                    color: isEmailVerified
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isEmailVerified
                                                        ? 'Verified'
                                                        : 'Unverified',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isEmailVerified
                                                          ? Colors.green
                                                          : Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    readOnly: !(widget.email.startsWith('phone_') && widget.email.endsWith('@bottleji.temp')) && 
                                              !(user?.registeredWithPhone == true),
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(color: theme.colorScheme.onSurface),
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context).email,
                                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: theme.colorScheme.outline),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: theme.colorScheme.outline),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: appGreenColor, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    validator: (v) {
                                      // Only validate if email is provided (optional for phone sign-in users)
                                      if (v != null && v.isNotEmpty) {
                                        if (!v.contains('@') || !v.contains('.')) {
                                          return AppLocalizations.of(context).pleaseEnterValidEmail;
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  // Show verification message for unverified email
                                  if (!widget.isNewUserSetup && user?.email != null && user!.email!.isNotEmpty && !user.email!.startsWith('phone_') && !(user.isEmailVerified ?? false))
                                    Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Please verify your email address to receive important notifications.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  // Navigate to email verification or show dialog
                                                  if (user != null) {
                                                    _showEmailVerificationDialog(context, user);
                                                  }
                                                },
                                                child: Text('Verify'),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size(0, 0),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Phone Field - Only show if not already verified from phone sign-in
                              if (!(widget.isPhoneVerified && widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.lightMapPin.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.phone_outlined,
                                            color: AppColors.lightMapPin,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizations.of(context).phoneNumber,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Phone number input field with country code picker
                                    IntlPhoneField(
                                      controller: _phoneController,
                                      enabled: !(widget.isPhoneVerified && widget.phoneNumber != null),
                                      style: TextStyle(color: theme.colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context).enterYourPhoneNumber,
                                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: theme.colorScheme.outline),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: theme.colorScheme.outline),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: appGreenColor, width: 2),
                                        ),
                                        filled: true,
                                        fillColor: theme.colorScheme.surface,
                                      ),
                                      initialCountryCode: _initialPhoneCountryCode,
                                      onChanged: (phone) {
                                        _phoneCountryCode = phone.countryCode;
                                        _completePhoneNumber = phone.completeNumber;
                                        if (phone.number.isNotEmpty) {
                                          _isPhoneModified = true;
                                        }
                                      },
                                      validator: (phone) {
                                        // Skip validation if phone is already verified from phone sign-in
                                        if (widget.isPhoneVerified && widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
                                          return null; // Phone already verified, no validation needed
                                        }
                                        
                                        // Always validate as required for new users (email sign-up)
                                        if (widget.isNewUserSetup) {
                                          if (phone == null || phone.number.isEmpty) {
                                            return AppLocalizations.of(context).phoneNumberRequired;
                                          }
                                          if (!PhoneVerificationService.isValidPhoneNumber(phone.completeNumber)) {
                                            return AppLocalizations.of(context).pleaseEnterValidPhoneNumber;
                                          }
                                        }
                                        // For existing users, only validate if the phone has been modified
                                        if (_isPhoneModified && phone != null && phone.number.isNotEmpty) {
                                          if (!PhoneVerificationService.isValidPhoneNumber(phone.completeNumber)) {
                                            return AppLocalizations.of(context).pleaseEnterValidPhoneNumber;
                                          }
                                        }
                                        return null;
                                      },
                                      dropdownIcon: Icon(
                                        Icons.arrow_drop_down,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      flagsButtonPadding: const EdgeInsets.only(left: 12),
                                      dropdownTextStyle: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                // Show verified phone number (read-only) for phone sign-in users
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.phone_outlined,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizations.of(context).phoneNumber,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.green, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.phoneNumber!,
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              AppLocalizations.of(context).phoneNumberVerified,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              
                              // Phone verification status - only show for email sign-in users who need to verify
                              if (!(widget.isPhoneVerified && widget.phoneNumber != null) && user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      _isPhoneVerifiedStatus(user) ? Icons.verified : Icons.warning,
                                      size: 16,
                                      color: _isPhoneVerifiedStatus(user) ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getPhoneVerificationMessage(user),
                                      style: TextStyle(
                                        color: _isPhoneVerifiedStatus(user) ? Colors.green.shade800 : Colors.orange.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                                  
                              // Phone verification UI - show only when needed (not for phone sign-in users)
                              if (!(widget.isPhoneVerified && widget.phoneNumber != null) && _shouldShowVerificationUI(user)) ...[
                                // Verification buttons
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: OutlinedButton.icon(
                                        onPressed: _isSendingSMS ? null : _sendSMSVerification,
                                        icon: _isSendingSMS 
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: appGreenColor,
                                                ),
                                              )
                                            : const Icon(Icons.send, size: 16),
                                        label: Text(
                                          _isSendingSMS ? AppLocalizations.of(context).sending : AppLocalizations.of(context).sendCode,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: appGreenColor,
                                          side: BorderSide(color: appGreenColor),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        ),
                                      ),
                                    ),
                                    if (_verificationId != null) ...[
                                      SizedBox(
                                        width: 100,
                                        child: OutlinedButton.icon(
                                          onPressed: _resendCountdown > 0 ? null : _resendSMS,
                                          icon: const Icon(Icons.refresh, size: 16),
                                          label: Text(
                                            _resendCountdown > 0 ? '$_resendCountdown' : AppLocalizations.of(context).resend,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _resendCountdown > 0 ? Colors.grey : appGreenColor,
                                            side: BorderSide(color: _resendCountdown > 0 ? Colors.grey : appGreenColor),
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // SMS Code Input
                                if (_verificationId != null) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _smsCodeController,
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          textDirection: TextDirection.ltr, // Force LTR for OTP codes
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(context).smsCode,
                                            hintText: AppLocalizations.of(context).enter6DigitCode,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: theme.colorScheme.outline),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: theme.colorScheme.outline),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: appGreenColor, width: 2),
                                            ),
                                            filled: true,
                                            fillColor: theme.colorScheme.surface,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            counterText: '',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        child: FilledButton.icon(
                                          onPressed: _isVerifyingCode ? null : _verifySMSCode,
                                          icon: _isVerifyingCode 
                                              ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.check),
                                          label: Text(_isVerifyingCode ? AppLocalizations.of(context).verifying : AppLocalizations.of(context).verifyCode),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: appGreenColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Verification status
                                  if (_isPhoneVerified) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(context).phoneNumberVerified,
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                              const SizedBox(height: 20),
                              
                              // Address Field
                              _buildAddressField(context, theme),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _saveProfile,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isLoading 
                              ? AppLocalizations.of(context).saving
                              : (widget.isNewUserSetup ? AppLocalizations.of(context).completeSetup : AppLocalizations.of(context).saveProfile)),
                          style: FilledButton.styleFrom(
                            backgroundColor: appGreenColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Builder(
            builder: (context) => Text(
              AppLocalizations.of(context).editProfile,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Builder(
            builder: (context) => Text(
              AppLocalizations.of(context).editProfile,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(authNotifierProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lightPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixText: prefixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: appGreenColor, width: 2),
            ),
            filled: true,
            fillColor: readOnly 
                ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                : theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
    
  


  void _showEmailVerificationDialog(BuildContext context, UserData user) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    bool isResending = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Verify Email',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the verification code sent to ${user.email}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter 6-digit code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              if (isResending)
                Center(
                  child: CircularProgressIndicator(),
                )
              else
                TextButton(
                  onPressed: () async {
                    setDialogState(() {
                      isResending = true;
                    });
                  try {
                    final authRepo = ref.read(authRepositoryProvider);
                    await authRepo.resendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Verification code resent!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to resend code: $e')),
                        );
                      }
                    } finally {
                      setDialogState(() {
                        isResending = false;
                      });
                    }
                  },
                  child: Text('Resend Code'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                if (otpController.text.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a 6-digit code')),
                  );
                  return;
                }
                
                setDialogState(() {
                  isVerifying = true;
                });
                
                try {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.verifyEmail(otpController.text);
                  
                  // Refresh user data
                  await ref.read(authNotifierProvider.notifier).refreshUserData();
                  
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email verified successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    String errorMessage = 'Verification failed: $e';
                    // Check if error is about email already associated with another account
                    if (e.toString().contains('already verified and associated with another account') || 
                        e.toString().contains('Email already registered')) {
                      errorMessage = 'This email is already associated with another account. Please use a different email address in your profile.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        duration: const Duration(seconds: 5),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  setDialogState(() {
                    isVerifying = false;
                  });
                }
              },
              child: isVerifying
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.lightSuccess,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).address,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

      /// Address field
        FormField<String>(
          validator: (value) {
          // Validate only if new user or address changed
          final l10n = AppLocalizations.of(context);
          if (widget.isNewUserSetup ||
              _addressController.text != _originalAddress) {
            return value == null || value.isEmpty
                ? l10n.addressRequired
                : null;
          }
          return null; // Skip validation if unchanged
          },
          builder: (FormFieldState<String> field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).typeToSearch,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.lightPrimary, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isLoadingAddressSuggestions
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    errorText: field.errorText,
                  ),
                  onChanged: (value) {
                    field.didChange(value);
                    _searchAddress(value);
                  },
                ),
                // Show suggestions list
                if (_addressSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _addressSuggestions.length,
                      itemBuilder: (context, index) {
                        final prediction = _addressSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(
                            prediction.description ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                          onTap: () {
                            _addressController.text = prediction.description ?? '';
                            setState(() {
                              _addressSuggestions = [];
                              _hasAddressBeenCleared = false; // Reset cleared flag when address is selected
                            });
                            field.didChange(_addressController.text);
                            _formKey.currentState?.validate();
                            // Remove focus to hide keyboard
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    ),
                  )
                else if (_addressSearchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      _addressSearchError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
} 

  
