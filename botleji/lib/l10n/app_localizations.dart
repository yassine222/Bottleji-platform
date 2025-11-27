import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bottleji'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @manageLocationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage location preferences'**
  String get manageLocationPreferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @manageNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotificationPreferences;

  /// No description provided for @displayTheme.
  ///
  /// In en, this message translates to:
  /// **'Display Theme'**
  String get displayTheme;

  /// No description provided for @changeAppAppearance.
  ///
  /// In en, this message translates to:
  /// **'Change app appearance'**
  String get changeAppAppearance;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get invalidEmailOrPassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials and try again.'**
  String get loginFailed;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout. Please check your internet connection and try again.'**
  String get connectionTimeout;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get networkError;

  /// No description provided for @requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout. Please try again.'**
  String get requestTimeout;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account Deleted'**
  String get accountDeleted;

  /// No description provided for @accountDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted by an administrator.\n\nIf you believe this is a mistake, please contact our support team:\n\n📧 Email: support@bottleji.com\n📱 Support Hours: 9 AM - 6 PM (GMT+1)\n\nWe apologize for any inconvenience.'**
  String get accountDeletedMessage;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @youWillBeRedirectedToLoginScreen.
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to the login screen.'**
  String get youWillBeRedirectedToLoginScreen;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterEmailToReceiveResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset code'**
  String get enterEmailToReceiveResetCode;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @resetCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Reset code sent to your email'**
  String get resetCodeSentToEmail;

  /// No description provided for @enterResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Reset Code'**
  String get enterResetCode;

  /// No description provided for @weHaveSentResetCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We have sent a reset code to\n{email}'**
  String weHaveSentResetCodeTo(String email);

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @resetCodeResentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Reset code resent successfully!'**
  String get resetCodeResentSuccessfully;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPassword;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterNewPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful! Please login with your new password.'**
  String get passwordResetSuccessful;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @pleaseEnterOtpSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP sent to your email'**
  String get pleaseEnterOtpSentToEmail;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds} seconds'**
  String resendOtpIn(int seconds);

  /// No description provided for @otpVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP verified successfully'**
  String get otpVerifiedSuccessfully;

  /// No description provided for @invalidVerificationResponse.
  ///
  /// In en, this message translates to:
  /// **'Error: Invalid verification response'**
  String get invalidVerificationResponse;

  /// No description provided for @otpResentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully!'**
  String get otpResentSuccessfully;

  /// No description provided for @startYourBottlejiJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Your Bottleji Journey'**
  String get startYourBottlejiJourney;

  /// No description provided for @createAccountToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Create an account to get started'**
  String get createAccountToGetStarted;

  /// No description provided for @createAPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createAPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registrationSuccessful;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeToBottleji.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bottleji'**
  String get welcomeToBottleji;

  /// No description provided for @yourSustainableWasteManagementSolution.
  ///
  /// In en, this message translates to:
  /// **'Your Sustainable Waste Management Solution'**
  String get yourSustainableWasteManagementSolution;

  /// No description provided for @joinThousandsOfUsersMakingDifference.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of users making a difference by recycling bottles and cans while earning rewards.'**
  String get joinThousandsOfUsersMakingDifference;

  /// No description provided for @createAndTrackDrops.
  ///
  /// In en, this message translates to:
  /// **'Create & Track Drops'**
  String get createAndTrackDrops;

  /// No description provided for @forHouseholdUsers.
  ///
  /// In en, this message translates to:
  /// **'For Household Users'**
  String get forHouseholdUsers;

  /// No description provided for @easilyCreateDropRequests.
  ///
  /// In en, this message translates to:
  /// **'Easily create drop requests for your recyclable bottles and cans. Track collection status and get notified when collectors pick them up.'**
  String get easilyCreateDropRequests;

  /// No description provided for @collectAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Collect & Earn'**
  String get collectAndEarn;

  /// No description provided for @forCollectors.
  ///
  /// In en, this message translates to:
  /// **'For Collectors'**
  String get forCollectors;

  /// No description provided for @findNearbyDropsCollectRecyclables.
  ///
  /// In en, this message translates to:
  /// **'Find nearby drops, collect recyclables, and earn rewards. Help build a sustainable community while making money.'**
  String get findNearbyDropsCollectRecyclables;

  /// No description provided for @realTimeUpdates.
  ///
  /// In en, this message translates to:
  /// **'Real-time Updates'**
  String get realTimeUpdates;

  /// No description provided for @stayConnected.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected'**
  String get stayConnected;

  /// No description provided for @getInstantNotificationsAboutDrops.
  ///
  /// In en, this message translates to:
  /// **'Get instant notifications about your drops, collections, and important updates. Never miss an opportunity.'**
  String get getInstantNotificationsAboutDrops;

  /// No description provided for @appPermissions.
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get appPermissions;

  /// No description provided for @bottlejiRequiresAdditionalPermissions.
  ///
  /// In en, this message translates to:
  /// **'Bottleji requires additional permissions to work properly'**
  String get bottlejiRequiresAdditionalPermissions;

  /// No description provided for @permissionsHelpProvideBestExperience.
  ///
  /// In en, this message translates to:
  /// **'These permissions help us provide you with the best experience.'**
  String get permissionsHelpProvideBestExperience;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get locationServices;

  /// No description provided for @accessLocationToShowNearbyDrops.
  ///
  /// In en, this message translates to:
  /// **'Access your location to show nearby drops and enable navigation for collectors.'**
  String get accessLocationToShowNearbyDrops;

  /// No description provided for @localNetworkAccess.
  ///
  /// In en, this message translates to:
  /// **'Local Network Access'**
  String get localNetworkAccess;

  /// No description provided for @allowAppToDiscoverServicesOnWifi.
  ///
  /// In en, this message translates to:
  /// **'Allow the app to discover services on your Wi‑Fi for real-time features.'**
  String get allowAppToDiscoverServicesOnWifi;

  /// No description provided for @receiveRealTimeUpdatesAboutDrops.
  ///
  /// In en, this message translates to:
  /// **'Receive real-time updates about your drops, collections, and important announcements.'**
  String get receiveRealTimeUpdatesAboutDrops;

  /// No description provided for @photoStorage.
  ///
  /// In en, this message translates to:
  /// **'Photo Storage'**
  String get photoStorage;

  /// No description provided for @saveAndAccessPhotosOfRecyclableItems.
  ///
  /// In en, this message translates to:
  /// **'Save and access photos of your recyclable items.'**
  String get saveAndAccessPhotosOfRecyclableItems;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to App'**
  String get continueToApp;

  /// No description provided for @enableRequiredPermissions.
  ///
  /// In en, this message translates to:
  /// **'Enable Required Permissions'**
  String get enableRequiredPermissions;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account Disabled'**
  String get accountDisabled;

  /// No description provided for @accountDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been permanently disabled due to repeated violations of Bottleji\'s community guidelines.\n\nYou can no longer access or use this account.\n\nIf you believe this decision was made in error, please contact support:'**
  String get accountDisabledMessage;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'support@bottleji.com'**
  String get supportEmail;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @pleaseEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Please email support@bottleji.com for assistance'**
  String get pleaseEmailSupport;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpired;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again to continue.'**
  String get sessionExpiredMessage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @drops.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get drops;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @errorDuringLogout.
  ///
  /// In en, this message translates to:
  /// **'Error during logout: {error}'**
  String errorDuringLogout(String error);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @filterDrops.
  ///
  /// In en, this message translates to:
  /// **'Filter Drops'**
  String get filterDrops;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @deleteDrop.
  ///
  /// In en, this message translates to:
  /// **'Delete Drop'**
  String get deleteDrop;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this drop?'**
  String get areYouSureDelete;

  /// No description provided for @createDrop.
  ///
  /// In en, this message translates to:
  /// **'Create Drop'**
  String get createDrop;

  /// No description provided for @editDrop.
  ///
  /// In en, this message translates to:
  /// **'Edit Drop'**
  String get editDrop;

  /// No description provided for @startCollection.
  ///
  /// In en, this message translates to:
  /// **'Start Collection'**
  String get startCollection;

  /// No description provided for @resumeNavigation.
  ///
  /// In en, this message translates to:
  /// **'Resume Navigation'**
  String get resumeNavigation;

  /// No description provided for @cancelCollection.
  ///
  /// In en, this message translates to:
  /// **'Cancel Collection'**
  String get cancelCollection;

  /// No description provided for @areYouSureCancelCollection.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this collection?'**
  String get areYouSureCancelCollection;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @leaveCollection.
  ///
  /// In en, this message translates to:
  /// **'Leave Collection?'**
  String get leaveCollection;

  /// No description provided for @areYouSureLeaveCollection.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave? Your collection will remain active.'**
  String get areYouSureLeaveCollection;

  /// No description provided for @exitNavigation.
  ///
  /// In en, this message translates to:
  /// **'Exit Navigation'**
  String get exitNavigation;

  /// No description provided for @areYouSureExitNavigation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit navigation? Your collection will remain active.'**
  String get areYouSureExitNavigation;

  /// No description provided for @reportDrop.
  ///
  /// In en, this message translates to:
  /// **'Report Drop'**
  String get reportDrop;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @setCollectionRadius.
  ///
  /// In en, this message translates to:
  /// **'Set Collection Radius'**
  String get setCollectionRadius;

  /// No description provided for @setCollectionRadiusDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the radius (in kilometers) within which you want to collect bottles.'**
  String get setCollectionRadiusDescription;

  /// No description provided for @kilometers.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kilometers;

  /// No description provided for @collectionRadiusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Collection radius updated!'**
  String get collectionRadiusUpdated;

  /// No description provided for @saveRadius.
  ///
  /// In en, this message translates to:
  /// **'Save Radius'**
  String get saveRadius;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @galleryIOSSimulatorIssue.
  ///
  /// In en, this message translates to:
  /// **'Gallery (iOS Simulator Issue)'**
  String get galleryIOSSimulatorIssue;

  /// No description provided for @useCameraOrRealDevice.
  ///
  /// In en, this message translates to:
  /// **'Use camera or real device'**
  String get useCameraOrRealDevice;

  /// No description provided for @leaveOutsideDoor.
  ///
  /// In en, this message translates to:
  /// **'Leave outside the door'**
  String get leaveOutsideDoor;

  /// No description provided for @pleaseTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please take a photo of your bottles'**
  String get pleaseTakePhoto;

  /// No description provided for @pleaseWaitLoading.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we load your account information'**
  String get pleaseWaitLoading;

  /// No description provided for @mustBeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to create a drop'**
  String get mustBeLoggedIn;

  /// No description provided for @authenticationIssue.
  ///
  /// In en, this message translates to:
  /// **'Authentication issue detected. Please log out and log in again.'**
  String get authenticationIssue;

  /// No description provided for @dropCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Drop created successfully!'**
  String get dropCreatedSuccessfully;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @reloadMap.
  ///
  /// In en, this message translates to:
  /// **'Reload Map'**
  String get reloadMap;

  /// No description provided for @thisHelpsUsShowNearby.
  ///
  /// In en, this message translates to:
  /// **'This helps us show nearby drops and provide accurate collection services.'**
  String get thisHelpsUsShowNearby;

  /// No description provided for @errorLoadingUserMode.
  ///
  /// In en, this message translates to:
  /// **'Error loading user mode: {error}'**
  String errorLoadingUserMode(String error);

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new drops'**
  String get checkBackLater;

  /// No description provided for @createFirstDrop.
  ///
  /// In en, this message translates to:
  /// **'Create your first drop to get started'**
  String get createFirstDrop;

  /// No description provided for @collectionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Collection in Progress'**
  String get collectionInProgress;

  /// No description provided for @resumeCollection.
  ///
  /// In en, this message translates to:
  /// **'Resume Collection'**
  String get resumeCollection;

  /// No description provided for @collectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Collection Timeout'**
  String get collectionTimeout;

  /// No description provided for @warningSystem.
  ///
  /// In en, this message translates to:
  /// **'Warning System'**
  String get warningSystem;

  /// No description provided for @warningAddedToAccount.
  ///
  /// In en, this message translates to:
  /// **'A warning was added to your account for this drop. Please make sure future images follow the community guidelines.'**
  String get warningAddedToAccount;

  /// No description provided for @timerExpired.
  ///
  /// In en, this message translates to:
  /// **'⏰ Timer Expired!'**
  String get timerExpired;

  /// No description provided for @timerExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'The collection timer has expired. The navigation screen will now exit.'**
  String get timerExpiredMessage;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application Rejected'**
  String get applicationRejected;

  /// No description provided for @applicationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your collector application was rejected. Reason: {reason}'**
  String applicationRejectedMessage(String reason);

  /// No description provided for @noSpecificReason.
  ///
  /// In en, this message translates to:
  /// **'No specific reason provided'**
  String get noSpecificReason;

  /// No description provided for @canEditApplication.
  ///
  /// In en, this message translates to:
  /// **'You can edit your application and submit it again.'**
  String get canEditApplication;

  /// No description provided for @editApplication.
  ///
  /// In en, this message translates to:
  /// **'Edit Application'**
  String get editApplication;

  /// No description provided for @pleaseLogInCollector.
  ///
  /// In en, this message translates to:
  /// **'Please log in to access collector mode'**
  String get pleaseLogInCollector;

  /// No description provided for @tierSystem.
  ///
  /// In en, this message translates to:
  /// **'Tier System'**
  String get tierSystem;

  /// No description provided for @bySubscribingAgree.
  ///
  /// In en, this message translates to:
  /// **'By subscribing, you agree to our Terms of Service\nand Privacy Policy'**
  String get bySubscribingAgree;

  /// No description provided for @startProSubscription.
  ///
  /// In en, this message translates to:
  /// **'Start PRO Subscription'**
  String get startProSubscription;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: March 15, 2024'**
  String get lastUpdated;

  /// No description provided for @acceptanceOfTerms.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get acceptanceOfTerms;

  /// No description provided for @acceptanceOfTermsContent.
  ///
  /// In en, this message translates to:
  /// **'By accessing and using the Bottleji application, you agree to be bound by these Terms and Conditions. If you disagree with any part of these terms, you may not access the application.'**
  String get acceptanceOfTermsContent;

  /// No description provided for @userResponsibilities.
  ///
  /// In en, this message translates to:
  /// **'2. User Responsibilities'**
  String get userResponsibilities;

  /// No description provided for @userResponsibilitiesContent.
  ///
  /// In en, this message translates to:
  /// **'As a user of Bottleji, you agree to:\n• Provide accurate and complete information\n• Maintain the security of your account\n• Follow waste segregation guidelines\n• Schedule collections responsibly\n• Use the service in accordance with local laws'**
  String get userResponsibilitiesContent;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @collector.
  ///
  /// In en, this message translates to:
  /// **'Collector'**
  String get collector;

  /// No description provided for @activeMode.
  ///
  /// In en, this message translates to:
  /// **'Active Mode'**
  String get activeMode;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @trainings.
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get trainings;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer and Earn'**
  String get referAndEarn;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @becomeACollector.
  ///
  /// In en, this message translates to:
  /// **'Become a Collector'**
  String get becomeACollector;

  /// No description provided for @applicationUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Your application is currently under review. Would you like to view your application status?'**
  String get applicationUnderReview;

  /// No description provided for @viewStatus.
  ///
  /// In en, this message translates to:
  /// **'View Status'**
  String get viewStatus;

  /// No description provided for @applicationRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Your application was rejected for the following reason:\n\n\"{rejectionReason}\"\n\nWould you like to edit your application and submit it again?'**
  String applicationRejectedReason(String rejectionReason);

  /// No description provided for @applicationApprovedSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your application was approved but your collector access has been temporarily suspended. Please contact support or reapply.'**
  String get applicationApprovedSuspended;

  /// No description provided for @reapply.
  ///
  /// In en, this message translates to:
  /// **'Reapply'**
  String get reapply;

  /// No description provided for @needToApplyCollector.
  ///
  /// In en, this message translates to:
  /// **'You need to apply and be approved to access collector mode. Would you like to apply now?'**
  String get needToApplyCollector;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @householdMode.
  ///
  /// In en, this message translates to:
  /// **'Household Mode'**
  String get householdMode;

  /// No description provided for @collectorMode.
  ///
  /// In en, this message translates to:
  /// **'Collector Mode'**
  String get collectorMode;

  /// No description provided for @householdModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Create drops and track your recycling'**
  String get householdModeDescription;

  /// No description provided for @collectorModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Collect bottles and earn rewards'**
  String get collectorModeDescription;

  /// No description provided for @sustainableWasteManagement.
  ///
  /// In en, this message translates to:
  /// **'Sustainable Waste Management'**
  String get sustainableWasteManagement;

  /// No description provided for @ecoFriendlyBottleCollection.
  ///
  /// In en, this message translates to:
  /// **'Eco-friendly bottle collection'**
  String get ecoFriendlyBottleCollection;

  /// No description provided for @bottleType.
  ///
  /// In en, this message translates to:
  /// **'Bottle Type'**
  String get bottleType;

  /// No description provided for @numberOfPlasticBottles.
  ///
  /// In en, this message translates to:
  /// **'Number of Plastic Bottles'**
  String get numberOfPlasticBottles;

  /// No description provided for @numberOfCans.
  ///
  /// In en, this message translates to:
  /// **'Number of Cans'**
  String get numberOfCans;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @failedToCreateDrop.
  ///
  /// In en, this message translates to:
  /// **'Failed to create drop. Please try again.'**
  String get failedToCreateDrop;

  /// No description provided for @imageSelectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image selected successfully!'**
  String get imageSelectedSuccessfully;

  /// No description provided for @errorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errorSelectingImage;

  /// No description provided for @permissionDeniedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please allow photo access in Settings.'**
  String get permissionDeniedPhoto;

  /// No description provided for @galleryNotAvailableSimulator.
  ///
  /// In en, this message translates to:
  /// **'Gallery not available on simulator. Try camera or use a real device.'**
  String get galleryNotAvailableSimulator;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @collectorStatus.
  ///
  /// In en, this message translates to:
  /// **'Collector Status'**
  String get collectorStatus;

  /// No description provided for @approvedCollector.
  ///
  /// In en, this message translates to:
  /// **'You are an approved collector'**
  String get approvedCollector;

  /// No description provided for @applicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get applicationStatus;

  /// No description provided for @applicationUnderReviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Your application is under review'**
  String get applicationUnderReviewStatus;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @applicationRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Rejected'**
  String get applicationRejectedTitle;

  /// No description provided for @pleaseLoginToViewProfile.
  ///
  /// In en, this message translates to:
  /// **'Please login to view your profile'**
  String get pleaseLoginToViewProfile;

  /// No description provided for @bottlejiRequiresPermissions.
  ///
  /// In en, this message translates to:
  /// **'Bottleji requires additional permissions to work properly'**
  String get bottlejiRequiresPermissions;

  /// No description provided for @galleryError.
  ///
  /// In en, this message translates to:
  /// **'Gallery error: {error}'**
  String galleryError(String error);

  /// No description provided for @galleryNotAvailableIOS.
  ///
  /// In en, this message translates to:
  /// **'Gallery not available on iOS simulator: {error}'**
  String galleryNotAvailableIOS(String error);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @phoneNumberMustBe8Digits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 8 digits'**
  String get phoneNumberMustBe8Digits;

  /// No description provided for @phoneNumberMustContainOnlyDigits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must contain only digits'**
  String get phoneNumberMustContainOnlyDigits;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @pleaseEnterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhoneNumber;

  /// No description provided for @pleaseEnterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address'**
  String get pleaseEnterYourAddress;

  /// No description provided for @pleaseVerifyYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please verify your phone number before saving'**
  String get pleaseVerifyYourPhoneNumber;

  /// No description provided for @noChangesDetected.
  ///
  /// In en, this message translates to:
  /// **'No changes detected. Profile remains unchanged.'**
  String get noChangesDetected;

  /// No description provided for @profileSetupCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile setup completed successfully! Welcome to Bottleji!'**
  String get profileSetupCompletedSuccessfully;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String failedToUploadImage(String error);

  /// No description provided for @smsCode.
  ///
  /// In en, this message translates to:
  /// **'SMS Code'**
  String get smsCode;

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get enter6DigitCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @phoneNumberVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified'**
  String get phoneNumberVerified;

  /// No description provided for @phoneNumberNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number not verified'**
  String get phoneNumberNotVerified;

  /// No description provided for @phoneNumberNeedsVerification.
  ///
  /// In en, this message translates to:
  /// **'Phone number needs verification'**
  String get phoneNumberNeedsVerification;

  /// No description provided for @phoneNumberVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified successfully!'**
  String get phoneNumberVerifiedSuccessfully;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search Address'**
  String get searchAddress;

  /// No description provided for @tapToSearchAddress.
  ///
  /// In en, this message translates to:
  /// **'Tap to search for your address'**
  String get tapToSearchAddress;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search...'**
  String get typeToSearch;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @errorFetchingSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Error fetching suggestions: {error}'**
  String errorFetchingSuggestions(String error);

  /// No description provided for @pleaseEnterPhoneNumberFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number first'**
  String get pleaseEnterPhoneNumberFirst;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number with country code (e.g., +49 123456789)'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for address features'**
  String get locationPermissionRequired;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @createNewDrop.
  ///
  /// In en, this message translates to:
  /// **'Create New Drop'**
  String get createNewDrop;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @takePhotoOrChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or choose from gallery - show your bottles clearly to help collectors'**
  String get takePhotoOrChooseFromGallery;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @cameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or Gallery'**
  String get cameraOrGallery;

  /// No description provided for @allDrops.
  ///
  /// In en, this message translates to:
  /// **'All Drops'**
  String get allDrops;

  /// No description provided for @myDrops.
  ///
  /// In en, this message translates to:
  /// **'My Drops'**
  String get myDrops;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @flagged.
  ///
  /// In en, this message translates to:
  /// **'FLAGGED'**
  String get flagged;

  /// No description provided for @censored.
  ///
  /// In en, this message translates to:
  /// **'Censored'**
  String get censored;

  /// No description provided for @stale.
  ///
  /// In en, this message translates to:
  /// **'Stale'**
  String get stale;

  /// No description provided for @dropsInThisFilterCollected.
  ///
  /// In en, this message translates to:
  /// **'Drops in this filter have been successfully collected by a collector. These drops show your recycling impact and cannot be edited.'**
  String get dropsInThisFilterCollected;

  /// No description provided for @dropsInThisFilterFlagged.
  ///
  /// In en, this message translates to:
  /// **'Drops in this filter were flagged due to multiple cancellations or suspicious activity. Flagged drops are hidden from the map and cannot be edited.'**
  String get dropsInThisFilterFlagged;

  /// No description provided for @dropsInThisFilterCensored.
  ///
  /// In en, this message translates to:
  /// **'Drops in this filter were censored due to inappropriate content. Censored drops are hidden from the map and cannot be edited.'**
  String get dropsInThisFilterCensored;

  /// No description provided for @dropsInThisFilterStale.
  ///
  /// In en, this message translates to:
  /// **'Drops in this filter were marked as stale because they were older than 3 days and likely collected by external collectors. Stale drops are hidden from the map and cannot be edited.'**
  String get dropsInThisFilterStale;

  /// No description provided for @inActiveCollection.
  ///
  /// In en, this message translates to:
  /// **'In Active Collection - Collector on the way'**
  String get inActiveCollection;

  /// No description provided for @censoredInappropriateImage.
  ///
  /// In en, this message translates to:
  /// **'Censored: {reason}'**
  String censoredInappropriateImage(String reason);

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @collectorOnHisWay.
  ///
  /// In en, this message translates to:
  /// **'Collector on his way to pick up your drop'**
  String get collectorOnHisWay;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get waiting;

  /// No description provided for @notYetCollected.
  ///
  /// In en, this message translates to:
  /// **'Not yet collected'**
  String get notYetCollected;

  /// No description provided for @yourPoints.
  ///
  /// In en, this message translates to:
  /// **'Your Points'**
  String get yourPoints;

  /// No description provided for @pointsToGo.
  ///
  /// In en, this message translates to:
  /// **'{points} points to go'**
  String pointsToGo(int points);

  /// No description provided for @progressToNextTier.
  ///
  /// In en, this message translates to:
  /// **'Progress to Next Tier'**
  String get progressToNextTier;

  /// No description provided for @bronzeCollector.
  ///
  /// In en, this message translates to:
  /// **'Bronze Collector'**
  String get bronzeCollector;

  /// No description provided for @silverCollector.
  ///
  /// In en, this message translates to:
  /// **'Silver Collector'**
  String get silverCollector;

  /// No description provided for @goldCollector.
  ///
  /// In en, this message translates to:
  /// **'Gold Collector'**
  String get goldCollector;

  /// No description provided for @platinumCollector.
  ///
  /// In en, this message translates to:
  /// **'Platinum Collector'**
  String get platinumCollector;

  /// No description provided for @diamondCollector.
  ///
  /// In en, this message translates to:
  /// **'Diamond Collector'**
  String get diamondCollector;

  /// No description provided for @earnPointsPerDropCollected.
  ///
  /// In en, this message translates to:
  /// **'Earn {points} points per drop collected'**
  String earnPointsPerDropCollected(int points);

  /// No description provided for @earnPointsWhenDropsCollected.
  ///
  /// In en, this message translates to:
  /// **'Earn {points} points when your drops are collected'**
  String earnPointsWhenDropsCollected(int points);

  /// No description provided for @rewardShop.
  ///
  /// In en, this message translates to:
  /// **'Reward Shop'**
  String get rewardShop;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @yourOrderHistoryWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here'**
  String get yourOrderHistoryWillAppearHere;

  /// No description provided for @notEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough points'**
  String get notEnoughPoints;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pts;

  /// No description provided for @myStats.
  ///
  /// In en, this message translates to:
  /// **'My Stats'**
  String get myStats;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get timeRange;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @dropStatus.
  ///
  /// In en, this message translates to:
  /// **'Drop Status'**
  String get dropStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @collectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection Rate'**
  String get collectionRate;

  /// No description provided for @avgCollectionTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Collection Time'**
  String get avgCollectionTime;

  /// No description provided for @recentCollections.
  ///
  /// In en, this message translates to:
  /// **'Recent Collections'**
  String get recentCollections;

  /// No description provided for @supportAndHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get supportAndHelp;

  /// No description provided for @howCanWeHelpYou.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelpYou;

  /// No description provided for @selectCategoryToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Select a category to get started'**
  String get selectCategoryToGetStarted;

  /// No description provided for @supportCategories.
  ///
  /// In en, this message translates to:
  /// **'Support Categories'**
  String get supportCategories;

  /// No description provided for @whatDoYouNeedHelpWith.
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get whatDoYouNeedHelpWith;

  /// No description provided for @selectCategoryToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a category to continue'**
  String get selectCategoryToContinue;

  /// No description provided for @trainingCenter.
  ///
  /// In en, this message translates to:
  /// **'Training Center'**
  String get trainingCenter;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAt(String time);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @leaveOutside.
  ///
  /// In en, this message translates to:
  /// **'Leave Outside'**
  String get leaveOutside;

  /// No description provided for @noImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No image available'**
  String get noImageAvailable;

  /// No description provided for @estTime.
  ///
  /// In en, this message translates to:
  /// **'Est. Time'**
  String get estTime;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival Time'**
  String get estimatedTime;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @dropLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop Location'**
  String get dropLocation;

  /// No description provided for @routePreview.
  ///
  /// In en, this message translates to:
  /// **'Route Preview'**
  String get routePreview;

  /// No description provided for @dropInformation.
  ///
  /// In en, this message translates to:
  /// **'Drop Information'**
  String get dropInformation;

  /// No description provided for @plasticBottles.
  ///
  /// In en, this message translates to:
  /// **'Plastic Bottles'**
  String get plasticBottles;

  /// No description provided for @cans.
  ///
  /// In en, this message translates to:
  /// **'Cans'**
  String get cans;

  /// No description provided for @plastic.
  ///
  /// In en, this message translates to:
  /// **'Plastic'**
  String get plastic;

  /// No description provided for @can.
  ///
  /// In en, this message translates to:
  /// **'CAN'**
  String get can;

  /// No description provided for @mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get mixed;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated Value'**
  String get estimatedValue;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @completeCurrentCollectionFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete your current collection before starting a new one.'**
  String get completeCurrentCollectionFirst;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Please check your internet connection.'**
  String get youAreOffline;

  /// No description provided for @errorColon.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorColon(String error);

  /// No description provided for @yourInformation.
  ///
  /// In en, this message translates to:
  /// **'Your Information'**
  String get yourInformation;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @youWillSeeNotificationsHere.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see your notifications here'**
  String get youWillSeeNotificationsHere;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingStatus;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get acceptedStatus;

  /// No description provided for @collectedStatus.
  ///
  /// In en, this message translates to:
  /// **'COLLECTED'**
  String get collectedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get cancelledStatus;

  /// No description provided for @expiredStatus.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expiredStatus;

  /// No description provided for @staleStatus.
  ///
  /// In en, this message translates to:
  /// **'STALE'**
  String get staleStatus;

  /// No description provided for @howRewardsWork.
  ///
  /// In en, this message translates to:
  /// **'How Rewards Work'**
  String get howRewardsWork;

  /// No description provided for @howRewardsWorkCollector.
  ///
  /// In en, this message translates to:
  /// **'• Collect drops to earn points\n• Higher tiers = more points per drop\n• Use points in the reward shop\n• Track your progress and achievements'**
  String get howRewardsWorkCollector;

  /// No description provided for @howRewardsWorkHousehold.
  ///
  /// In en, this message translates to:
  /// **'• Create drops to contribute to recycling\n• Earn points when collectors pick up your drops\n• Higher tiers = more points per collected drop\n• Use points in the reward shop'**
  String get howRewardsWorkHousehold;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @itemNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Item is not available'**
  String get itemNotAvailable;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @pleaseLogInToViewOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view order history'**
  String get pleaseLogInToViewOrderHistory;

  /// No description provided for @failedToLoadOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order history'**
  String get failedToLoadOrderHistory;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @pointsSpent.
  ///
  /// In en, this message translates to:
  /// **'Points Spent'**
  String get pointsSpent;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery'**
  String get estimatedDelivery;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Note'**
  String get adminNote;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String available(int count);

  /// No description provided for @updateDrop.
  ///
  /// In en, this message translates to:
  /// **'Update Drop'**
  String get updateDrop;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @recyclingImpact.
  ///
  /// In en, this message translates to:
  /// **'Recycling Impact'**
  String get recyclingImpact;

  /// No description provided for @recentDrops.
  ///
  /// In en, this message translates to:
  /// **'Recent Drops'**
  String get recentDrops;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @dropStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Drop Status'**
  String get dropStatusDistribution;

  /// No description provided for @co2VolumeSaved.
  ///
  /// In en, this message translates to:
  /// **'CO₂ Volume Saved'**
  String get co2VolumeSaved;

  /// No description provided for @totalCo2Saved.
  ///
  /// In en, this message translates to:
  /// **'Total CO₂ Saved: {amount} kg'**
  String totalCo2Saved(String amount);

  /// No description provided for @dropActivity.
  ///
  /// In en, this message translates to:
  /// **'Drop Activity'**
  String get dropActivity;

  /// No description provided for @dropsCreated.
  ///
  /// In en, this message translates to:
  /// **'Drops Created ({timeRange}): {count}'**
  String dropsCreated(String timeRange, int count);

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(String error);

  /// No description provided for @dropUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Drop updated successfully!'**
  String get dropUpdatedSuccessfully;

  /// No description provided for @errorUpdatingDrop.
  ///
  /// In en, this message translates to:
  /// **'Error updating drop: {error}'**
  String errorUpdatingDrop(String error);

  /// No description provided for @areYouSureDeleteDrop.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this drop? This action cannot be undone.'**
  String get areYouSureDeleteDrop;

  /// No description provided for @dropDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Drop deleted successfully!'**
  String get dropDeletedSuccessfully;

  /// No description provided for @errorDeletingDrop.
  ///
  /// In en, this message translates to:
  /// **'Error deleting drop: {error}'**
  String errorDeletingDrop(String error);

  /// No description provided for @pleaseEnterNumberOfBottles.
  ///
  /// In en, this message translates to:
  /// **'Please enter number of bottles'**
  String get pleaseEnterNumberOfBottles;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @pleaseEnterNumberOfCans.
  ///
  /// In en, this message translates to:
  /// **'Please enter number of cans'**
  String get pleaseEnterNumberOfCans;

  /// No description provided for @anyAdditionalInstructions.
  ///
  /// In en, this message translates to:
  /// **'Any additional instructions for the collector...'**
  String get anyAdditionalInstructions;

  /// No description provided for @collectorCanLeaveOutside.
  ///
  /// In en, this message translates to:
  /// **'Collector can leave items outside if no one is home'**
  String get collectorCanLeaveOutside;

  /// No description provided for @loadingAddress.
  ///
  /// In en, this message translates to:
  /// **'Loading address...'**
  String get loadingAddress;

  /// No description provided for @locationFormat.
  ///
  /// In en, this message translates to:
  /// **'Location: {lat}, {lng}'**
  String locationFormat(String lat, String lng);

  /// No description provided for @locationSelected.
  ///
  /// In en, this message translates to:
  /// **'Location selected'**
  String get locationSelected;

  /// No description provided for @currentDropLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Drop Location'**
  String get currentDropLocation;

  /// No description provided for @tapConfirmToSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Confirm\" to set this location'**
  String get tapConfirmToSetLocation;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get Help'**
  String get getHelp;

  /// No description provided for @selectCategoryAndGetSupport.
  ///
  /// In en, this message translates to:
  /// **'Select a category and get support for your issue'**
  String get selectCategoryAndGetSupport;

  /// No description provided for @mySupportTickets.
  ///
  /// In en, this message translates to:
  /// **'My Support Tickets'**
  String get mySupportTickets;

  /// No description provided for @viewAndManageTickets.
  ///
  /// In en, this message translates to:
  /// **'View and manage your existing support tickets'**
  String get viewAndManageTickets;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @findAnswersToCommonQuestions.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions'**
  String get findAnswersToCommonQuestions;

  /// No description provided for @needMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need More Help?'**
  String get needMoreHelp;

  /// No description provided for @supportTeamAvailable247.
  ///
  /// In en, this message translates to:
  /// **'If you can\'t find what you\'re looking for, our support team is here to help 24/7.'**
  String get supportTeamAvailable247;

  /// No description provided for @dropIssues.
  ///
  /// In en, this message translates to:
  /// **'Drop Issues'**
  String get dropIssues;

  /// No description provided for @getHelpWithDropProblems.
  ///
  /// In en, this message translates to:
  /// **'Get help with drop-related problems'**
  String get getHelpWithDropProblems;

  /// No description provided for @dropIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expired drops, canceled collections, active collections'**
  String get dropIssuesSubtitle;

  /// No description provided for @applicationIssues.
  ///
  /// In en, this message translates to:
  /// **'Application Issues'**
  String get applicationIssues;

  /// No description provided for @getHelpWithApplications.
  ///
  /// In en, this message translates to:
  /// **'Get help with collector applications'**
  String get getHelpWithApplications;

  /// No description provided for @applicationIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rejected applications, pending reviews'**
  String get applicationIssuesSubtitle;

  /// No description provided for @accountIssues.
  ///
  /// In en, this message translates to:
  /// **'Account Issues'**
  String get accountIssues;

  /// No description provided for @getHelpWithAccount.
  ///
  /// In en, this message translates to:
  /// **'Get help with your account'**
  String get getHelpWithAccount;

  /// No description provided for @accountIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile updates, login problems, account settings'**
  String get accountIssuesSubtitle;

  /// No description provided for @technicalIssues.
  ///
  /// In en, this message translates to:
  /// **'Technical Issues'**
  String get technicalIssues;

  /// No description provided for @getHelpWithAppProblems.
  ///
  /// In en, this message translates to:
  /// **'Get help with app problems'**
  String get getHelpWithAppProblems;

  /// No description provided for @technicalIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App crashes, bugs, performance issues'**
  String get technicalIssuesSubtitle;

  /// No description provided for @paymentIssues.
  ///
  /// In en, this message translates to:
  /// **'Payment Issues'**
  String get paymentIssues;

  /// No description provided for @getHelpWithPayments.
  ///
  /// In en, this message translates to:
  /// **'Get help with payments'**
  String get getHelpWithPayments;

  /// No description provided for @paymentIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment delays, missing payments, payment methods'**
  String get paymentIssuesSubtitle;

  /// No description provided for @generalSupport.
  ///
  /// In en, this message translates to:
  /// **'General Support'**
  String get generalSupport;

  /// No description provided for @getHelpWithAnythingElse.
  ///
  /// In en, this message translates to:
  /// **'Get help with anything else'**
  String get getHelpWithAnythingElse;

  /// No description provided for @generalSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions, suggestions, other issues'**
  String get generalSupportSubtitle;

  /// No description provided for @selectItemToGetHelp.
  ///
  /// In en, this message translates to:
  /// **'Select an item to get help'**
  String get selectItemToGetHelp;

  /// No description provided for @selectDropFromLast3Days.
  ///
  /// In en, this message translates to:
  /// **'Select a drop from the last 3 days to get help'**
  String get selectDropFromLast3Days;

  /// No description provided for @selectApplicationToGetHelp.
  ///
  /// In en, this message translates to:
  /// **'Select your collector application to get help'**
  String get selectApplicationToGetHelp;

  /// No description provided for @getHelpWithAccountIssues.
  ///
  /// In en, this message translates to:
  /// **'Get help with your account issues'**
  String get getHelpWithAccountIssues;

  /// No description provided for @getHelpWithTechnicalProblems.
  ///
  /// In en, this message translates to:
  /// **'Get help with technical problems'**
  String get getHelpWithTechnicalProblems;

  /// No description provided for @getHelpWithPaymentIssues.
  ///
  /// In en, this message translates to:
  /// **'Get help with payment issues'**
  String get getHelpWithPaymentIssues;

  /// No description provided for @getHelpWithAnyOtherIssue.
  ///
  /// In en, this message translates to:
  /// **'Get help with any other issue'**
  String get getHelpWithAnyOtherIssue;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication Error'**
  String get authenticationError;

  /// No description provided for @pleaseLogInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please log in again to view your items.'**
  String get pleaseLogInAgain;

  /// No description provided for @noCollectionsFound.
  ///
  /// In en, this message translates to:
  /// **'No Collections Found'**
  String get noCollectionsFound;

  /// No description provided for @noCollectionsToReport.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any collections to report issues for.'**
  String get noCollectionsToReport;

  /// No description provided for @yourCollectionsLast3Days.
  ///
  /// In en, this message translates to:
  /// **'Your Collections (Last 3 Days)'**
  String get yourCollectionsLast3Days;

  /// No description provided for @errorLoadingCollections.
  ///
  /// In en, this message translates to:
  /// **'Error loading collections: {error}'**
  String errorLoadingCollections(String error);

  /// No description provided for @noDropsFound.
  ///
  /// In en, this message translates to:
  /// **'No Drops Found'**
  String get noDropsFound;

  /// No description provided for @noDropsToReport.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any drops to report issues for.'**
  String get noDropsToReport;

  /// No description provided for @yourDropsLast3Days.
  ///
  /// In en, this message translates to:
  /// **'Your Drops (Last 3 Days)'**
  String get yourDropsLast3Days;

  /// No description provided for @errorLoadingDrops.
  ///
  /// In en, this message translates to:
  /// **'Error loading drops: {error}'**
  String errorLoadingDrops(String error);

  /// No description provided for @noApplications.
  ///
  /// In en, this message translates to:
  /// **'No Applications'**
  String get noApplications;

  /// No description provided for @noCollectorApplications.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any collector applications.'**
  String get noCollectorApplications;

  /// No description provided for @noIssuesFound.
  ///
  /// In en, this message translates to:
  /// **'No Issues Found'**
  String get noIssuesFound;

  /// No description provided for @applicationBeingProcessed.
  ///
  /// In en, this message translates to:
  /// **'Your application is being processed normally.'**
  String get applicationBeingProcessed;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No Payments Yet'**
  String get noPaymentsYet;

  /// No description provided for @paymentFeatureNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Payment feature is not available yet. Select a payment to get help with payment-related issues.'**
  String get paymentFeatureNotAvailable;

  /// No description provided for @paymentSupport.
  ///
  /// In en, this message translates to:
  /// **'Payment Support'**
  String get paymentSupport;

  /// No description provided for @getHelpWithPaymentRelatedIssues.
  ///
  /// In en, this message translates to:
  /// **'Get help with payment-related issues'**
  String get getHelpWithPaymentRelatedIssues;

  /// No description provided for @supportOptions.
  ///
  /// In en, this message translates to:
  /// **'Support Options'**
  String get supportOptions;

  /// No description provided for @collectorApplication.
  ///
  /// In en, this message translates to:
  /// **'Collector Application'**
  String get collectorApplication;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applied;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drop;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @reviewTicket.
  ///
  /// In en, this message translates to:
  /// **'Review Ticket'**
  String get reviewTicket;

  /// No description provided for @reviewYourTicket.
  ///
  /// In en, this message translates to:
  /// **'Review Your Ticket'**
  String get reviewYourTicket;

  /// No description provided for @pleaseReviewDetailsBeforeCreating.
  ///
  /// In en, this message translates to:
  /// **'Please review the details before creating'**
  String get pleaseReviewDetailsBeforeCreating;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @confirmAndCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Create Ticket'**
  String get confirmAndCreateTicket;

  /// No description provided for @supportTicketCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Support ticket created successfully!'**
  String get supportTicketCreatedSuccessfully;

  /// No description provided for @failedToCreateTicket.
  ///
  /// In en, this message translates to:
  /// **'Failed to create ticket: {error}'**
  String failedToCreateTicket(String error);

  /// No description provided for @allTickets.
  ///
  /// In en, this message translates to:
  /// **'All Tickets'**
  String get allTickets;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @onHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get onHold;

  /// No description provided for @noSupportTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get noSupportTicketsYet;

  /// No description provided for @createFirstSupportTicket.
  ///
  /// In en, this message translates to:
  /// **'Create your first support ticket if you need help'**
  String get createFirstSupportTicket;

  /// No description provided for @errorLoadingTickets.
  ///
  /// In en, this message translates to:
  /// **'Error loading tickets'**
  String get errorLoadingTickets;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get lowPriority;

  /// No description provided for @mediumPriority.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority'**
  String get mediumPriority;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get highPriority;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @dropIssue.
  ///
  /// In en, this message translates to:
  /// **'Drop Issue'**
  String get dropIssue;

  /// No description provided for @collectionIssue.
  ///
  /// In en, this message translates to:
  /// **'Collection Issue'**
  String get collectionIssue;

  /// No description provided for @issueWithDropCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Issue with drop created on {date}'**
  String issueWithDropCreatedOn(String date);

  /// No description provided for @bottles.
  ///
  /// In en, this message translates to:
  /// **'Bottles'**
  String get bottles;

  /// No description provided for @issueWithCollection.
  ///
  /// In en, this message translates to:
  /// **'Issue with collection {status} on {date}'**
  String issueWithCollection(String status, String date);

  /// No description provided for @authenticationAccount.
  ///
  /// In en, this message translates to:
  /// **'🔐 Authentication & Account'**
  String get authenticationAccount;

  /// No description provided for @appTechnicalIssues.
  ///
  /// In en, this message translates to:
  /// **'📱 App Technical Issues'**
  String get appTechnicalIssues;

  /// No description provided for @dropCreationManagement.
  ///
  /// In en, this message translates to:
  /// **'🏠 Drop Creation & Management'**
  String get dropCreationManagement;

  /// No description provided for @collectionNavigation.
  ///
  /// In en, this message translates to:
  /// **'🚚 Collection & Navigation'**
  String get collectionNavigation;

  /// No description provided for @collectorApplicationCategory.
  ///
  /// In en, this message translates to:
  /// **'👤 Collector Application'**
  String get collectorApplicationCategory;

  /// No description provided for @paymentRewards.
  ///
  /// In en, this message translates to:
  /// **'💰 Payment & Rewards'**
  String get paymentRewards;

  /// No description provided for @statisticsHistory.
  ///
  /// In en, this message translates to:
  /// **'📊 Statistics & History'**
  String get statisticsHistory;

  /// No description provided for @roleSwitching.
  ///
  /// In en, this message translates to:
  /// **'🔄 Role Switching'**
  String get roleSwitching;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'📞 Communication'**
  String get communication;

  /// No description provided for @generalSupportCategory.
  ///
  /// In en, this message translates to:
  /// **'🛠️ General Support'**
  String get generalSupportCategory;

  /// No description provided for @supportTicket.
  ///
  /// In en, this message translates to:
  /// **'Support Ticket'**
  String get supportTicket;

  /// No description provided for @cannotSendMessageTicketClosed.
  ///
  /// In en, this message translates to:
  /// **'Cannot send message. This ticket is closed.'**
  String get cannotSendMessageTicketClosed;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: {error}'**
  String failedToSendMessage(String error);

  /// No description provided for @adminIsOnline.
  ///
  /// In en, this message translates to:
  /// **'Admin is online'**
  String get adminIsOnline;

  /// No description provided for @adminIsTyping.
  ///
  /// In en, this message translates to:
  /// **'Admin is typing...'**
  String get adminIsTyping;

  /// No description provided for @helpUsMaintainQuality.
  ///
  /// In en, this message translates to:
  /// **'Help us maintain quality'**
  String get helpUsMaintainQuality;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select Reason'**
  String get selectReason;

  /// No description provided for @inappropriateImage.
  ///
  /// In en, this message translates to:
  /// **'🚫 Inappropriate Image'**
  String get inappropriateImage;

  /// No description provided for @fakeDrop.
  ///
  /// In en, this message translates to:
  /// **'❌ Fake Drop'**
  String get fakeDrop;

  /// No description provided for @amountMismatch.
  ///
  /// In en, this message translates to:
  /// **'📊 Amount of bottles not matching the real drop'**
  String get amountMismatch;

  /// No description provided for @additionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Details (Optional)'**
  String get additionalDetailsOptional;

  /// No description provided for @provideMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'Provide more information...'**
  String get provideMoreInformation;

  /// No description provided for @pleaseSelectReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason'**
  String get pleaseSelectReason;

  /// No description provided for @dropReportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Drop reported successfully. Thank you for helping keep our community safe!'**
  String get dropReportedSuccessfully;

  /// No description provided for @errorReportingDrop.
  ///
  /// In en, this message translates to:
  /// **'Error reporting drop: {error}'**
  String errorReportingDrop(String error);

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @dropCollection.
  ///
  /// In en, this message translates to:
  /// **'Drop Collection'**
  String get dropCollection;

  /// No description provided for @walkStraightToDestination.
  ///
  /// In en, this message translates to:
  /// **'Walk straight to destination'**
  String get walkStraightToDestination;

  /// No description provided for @directRoute.
  ///
  /// In en, this message translates to:
  /// **'Direct route'**
  String get directRoute;

  /// No description provided for @unknownDistance.
  ///
  /// In en, this message translates to:
  /// **'Unknown distance'**
  String get unknownDistance;

  /// No description provided for @unknownDuration.
  ///
  /// In en, this message translates to:
  /// **'Unknown duration'**
  String get unknownDuration;

  /// No description provided for @routeToDrop.
  ///
  /// In en, this message translates to:
  /// **'Route to Drop'**
  String get routeToDrop;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @completeCollectionIn.
  ///
  /// In en, this message translates to:
  /// **'Complete collection in:'**
  String get completeCollectionIn;

  /// No description provided for @youHaveArrivedAtDestination.
  ///
  /// In en, this message translates to:
  /// **'You have arrived at the destination!'**
  String get youHaveArrivedAtDestination;

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculatingRoute;

  /// No description provided for @leaveCollectionMessage.
  ///
  /// In en, this message translates to:
  /// **'You have an active collection. Are you sure you want to leave? You must complete or cancel the collection to proceed.'**
  String get leaveCollectionMessage;

  /// No description provided for @slideToCollect.
  ///
  /// In en, this message translates to:
  /// **'Slide to Collect'**
  String get slideToCollect;

  /// No description provided for @releaseToCollect.
  ///
  /// In en, this message translates to:
  /// **'Release to Collect'**
  String get releaseToCollect;

  /// No description provided for @collectionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Collection confirmed!'**
  String get collectionConfirmed;

  /// No description provided for @collectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Collection cancelled: {reason}'**
  String collectionCancelled(String reason);

  /// No description provided for @errorUserNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Error: User not authenticated'**
  String get errorUserNotAuthenticated;

  /// No description provided for @errorCancellingCollection.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling collection: {error}'**
  String errorCancellingCollection(String error);

  /// No description provided for @collectionCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Collection completed successfully!'**
  String get collectionCompletedSuccessfully;

  /// No description provided for @collectionCompletedSuccessfullyNoExclamation.
  ///
  /// In en, this message translates to:
  /// **'Collection completed successfully'**
  String get collectionCompletedSuccessfullyNoExclamation;

  /// No description provided for @errorNoCollectorIdFound.
  ///
  /// In en, this message translates to:
  /// **'Error: No collector ID found'**
  String get errorNoCollectorIdFound;

  /// No description provided for @errorConfirmingCollection.
  ///
  /// In en, this message translates to:
  /// **'Error confirming collection: {error}'**
  String errorConfirmingCollection(String error);

  /// No description provided for @dropCollected.
  ///
  /// In en, this message translates to:
  /// **'Drop Collected'**
  String get dropCollected;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{points} Points Earned!'**
  String pointsEarned(int points);

  /// No description provided for @currentTier.
  ///
  /// In en, this message translates to:
  /// **'Current Tier'**
  String get currentTier;

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPoints;

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @exitNavigationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit navigation? Your collection will remain active.'**
  String get exitNavigationMessage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @collectionTimerRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Collection timer running low: {time} remaining'**
  String collectionTimerRunningLow(String time);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @collectionTimerWarning.
  ///
  /// In en, this message translates to:
  /// **'Collection Timer Warning'**
  String get collectionTimerWarning;

  /// No description provided for @yourCollectionTimerRunningLow.
  ///
  /// In en, this message translates to:
  /// **'Your collection timer is running low: {time} remaining'**
  String yourCollectionTimerRunningLow(String time);

  /// No description provided for @cancelCollectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this collection? Please select a reason:'**
  String get cancelCollectionMessage;

  /// No description provided for @noAccess.
  ///
  /// In en, this message translates to:
  /// **'No Access'**
  String get noAccess;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get notFound;

  /// No description provided for @alreadyCollected.
  ///
  /// In en, this message translates to:
  /// **'Already Collected'**
  String get alreadyCollected;

  /// No description provided for @wrongLocation.
  ///
  /// In en, this message translates to:
  /// **'Wrong Location'**
  String get wrongLocation;

  /// No description provided for @unsafeLocation.
  ///
  /// In en, this message translates to:
  /// **'Unsafe Location'**
  String get unsafeLocation;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @cancellationReasons.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reasons'**
  String get cancellationReasons;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get cancellationReason;

  /// No description provided for @accountTemporarilyLocked.
  ///
  /// In en, this message translates to:
  /// **'Account Temporarily Locked'**
  String get accountTemporarilyLocked;

  /// No description provided for @accountLockedReason.
  ///
  /// In en, this message translates to:
  /// **'Your account has been locked for 24 hours due to 5 collection timeout warnings.'**
  String get accountLockedReason;

  /// No description provided for @unlocksIn.
  ///
  /// In en, this message translates to:
  /// **'Unlocks in {time}'**
  String unlocksIn(String time);

  /// No description provided for @lockExpired.
  ///
  /// In en, this message translates to:
  /// **'Lock expired'**
  String get lockExpired;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @second.
  ///
  /// In en, this message translates to:
  /// **'second'**
  String get second;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @availableAgainAt.
  ///
  /// In en, this message translates to:
  /// **'Available again at {time}'**
  String availableAgainAt(String time);

  /// No description provided for @accountLockedInfo.
  ///
  /// In en, this message translates to:
  /// **'You can still browse drops and use other features, but cannot accept new drops until unlocked.'**
  String get accountLockedInfo;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @orderApproved.
  ///
  /// In en, this message translates to:
  /// **'Order Approved'**
  String get orderApproved;

  /// No description provided for @orderApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order {orderId} has been approved and is being processed.'**
  String orderApprovedMessage(String orderId);

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order Rejected'**
  String get orderRejected;

  /// No description provided for @orderRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order has been rejected. Reason: {reason}'**
  String orderRejectedMessage(String reason);

  /// No description provided for @orderShipped.
  ///
  /// In en, this message translates to:
  /// **'Order Shipped'**
  String get orderShipped;

  /// No description provided for @orderShippedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order has been shipped. Tracking: {tracking}'**
  String orderShippedMessage(String tracking);

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order Delivered'**
  String get orderDelivered;

  /// No description provided for @orderDeliveredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order has been delivered successfully.'**
  String get orderDeliveredMessage;

  /// No description provided for @pointsEarnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get pointsEarnedTitle;

  /// No description provided for @pointsEarnedMessage.
  ///
  /// In en, this message translates to:
  /// **'You earned {points} points!'**
  String pointsEarnedMessage(int points);

  /// No description provided for @applicationApproved.
  ///
  /// In en, this message translates to:
  /// **'Application Approved'**
  String get applicationApproved;

  /// No description provided for @applicationApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your collector application has been approved.'**
  String get applicationApprovedMessage;

  /// No description provided for @applicationReversed.
  ///
  /// In en, this message translates to:
  /// **'Application Reversed'**
  String get applicationReversed;

  /// No description provided for @applicationReversedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your collector application status has been reversed.'**
  String get applicationReversedMessage;

  /// No description provided for @dropAccepted.
  ///
  /// In en, this message translates to:
  /// **'Drop Accepted'**
  String get dropAccepted;

  /// No description provided for @dropAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'A collector has accepted your drop.'**
  String get dropAcceptedMessage;

  /// No description provided for @dropCollectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your drop has been collected successfully.'**
  String get dropCollectedMessage;

  /// No description provided for @dropCollectedWithRewards.
  ///
  /// In en, this message translates to:
  /// **'Drop Collected'**
  String get dropCollectedWithRewards;

  /// No description provided for @dropCollectedWithRewardsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your drop has been collected! You earned {points} points.'**
  String dropCollectedWithRewardsMessage(int points);

  /// No description provided for @dropCollectedWithTierUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Drop Collected'**
  String get dropCollectedWithTierUpgrade;

  /// No description provided for @dropCollectedWithTierUpgradeMessage.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your drop was collected and you\'ve been upgraded to a higher tier!'**
  String get dropCollectedWithTierUpgradeMessage;

  /// No description provided for @dropCancelled.
  ///
  /// In en, this message translates to:
  /// **'Drop Cancelled'**
  String get dropCancelled;

  /// No description provided for @dropCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Your drop has been cancelled.'**
  String get dropCancelledMessage;

  /// No description provided for @dropExpired.
  ///
  /// In en, this message translates to:
  /// **'Drop Expired'**
  String get dropExpired;

  /// No description provided for @dropExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your drop has expired and is no longer available.'**
  String get dropExpiredMessage;

  /// No description provided for @dropNearExpiring.
  ///
  /// In en, this message translates to:
  /// **'Drop Near Expiring'**
  String get dropNearExpiring;

  /// No description provided for @dropNearExpiringMessage.
  ///
  /// In en, this message translates to:
  /// **'Your drop is about to expire soon.'**
  String get dropNearExpiringMessage;

  /// No description provided for @dropCensored.
  ///
  /// In en, this message translates to:
  /// **'Drop Censored'**
  String get dropCensored;

  /// No description provided for @dropCensoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your drop has been censored due to inappropriate content.'**
  String get dropCensoredMessage;

  /// No description provided for @ticketMessage.
  ///
  /// In en, this message translates to:
  /// **'New Ticket Message'**
  String get ticketMessage;

  /// No description provided for @ticketMessageNotification.
  ///
  /// In en, this message translates to:
  /// **'You have a new message in your support ticket.'**
  String get ticketMessageNotification;

  /// No description provided for @accountUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Account Unlocked'**
  String get accountUnlocked;

  /// No description provided for @accountUnlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been unlocked. You can now start collecting drops again!'**
  String get accountUnlockedMessage;

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account Deleted'**
  String get userDeleted;

  /// No description provided for @userDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get userDeletedMessage;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @shopAgain.
  ///
  /// In en, this message translates to:
  /// **'Shop Again'**
  String get shopAgain;

  /// No description provided for @viewRewards.
  ///
  /// In en, this message translates to:
  /// **'View Rewards'**
  String get viewRewards;

  /// No description provided for @tapToViewRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Tap to view rejection reason'**
  String get tapToViewRejectionReason;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// No description provided for @advancedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Advanced Features'**
  String get advancedFeatures;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshooting;

  /// No description provided for @bestPractices.
  ///
  /// In en, this message translates to:
  /// **'Best Practices'**
  String get bestPractices;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @story.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get story;

  /// No description provided for @totalDrops.
  ///
  /// In en, this message translates to:
  /// **'Total Drops'**
  String get totalDrops;

  /// No description provided for @aluminumCans.
  ///
  /// In en, this message translates to:
  /// **'Aluminum Cans'**
  String get aluminumCans;

  /// No description provided for @recycled.
  ///
  /// In en, this message translates to:
  /// **'Recycled'**
  String get recycled;

  /// No description provided for @recycledBottles.
  ///
  /// In en, this message translates to:
  /// **'Recycled {count} bottles'**
  String recycledBottles(String count);

  /// No description provided for @recycledCans.
  ///
  /// In en, this message translates to:
  /// **'Recycled {count} cans'**
  String recycledCans(String count);

  /// No description provided for @totalItemsRecycled.
  ///
  /// In en, this message translates to:
  /// **'Total Items Recycled'**
  String get totalItemsRecycled;

  /// No description provided for @dropsCollected.
  ///
  /// In en, this message translates to:
  /// **'Drops Collected'**
  String get dropsCollected;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get december;

  /// No description provided for @todaysTotal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Total'**
  String get todaysTotal;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @noEarningsHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No earnings history yet'**
  String get noEarningsHistoryYet;

  /// No description provided for @earningsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your earnings will appear here once you complete collections'**
  String get earningsWillAppearHere;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @errorLoadingEarnings.
  ///
  /// In en, this message translates to:
  /// **'Error loading earnings: {error}'**
  String errorLoadingEarnings(String error);

  /// No description provided for @noCompletedCollectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed collections yet'**
  String get noCompletedCollectionsYet;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @collectionsOverTime.
  ///
  /// In en, this message translates to:
  /// **'Collections Over Time'**
  String get collectionsOverTime;

  /// No description provided for @expiredOverTime.
  ///
  /// In en, this message translates to:
  /// **'Expired Over Time'**
  String get expiredOverTime;

  /// No description provided for @cancelledOverTime.
  ///
  /// In en, this message translates to:
  /// **'Cancelled Over Time'**
  String get cancelledOverTime;

  /// No description provided for @totalThisWeek.
  ///
  /// In en, this message translates to:
  /// **'total this week'**
  String get totalThisWeek;

  /// No description provided for @totalThisMonth.
  ///
  /// In en, this message translates to:
  /// **'total this month'**
  String get totalThisMonth;

  /// No description provided for @totalThisYear.
  ///
  /// In en, this message translates to:
  /// **'total this year'**
  String get totalThisYear;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @daysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgoShort(int days);

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @noDropsCreatedYet.
  ///
  /// In en, this message translates to:
  /// **'No drops created yet'**
  String get noDropsCreatedYet;

  /// No description provided for @createYourFirstDropToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Create your first drop to get started'**
  String get createYourFirstDropToGetStarted;

  /// No description provided for @noActiveDrops.
  ///
  /// In en, this message translates to:
  /// **'No active drops'**
  String get noActiveDrops;

  /// No description provided for @noCollectedDrops.
  ///
  /// In en, this message translates to:
  /// **'No collected drops yet'**
  String get noCollectedDrops;

  /// No description provided for @noStaleDrops.
  ///
  /// In en, this message translates to:
  /// **'No stale drops'**
  String get noStaleDrops;

  /// No description provided for @noCensoredDrops.
  ///
  /// In en, this message translates to:
  /// **'No censored drops'**
  String get noCensoredDrops;

  /// No description provided for @noFlaggedDrops.
  ///
  /// In en, this message translates to:
  /// **'No flagged drops'**
  String get noFlaggedDrops;

  /// No description provided for @noDropsMatchYourFilters.
  ///
  /// In en, this message translates to:
  /// **'No drops match your filters'**
  String get noDropsMatchYourFilters;

  /// No description provided for @tryAdjustingYourFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingYourFilters;

  /// No description provided for @noDropsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No drops available'**
  String get noDropsAvailable;

  /// No description provided for @checkBackLaterForNewDrops.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new drops'**
  String get checkBackLaterForNewDrops;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @outside.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get outside;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @within1Km.
  ///
  /// In en, this message translates to:
  /// **'Within 1 km'**
  String get within1Km;

  /// No description provided for @within3Km.
  ///
  /// In en, this message translates to:
  /// **'Within 3 km'**
  String get within3Km;

  /// No description provided for @within5Km.
  ///
  /// In en, this message translates to:
  /// **'Within 5 km'**
  String get within5Km;

  /// No description provided for @within10Km.
  ///
  /// In en, this message translates to:
  /// **'Within 10 km'**
  String get within10Km;

  /// No description provided for @rewardHistory.
  ///
  /// In en, this message translates to:
  /// **'Reward History'**
  String get rewardHistory;

  /// No description provided for @noRewardHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No reward history yet'**
  String get noRewardHistoryYet;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @tier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get tier;

  /// No description provided for @tierUp.
  ///
  /// In en, this message translates to:
  /// **'Tier Up!'**
  String get tierUp;

  /// No description provided for @acceptDrop.
  ///
  /// In en, this message translates to:
  /// **'Accept Drop'**
  String get acceptDrop;

  /// No description provided for @completeCurrentDropFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete Current Drop First'**
  String get completeCurrentDropFirst;

  /// No description provided for @distanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Distance unavailable'**
  String get distanceUnavailable;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'away'**
  String get away;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get meters;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @earnPointsPerDrop.
  ///
  /// In en, this message translates to:
  /// **'Earn {points} points per drop'**
  String earnPointsPerDrop(int points);

  /// No description provided for @dropsRequired.
  ///
  /// In en, this message translates to:
  /// **'{count} drops required'**
  String dropsRequired(int count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @filterHistory.
  ///
  /// In en, this message translates to:
  /// **'Filter History'**
  String get filterHistory;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchHistory;

  /// No description provided for @searchByNotesBottleTypeOrCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Search by notes, bottle type, or cancellation reason...'**
  String get searchByNotesBottleTypeOrCancellationReason;

  /// No description provided for @viewType.
  ///
  /// In en, this message translates to:
  /// **'View Type'**
  String get viewType;

  /// No description provided for @itemType.
  ///
  /// In en, this message translates to:
  /// **'Item Type'**
  String get itemType;

  /// No description provided for @last3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 Months'**
  String get last3Months;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get last6Months;

  /// No description provided for @allItems.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get allItems;

  /// No description provided for @bottlesOnly.
  ///
  /// In en, this message translates to:
  /// **'Bottles Only'**
  String get bottlesOnly;

  /// No description provided for @cansOnly.
  ///
  /// In en, this message translates to:
  /// **'Cans Only'**
  String get cansOnly;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeFilters;

  /// No description provided for @waitingForCollector.
  ///
  /// In en, this message translates to:
  /// **'Waiting for collector'**
  String get waitingForCollector;

  /// No description provided for @liveCollectorOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'🟢 Live - Collector on the way'**
  String get liveCollectorOnTheWay;

  /// No description provided for @collectorWasOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Collector was on the way'**
  String get collectorWasOnTheWay;

  /// No description provided for @wasOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Was on the way'**
  String get wasOnTheWay;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @sessionTime.
  ///
  /// In en, this message translates to:
  /// **'Session Time'**
  String get sessionTime;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pleaseLoginToViewYourDrops.
  ///
  /// In en, this message translates to:
  /// **'Please login to view your drops'**
  String get pleaseLoginToViewYourDrops;

  /// No description provided for @errorLoadingUserData.
  ///
  /// In en, this message translates to:
  /// **'Error loading user data: {error}'**
  String errorLoadingUserData(String error);

  /// No description provided for @earn500Points.
  ///
  /// In en, this message translates to:
  /// **'Earn 500 Points'**
  String get earn500Points;

  /// No description provided for @forEachFriendWhoJoins.
  ///
  /// In en, this message translates to:
  /// **'For each friend who joins'**
  String get forEachFriendWhoJoins;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @referralCodeCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied to clipboard'**
  String get referralCodeCopiedToClipboard;

  /// No description provided for @shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via'**
  String get shareVia;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @sms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get sms;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @shareYourCode.
  ///
  /// In en, this message translates to:
  /// **'Share your code'**
  String get shareYourCode;

  /// No description provided for @shareYourUniqueReferralCodeWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share your unique referral code with friends'**
  String get shareYourUniqueReferralCodeWithFriends;

  /// No description provided for @friendSignsUp.
  ///
  /// In en, this message translates to:
  /// **'Friend signs up'**
  String get friendSignsUp;

  /// No description provided for @yourFriendCreatesAnAccountUsingYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your friend creates an account using your code'**
  String get yourFriendCreatesAnAccountUsingYourCode;

  /// No description provided for @earnRewards.
  ///
  /// In en, this message translates to:
  /// **'Earn rewards'**
  String get earnRewards;

  /// No description provided for @get500PointsWhenTheyCompleteFirstActivity.
  ///
  /// In en, this message translates to:
  /// **'Get 500 points when they complete first activity'**
  String get get500PointsWhenTheyCompleteFirstActivity;

  /// No description provided for @trainingCenterInfo.
  ///
  /// In en, this message translates to:
  /// **'Training Center'**
  String get trainingCenterInfo;

  /// No description provided for @trainingCenterInfoHousehold.
  ///
  /// In en, this message translates to:
  /// **'Access training content tailored for household users. Learn how to use Botleji effectively!'**
  String get trainingCenterInfoHousehold;

  /// No description provided for @trainingCenterInfoCollector.
  ///
  /// In en, this message translates to:
  /// **'Access training content for collectors. Master collection techniques and best practices!'**
  String get trainingCenterInfoCollector;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @glass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get glass;

  /// No description provided for @aluminum.
  ///
  /// In en, this message translates to:
  /// **'Aluminum'**
  String get aluminum;

  /// No description provided for @dropProgress.
  ///
  /// In en, this message translates to:
  /// **'Drop Progress'**
  String get dropProgress;

  /// No description provided for @collectionIssues.
  ///
  /// In en, this message translates to:
  /// **'Collection issues'**
  String get collectionIssues;

  /// No description provided for @cancelledTimes.
  ///
  /// In en, this message translates to:
  /// **'Cancelled {count} times'**
  String cancelledTimes(int count);

  /// No description provided for @dropAcceptedByCollector.
  ///
  /// In en, this message translates to:
  /// **'Drop accepted by collector'**
  String get dropAcceptedByCollector;

  /// No description provided for @acceptedDropForCollection.
  ///
  /// In en, this message translates to:
  /// **'Accepted drop for collection'**
  String get acceptedDropForCollection;

  /// No description provided for @applicationIssue.
  ///
  /// In en, this message translates to:
  /// **'Application Issue'**
  String get applicationIssue;

  /// No description provided for @paymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue'**
  String get paymentIssue;

  /// No description provided for @accountIssue.
  ///
  /// In en, this message translates to:
  /// **'Account Issue'**
  String get accountIssue;

  /// No description provided for @technicalIssue.
  ///
  /// In en, this message translates to:
  /// **'Technical Issue'**
  String get technicalIssue;

  /// No description provided for @generalSupportRequest.
  ///
  /// In en, this message translates to:
  /// **'General Support Request'**
  String get generalSupportRequest;

  /// No description provided for @supportRequest.
  ///
  /// In en, this message translates to:
  /// **'Support Request'**
  String get supportRequest;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get noDescriptionProvided;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @idVerification.
  ///
  /// In en, this message translates to:
  /// **'ID Verification'**
  String get idVerification;

  /// No description provided for @selfieWithId.
  ///
  /// In en, this message translates to:
  /// **'Selfie with ID'**
  String get selfieWithId;

  /// No description provided for @reviewAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewAndSubmit;

  /// No description provided for @welcomeToCollectorProgram.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Collector Program!'**
  String get welcomeToCollectorProgram;

  /// No description provided for @joinOurCommunityOfEcoConsciousCollectors.
  ///
  /// In en, this message translates to:
  /// **'Join our community of eco-conscious collectors and help make a difference in recycling.'**
  String get joinOurCommunityOfEcoConsciousCollectors;

  /// No description provided for @earnMoney.
  ///
  /// In en, this message translates to:
  /// **'Earn Money'**
  String get earnMoney;

  /// No description provided for @getPaidForEveryBottleAndCan.
  ///
  /// In en, this message translates to:
  /// **'Get paid for every bottle and can you collect'**
  String get getPaidForEveryBottleAndCan;

  /// No description provided for @flexibleHours.
  ///
  /// In en, this message translates to:
  /// **'Flexible Hours'**
  String get flexibleHours;

  /// No description provided for @collectWheneverAndWherever.
  ///
  /// In en, this message translates to:
  /// **'Collect whenever and wherever you want'**
  String get collectWheneverAndWherever;

  /// No description provided for @helpTheEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Help the Environment'**
  String get helpTheEnvironment;

  /// No description provided for @contributeToCleanerGreenerWorld.
  ///
  /// In en, this message translates to:
  /// **'Contribute to a cleaner, greener world'**
  String get contributeToCleanerGreenerWorld;

  /// No description provided for @requirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirements;

  /// No description provided for @mustBe18YearsOrOlder.
  ///
  /// In en, this message translates to:
  /// **'• Must be 18 years or older'**
  String get mustBe18YearsOrOlder;

  /// No description provided for @validNationalIdCard.
  ///
  /// In en, this message translates to:
  /// **'• Valid National ID Card'**
  String get validNationalIdCard;

  /// No description provided for @clearPhotosOfIdAndSelfie.
  ///
  /// In en, this message translates to:
  /// **'• Clear photos of ID and selfie'**
  String get clearPhotosOfIdAndSelfie;

  /// No description provided for @goodStandingInCommunity.
  ///
  /// In en, this message translates to:
  /// **'• Good standing in the community'**
  String get goodStandingInCommunity;

  /// No description provided for @idCardVerification.
  ///
  /// In en, this message translates to:
  /// **'ID Card Verification'**
  String get idCardVerification;

  /// No description provided for @pleaseProvideYourIdCardInformation.
  ///
  /// In en, this message translates to:
  /// **'Please provide your {idType} information and take clear photos'**
  String pleaseProvideYourIdCardInformation(String idType);

  /// No description provided for @idCardDetails.
  ///
  /// In en, this message translates to:
  /// **'ID Card Details'**
  String get idCardDetails;

  /// No description provided for @passportDetails.
  ///
  /// In en, this message translates to:
  /// **'Passport Details'**
  String get passportDetails;

  /// No description provided for @idCardType.
  ///
  /// In en, this message translates to:
  /// **'ID Card Type'**
  String get idCardType;

  /// No description provided for @selectYourIdCardType.
  ///
  /// In en, this message translates to:
  /// **'Select your ID card type'**
  String get selectYourIdCardType;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @pleaseSelectAnIdCardType.
  ///
  /// In en, this message translates to:
  /// **'Please select an ID card type'**
  String get pleaseSelectAnIdCardType;

  /// No description provided for @passportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport Number'**
  String get passportNumber;

  /// No description provided for @enterYourPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your passport number'**
  String get enterYourPassportNumber;

  /// No description provided for @selectIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Select Issue Date'**
  String get selectIssueDate;

  /// No description provided for @issueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDateLabel;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date: {date}'**
  String issueDate(String date);

  /// No description provided for @selectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select Expiry Date'**
  String get selectExpiryDate;

  /// No description provided for @expiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDateLabel;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date: {date}'**
  String expiryDate(String date);

  /// No description provided for @issuingAuthority.
  ///
  /// In en, this message translates to:
  /// **'Issuing Authority'**
  String get issuingAuthority;

  /// No description provided for @egMinistryOfForeignAffairs.
  ///
  /// In en, this message translates to:
  /// **'e.g., Ministry of Foreign Affairs'**
  String get egMinistryOfForeignAffairs;

  /// No description provided for @idCardNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Card Number'**
  String get idCardNumber;

  /// No description provided for @idCardNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'12345678'**
  String get idCardNumberPlaceholder;

  /// No description provided for @idCardNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'ID card number is required'**
  String get idCardNumberIsRequired;

  /// No description provided for @idCardNumberMustBe8Digits.
  ///
  /// In en, this message translates to:
  /// **'ID card number must be 8 digits'**
  String get idCardNumberMustBe8Digits;

  /// No description provided for @idCardNumberMustContainOnlyDigits.
  ///
  /// In en, this message translates to:
  /// **'ID card number must contain only digits'**
  String get idCardNumberMustContainOnlyDigits;

  /// No description provided for @idCardPhotos.
  ///
  /// In en, this message translates to:
  /// **'ID Card Photos'**
  String get idCardPhotos;

  /// No description provided for @passportPhotos.
  ///
  /// In en, this message translates to:
  /// **'Passport Photos'**
  String get passportPhotos;

  /// No description provided for @noPassportMainPagePhoto.
  ///
  /// In en, this message translates to:
  /// **'No Passport Main Page Photo'**
  String get noPassportMainPagePhoto;

  /// No description provided for @takePhotoOfMainPageWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Take photo of the main page with your details'**
  String get takePhotoOfMainPageWithDetails;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @takePassportMainPagePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Passport Main Page Photo'**
  String get takePassportMainPagePhoto;

  /// No description provided for @noIdCardFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'No ID Card Front Photo'**
  String get noIdCardFrontPhoto;

  /// No description provided for @takePhotoOfFrontOfIdCard.
  ///
  /// In en, this message translates to:
  /// **'Take photo of the front of your ID card'**
  String get takePhotoOfFrontOfIdCard;

  /// No description provided for @retakeFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Front Photo'**
  String get retakeFrontPhoto;

  /// No description provided for @takeIdCardFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take ID Card Front Photo'**
  String get takeIdCardFrontPhoto;

  /// No description provided for @noIdCardBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'No ID Card Back Photo'**
  String get noIdCardBackPhoto;

  /// No description provided for @takePhotoOfBackOfIdCard.
  ///
  /// In en, this message translates to:
  /// **'Take photo of the back of your ID card'**
  String get takePhotoOfBackOfIdCard;

  /// No description provided for @retakeBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Back Photo'**
  String get retakeBackPhoto;

  /// No description provided for @takeIdCardBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take ID Card Back Photo'**
  String get takeIdCardBackPhoto;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @selfieWithIdCard.
  ///
  /// In en, this message translates to:
  /// **'Selfie with ID Card'**
  String get selfieWithIdCard;

  /// No description provided for @pleaseTakeSelfieWhileHoldingId.
  ///
  /// In en, this message translates to:
  /// **'Please take a selfie while holding your ID card next to your face'**
  String get pleaseTakeSelfieWhileHoldingId;

  /// No description provided for @noSelfiePhoto.
  ///
  /// In en, this message translates to:
  /// **'No Selfie Photo'**
  String get noSelfiePhoto;

  /// No description provided for @takeSelfie.
  ///
  /// In en, this message translates to:
  /// **'Take Selfie'**
  String get takeSelfie;

  /// No description provided for @reviewAndSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewAndSubmitTitle;

  /// No description provided for @pleaseReviewYourApplication.
  ///
  /// In en, this message translates to:
  /// **'Please review your application before submitting'**
  String get pleaseReviewYourApplication;

  /// No description provided for @idCardInformation.
  ///
  /// In en, this message translates to:
  /// **'ID Card Information'**
  String get idCardInformation;

  /// No description provided for @idType.
  ///
  /// In en, this message translates to:
  /// **'ID Type'**
  String get idType;

  /// No description provided for @idNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get idNumber;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @idCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get idCard;

  /// No description provided for @selfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie'**
  String get selfie;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get whatHappensNext;

  /// No description provided for @applicationReviewProcess.
  ///
  /// In en, this message translates to:
  /// **'• Your application will be reviewed by our team\n• Review typically takes 1-3 business days\n• You\'ll receive a notification once reviewed\n• If approved, you can start collecting immediately'**
  String get applicationReviewProcess;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @pleaseTakeBothPhotosBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Please take both photos before submitting'**
  String get pleaseTakeBothPhotosBeforeSubmitting;

  /// No description provided for @pleaseFillInAllRequiredPassportInformation.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required passport information'**
  String get pleaseFillInAllRequiredPassportInformation;

  /// No description provided for @pleaseFillInAllRequiredIdCardInformation.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required ID card information (ID number and type)'**
  String get pleaseFillInAllRequiredIdCardInformation;

  /// No description provided for @applicationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Application updated successfully!'**
  String get applicationUpdatedSuccessfully;

  /// No description provided for @applicationSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Application submitted successfully!'**
  String get applicationSubmittedSuccessfully;

  /// No description provided for @errorSubmittingApplication.
  ///
  /// In en, this message translates to:
  /// **'Error submitting application: {error}'**
  String errorSubmittingApplication(String error);

  /// No description provided for @errorLoadingApplication.
  ///
  /// In en, this message translates to:
  /// **'Error loading application'**
  String get errorLoadingApplication;

  /// No description provided for @noApplicationFound.
  ///
  /// In en, this message translates to:
  /// **'No Application Found'**
  String get noApplicationFound;

  /// No description provided for @youHaventSubmittedApplicationYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t submitted a collector application yet.'**
  String get youHaventSubmittedApplicationYet;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @yourApplicationIsBeingReviewed.
  ///
  /// In en, this message translates to:
  /// **'Your application is being reviewed by our team.'**
  String get yourApplicationIsBeingReviewed;

  /// No description provided for @congratulationsApplicationApproved.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your application has been approved.'**
  String get congratulationsApplicationApproved;

  /// No description provided for @applicationNotApprovedCanApplyAgain.
  ///
  /// In en, this message translates to:
  /// **'Your application was not approved. You can apply again.'**
  String get applicationNotApprovedCanApplyAgain;

  /// No description provided for @applicationStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Application status is unknown.'**
  String get applicationStatusUnknown;

  /// No description provided for @applicationDetails.
  ///
  /// In en, this message translates to:
  /// **'Application Details'**
  String get applicationDetails;

  /// No description provided for @applicationId.
  ///
  /// In en, this message translates to:
  /// **'Application ID'**
  String get applicationId;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @appliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied On'**
  String get appliedOn;

  /// No description provided for @reviewedOn.
  ///
  /// In en, this message translates to:
  /// **'Reviewed On'**
  String get reviewedOn;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @reviewNotes.
  ///
  /// In en, this message translates to:
  /// **'Review Notes'**
  String get reviewNotes;

  /// No description provided for @applyAgain.
  ///
  /// In en, this message translates to:
  /// **'Apply Again'**
  String get applyAgain;

  /// No description provided for @applicationInReview.
  ///
  /// In en, this message translates to:
  /// **'Application in Review'**
  String get applicationInReview;

  /// No description provided for @applicationInReviewDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Your application is currently being reviewed by our team. This process typically takes 1-3 business days. You will be notified once a decision has been made.'**
  String get applicationInReviewDialogContent;

  /// No description provided for @reviewProcess.
  ///
  /// In en, this message translates to:
  /// **'Review Process'**
  String get reviewProcess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
