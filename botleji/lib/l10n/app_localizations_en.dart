// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bottleji';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Change app language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get french => 'French';

  @override
  String get german => 'German';

  @override
  String get arabic => 'Arabic';

  @override
  String get location => 'Location';

  @override
  String get manageLocationPreferences => 'Manage location preferences';

  @override
  String get notifications => 'Notifications';

  @override
  String get manageNotificationPreferences => 'Manage notification preferences';

  @override
  String get displayTheme => 'Display Theme';

  @override
  String get changeAppAppearance => 'Change app appearance';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get loading => 'Loading...';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get invalidEmailOrPassword =>
      'Invalid email or password. Please try again.';

  @override
  String get loginFailed =>
      'Login failed. Please check your credentials and try again.';

  @override
  String get connectionTimeout =>
      'Connection timeout. Please check your internet connection and try again.';

  @override
  String get networkError =>
      'Network error. Please check your internet connection.';

  @override
  String get requestTimeout => 'Request timeout. Please try again.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get accountDeleted => 'Account Deleted';

  @override
  String get accountDeletedMessage =>
      'Your account has been deleted by an administrator.\n\nIf you believe this is a mistake, please contact our support team:\n\n📧 Email: support@bottleji.com\n📱 Support Hours: 9 AM - 6 PM (GMT+1)\n\nWe apologize for any inconvenience.';

  @override
  String get reason => 'Reason';

  @override
  String get youWillBeRedirectedToLoginScreen =>
      'You will be redirected to the login screen.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterEmailToReceiveResetCode =>
      'Enter your email to receive a reset code';

  @override
  String get sendResetCode => 'Send Reset Code';

  @override
  String get resetCodeSentToEmail => 'Reset code sent to your email';

  @override
  String get enterResetCode => 'Enter Reset Code';

  @override
  String weHaveSentResetCodeTo(String email) {
    return 'We have sent a reset code to\n$email';
  }

  @override
  String get verify => 'Verify';

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get resend => 'Resend';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resetCodeResentSuccessfully => 'Reset code resent successfully!';

  @override
  String get createNewPassword => 'Create New Password';

  @override
  String get pleaseEnterNewPassword => 'Please enter your new password';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterNewPassword => 'Enter your new password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmNewPassword => 'Confirm your new password';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Password must be at least 6 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordResetSuccessful =>
      'Password reset successful! Please login with your new password.';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get pleaseEnterOtpSentToEmail =>
      'Please enter the OTP sent to your email';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendOtpIn(int seconds) {
    return 'Resend OTP in $seconds seconds';
  }

  @override
  String get otpVerifiedSuccessfully => 'OTP verified successfully';

  @override
  String get invalidVerificationResponse =>
      'Error: Invalid verification response';

  @override
  String get otpResentSuccessfully => 'OTP resent successfully!';

  @override
  String get startYourBottlejiJourney => 'Start Your Bottleji Journey';

  @override
  String get createAccountToGetStarted => 'Create an account to get started';

  @override
  String get createAPassword => 'Create a password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get registrationSuccessful => 'Registration successful';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get welcomeToBottleji => 'Welcome to Bottleji';

  @override
  String get yourSustainableWasteManagementSolution =>
      'Your Sustainable Waste Management Solution';

  @override
  String get joinThousandsOfUsersMakingDifference =>
      'Join thousands of users making a difference by recycling bottles and cans while earning rewards.';

  @override
  String get createAndTrackDrops => 'Create & Track Drops';

  @override
  String get forHouseholdUsers => 'For Household Users';

  @override
  String get easilyCreateDropRequests =>
      'Easily create drop requests for your recyclable bottles and cans. Track collection status and get notified when collectors pick them up.';

  @override
  String get collectAndEarn => 'Collect & Earn';

  @override
  String get forCollectors => 'For Collectors';

  @override
  String get findNearbyDropsCollectRecyclables =>
      'Find nearby drops, collect recyclables, and earn rewards. Help build a sustainable community while making money.';

  @override
  String get realTimeUpdates => 'Real-time Updates';

  @override
  String get stayConnected => 'Stay Connected';

  @override
  String get getInstantNotificationsAboutDrops =>
      'Get instant notifications about your drops, collections, and important updates. Never miss an opportunity.';

  @override
  String get appPermissions => 'App Permissions';

  @override
  String get bottlejiRequiresAdditionalPermissions =>
      'Bottleji requires additional permissions to work properly';

  @override
  String get permissionsHelpProvideBestExperience =>
      'These permissions help us provide you with the best experience.';

  @override
  String get locationServices => 'Location Services';

  @override
  String get accessLocationToShowNearbyDrops =>
      'Access your location to show nearby drops and enable navigation for collectors.';

  @override
  String get localNetworkAccess => 'Local Network Access';

  @override
  String get allowAppToDiscoverServicesOnWifi =>
      'Allow the app to discover services on your Wi‑Fi for real-time features.';

  @override
  String get receiveRealTimeUpdatesAboutDrops =>
      'Receive real-time updates about your drops, collections, and important announcements.';

  @override
  String get photoStorage => 'Photo Storage';

  @override
  String get saveAndAccessPhotosOfRecyclableItems =>
      'Save and access photos of your recyclable items.';

  @override
  String get enable => 'Enable';

  @override
  String get continueToApp => 'Continue to App';

  @override
  String get enableRequiredPermissions => 'Enable Required Permissions';

  @override
  String get accountDisabled => 'Account Disabled';

  @override
  String get accountDisabledMessage =>
      'Your account has been permanently disabled due to repeated violations of Bottleji\'s community guidelines.\n\nYou can no longer access or use this account.\n\nIf you believe this decision was made in error, please contact support:';

  @override
  String get supportEmail => 'support@bottleji.com';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get pleaseEmailSupport =>
      'Please email support@bottleji.com for assistance';

  @override
  String get sessionExpired => 'Session Expired';

  @override
  String get sessionExpiredMessage =>
      'Your session has expired. Please login again to continue.';

  @override
  String get home => 'Home';

  @override
  String get drops => 'Drops';

  @override
  String get rewards => 'Rewards';

  @override
  String get stats => 'Stats';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get account => 'Account';

  @override
  String get support => 'Support';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get logout => 'Logout';

  @override
  String get areYouSureLogout => 'Are you sure you want to logout?';

  @override
  String errorDuringLogout(String error) {
    return 'Error during logout: $error';
  }

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get back => 'Back';

  @override
  String get previous => 'Previous';

  @override
  String get done => 'Done';

  @override
  String get gotIt => 'Got it';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get apply => 'Apply';

  @override
  String get filterDrops => 'Filter Drops';

  @override
  String get status => 'Status';

  @override
  String get all => 'All';

  @override
  String get date => 'Date';

  @override
  String get distance => 'Distance';

  @override
  String get deleteDrop => 'Delete Drop';

  @override
  String get areYouSureDelete => 'Are you sure you want to delete this drop?';

  @override
  String get createDrop => 'Create Drop';

  @override
  String get editDrop => 'Edit Drop';

  @override
  String get startCollection => 'Start Collection';

  @override
  String get resumeNavigation => 'Resume Navigation';

  @override
  String get cancelCollection => 'Cancel Collection';

  @override
  String get areYouSureCancelCollection =>
      'Are you sure you want to cancel this collection?';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get leaveCollection => 'Leave Collection?';

  @override
  String get areYouSureLeaveCollection =>
      'Are you sure you want to leave? Your collection will remain active.';

  @override
  String get exitNavigation => 'Exit Navigation';

  @override
  String get areYouSureExitNavigation =>
      'Are you sure you want to exit navigation? Your collection will remain active.';

  @override
  String get reportDrop => 'Report Drop';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get setCollectionRadius => 'Set Collection Radius';

  @override
  String get setCollectionRadiusDescription =>
      'Set the radius (in kilometers) within which you want to collect bottles.';

  @override
  String get kilometers => 'km';

  @override
  String get collectionRadiusUpdated => 'Collection radius updated!';

  @override
  String get saveRadius => 'Save Radius';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get galleryIOSSimulatorIssue => 'Gallery (iOS Simulator Issue)';

  @override
  String get useCameraOrRealDevice => 'Use camera or real device';

  @override
  String get leaveOutsideDoor => 'Leave outside the door';

  @override
  String get pleaseTakePhoto => 'Please take a photo of your bottles';

  @override
  String get pleaseWaitLoading =>
      'Please wait while we load your account information';

  @override
  String get mustBeLoggedIn => 'You must be logged in to create a drop';

  @override
  String get authenticationIssue =>
      'Authentication issue detected. Please log out and log in again.';

  @override
  String get dropCreatedSuccessfully => 'Drop created successfully!';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get reloadMap => 'Reload Map';

  @override
  String get thisHelpsUsShowNearby =>
      'This helps us show nearby drops and provide accurate collection services.';

  @override
  String errorLoadingUserMode(String error) {
    return 'Error loading user mode: $error';
  }

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters';

  @override
  String get checkBackLater => 'Check back later for new drops';

  @override
  String get createFirstDrop => 'Create your first drop to get started';

  @override
  String get collectionInProgress => 'Collection in Progress';

  @override
  String get resumeCollection => 'Resume Collection';

  @override
  String get collectionTimeout => '⚠️ Collection Timeout';

  @override
  String get warningSystem => 'Warning System';

  @override
  String get warningAddedToAccount =>
      'A warning was added to your account for this drop. Please make sure future images follow the community guidelines.';

  @override
  String get timerExpired => '⏰ Timer Expired!';

  @override
  String get timerExpiredMessage =>
      'The collection timer has expired. The navigation screen will now exit.';

  @override
  String get applicationRejected => 'Application Rejected';

  @override
  String applicationRejectedMessage(String reason) {
    return 'Your collector application was rejected. Reason: $reason';
  }

  @override
  String get noSpecificReason => 'No specific reason provided';

  @override
  String get canEditApplication =>
      'You can edit your application and submit it again.';

  @override
  String get editApplication => 'Edit Application';

  @override
  String get pleaseLogInCollector => 'Please log in to access collector mode';

  @override
  String get tierSystem => 'Tier System';

  @override
  String get bySubscribingAgree =>
      'By subscribing, you agree to our Terms of Service\nand Privacy Policy';

  @override
  String get startProSubscription => 'Start PRO Subscription';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get lastUpdated => 'Last updated: March 15, 2024';

  @override
  String get acceptanceOfTerms => '1. Acceptance of Terms';

  @override
  String get acceptanceOfTermsContent =>
      'By accessing and using the Bottleji application, you agree to be bound by these Terms and Conditions. If you disagree with any part of these terms, you may not access the application.';

  @override
  String get userResponsibilities => '2. User Responsibilities';

  @override
  String get userResponsibilitiesContent =>
      'As a user of Bottleji, you agree to:\n• Provide accurate and complete information\n• Maintain the security of your account\n• Follow waste segregation guidelines\n• Schedule collections responsibly\n• Use the service in accordance with local laws';

  @override
  String get household => 'Household';

  @override
  String get collector => 'Collector';

  @override
  String get activeMode => 'Active Mode';

  @override
  String get myAccount => 'My Account';

  @override
  String get trainings => 'Trainings';

  @override
  String get referAndEarn => 'Refer and Earn';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get review => 'Review';

  @override
  String get rejected => 'Rejected';

  @override
  String get becomeACollector => 'Become a Collector';

  @override
  String get applicationUnderReview =>
      'Your application is currently under review. Would you like to view your application status?';

  @override
  String get viewStatus => 'View Status';

  @override
  String applicationRejectedReason(String rejectionReason) {
    return 'Your application was rejected for the following reason:\n\n\"$rejectionReason\"\n\nWould you like to edit your application and submit it again?';
  }

  @override
  String get applicationApprovedSuspended =>
      'Your application was approved but your collector access has been temporarily suspended. Please contact support or reapply.';

  @override
  String get reapply => 'Reapply';

  @override
  String get needToApplyCollector =>
      'You need to apply and be approved to access collector mode. Would you like to apply now?';

  @override
  String get applyNow => 'Apply Now';

  @override
  String get householdMode => 'Household Mode';

  @override
  String get collectorMode => 'Collector Mode';

  @override
  String get householdModeDescription =>
      'Create drops and track your recycling';

  @override
  String get collectorModeDescription => 'Collect bottles and earn rewards';

  @override
  String get sustainableWasteManagement => 'Sustainable Waste Management';

  @override
  String get ecoFriendlyBottleCollection => 'Eco-friendly bottle collection';

  @override
  String get bottleType => 'Bottle Type';

  @override
  String get numberOfPlasticBottles => 'Number of Plastic Bottles';

  @override
  String get numberOfCans => 'Number of Cans';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get notes => 'Notes';

  @override
  String get failedToCreateDrop => 'Failed to create drop. Please try again.';

  @override
  String get imageSelectedSuccessfully => 'Image selected successfully!';

  @override
  String get errorSelectingImage => 'Error selecting image';

  @override
  String get permissionDeniedPhoto =>
      'Permission denied. Please allow photo access in Settings.';

  @override
  String get galleryNotAvailableSimulator =>
      'Gallery not available on simulator. Try camera or use a real device.';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get fullName => 'Full Name';

  @override
  String get notSet => 'Not set';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get collectorStatus => 'Collector Status';

  @override
  String get approvedCollector => 'You are an approved collector';

  @override
  String get applicationStatus => 'Application Status';

  @override
  String get applicationUnderReviewStatus => 'Your application is under review';

  @override
  String get viewDetails => 'View Details';

  @override
  String get applicationRejectedTitle => 'Application Rejected';

  @override
  String get pleaseLoginToViewProfile => 'Please login to view your profile';

  @override
  String get bottlejiRequiresPermissions =>
      'Bottleji requires additional permissions to work properly';

  @override
  String galleryError(String error) {
    return 'Gallery error: $error';
  }

  @override
  String galleryNotAvailableIOS(String error) {
    return 'Gallery not available on iOS simulator: $error';
  }

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get tapToChangePhoto => 'Tap to change photo';

  @override
  String get saving => 'Saving...';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get phoneNumberMustBe8Digits => 'Phone number must be 8 digits';

  @override
  String get phoneNumberMustContainOnlyDigits =>
      'Phone number must contain only digits';

  @override
  String get pleaseEnterYourFullName => 'Please enter your full name';

  @override
  String get pleaseEnterYourPhoneNumber => 'Please enter your phone number';

  @override
  String get pleaseEnterYourAddress => 'Please enter your address';

  @override
  String get pleaseVerifyYourPhoneNumber =>
      'Please verify your phone number before saving';

  @override
  String get noChangesDetected =>
      'No changes detected. Profile remains unchanged.';

  @override
  String get profileSetupCompletedSuccessfully =>
      'Profile setup completed successfully! Welcome to Bottleji!';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String failedToUploadImage(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get smsCode => 'SMS Code';

  @override
  String get enter6DigitCode => 'Enter 6-digit code';

  @override
  String get sendCode => 'Send Code';

  @override
  String get sending => 'Sending...';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get verifying => 'Verifying...';

  @override
  String get phoneNumberVerified => 'Phone number verified';

  @override
  String get phoneNumberNotVerified => 'Phone number not verified';

  @override
  String get phoneNumberNeedsVerification => 'Phone number needs verification';

  @override
  String get phoneNumberVerifiedSuccessfully =>
      'Phone number verified successfully!';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get searchAddress => 'Search Address';

  @override
  String get tapToSearchAddress => 'Tap to search for your address';

  @override
  String get typeToSearch => 'Type to search...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String errorFetchingSuggestions(String error) {
    return 'Error fetching suggestions: $error';
  }

  @override
  String get pleaseEnterPhoneNumberFirst => 'Please enter a phone number first';

  @override
  String get pleaseEnterValidPhoneNumber =>
      'Please enter a valid phone number with country code (e.g., +49 123456789)';

  @override
  String get locationPermissionRequired =>
      'Location permission is required for address features';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get failedToLoadNotifications => 'Failed to load notifications';

  @override
  String get createNewDrop => 'Create New Drop';

  @override
  String get photo => 'Photo';

  @override
  String get takePhotoOrChooseFromGallery =>
      'Take a photo or choose from gallery - show your bottles clearly to help collectors';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get cameraOrGallery => 'Camera or Gallery';

  @override
  String get allDrops => 'All Drops';

  @override
  String get myDrops => 'My Drops';

  @override
  String get active => 'Active';

  @override
  String get collected => 'Collected';

  @override
  String get flagged => 'FLAGGED';

  @override
  String get censored => 'Censored';

  @override
  String get stale => 'Stale';

  @override
  String get dropsInThisFilterCollected =>
      'Drops in this filter have been successfully collected by a collector. These drops show your recycling impact and cannot be edited.';

  @override
  String get dropsInThisFilterFlagged =>
      'Drops in this filter were flagged due to multiple cancellations or suspicious activity. Flagged drops are hidden from the map and cannot be edited.';

  @override
  String get dropsInThisFilterCensored =>
      'Drops in this filter were censored due to inappropriate content. Censored drops are hidden from the map and cannot be edited.';

  @override
  String get dropsInThisFilterStale =>
      'Drops in this filter were marked as stale because they were older than 3 days and likely collected by external collectors. Stale drops are hidden from the map and cannot be edited.';

  @override
  String get inActiveCollection =>
      'In Active Collection - Collector on the way';

  @override
  String censoredInappropriateImage(String reason) {
    return 'Censored: $reason';
  }

  @override
  String get onTheWay => 'On the way';

  @override
  String get collectorOnHisWay => 'Collector on his way to pick up your drop';

  @override
  String get waiting => 'Waiting...';

  @override
  String get notYetCollected => 'Not yet collected';

  @override
  String get yourPoints => 'Your Points';

  @override
  String pointsToGo(int points) {
    return '$points points to go';
  }

  @override
  String get progressToNextTier => 'Progress to Next Tier';

  @override
  String get bronzeCollector => 'Bronze Collector';

  @override
  String get silverCollector => 'Silver Collector';

  @override
  String get goldCollector => 'Gold Collector';

  @override
  String get platinumCollector => 'Platinum Collector';

  @override
  String get diamondCollector => 'Diamond Collector';

  @override
  String earnPointsPerDropCollected(int points) {
    return 'Earn $points points per drop collected';
  }

  @override
  String earnPointsWhenDropsCollected(int points) {
    return 'Earn $points points when your drops are collected';
  }

  @override
  String get rewardShop => 'Reward Shop';

  @override
  String get orderHistory => 'Order History';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get yourOrderHistoryWillAppearHere =>
      'Your order history will appear here';

  @override
  String get notEnoughPoints => 'Not enough points';

  @override
  String get pts => 'pts';

  @override
  String get myStats => 'My Stats';

  @override
  String get timeRange => 'Time Range';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This month';

  @override
  String get thisYear => 'This Year';

  @override
  String get allTime => 'All Time';

  @override
  String get overview => 'Overview';

  @override
  String get dropStatus => 'Drop Status';

  @override
  String get pending => 'Pending';

  @override
  String get collectionRate => 'Collection Rate';

  @override
  String get avgCollectionTime => 'Avg Collection Time';

  @override
  String get recentCollections => 'Recent Collections';

  @override
  String get supportAndHelp => 'Support & Help';

  @override
  String get howCanWeHelpYou => 'How can we help you?';

  @override
  String get selectCategoryToGetStarted => 'Select a category to get started';

  @override
  String get supportCategories => 'Support Categories';

  @override
  String get whatDoYouNeedHelpWith => 'What do you need help with?';

  @override
  String get selectCategoryToContinue => 'Select a category to continue';

  @override
  String get trainingCenter => 'Training Center';

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday at $time';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get leaveOutside => 'Leave Outside';

  @override
  String get noImageAvailable => 'No image available';

  @override
  String get estTime => 'Est. Time';

  @override
  String get estimatedTime => 'Estimated Arrival Time';

  @override
  String get yourLocation => 'Your Location';

  @override
  String get dropLocation => 'Drop Location';

  @override
  String get routePreview => 'Route Preview';

  @override
  String get dropInformation => 'Drop Information';

  @override
  String get plasticBottles => 'Plastic Bottles';

  @override
  String get cans => 'Cans';

  @override
  String get plastic => 'Plastic';

  @override
  String get can => 'CAN';

  @override
  String get mixed => 'Mixed';

  @override
  String get totalItems => 'Total Items';

  @override
  String get estimatedValue => 'Estimated Value';

  @override
  String get created => 'Created';

  @override
  String get completeCurrentCollectionFirst =>
      'Complete your current collection before starting a new one.';

  @override
  String get youAreOffline =>
      'You are offline. Please check your internet connection.';

  @override
  String errorColon(String error) {
    return 'Error: $error';
  }

  @override
  String get yourInformation => 'Your Information';

  @override
  String get createdBy => 'Created by';

  @override
  String get youWillSeeNotificationsHere =>
      'You\'ll see your notifications here';

  @override
  String get pendingStatus => 'PENDING';

  @override
  String get acceptedStatus => 'ACCEPTED';

  @override
  String get collectedStatus => 'COLLECTED';

  @override
  String get cancelledStatus => 'CANCELLED';

  @override
  String get expiredStatus => 'EXPIRED';

  @override
  String get staleStatus => 'STALE';

  @override
  String get howRewardsWork => 'How Rewards Work';

  @override
  String get howRewardsWorkCollector =>
      '• Collect drops to earn points\n• Higher tiers = more points per drop\n• Use points in the reward shop\n• Track your progress and achievements';

  @override
  String get howRewardsWorkHousehold =>
      '• Create drops to contribute to recycling\n• Earn points when collectors pick up your drops\n• Higher tiers = more points per collected drop\n• Use points in the reward shop';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get itemNotAvailable => 'Item is not available';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get orderNow => 'Order Now';

  @override
  String get pleaseLogInToViewOrderHistory =>
      'Please log in to view order history';

  @override
  String get failedToLoadOrderHistory => 'Failed to load order history';

  @override
  String get refresh => 'Refresh';

  @override
  String get pointsSpent => 'Points Spent';

  @override
  String get size => 'Size';

  @override
  String get orderDate => 'Order Date';

  @override
  String get tracking => 'Tracking';

  @override
  String get estimatedDelivery => 'Estimated Delivery';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get adminNote => 'Admin Note';

  @override
  String get approved => 'Approved';

  @override
  String get processing => 'Processing';

  @override
  String get shipped => 'Shipped';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String available(int count) {
    return '$count available';
  }

  @override
  String get updateDrop => 'Update Drop';

  @override
  String get updating => 'Updating...';

  @override
  String get recyclingImpact => 'Recycling Impact';

  @override
  String get recentDrops => 'Recent Drops';

  @override
  String get viewAll => 'View All';

  @override
  String get dropStatusDistribution => 'Drop Status';

  @override
  String get co2VolumeSaved => 'CO₂ Volume Saved';

  @override
  String totalCo2Saved(String amount) {
    return 'Total CO₂ Saved: $amount kg';
  }

  @override
  String get dropActivity => 'Drop Activity';

  @override
  String dropsCreated(String timeRange, int count) {
    return 'Drops Created ($timeRange): $count';
  }

  @override
  String errorPickingImage(String error) {
    return 'Error picking image: $error';
  }

  @override
  String get dropUpdatedSuccessfully => 'Drop updated successfully!';

  @override
  String errorUpdatingDrop(String error) {
    return 'Error updating drop: $error';
  }

  @override
  String get areYouSureDeleteDrop =>
      'Are you sure you want to delete this drop? This action cannot be undone.';

  @override
  String get dropDeletedSuccessfully => 'Drop deleted successfully!';

  @override
  String errorDeletingDrop(String error) {
    return 'Error deleting drop: $error';
  }

  @override
  String get pleaseEnterNumberOfBottles => 'Please enter number of bottles';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get pleaseEnterNumberOfCans => 'Please enter number of cans';

  @override
  String get anyAdditionalInstructions =>
      'Any additional instructions for the collector...';

  @override
  String get collectorCanLeaveOutside =>
      'Collector can leave items outside if no one is home';

  @override
  String get loadingAddress => 'Loading address...';

  @override
  String locationFormat(String lat, String lng) {
    return 'Location: $lat, $lng';
  }

  @override
  String get locationSelected => 'Location selected';

  @override
  String get currentDropLocation => 'Current Drop Location';

  @override
  String get tapConfirmToSetLocation => 'Tap \"Confirm\" to set this location';

  @override
  String get userNotFound => 'User not found';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get getHelp => 'Get Help';

  @override
  String get selectCategoryAndGetSupport =>
      'Select a category and get support for your issue';

  @override
  String get mySupportTickets => 'My Support Tickets';

  @override
  String get viewAndManageTickets =>
      'View and manage your existing support tickets';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get phoneSupport => 'Phone Support';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get findAnswersToCommonQuestions => 'Find answers to common questions';

  @override
  String get needMoreHelp => 'Need More Help?';

  @override
  String get supportTeamAvailable247 =>
      'If you can\'t find what you\'re looking for, our support team is here to help 24/7.';

  @override
  String get dropIssues => 'Drop Issues';

  @override
  String get getHelpWithDropProblems => 'Get help with drop-related problems';

  @override
  String get dropIssuesSubtitle =>
      'Expired drops, canceled collections, active collections';

  @override
  String get applicationIssues => 'Application Issues';

  @override
  String get getHelpWithApplications => 'Get help with collector applications';

  @override
  String get applicationIssuesSubtitle =>
      'Rejected applications, pending reviews';

  @override
  String get accountIssues => 'Account Issues';

  @override
  String get getHelpWithAccount => 'Get help with your account';

  @override
  String get accountIssuesSubtitle =>
      'Profile updates, login problems, account settings';

  @override
  String get technicalIssues => 'Technical Issues';

  @override
  String get getHelpWithAppProblems => 'Get help with app problems';

  @override
  String get technicalIssuesSubtitle => 'App crashes, bugs, performance issues';

  @override
  String get paymentIssues => 'Payment Issues';

  @override
  String get getHelpWithPayments => 'Get help with payments';

  @override
  String get paymentIssuesSubtitle =>
      'Payment delays, missing payments, payment methods';

  @override
  String get generalSupport => 'General Support';

  @override
  String get getHelpWithAnythingElse => 'Get help with anything else';

  @override
  String get generalSupportSubtitle => 'Questions, suggestions, other issues';

  @override
  String get selectItemToGetHelp => 'Select an item to get help';

  @override
  String get selectDropFromLast3Days =>
      'Select a drop from the last 3 days to get help';

  @override
  String get selectApplicationToGetHelp =>
      'Select your collector application to get help';

  @override
  String get getHelpWithAccountIssues => 'Get help with your account issues';

  @override
  String get getHelpWithTechnicalProblems => 'Get help with technical problems';

  @override
  String get getHelpWithPaymentIssues => 'Get help with payment issues';

  @override
  String get getHelpWithAnyOtherIssue => 'Get help with any other issue';

  @override
  String get authenticationError => 'Authentication Error';

  @override
  String get pleaseLogInAgain => 'Please log in again to view your items.';

  @override
  String get noCollectionsFound => 'No Collections Found';

  @override
  String get noCollectionsToReport =>
      'You don\'t have any collections to report issues for.';

  @override
  String get yourCollectionsLast3Days => 'Your Collections (Last 3 Days)';

  @override
  String errorLoadingCollections(String error) {
    return 'Error loading collections: $error';
  }

  @override
  String get noDropsFound => 'No Drops Found';

  @override
  String get noDropsToReport =>
      'You don\'t have any drops to report issues for.';

  @override
  String get yourDropsLast3Days => 'Your Drops (Last 3 Days)';

  @override
  String errorLoadingDrops(String error) {
    return 'Error loading drops: $error';
  }

  @override
  String get noApplications => 'No Applications';

  @override
  String get noCollectorApplications =>
      'You don\'t have any collector applications.';

  @override
  String get noIssuesFound => 'No Issues Found';

  @override
  String get applicationBeingProcessed =>
      'Your application is being processed normally.';

  @override
  String get noPaymentsYet => 'No Payments Yet';

  @override
  String get paymentFeatureNotAvailable =>
      'Payment feature is not available yet. Select a payment to get help with payment-related issues.';

  @override
  String get paymentSupport => 'Payment Support';

  @override
  String get getHelpWithPaymentRelatedIssues =>
      'Get help with payment-related issues';

  @override
  String get supportOptions => 'Support Options';

  @override
  String get collectorApplication => 'Collector Application';

  @override
  String get applied => 'Applied';

  @override
  String get items => 'items';

  @override
  String get drop => 'Drop';

  @override
  String get collection => 'Collection';

  @override
  String get unknown => 'Unknown';

  @override
  String get justNow => 'Just now';

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get reviewTicket => 'Review Ticket';

  @override
  String get reviewYourTicket => 'Review Your Ticket';

  @override
  String get pleaseReviewDetailsBeforeCreating =>
      'Please review the details before creating';

  @override
  String get title => 'Title';

  @override
  String get category => 'Category';

  @override
  String get priority => 'Priority';

  @override
  String get description => 'Description';

  @override
  String get confirmAndCreateTicket => 'Confirm & Create Ticket';

  @override
  String get supportTicketCreatedSuccessfully =>
      'Support ticket created successfully!';

  @override
  String failedToCreateTicket(String error) {
    return 'Failed to create ticket: $error';
  }

  @override
  String get allTickets => 'All Tickets';

  @override
  String get open => 'Open';

  @override
  String get inProgress => 'In Progress';

  @override
  String get resolved => 'Resolved';

  @override
  String get closed => 'Closed';

  @override
  String get onHold => 'On Hold';

  @override
  String get noSupportTicketsYet => 'No support tickets yet';

  @override
  String get createFirstSupportTicket =>
      'Create your first support ticket if you need help';

  @override
  String get errorLoadingTickets => 'Error loading tickets';

  @override
  String get lowPriority => 'Low Priority';

  @override
  String get mediumPriority => 'Medium Priority';

  @override
  String get highPriority => 'HIGH';

  @override
  String get urgent => 'Urgent';

  @override
  String get dropIssue => 'Drop Issue';

  @override
  String get collectionIssue => 'Collection Issue';

  @override
  String issueWithDropCreatedOn(String date) {
    return 'Issue with drop created on $date';
  }

  @override
  String get bottles => 'Bottles';

  @override
  String issueWithCollection(String status, String date) {
    return 'Issue with collection $status on $date';
  }

  @override
  String get authenticationAccount => '🔐 Authentication & Account';

  @override
  String get appTechnicalIssues => '📱 App Technical Issues';

  @override
  String get dropCreationManagement => '🏠 Drop Creation & Management';

  @override
  String get collectionNavigation => '🚚 Collection & Navigation';

  @override
  String get collectorApplicationCategory => '👤 Collector Application';

  @override
  String get paymentRewards => '💰 Payment & Rewards';

  @override
  String get statisticsHistory => '📊 Statistics & History';

  @override
  String get roleSwitching => '🔄 Role Switching';

  @override
  String get communication => '📞 Communication';

  @override
  String get generalSupportCategory => '🛠️ General Support';

  @override
  String get supportTicket => 'Support Ticket';

  @override
  String get cannotSendMessageTicketClosed =>
      'Cannot send message. This ticket is closed.';

  @override
  String failedToSendMessage(String error) {
    return 'Failed to send message: $error';
  }

  @override
  String get adminIsOnline => 'Admin is online';

  @override
  String get adminIsTyping => 'Admin is typing...';

  @override
  String get helpUsMaintainQuality => 'Help us maintain quality';

  @override
  String get selectReason => 'Select Reason';

  @override
  String get inappropriateImage => '🚫 Inappropriate Image';

  @override
  String get fakeDrop => '❌ Fake Drop';

  @override
  String get amountMismatch =>
      '📊 Amount of bottles not matching the real drop';

  @override
  String get additionalDetailsOptional => 'Additional Details (Optional)';

  @override
  String get provideMoreInformation => 'Provide more information...';

  @override
  String get pleaseSelectReason => 'Please select a reason';

  @override
  String get dropReportedSuccessfully =>
      'Drop reported successfully. Thank you for helping keep our community safe!';

  @override
  String errorReportingDrop(String error) {
    return 'Error reporting drop: $error';
  }

  @override
  String get submitReport => 'Submit Report';

  @override
  String get dropCollection => 'Drop Collection';

  @override
  String get walkStraightToDestination => 'Walk straight to destination';

  @override
  String get directRoute => 'Direct route';

  @override
  String get unknownDistance => 'Unknown distance';

  @override
  String get unknownDuration => 'Unknown duration';

  @override
  String get routeToDrop => 'Route to Drop';

  @override
  String get remaining => 'remaining';

  @override
  String get completeCollectionIn => 'Complete collection in:';

  @override
  String get youHaveArrivedAtDestination =>
      'You have arrived at the destination!';

  @override
  String get calculatingRoute => 'Calculating route...';

  @override
  String get leaveCollectionMessage =>
      'You have an active collection. Are you sure you want to leave? You must complete or cancel the collection to proceed.';

  @override
  String get slideToCollect => 'Slide to Collect';

  @override
  String get releaseToCollect => 'Release to Collect';

  @override
  String get collectionConfirmed => 'Collection confirmed!';

  @override
  String collectionCancelled(String reason) {
    return 'Collection cancelled: $reason';
  }

  @override
  String get errorUserNotAuthenticated => 'Error: User not authenticated';

  @override
  String errorCancellingCollection(String error) {
    return 'Error cancelling collection: $error';
  }

  @override
  String get collectionCompletedSuccessfully =>
      'Collection completed successfully!';

  @override
  String get collectionCompletedSuccessfullyNoExclamation =>
      'Collection completed successfully';

  @override
  String get errorNoCollectorIdFound => 'Error: No collector ID found';

  @override
  String errorConfirmingCollection(String error) {
    return 'Error confirming collection: $error';
  }

  @override
  String get dropCollected => 'Drop Collected';

  @override
  String pointsEarned(int points) {
    final intl.NumberFormat pointsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String pointsString = pointsNumberFormat.format(points);

    return '+$pointsString Points Earned!';
  }

  @override
  String get currentTier => 'Current Tier';

  @override
  String get totalPoints => 'Total Points';

  @override
  String get awesome => 'Awesome!';

  @override
  String get exitNavigationMessage =>
      'Are you sure you want to exit navigation? Your collection will remain active.';

  @override
  String get exit => 'Exit';

  @override
  String collectionTimerRunningLow(String time) {
    return 'Collection timer running low: $time remaining';
  }

  @override
  String get view => 'View';

  @override
  String get collectionTimerWarning => 'Collection Timer Warning';

  @override
  String yourCollectionTimerRunningLow(String time) {
    return 'Your collection timer is running low: $time remaining';
  }

  @override
  String get cancelCollectionMessage =>
      'Are you sure you want to cancel this collection? Please select a reason:';

  @override
  String get noAccess => 'No Access';

  @override
  String get notFound => 'Not Found';

  @override
  String get alreadyCollected => 'Already Collected';

  @override
  String get wrongLocation => 'Wrong Location';

  @override
  String get unsafeLocation => 'Unsafe Location';

  @override
  String get other => 'Other';

  @override
  String get cancellationReasons => 'Cancellation Reasons';

  @override
  String get cancellationReason => 'Cancellation Reason';

  @override
  String get accountTemporarilyLocked => 'Account Temporarily Locked';

  @override
  String get accountLockedReason =>
      'Your account has been locked for 24 hours due to 5 collection timeout warnings.';

  @override
  String unlocksIn(String time) {
    return 'Unlocks in $time';
  }

  @override
  String get lockExpired => 'Lock expired';

  @override
  String get hour => 'hour';

  @override
  String get hours => 'hours';

  @override
  String get minute => 'minute';

  @override
  String get minutes => 'minutes';

  @override
  String get second => 'second';

  @override
  String get seconds => 'seconds';

  @override
  String availableAgainAt(String time) {
    return 'Available again at $time';
  }

  @override
  String get accountLockedInfo =>
      'You can still browse drops and use other features, but cannot accept new drops until unlocked.';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get orderApproved => 'Order Approved';

  @override
  String orderApprovedMessage(String orderId) {
    return 'Your order $orderId has been approved and is being processed.';
  }

  @override
  String get orderRejected => 'Order Rejected';

  @override
  String orderRejectedMessage(String reason) {
    return 'Your order has been rejected. Reason: $reason';
  }

  @override
  String get orderShipped => 'Order Shipped';

  @override
  String orderShippedMessage(String tracking) {
    return 'Your order has been shipped. Tracking: $tracking';
  }

  @override
  String get orderDelivered => 'Order Delivered';

  @override
  String get orderDeliveredMessage =>
      'Your order has been delivered successfully.';

  @override
  String get pointsEarnedTitle => 'Points Earned';

  @override
  String pointsEarnedMessage(int points) {
    final intl.NumberFormat pointsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String pointsString = pointsNumberFormat.format(points);

    return 'You earned $pointsString points!';
  }

  @override
  String get applicationApproved => 'Application Approved';

  @override
  String get applicationApprovedMessage =>
      'Congratulations! Your collector application has been approved.';

  @override
  String get applicationReversed => 'Application Reversed';

  @override
  String get applicationReversedMessage =>
      'Your collector application status has been reversed.';

  @override
  String get dropAccepted => 'Drop Accepted';

  @override
  String get dropAcceptedMessage => 'A collector has accepted your drop.';

  @override
  String get dropCollectedMessage =>
      'Your drop has been collected successfully.';

  @override
  String get dropCollectedWithRewards => 'Drop Collected';

  @override
  String dropCollectedWithRewardsMessage(int points) {
    final intl.NumberFormat pointsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String pointsString = pointsNumberFormat.format(points);

    return 'Your drop has been collected! You earned $pointsString points.';
  }

  @override
  String get dropCollectedWithTierUpgrade => 'Drop Collected';

  @override
  String get dropCollectedWithTierUpgradeMessage =>
      'Congratulations! Your drop was collected and you\'ve been upgraded to a higher tier!';

  @override
  String get dropCancelled => 'Drop Cancelled';

  @override
  String get dropCancelledMessage => 'Your drop has been cancelled.';

  @override
  String get dropExpired => 'Drop Expired';

  @override
  String get dropExpiredMessage =>
      'Your drop has expired and is no longer available.';

  @override
  String get dropNearExpiring => 'Drop Near Expiring';

  @override
  String get dropNearExpiringMessage => 'Your drop is about to expire soon.';

  @override
  String get dropCensored => 'Drop Censored';

  @override
  String get dropCensoredMessage =>
      'Your drop has been censored due to inappropriate content.';

  @override
  String get ticketMessage => 'New Ticket Message';

  @override
  String get ticketMessageNotification =>
      'You have a new message in your support ticket.';

  @override
  String get accountUnlocked => 'Account Unlocked';

  @override
  String get accountUnlockedMessage =>
      'Your account has been unlocked. You can now start collecting drops again!';

  @override
  String get userDeleted => 'Account Deleted';

  @override
  String get userDeletedMessage => 'Your account has been deleted.';

  @override
  String get trackOrder => 'Track Order';

  @override
  String get viewOrder => 'View Order';

  @override
  String get shopAgain => 'Shop Again';

  @override
  String get viewRewards => 'View Rewards';

  @override
  String get tapToViewRejectionReason => 'Tap to view rejection reason';

  @override
  String get gettingStarted => 'Getting Started';

  @override
  String get advancedFeatures => 'Advanced Features';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get bestPractices => 'Best Practices';

  @override
  String get payments => 'Payments';

  @override
  String get help => 'Help';

  @override
  String get advanced => 'Advanced';

  @override
  String get story => 'Story';

  @override
  String get totalDrops => 'Total Drops';

  @override
  String get aluminumCans => 'Aluminum Cans';

  @override
  String get recycled => 'Recycled';

  @override
  String recycledBottles(String count) {
    return 'Recycled $count bottles';
  }

  @override
  String recycledCans(String count) {
    return 'Recycled $count cans';
  }

  @override
  String get totalItemsRecycled => 'Total Items Recycled';

  @override
  String get dropsCollected => 'Drops Collected';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String get january => 'Jan';

  @override
  String get february => 'Feb';

  @override
  String get march => 'Mar';

  @override
  String get april => 'Apr';

  @override
  String get may => 'May';

  @override
  String get june => 'Jun';

  @override
  String get july => 'Jul';

  @override
  String get august => 'Aug';

  @override
  String get september => 'Sep';

  @override
  String get october => 'Oct';

  @override
  String get november => 'Nov';

  @override
  String get december => 'Dec';

  @override
  String get todaysTotal => 'Today\'s Total';

  @override
  String get earnings => 'Earnings';

  @override
  String get collections => 'Collections';

  @override
  String get noEarningsHistoryYet => 'No earnings history yet';

  @override
  String get earningsWillAppearHere =>
      'Your earnings will appear here once you complete collections';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String errorLoadingEarnings(String error) {
    return 'Error loading earnings: $error';
  }

  @override
  String get noCompletedCollectionsYet => 'No completed collections yet';

  @override
  String get performanceMetrics => 'Performance Metrics';

  @override
  String get expired => 'Expired';

  @override
  String get collectionsOverTime => 'Collections Over Time';

  @override
  String get expiredOverTime => 'Expired Over Time';

  @override
  String get cancelledOverTime => 'Cancelled Over Time';

  @override
  String get totalThisWeek => 'total this week';

  @override
  String get totalThisMonth => 'total this month';

  @override
  String get totalThisYear => 'total this year';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String daysAgoShort(int days) {
    return '${days}d ago';
  }

  @override
  String get at => 'at';

  @override
  String get total => 'Total';

  @override
  String get noDropsCreatedYet => 'No drops created yet';

  @override
  String get createYourFirstDropToGetStarted =>
      'Create your first drop to get started';

  @override
  String get noActiveDrops => 'No active drops';

  @override
  String get noCollectedDrops => 'No collected drops yet';

  @override
  String get noStaleDrops => 'No stale drops';

  @override
  String get noCensoredDrops => 'No censored drops';

  @override
  String get noFlaggedDrops => 'No flagged drops';

  @override
  String get noDropsMatchYourFilters => 'No drops match your filters';

  @override
  String get tryAdjustingYourFilters => 'Try adjusting your filters';

  @override
  String get noDropsAvailable => 'No drops available';

  @override
  String get checkBackLaterForNewDrops => 'Check back later for new drops';

  @override
  String get note => 'Note';

  @override
  String get outside => 'Outside';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get lastMonth => 'Last month';

  @override
  String get within1Km => 'Within 1 km';

  @override
  String get within3Km => 'Within 3 km';

  @override
  String get within5Km => 'Within 5 km';

  @override
  String get within10Km => 'Within 10 km';

  @override
  String get rewardHistory => 'Reward History';

  @override
  String get noRewardHistoryYet => 'No reward history yet';

  @override
  String get points => 'Points';

  @override
  String get tier => 'Tier';

  @override
  String get tierUp => 'Tier Up!';

  @override
  String get acceptDrop => 'Accept Drop';

  @override
  String get completeCurrentDropFirst => 'Complete Current Drop First';

  @override
  String get distanceUnavailable => 'Distance unavailable';

  @override
  String get away => 'away';

  @override
  String get meters => 'm';

  @override
  String get minutesShort => 'min';

  @override
  String get hoursShort => 'h';

  @override
  String get current => 'Current';

  @override
  String earnPointsPerDrop(int points) {
    return 'Earn $points points per drop';
  }

  @override
  String dropsRequired(int count) {
    return '$count drops required';
  }

  @override
  String get start => 'Start';

  @override
  String get filterHistory => 'Filter History';

  @override
  String get searchHistory => 'Search History';

  @override
  String get searchByNotesBottleTypeOrCancellationReason =>
      'Search by notes, bottle type, or cancellation reason...';

  @override
  String get viewType => 'View Type';

  @override
  String get itemType => 'Item Type';

  @override
  String get last3Months => 'Last 3 Months';

  @override
  String get last6Months => 'Last 6 Months';

  @override
  String get allItems => 'All Items';

  @override
  String get bottlesOnly => 'Bottles Only';

  @override
  String get cansOnly => 'Cans Only';

  @override
  String get allTypes => 'All Types';

  @override
  String get activeFilters => 'ACTIVE';

  @override
  String get waitingForCollector => 'Waiting for collector';

  @override
  String get liveCollectorOnTheWay => '🟢 Live - Collector on the way';

  @override
  String get collectorWasOnTheWay => 'Collector was on the way';

  @override
  String get wasOnTheWay => 'Was on the way';

  @override
  String get accepted => 'Accepted';

  @override
  String get sessionTime => 'Session Time';

  @override
  String get completed => 'Completed';

  @override
  String get pleaseLoginToViewYourDrops => 'Please login to view your drops';

  @override
  String errorLoadingUserData(String error) {
    return 'Error loading user data: $error';
  }

  @override
  String get earn500Points => 'Earn 500 Points';

  @override
  String get forEachFriendWhoJoins => 'For each friend who joins';

  @override
  String get yourReferralCode => 'Your Referral Code';

  @override
  String get referralCodeCopiedToClipboard =>
      'Referral code copied to clipboard';

  @override
  String get shareVia => 'Share via';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get sms => 'SMS';

  @override
  String get more => 'More';

  @override
  String get howItWorks => 'How it works';

  @override
  String get shareYourCode => 'Share your code';

  @override
  String get shareYourUniqueReferralCodeWithFriends =>
      'Share your unique referral code with friends';

  @override
  String get friendSignsUp => 'Friend signs up';

  @override
  String get yourFriendCreatesAnAccountUsingYourCode =>
      'Your friend creates an account using your code';

  @override
  String get earnRewards => 'Earn rewards';

  @override
  String get get500PointsWhenTheyCompleteFirstActivity =>
      'Get 500 points when they complete first activity';

  @override
  String get trainingCenterInfo => 'Training Center';

  @override
  String get trainingCenterInfoHousehold =>
      'Access training content tailored for household users. Learn how to use Botleji effectively!';

  @override
  String get trainingCenterInfoCollector =>
      'Access training content for collectors. Master collection techniques and best practices!';

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get glass => 'Glass';

  @override
  String get aluminum => 'Aluminum';

  @override
  String get dropProgress => 'Drop Progress';

  @override
  String get collectionIssues => 'Collection issues';

  @override
  String cancelledTimes(int count) {
    return 'Cancelled $count times';
  }

  @override
  String get dropAcceptedByCollector => 'Drop accepted by collector';

  @override
  String get acceptedDropForCollection => 'Accepted drop for collection';

  @override
  String get applicationIssue => 'Application Issue';

  @override
  String get paymentIssue => 'Payment Issue';

  @override
  String get accountIssue => 'Account Issue';

  @override
  String get technicalIssue => 'Technical Issue';

  @override
  String get generalSupportRequest => 'General Support Request';

  @override
  String get supportRequest => 'Support Request';

  @override
  String get noDescriptionProvided => 'No description provided';

  @override
  String get welcome => 'Welcome';

  @override
  String get idVerification => 'ID Verification';

  @override
  String get selfieWithId => 'Selfie with ID';

  @override
  String get reviewAndSubmit => 'Review & Submit';

  @override
  String get welcomeToCollectorProgram => 'Welcome to the Collector Program!';

  @override
  String get joinOurCommunityOfEcoConsciousCollectors =>
      'Join our community of eco-conscious collectors and help make a difference in recycling.';

  @override
  String get earnMoney => 'Earn Money';

  @override
  String get getPaidForEveryBottleAndCan =>
      'Get paid for every bottle and can you collect';

  @override
  String get flexibleHours => 'Flexible Hours';

  @override
  String get collectWheneverAndWherever =>
      'Collect whenever and wherever you want';

  @override
  String get helpTheEnvironment => 'Help the Environment';

  @override
  String get contributeToCleanerGreenerWorld =>
      'Contribute to a cleaner, greener world';

  @override
  String get requirements => 'Requirements';

  @override
  String get mustBe18YearsOrOlder => '• Must be 18 years or older';

  @override
  String get validNationalIdCard => '• Valid National ID Card';

  @override
  String get clearPhotosOfIdAndSelfie => '• Clear photos of ID and selfie';

  @override
  String get goodStandingInCommunity => '• Good standing in the community';

  @override
  String get idCardVerification => 'ID Card Verification';

  @override
  String pleaseProvideYourIdCardInformation(String idType) {
    return 'Please provide your $idType information and take clear photos';
  }

  @override
  String get idCardDetails => 'ID Card Details';

  @override
  String get passportDetails => 'Passport Details';

  @override
  String get idCardType => 'ID Card Type';

  @override
  String get selectYourIdCardType => 'Select your ID card type';

  @override
  String get nationalId => 'National ID';

  @override
  String get passport => 'Passport';

  @override
  String get pleaseSelectAnIdCardType => 'Please select an ID card type';

  @override
  String get passportNumber => 'Passport Number';

  @override
  String get enterYourPassportNumber => 'Enter your passport number';

  @override
  String get selectIssueDate => 'Select Issue Date';

  @override
  String get issueDateLabel => 'Issue Date';

  @override
  String issueDate(String date) {
    return 'Issue Date: $date';
  }

  @override
  String get selectExpiryDate => 'Select Expiry Date';

  @override
  String get expiryDateLabel => 'Expiry Date';

  @override
  String expiryDate(String date) {
    return 'Expiry Date: $date';
  }

  @override
  String get issuingAuthority => 'Issuing Authority';

  @override
  String get egMinistryOfForeignAffairs => 'e.g., Ministry of Foreign Affairs';

  @override
  String get idCardNumber => 'ID Card Number';

  @override
  String get idCardNumberPlaceholder => '12345678';

  @override
  String get idCardNumberIsRequired => 'ID card number is required';

  @override
  String get idCardNumberMustBe8Digits => 'ID card number must be 8 digits';

  @override
  String get idCardNumberMustContainOnlyDigits =>
      'ID card number must contain only digits';

  @override
  String get idCardPhotos => 'ID Card Photos';

  @override
  String get passportPhotos => 'Passport Photos';

  @override
  String get noPassportMainPagePhoto => 'No Passport Main Page Photo';

  @override
  String get takePhotoOfMainPageWithDetails =>
      'Take photo of the main page with your details';

  @override
  String get retakePhoto => 'Retake Photo';

  @override
  String get takePassportMainPagePhoto => 'Take Passport Main Page Photo';

  @override
  String get noIdCardFrontPhoto => 'No ID Card Front Photo';

  @override
  String get takePhotoOfFrontOfIdCard =>
      'Take photo of the front of your ID card';

  @override
  String get retakeFrontPhoto => 'Retake Front Photo';

  @override
  String get takeIdCardFrontPhoto => 'Take ID Card Front Photo';

  @override
  String get noIdCardBackPhoto => 'No ID Card Back Photo';

  @override
  String get takePhotoOfBackOfIdCard =>
      'Take photo of the back of your ID card';

  @override
  String get retakeBackPhoto => 'Retake Back Photo';

  @override
  String get takeIdCardBackPhoto => 'Take ID Card Back Photo';

  @override
  String get continueButton => 'Continue';

  @override
  String get selfieWithIdCard => 'Selfie with ID Card';

  @override
  String get pleaseTakeSelfieWhileHoldingId =>
      'Please take a selfie while holding your ID card next to your face';

  @override
  String get noSelfiePhoto => 'No Selfie Photo';

  @override
  String get takeSelfie => 'Take Selfie';

  @override
  String get reviewAndSubmitTitle => 'Review & Submit';

  @override
  String get pleaseReviewYourApplication =>
      'Please review your application before submitting';

  @override
  String get idCardInformation => 'ID Card Information';

  @override
  String get idType => 'ID Type';

  @override
  String get idNumber => 'ID Number';

  @override
  String get notProvided => 'Not provided';

  @override
  String get idCard => 'ID Card';

  @override
  String get selfie => 'Selfie';

  @override
  String get whatHappensNext => 'What happens next?';

  @override
  String get applicationReviewProcess =>
      '• Your application will be reviewed by our team\n• Review typically takes 1-3 business days\n• You\'ll receive a notification once reviewed\n• If approved, you can start collecting immediately';

  @override
  String get submitting => 'Submitting...';

  @override
  String get submitApplication => 'Submit Application';

  @override
  String get pleaseTakeBothPhotosBeforeSubmitting =>
      'Please take both photos before submitting';

  @override
  String get pleaseFillInAllRequiredPassportInformation =>
      'Please fill in all required passport information';

  @override
  String get pleaseFillInAllRequiredIdCardInformation =>
      'Please fill in all required ID card information (ID number and type)';

  @override
  String get applicationUpdatedSuccessfully =>
      'Application updated successfully!';

  @override
  String get applicationSubmittedSuccessfully =>
      'Application submitted successfully!';

  @override
  String errorSubmittingApplication(String error) {
    return 'Error submitting application: $error';
  }

  @override
  String get errorLoadingApplication => 'Error loading application';

  @override
  String get noApplicationFound => 'No Application Found';

  @override
  String get youHaventSubmittedApplicationYet =>
      'You haven\'t submitted a collector application yet.';

  @override
  String get pendingReview => 'Pending Review';

  @override
  String get yourApplicationIsBeingReviewed =>
      'Your application is being reviewed by our team.';

  @override
  String get congratulationsApplicationApproved =>
      'Congratulations! Your application has been approved.';

  @override
  String get applicationNotApprovedCanApplyAgain =>
      'Your application was not approved. You can apply again.';

  @override
  String get applicationStatusUnknown => 'Application status is unknown.';

  @override
  String get applicationDetails => 'Application Details';

  @override
  String get applicationId => 'Application ID';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get appliedOn => 'Applied On';

  @override
  String get reviewedOn => 'Reviewed On';

  @override
  String get rejectionReason => 'Rejection Reason';

  @override
  String get reviewNotes => 'Review Notes';

  @override
  String get applyAgain => 'Apply Again';

  @override
  String get applicationInReview => 'Application in Review';

  @override
  String get applicationInReviewDialogContent =>
      'Your application is currently being reviewed by our team. This process typically takes 1-3 business days. You will be notified once a decision has been made.';

  @override
  String get reviewProcess => 'Review Process';
}
