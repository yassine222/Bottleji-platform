// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Bottleji';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get changeLanguage => 'تغيير لغة التطبيق';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get french => 'الفرنسية';

  @override
  String get german => 'الألمانية';

  @override
  String get arabic => 'العربية';

  @override
  String get location => 'الموقع';

  @override
  String get manageLocationPreferences => 'إدارة تفضيلات الموقع';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get manageNotificationPreferences => 'إدارة تفضيلات الإشعارات';

  @override
  String get displayTheme => 'مظهر العرض';

  @override
  String get changeAppAppearance => 'تغيير مظهر التطبيق';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get ok => 'موافق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'التسجيل';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get signInToContinue => 'قم بتسجيل الدخول للمتابعة';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get enterYourEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get pleaseEnterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordMinLength => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get invalidEmailOrPassword =>
      'بريد إلكتروني أو كلمة مرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get loginFailed =>
      'فشل تسجيل الدخول. يرجى التحقق من بيانات الاعتماد والمحاولة مرة أخرى.';

  @override
  String get connectionTimeout =>
      'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';

  @override
  String get networkError => 'خطأ في الشبكة. يرجى التحقق من اتصال الإنترنت.';

  @override
  String get requestTimeout => 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String get serverError => 'خطأ في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get accountDeletedMessage =>
      'تم حذف حسابك من قبل أحد المسؤولين.\n\nإذا كنت تعتقد أن هذا خطأ، يرجى الاتصال بفريق الدعم:\n\n📧 البريد الإلكتروني: support@bottleji.com\n📱 ساعات الدعم: 9 صباحاً - 6 مساءً (GMT+1)\n\nنعتذر عن الإزعاج.';

  @override
  String get reason => 'السبب';

  @override
  String get youWillBeRedirectedToLoginScreen =>
      'سيتم إعادة توجيهك إلى شاشة تسجيل الدخول.';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get enterEmailToReceiveResetCode =>
      'أدخل بريدك الإلكتروني لتلقي رمز إعادة التعيين';

  @override
  String get sendResetCode => 'إرسال رمز إعادة التعيين';

  @override
  String get resetCodeSentToEmail =>
      'تم إرسال رمز إعادة التعيين إلى بريدك الإلكتروني';

  @override
  String get enterResetCode => 'أدخل رمز إعادة التعيين';

  @override
  String weHaveSentResetCodeTo(String email) {
    return 'لقد أرسلنا رمز إعادة التعيين إلى\n$email';
  }

  @override
  String get verify => 'تحقق';

  @override
  String get didntReceiveCode => 'لم تستلم الرمز؟';

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال خلال $seconds ثانية';
  }

  @override
  String get resetCodeResentSuccessfully =>
      'تم إعادة إرسال رمز إعادة التعيين بنجاح!';

  @override
  String get createNewPassword => 'إنشاء كلمة مرور جديدة';

  @override
  String get pleaseEnterNewPassword => 'يرجى إدخال كلمة المرور الجديدة';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmNewPassword => 'أكد كلمة المرور الجديدة';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get pleaseConfirmPassword => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordResetSuccessful =>
      'تم إعادة تعيين كلمة المرور بنجاح! يرجى تسجيل الدخول بكلمة المرور الجديدة.';

  @override
  String get verifyYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get pleaseEnterOtpSentToEmail =>
      'يرجى إدخال رمز OTP المرسل إلى بريدك الإلكتروني';

  @override
  String get verifyOtp => 'تحقق من OTP';

  @override
  String get resendOtp => 'إعادة إرسال OTP';

  @override
  String resendOtpIn(int seconds) {
    return 'إعادة إرسال OTP خلال $seconds ثانية';
  }

  @override
  String get otpVerifiedSuccessfully => 'تم التحقق من OTP بنجاح';

  @override
  String get invalidVerificationResponse => 'خطأ: استجابة التحقق غير صالحة';

  @override
  String get otpResentSuccessfully => 'تم إعادة إرسال OTP بنجاح!';

  @override
  String get startYourBottlejiJourney => 'ابدأ رحلتك مع Bottleji';

  @override
  String get createAccountToGetStarted => 'أنشئ حسابًا للبدء';

  @override
  String get createAPassword => 'إنشاء كلمة مرور';

  @override
  String get confirmYourPassword => 'أكد كلمة المرور';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get registrationSuccessful => 'تم التسجيل بنجاح';

  @override
  String get skip => 'تخطي';

  @override
  String get next => 'التالي';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get welcomeToBottleji => 'مرحبًا بك في Bottleji';

  @override
  String get yourSustainableWasteManagementSolution =>
      'حل إدارة النفايات المستدام الخاص بك';

  @override
  String get joinThousandsOfUsersMakingDifference =>
      'انضم إلى آلاف المستخدمين الذين يحدثون فرقًا من خلال إعادة تدوير الزجاجات والعلب مع كسب المكافآت.';

  @override
  String get createAndTrackDrops => 'إنشاء وتتبع النقاط';

  @override
  String get forHouseholdUsers => 'للمستخدمين المنزليين';

  @override
  String get easilyCreateDropRequests =>
      'أنشئ بسهولة طلبات النقاط للزجاجات والعلب القابلة لإعادة التدوير. تتبع حالة التجميع واحصل على إشعارات عند قيام الجامعين بجمعها.';

  @override
  String get collectAndEarn => 'اجمع واكسب';

  @override
  String get forCollectors => 'للجامعين';

  @override
  String get findNearbyDropsCollectRecyclables =>
      'ابحث عن النقاط القريبة، اجمع المواد القابلة لإعادة التدوير، واكسب المكافآت. ساعد في بناء مجتمع مستدام مع كسب المال.';

  @override
  String get realTimeUpdates => 'التحديثات في الوقت الفعلي';

  @override
  String get stayConnected => 'ابق متصلاً';

  @override
  String get getInstantNotificationsAboutDrops =>
      'احصل على إشعارات فورية حول نقاطك وجمعك والتحديثات المهمة. لا تفوت فرصة أبدًا.';

  @override
  String get appPermissions => 'أذونات التطبيق';

  @override
  String get bottlejiRequiresAdditionalPermissions =>
      'يتطلب Bottleji أذونات إضافية للعمل بشكل صحيح';

  @override
  String get permissionsHelpProvideBestExperience =>
      'تساعدنا هذه الأذونات في توفير أفضل تجربة لك.';

  @override
  String get locationServices => 'خدمات الموقع';

  @override
  String get accessLocationToShowNearbyDrops =>
      'الوصول إلى موقعك لإظهار النقاط القريبة وتمكين التنقل للجامعين.';

  @override
  String get localNetworkAccess => 'الوصول إلى الشبكة المحلية';

  @override
  String get allowAppToDiscoverServicesOnWifi =>
      'السماح للتطبيق باكتشاف الخدمات على شبكة Wi‑Fi الخاصة بك للميزات في الوقت الفعلي.';

  @override
  String get receiveRealTimeUpdatesAboutDrops =>
      'احصل على تحديثات فورية حول نقاطك وجمعك والإعلانات المهمة.';

  @override
  String get photoStorage => 'تخزين الصور';

  @override
  String get saveAndAccessPhotosOfRecyclableItems =>
      'حفظ الصور والوصول إلى صور العناصر القابلة لإعادة التدوير.';

  @override
  String get enable => 'تفعيل';

  @override
  String get continueToApp => 'المتابعة إلى التطبيق';

  @override
  String get enableRequiredPermissions => 'تفعيل الأذونات المطلوبة';

  @override
  String get accountDisabled => 'تم تعطيل الحساب';

  @override
  String get accountDisabledMessage =>
      'تم تعطيل حسابك بشكل دائم بسبب انتهاكات متكررة لإرشادات مجتمع Bottleji.\n\nلم يعد بإمكانك الوصول إلى هذا الحساب أو استخدامه.\n\nإذا كنت تعتقد أن هذا القرار تم اتخاذه عن طريق الخطأ، يرجى الاتصال بالدعم:';

  @override
  String get supportEmail => 'support@bottleji.com';

  @override
  String get contactSupport => 'اتصل بالدعم';

  @override
  String get pleaseEmailSupport =>
      'يرجى إرسال بريد إلكتروني إلى support@bottleji.com للحصول على المساعدة';

  @override
  String get sessionExpired => 'انتهت الجلسة';

  @override
  String get sessionExpiredMessage =>
      'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى للمتابعة.';

  @override
  String get home => 'الرئيسية';

  @override
  String get drops => 'النقاط';

  @override
  String get rewards => 'المكافآت';

  @override
  String get stats => 'الإحصائيات';

  @override
  String get history => 'السجل';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get account => 'الحساب';

  @override
  String get support => 'الدعم';

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get areYouSureLogout => 'هل أنت متأكد من أنك تريد تسجيل الخروج؟';

  @override
  String errorDuringLogout(String error) {
    return 'حدث خطأ أثناء تسجيل الخروج: $error';
  }

  @override
  String get close => 'إغلاق';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get confirm => 'تأكيد';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get stay => 'البقاء';

  @override
  String get leave => 'مغادرة';

  @override
  String get back => 'رجوع';

  @override
  String get previous => 'السابق';

  @override
  String get done => 'تم';

  @override
  String get gotIt => 'فهمت';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get clearFilters => 'مسح المرشحات';

  @override
  String get apply => 'تطبيق';

  @override
  String get filterDrops => 'تصفية القطرات';

  @override
  String get status => 'الحالة';

  @override
  String get all => 'الكل';

  @override
  String get date => 'التاريخ';

  @override
  String get distance => 'المسافة';

  @override
  String get deleteDrop => 'حذف النقطة';

  @override
  String get areYouSureDelete => 'هل أنت متأكد من أنك تريد حذف هذه النقطة؟';

  @override
  String get createDrop => 'إنشاء نقطة';

  @override
  String get editDrop => 'تعديل النقطة';

  @override
  String get startCollection => 'بدء الجمع';

  @override
  String get resumeNavigation => 'استئناف التنقل';

  @override
  String get cancelCollection => 'إلغاء الجمع';

  @override
  String get areYouSureCancelCollection =>
      'هل أنت متأكد من أنك تريد إلغاء هذا الجمع؟';

  @override
  String get yesCancel => 'نعم، إلغاء';

  @override
  String get leaveCollection => 'مغادرة الجمع؟';

  @override
  String get areYouSureLeaveCollection =>
      'هل أنت متأكد من أنك تريد المغادرة؟ سيبقى جمعك نشطاً.';

  @override
  String get exitNavigation => 'مغادرة التنقل';

  @override
  String get areYouSureExitNavigation =>
      'هل أنت متأكد من أنك تريد الخروج من التنقل؟ سيبقى جمعك نشطاً.';

  @override
  String get reportDrop => 'الإبلاغ عن النقطة';

  @override
  String get useCurrentLocation => 'استخدام الموقع الحالي';

  @override
  String get setCollectionRadius => 'تعيين نصف قطر الجمع';

  @override
  String get setCollectionRadiusDescription =>
      'قم بتعيين نصف القطر (بالكيلومترات) الذي تريد جمع الزجاجات ضمنه.';

  @override
  String get kilometers => 'كم';

  @override
  String get collectionRadiusUpdated => 'تم تحديث نصف قطر الجمع!';

  @override
  String get saveRadius => 'حفظ نصف القطر';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختر من المعرض';

  @override
  String get galleryIOSSimulatorIssue => 'المعرض (مشكلة محاكي iOS)';

  @override
  String get useCameraOrRealDevice => 'استخدم الكاميرا أو جهاز حقيقي';

  @override
  String get leaveOutsideDoor => 'اتركه خارج الباب';

  @override
  String get pleaseTakePhoto => 'يرجى التقاط صورة للزجاجات';

  @override
  String get pleaseWaitLoading => 'يرجى الانتظار أثناء تحميل معلومات حسابك';

  @override
  String get mustBeLoggedIn => 'يجب أن تكون مسجلاً الدخول لإنشاء نقطة';

  @override
  String get authenticationIssue =>
      'تم اكتشاف مشكلة في المصادقة. يرجى تسجيل الخروج وتسجيل الدخول مرة أخرى.';

  @override
  String get dropCreatedSuccessfully => 'تم إنشاء النقطة بنجاح!';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get reloadMap => 'إعادة تحميل الخريطة';

  @override
  String get thisHelpsUsShowNearby =>
      'يساعدنا هذا في عرض النقاط القريبة وتوفير خدمات جمع دقيقة.';

  @override
  String errorLoadingUserMode(String error) {
    return 'خطأ في تحميل وضع المستخدم: $error';
  }

  @override
  String get tryAdjustingFilters => 'حاول تعديل المرشحات';

  @override
  String get checkBackLater => 'ارجع لاحقاً للحصول على نقاط جديدة';

  @override
  String get createFirstDrop => 'أنشئ نقطتك الأولى للبدء';

  @override
  String get collectionInProgress => 'الجمع قيد التنفيذ';

  @override
  String get resumeCollection => 'استئناف الجمع';

  @override
  String get collectionTimeout => '⚠️ انتهت مهلة الجمع';

  @override
  String get warningSystem => 'نظام التحذير';

  @override
  String get warningAddedToAccount =>
      'تمت إضافة تحذير إلى حسابك لهذه النقطة. يرجى التأكد من أن الصور المستقبلية تتبع إرشادات المجتمع.';

  @override
  String get timerExpired => '⏰ انتهى المؤقت!';

  @override
  String get timerExpiredMessage =>
      'انتهى مؤقت الجمع. سيتم إغلاق شاشة التنقل الآن.';

  @override
  String get applicationRejected => 'تم رفض الطلب';

  @override
  String applicationRejectedMessage(String reason) {
    return 'تم رفض طلب المجمع الخاص بك. السبب: $reason';
  }

  @override
  String get noSpecificReason => 'لم يتم تقديم سبب محدد';

  @override
  String get canEditApplication => 'يمكنك تعديل طلبك وإرساله مرة أخرى.';

  @override
  String get editApplication => 'تعديل الطلب';

  @override
  String get pleaseLogInCollector => 'يرجى تسجيل الدخول للوصول إلى وضع المجمع';

  @override
  String get tierSystem => 'نظام المستويات';

  @override
  String get bySubscribingAgree =>
      'من خلال الاشتراك، أنت توافق على شروط الخدمة\nوسياسة الخصوصية الخاصة بنا';

  @override
  String get startProSubscription => 'بدء اشتراك PRO';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get lastUpdated => 'آخر تحديث: 15 مارس 2024';

  @override
  String get acceptanceOfTerms => '1. قبول الشروط';

  @override
  String get acceptanceOfTermsContent =>
      'من خلال الوصول إلى تطبيق Bottleji واستخدامه، أنت توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي جزء من هذه الشروط، قد لا تتمكن من الوصول إلى التطبيق.';

  @override
  String get userResponsibilities => '2. مسؤوليات المستخدم';

  @override
  String get userResponsibilitiesContent =>
      'كمستخدم لتطبيق Bottleji، أنت توافق على:\n• تقديم معلومات دقيقة وكاملة\n• الحفاظ على أمان حسابك\n• اتباع إرشادات فصل النفايات\n• جدولة عمليات الجمع بمسؤولية\n• استخدام الخدمة وفقاً للقوانين المحلية';

  @override
  String get household => 'المنزل';

  @override
  String get collector => 'جامع';

  @override
  String get activeMode => 'الوضع النشط';

  @override
  String get myAccount => 'حسابي';

  @override
  String get trainings => 'التدريبات';

  @override
  String get referAndEarn => 'أحال واكسب';

  @override
  String get upgrade => 'ترقية';

  @override
  String get review => 'قيد المراجعة';

  @override
  String get rejected => 'مرفوض';

  @override
  String get becomeACollector => 'كن جامعًا';

  @override
  String get applicationUnderReview =>
      'طلبك قيد المراجعة حالياً. هل تريد عرض حالة طلبك؟';

  @override
  String get viewStatus => 'عرض الحالة';

  @override
  String applicationRejectedReason(String rejectionReason) {
    return 'تم رفض طلبك للأسباب التالية:\n\n\"$rejectionReason\"\n\nهل تريد تعديل طلبك وإرساله مرة أخرى؟';
  }

  @override
  String get applicationApprovedSuspended =>
      'تمت الموافقة على طلبك ولكن تم تعليق وصول المجمع مؤقتاً. يرجى الاتصال بالدعم أو إعادة التقديم.';

  @override
  String get reapply => 'إعادة التقديم';

  @override
  String get needToApplyCollector =>
      'تحتاج إلى التقديم والحصول على الموافقة للوصول إلى وضع المجمع. هل تريد التقديم الآن؟';

  @override
  String get applyNow => 'قدّم مطلب';

  @override
  String get householdMode => 'وضع المنزل';

  @override
  String get collectorMode => 'وضع المجمع';

  @override
  String get householdModeDescription => 'إنشاء النقاط وتتبع إعادة التدوير';

  @override
  String get collectorModeDescription => 'جمع الزجاجات وكسب المكافآت';

  @override
  String get sustainableWasteManagement => 'إدارة النفايات المستدامة';

  @override
  String get ecoFriendlyBottleCollection => 'جمع الزجاجات الصديق للبيئة';

  @override
  String get bottleType => 'نوع الزجاجة';

  @override
  String get numberOfPlasticBottles => 'عدد زجاجات البلاستيك';

  @override
  String get numberOfCans => 'عدد العلب';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get notes => 'ملاحظات';

  @override
  String get failedToCreateDrop => 'فشل إنشاء النقطة. يرجى المحاولة مرة أخرى.';

  @override
  String get imageSelectedSuccessfully => 'تم اختيار الصورة بنجاح!';

  @override
  String get errorSelectingImage => 'خطأ في اختيار الصورة';

  @override
  String get permissionDeniedPhoto =>
      'تم رفض الإذن. يرجى السماح بالوصول إلى الصور في الإعدادات.';

  @override
  String get galleryNotAvailableSimulator =>
      'المعرض غير متاح على المحاكي. جرب الكاميرا أو استخدم جهازاً حقيقياً.';

  @override
  String get profileInformation => 'معلومات الملف الشخصي';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get notSet => 'غير محدد';

  @override
  String get phone => 'الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get collectorStatus => 'حالة المجمع';

  @override
  String get approvedCollector => 'أنت مجمع معتمد';

  @override
  String get applicationStatus => 'حالة الطلب';

  @override
  String get applicationUnderReviewStatus => 'طلبك قيد المراجعة';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get applicationRejectedTitle => 'تم رفض الطلب';

  @override
  String get pleaseLoginToViewProfile => 'يرجى تسجيل الدخول لعرض ملفك الشخصي';

  @override
  String get bottlejiRequiresPermissions =>
      'يتطلب Bottleji أذونات إضافية للعمل بشكل صحيح';

  @override
  String galleryError(String error) {
    return 'خطأ في المعرض: $error';
  }

  @override
  String galleryNotAvailableIOS(String error) {
    return 'المعرض غير متاح على محاكي iOS: $error';
  }

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get completeYourProfile => 'أكمل ملفك الشخصي';

  @override
  String get profilePhoto => 'صورة الملف الشخصي';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get tapToChangePhoto => 'انقر لتغيير الصورة';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get completeSetup => 'إكمال الإعداد';

  @override
  String get saveProfile => 'حفظ الملف الشخصي';

  @override
  String get phoneNumberRequired => 'رقم الهاتف مطلوب';

  @override
  String get phoneNumberMustBe8Digits => 'يجب أن يكون رقم الهاتف 8 أرقام';

  @override
  String get phoneNumberMustContainOnlyDigits =>
      'يجب أن يحتوي رقم الهاتف على أرقام فقط';

  @override
  String get pleaseEnterYourFullName => 'يرجى إدخال اسمك الكامل';

  @override
  String get pleaseEnterYourPhoneNumber => 'يرجى إدخال رقم هاتفك';

  @override
  String get pleaseEnterYourAddress => 'يرجى إدخال عنوانك';

  @override
  String get pleaseVerifyYourPhoneNumber =>
      'يرجى التحقق من رقم هاتفك قبل الحفظ';

  @override
  String get noChangesDetected =>
      'لم يتم اكتشاف أي تغييرات. يبقى الملف الشخصي دون تغيير.';

  @override
  String get profileSetupCompletedSuccessfully =>
      'اكتمل إعداد الملف الشخصي بنجاح! مرحباً بك في Bottleji!';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String failedToUploadImage(String error) {
    return 'فشل تحميل الصورة: $error';
  }

  @override
  String get smsCode => 'رمز SMS';

  @override
  String get enter6DigitCode => 'أدخل الرمز المكون من 6 أرقام';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get sending => 'جاري الإرسال...';

  @override
  String get verifyCode => 'التحقق من الرمز';

  @override
  String get verifying => 'جاري التحقق...';

  @override
  String get phoneNumberVerified => 'تم التحقق من رقم الهاتف';

  @override
  String get phoneNumberNotVerified => 'لم يتم التحقق من رقم الهاتف';

  @override
  String get phoneNumberNeedsVerification => 'رقم الهاتف يحتاج إلى التحقق';

  @override
  String get phoneNumberVerifiedSuccessfully =>
      'تم التحقق من رقم الهاتف بنجاح!';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get fullNameRequired => 'الاسم الكامل مطلوب';

  @override
  String get addressRequired => 'العنوان مطلوب';

  @override
  String get searchAddress => 'البحث عن العنوان';

  @override
  String get tapToSearchAddress => 'اضغط للبحث عن عنوانك';

  @override
  String get typeToSearch => 'اكتب للبحث...';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String errorFetchingSuggestions(String error) {
    return 'خطأ في جلب الاقتراحات: $error';
  }

  @override
  String get pleaseEnterPhoneNumberFirst => 'يرجى إدخال رقم الهاتف أولاً';

  @override
  String get pleaseEnterValidPhoneNumber =>
      'يرجى إدخال رقم هاتف صحيح مع رمز البلد (مثل +49 123456789)';

  @override
  String get locationPermissionRequired => 'إذن الموقع مطلوب لميزات العنوان';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات حتى الآن';

  @override
  String get failedToLoadNotifications => 'فشل تحميل الإشعارات';

  @override
  String get createNewDrop => 'إنشاء نقطة جديدة';

  @override
  String get photo => 'الصورة';

  @override
  String get takePhotoOrChooseFromGallery =>
      'التقاط صورة أو اختيار من المعرض - أظهر زجاجاتك بوضوح لمساعدة المجمعين';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get cameraOrGallery => 'الكاميرا أو المعرض';

  @override
  String get allDrops => 'جميع النقاط';

  @override
  String get myDrops => 'إسقاطاتي';

  @override
  String get active => 'نشط';

  @override
  String get collected => 'تم الجمع';

  @override
  String get flagged => 'مُعلّم';

  @override
  String get censored => 'مُحذف';

  @override
  String get stale => 'منتهي الصلاحية';

  @override
  String get dropsInThisFilterCollected =>
      'تم جمع النقاط في هذا المرشح بنجاح من قبل مجمع. تُظهر هذه النقاط تأثير إعادة التدوير الخاص بك ولا يمكن تعديلها.';

  @override
  String get dropsInThisFilterFlagged =>
      'تم تعليم النقاط في هذا المرشح بسبب إلغاءات متعددة أو نشاط مشبوه. النقاط المُعلّمة مخفية عن الخريطة ولا يمكن تعديلها.';

  @override
  String get dropsInThisFilterCensored =>
      'تم حذف النقاط في هذا المرشح بسبب محتوى غير مناسب. النقاط المحذوفة مخفية عن الخريطة ولا يمكن تعديلها.';

  @override
  String get dropsInThisFilterStale =>
      'تم تعليم النقاط في هذا المرشح على أنها منتهية الصلاحية لأنها كانت أقدم من 3 أيام وتم جمعها على الأرجح من قبل مجمعين خارجيين. النقاط المنتهية الصلاحية مخفية عن الخريطة ولا يمكن تعديلها.';

  @override
  String get inActiveCollection => 'في جمع نشط - المجمع في الطريق';

  @override
  String censoredInappropriateImage(String reason) {
    return 'محذوف: $reason';
  }

  @override
  String get onTheWay => 'في الطريق';

  @override
  String get collectorOnHisWay => 'المجمع في طريقه لالتقاط إسقاطك';

  @override
  String get waiting => 'في الانتظار...';

  @override
  String get notYetCollected => 'لم يتم الجمع بعد';

  @override
  String get yourPoints => 'نقاطك';

  @override
  String pointsToGo(int points) {
    return '$points نقاط متبقية';
  }

  @override
  String get progressToNextTier => 'التقدم إلى المستوى التالي';

  @override
  String get bronzeCollector => 'مجمع برونزي';

  @override
  String get silverCollector => 'مجمع فضي';

  @override
  String get goldCollector => 'مجمع ذهبي';

  @override
  String get platinumCollector => 'مجمع بلاتيني';

  @override
  String get diamondCollector => 'مجمع ماسي';

  @override
  String earnPointsPerDropCollected(int points) {
    return 'اكسب $points نقاط لكل نقطة مجمعة';
  }

  @override
  String earnPointsWhenDropsCollected(int points) {
    return 'اكسب $points نقاط عندما يتم جمع نقاطك';
  }

  @override
  String get rewardShop => 'متجر المكافآت';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get noOrdersYet => 'لا توجد طلبات حتى الآن';

  @override
  String get yourOrderHistoryWillAppearHere => 'سيظهر سجل طلباتك هنا';

  @override
  String get notEnoughPoints => 'نقاط غير كافية';

  @override
  String get pts => 'نقطة';

  @override
  String get myStats => 'إحصائياتي';

  @override
  String get timeRange => 'النطاق الزمني';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get thisYear => 'هذا العام';

  @override
  String get allTime => 'كل الوقت';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get dropStatus => 'حالة النقاط';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get collectionRate => 'معدل الجمع';

  @override
  String get avgCollectionTime => 'متوسط وقت الجمع';

  @override
  String get recentCollections => 'عمليات الجمع الأخيرة';

  @override
  String get supportAndHelp => 'الدعم والمساعدة';

  @override
  String get howCanWeHelpYou => 'كيف يمكننا مساعدتك؟';

  @override
  String get selectCategoryToGetStarted => 'اختر فئة للبدء';

  @override
  String get supportCategories => 'فئات الدعم';

  @override
  String get whatDoYouNeedHelpWith => 'بماذا تحتاج المساعدة؟';

  @override
  String get selectCategoryToContinue => 'اختر فئة للمتابعة';

  @override
  String get trainingCenter => 'مركز التدريب';

  @override
  String todayAt(String time) {
    return 'اليوم في $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'أمس في $time';
  }

  @override
  String daysAgo(int days) {
    return 'منذ $days يوم';
  }

  @override
  String get leaveOutside => 'اتركه في الخارج';

  @override
  String get noImageAvailable => 'لا توجد صورة متاحة';

  @override
  String get estTime => 'الوقت المقدر';

  @override
  String get estimatedTime => 'وقت الوصول المقدر';

  @override
  String get yourLocation => 'موقعك';

  @override
  String get dropLocation => 'موقع النقطة';

  @override
  String get routePreview => 'معاينة المسار';

  @override
  String get dropInformation => 'معلومات النقطة';

  @override
  String get plasticBottles => 'زجاجات بلاستيكية';

  @override
  String get cans => 'علب';

  @override
  String get plastic => 'بلاستيك';

  @override
  String get can => 'علبة';

  @override
  String get mixed => 'مختلط';

  @override
  String get totalItems => 'إجمالي العناصر';

  @override
  String get estimatedValue => 'القيمة المقدرة';

  @override
  String get created => 'تم الإنشاء';

  @override
  String get completeCurrentCollectionFirst =>
      'أكمل جمعك الحالي قبل البدء بجمع جديد.';

  @override
  String get youAreOffline => 'أنت غير متصل. يرجى التحقق من اتصال الإنترنت.';

  @override
  String errorColon(String error) {
    return 'خطأ: $error';
  }

  @override
  String get yourInformation => 'معلوماتك';

  @override
  String get createdBy => 'تم الإنشاء بواسطة';

  @override
  String get youWillSeeNotificationsHere => 'سترى إشعاراتك هنا';

  @override
  String get pendingStatus => 'قيد الانتظار';

  @override
  String get acceptedStatus => 'مقبول';

  @override
  String get collectedStatus => 'تم الجمع';

  @override
  String get cancelledStatus => 'ملغي';

  @override
  String get expiredStatus => 'منتهي الصلاحية';

  @override
  String get staleStatus => 'قديم';

  @override
  String get howRewardsWork => 'كيف تعمل المكافآت';

  @override
  String get howRewardsWorkCollector =>
      '• اجمع النقاط لكسب النقاط\n• المستويات الأعلى = المزيد من النقاط لكل نقطة\n• استخدم النقاط في متجر المكافآت\n• تتبع تقدمك وإنجازاتك';

  @override
  String get howRewardsWorkHousehold =>
      '• أنشئ النقاط للمساهمة في إعادة التدوير\n• اربح النقاط عندما يلتقط جامعو النقاط نقاطك\n• المستويات الأعلى = المزيد من النقاط لكل نقطة مجمعة\n• استخدم النقاط في متجر المكافآت';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get itemNotAvailable => 'العنصر غير متاح';

  @override
  String get outOfStock => 'نفد المخزون';

  @override
  String get orderNow => 'اطلب الآن';

  @override
  String get pleaseLogInToViewOrderHistory =>
      'يرجى تسجيل الدخول لعرض سجل الطلبات';

  @override
  String get failedToLoadOrderHistory => 'فشل تحميل سجل الطلبات';

  @override
  String get refresh => 'تحديث';

  @override
  String get pointsSpent => 'النقاط المستخدمة';

  @override
  String get size => 'الحجم';

  @override
  String get orderDate => 'تاريخ الطلب';

  @override
  String get tracking => 'التتبع';

  @override
  String get estimatedDelivery => 'التسليم المقدر';

  @override
  String get deliveryAddress => 'عنوان التسليم';

  @override
  String get adminNote => 'ملاحظة المسؤول';

  @override
  String get approved => 'موافق عليه';

  @override
  String get processing => 'قيد المعالجة';

  @override
  String get shipped => 'تم الشحن';

  @override
  String get delivered => 'تم التسليم';

  @override
  String get cancelled => 'ملغي';

  @override
  String available(int count) {
    return '$count متاح';
  }

  @override
  String get updateDrop => 'تحديث النقطة';

  @override
  String get updating => 'جاري التحديث...';

  @override
  String get recyclingImpact => 'تأثير إعادة التدوير';

  @override
  String get recentDrops => 'النقاط الأخيرة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get dropStatusDistribution => 'حالة النقطة';

  @override
  String get co2VolumeSaved => 'حجم CO₂ المحفوظ';

  @override
  String totalCo2Saved(String amount) {
    return 'إجمالي CO₂ المحفوظ: $amount كجم';
  }

  @override
  String get dropActivity => 'نشاط النقاط';

  @override
  String dropsCreated(String timeRange, int count) {
    return 'النقاط المُنشأة ($timeRange): $count';
  }

  @override
  String errorPickingImage(String error) {
    return 'خطأ في اختيار الصورة: $error';
  }

  @override
  String get dropUpdatedSuccessfully => 'تم تحديث النقطة بنجاح!';

  @override
  String errorUpdatingDrop(String error) {
    return 'خطأ في تحديث النقطة: $error';
  }

  @override
  String get areYouSureDeleteDrop =>
      'هل أنت متأكد من أنك تريد حذف هذه النقطة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get dropDeletedSuccessfully => 'تم حذف النقطة بنجاح!';

  @override
  String errorDeletingDrop(String error) {
    return 'خطأ في حذف النقطة: $error';
  }

  @override
  String get pleaseEnterNumberOfBottles => 'يرجى إدخال عدد الزجاجات';

  @override
  String get pleaseEnterValidNumber => 'يرجى إدخال رقم صحيح';

  @override
  String get pleaseEnterNumberOfCans => 'يرجى إدخال عدد العلب';

  @override
  String get anyAdditionalInstructions => 'أي تعليمات إضافية للجامع...';

  @override
  String get collectorCanLeaveOutside =>
      'يمكن للجامع ترك العناصر في الخارج إذا لم يكن أحد في المنزل';

  @override
  String get loadingAddress => 'جاري تحميل العنوان...';

  @override
  String locationFormat(String lat, String lng) {
    return 'الموقع: $lat, $lng';
  }

  @override
  String get locationSelected => 'تم اختيار الموقع';

  @override
  String get currentDropLocation => 'موقع النقطة الحالي';

  @override
  String get tapConfirmToSetLocation => 'اضغط على \"تأكيد\" لتعيين هذا الموقع';

  @override
  String get userNotFound => 'المستخدم غير موجود';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get getHelp => 'احصل على المساعدة';

  @override
  String get selectCategoryAndGetSupport => 'اختر فئة واحصل على الدعم لمشكلتك';

  @override
  String get mySupportTickets => 'تذاكر الدعم الخاصة بي';

  @override
  String get viewAndManageTickets => 'عرض وإدارة تذاكر الدعم الموجودة';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get emailSupport => 'دعم البريد الإلكتروني';

  @override
  String get phoneSupport => 'دعم الهاتف';

  @override
  String get frequentlyAskedQuestions => 'الأسئلة الشائعة';

  @override
  String get findAnswersToCommonQuestions => 'ابحث عن إجابات للأسئلة الشائعة';

  @override
  String get needMoreHelp => 'تحتاج إلى مزيد من المساعدة؟';

  @override
  String get supportTeamAvailable247 =>
      'إذا لم تجد ما تبحث عنه، فريق الدعم لدينا هنا لمساعدتك على مدار الساعة طوال أيام الأسبوع.';

  @override
  String get dropIssues => 'مشاكل النقاط';

  @override
  String get getHelpWithDropProblems =>
      'احصل على المساعدة في المشاكل المتعلقة بالنقاط';

  @override
  String get dropIssuesSubtitle =>
      'النقاط المنتهية، المجموعات الملغاة، المجموعات النشطة';

  @override
  String get applicationIssues => 'مشاكل الطلب';

  @override
  String get getHelpWithApplications => 'احصل على المساعدة في طلبات المجمع';

  @override
  String get applicationIssuesSubtitle => 'الطلبات المرفوضة، المراجعات المعلقة';

  @override
  String get accountIssues => 'مشاكل الحساب';

  @override
  String get getHelpWithAccount => 'احصل على المساعدة في حسابك';

  @override
  String get accountIssuesSubtitle =>
      'تحديثات الملف الشخصي، مشاكل تسجيل الدخول، إعدادات الحساب';

  @override
  String get technicalIssues => 'المشاكل التقنية';

  @override
  String get getHelpWithAppProblems => 'احصل على المساعدة في مشاكل التطبيق';

  @override
  String get technicalIssuesSubtitle => 'تعطل التطبيق، الأخطاء، مشاكل الأداء';

  @override
  String get paymentIssues => 'مشاكل الدفع';

  @override
  String get getHelpWithPayments => 'احصل على المساعدة في المدفوعات';

  @override
  String get paymentIssuesSubtitle =>
      'تأخيرات الدفع، المدفوعات المفقودة، طرق الدفع';

  @override
  String get generalSupport => 'الدعم العام';

  @override
  String get getHelpWithAnythingElse => 'احصل على المساعدة في أي شيء آخر';

  @override
  String get generalSupportSubtitle => 'الأسئلة، الاقتراحات، القضايا الأخرى';

  @override
  String get selectItemToGetHelp => 'اختر عنصرًا للحصول على المساعدة';

  @override
  String get selectDropFromLast3Days =>
      'اختر نقطة من آخر 3 أيام للحصول على المساعدة';

  @override
  String get selectApplicationToGetHelp =>
      'اختر طلب المجمع الخاص بك للحصول على المساعدة';

  @override
  String get getHelpWithAccountIssues => 'احصل على المساعدة في مشاكل حسابك';

  @override
  String get getHelpWithTechnicalProblems =>
      'احصل على المساعدة في المشاكل التقنية';

  @override
  String get getHelpWithPaymentIssues => 'احصل على المساعدة في مشاكل الدفع';

  @override
  String get getHelpWithAnyOtherIssue => 'احصل على المساعدة في أي قضية أخرى';

  @override
  String get authenticationError => 'خطأ في المصادقة';

  @override
  String get pleaseLogInAgain =>
      'يرجى تسجيل الدخول مرة أخرى لعرض العناصر الخاصة بك.';

  @override
  String get noCollectionsFound => 'لم يتم العثور على مجموعات';

  @override
  String get noCollectionsToReport =>
      'ليس لديك أي مجموعات للإبلاغ عن مشاكل لها.';

  @override
  String get yourCollectionsLast3Days => 'مجموعاتك (آخر 3 أيام)';

  @override
  String errorLoadingCollections(String error) {
    return 'خطأ في تحميل المجموعات: $error';
  }

  @override
  String get noDropsFound => 'لم يتم العثور على نقاط';

  @override
  String get noDropsToReport => 'ليس لديك أي نقاط للإبلاغ عن مشاكل لها.';

  @override
  String get yourDropsLast3Days => 'نقاطك (آخر 3 أيام)';

  @override
  String errorLoadingDrops(String error) {
    return 'خطأ في تحميل النقاط: $error';
  }

  @override
  String get noApplications => 'لا توجد طلبات';

  @override
  String get noCollectorApplications => 'ليس لديك أي طلبات مجمع.';

  @override
  String get noIssuesFound => 'لم يتم العثور على مشاكل';

  @override
  String get applicationBeingProcessed => 'يتم معالجة طلبك بشكل طبيعي.';

  @override
  String get noPaymentsYet => 'لا توجد مدفوعات بعد';

  @override
  String get paymentFeatureNotAvailable =>
      'ميزة الدفع غير متاحة بعد. اختر دفعة للحصول على المساعدة في المشاكل المتعلقة بالدفع.';

  @override
  String get paymentSupport => 'دعم الدفع';

  @override
  String get getHelpWithPaymentRelatedIssues =>
      'احصل على المساعدة في المشاكل المتعلقة بالدفع';

  @override
  String get supportOptions => 'خيارات الدعم';

  @override
  String get collectorApplication => 'طلب جامع';

  @override
  String get applied => 'تم التقديم';

  @override
  String get items => 'عناصر';

  @override
  String get drop => 'نقطة';

  @override
  String get collection => 'مجموعة';

  @override
  String get unknown => 'غير معروف';

  @override
  String get justNow => 'الآن';

  @override
  String hoursAgo(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String minutesAgo(int minutes) {
    return 'منذ $minutes دقيقة';
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
  String get description => 'الوصف';

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
  String get allTickets => 'جميع التذاكر';

  @override
  String get open => 'مفتوح';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get resolved => 'تم الحل';

  @override
  String get closed => 'مغلق';

  @override
  String get onHold => 'في الانتظار';

  @override
  String get noSupportTicketsYet => 'لا توجد تذاكر دعم بعد';

  @override
  String get createFirstSupportTicket =>
      'أنشئ تذكرة الدعم الأولى إذا كنت بحاجة إلى مساعدة';

  @override
  String get errorLoadingTickets => 'خطأ في تحميل التذاكر';

  @override
  String get lowPriority => 'أولوية منخفضة';

  @override
  String get mediumPriority => 'أولوية متوسطة';

  @override
  String get highPriority => 'عالي';

  @override
  String get urgent => 'عاجل';

  @override
  String get dropIssue => 'مشكلة نقطة';

  @override
  String get collectionIssue => 'مشكلة مجموعة';

  @override
  String issueWithDropCreatedOn(String date) {
    return 'مشكلة في النقطة التي تم إنشاؤها في $date';
  }

  @override
  String get bottles => 'زجاجات';

  @override
  String issueWithCollection(String status, String date) {
    return 'مشكلة في المجموعة $status في $date';
  }

  @override
  String get authenticationAccount => '🔐 المصادقة والحساب';

  @override
  String get appTechnicalIssues => '📱 المشاكل التقنية للتطبيق';

  @override
  String get dropCreationManagement => '🏠 إنشاء وإدارة النقاط';

  @override
  String get collectionNavigation => '🚚 المجموعة والتنقل';

  @override
  String get collectorApplicationCategory => '👤 طلب المجمع';

  @override
  String get paymentRewards => '💰 الدفع والمكافآت';

  @override
  String get statisticsHistory => '📊 الإحصائيات والتاريخ';

  @override
  String get roleSwitching => '🔄 تبديل الدور';

  @override
  String get communication => '📞 التواصل';

  @override
  String get generalSupportCategory => '🛠️ الدعم العام';

  @override
  String get supportTicket => 'تذكرة الدعم';

  @override
  String get cannotSendMessageTicketClosed =>
      'لا يمكن إرسال الرسالة. هذه التذكرة مغلقة.';

  @override
  String failedToSendMessage(String error) {
    return 'فشل إرسال الرسالة: $error';
  }

  @override
  String get adminIsOnline => 'المسؤول متصل';

  @override
  String get adminIsTyping => 'المسؤول يكتب...';

  @override
  String get helpUsMaintainQuality => 'ساعدنا في الحفاظ على الجودة';

  @override
  String get selectReason => 'اختر السبب';

  @override
  String get inappropriateImage => '🚫 صورة غير مناسبة';

  @override
  String get fakeDrop => '❌ نقطة مزيفة';

  @override
  String get amountMismatch => '📊 عدد الزجاجات لا يتطابق مع النقطة الحقيقية';

  @override
  String get additionalDetailsOptional => 'تفاصيل إضافية (اختياري)';

  @override
  String get provideMoreInformation => 'قدم المزيد من المعلومات...';

  @override
  String get pleaseSelectReason => 'يرجى اختيار سبب';

  @override
  String get dropReportedSuccessfully =>
      'تم الإبلاغ عن النقطة بنجاح. شكرًا لمساعدتك في الحفاظ على سلامة مجتمعنا!';

  @override
  String errorReportingDrop(String error) {
    return 'خطأ في الإبلاغ عن النقطة: $error';
  }

  @override
  String get submitReport => 'إرسال التقرير';

  @override
  String get dropCollection => 'جمع النقطة';

  @override
  String get walkStraightToDestination => 'امشِ مباشرة إلى الوجهة';

  @override
  String get directRoute => 'طريق مباشر';

  @override
  String get unknownDistance => 'مسافة غير معروفة';

  @override
  String get unknownDuration => 'مدة غير معروفة';

  @override
  String get routeToDrop => 'طريق إلى النقطة';

  @override
  String get remaining => 'متبقي';

  @override
  String get completeCollectionIn => 'أكمل الجمع في:';

  @override
  String get youHaveArrivedAtDestination => 'لقد وصلت إلى الوجهة!';

  @override
  String get calculatingRoute => 'جاري حساب المسار...';

  @override
  String get leaveCollectionMessage =>
      'لديك جمع نشط. هل أنت متأكد أنك تريد المغادرة؟ يجب عليك إكمال أو إلغاء الجمع للمتابعة.';

  @override
  String get slideToCollect => 'اسحب للجمع';

  @override
  String get releaseToCollect => 'أفلت للجمع';

  @override
  String get collectionConfirmed => 'تم تأكيد الجمع!';

  @override
  String collectionCancelled(String reason) {
    return 'تم إلغاء الجمع: $reason';
  }

  @override
  String get errorUserNotAuthenticated => 'خطأ: المستخدم غير مصادق عليه';

  @override
  String errorCancellingCollection(String error) {
    return 'خطأ في إلغاء الجمع: $error';
  }

  @override
  String get collectionCompletedSuccessfully => 'تم إكمال الجمع بنجاح!';

  @override
  String get collectionCompletedSuccessfullyNoExclamation =>
      'اكتمل الجمع بنجاح';

  @override
  String get errorNoCollectorIdFound => 'خطأ: لم يتم العثور على معرف المجمع';

  @override
  String errorConfirmingCollection(String error) {
    return 'خطأ في تأكيد الجمع: $error';
  }

  @override
  String get dropCollected => 'تم جمع النقطة';

  @override
  String pointsEarned(int points) {
    final intl.NumberFormat pointsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String pointsString = pointsNumberFormat.format(points);

    return '+$pointsString نقطة مكتسبة!';
  }

  @override
  String get currentTier => 'المستوى الحالي';

  @override
  String get totalPoints => 'إجمالي النقاط';

  @override
  String get awesome => 'رائع!';

  @override
  String get exitNavigationMessage =>
      'هل أنت متأكد أنك تريد مغادرة التنقل؟ سيبقى جمعك نشطًا.';

  @override
  String get exit => 'مغادرة';

  @override
  String collectionTimerRunningLow(String time) {
    return 'مؤقت الجمع منخفض: متبقي $time';
  }

  @override
  String get view => 'عرض';

  @override
  String get collectionTimerWarning => 'تحذير مؤقت الجمع';

  @override
  String yourCollectionTimerRunningLow(String time) {
    return 'مؤقت الجمع الخاص بك منخفض: متبقي $time';
  }

  @override
  String get cancelCollectionMessage =>
      'هل أنت متأكد أنك تريد إلغاء هذا الجمع؟ يرجى اختيار سبب:';

  @override
  String get noAccess => 'لا يوجد وصول';

  @override
  String get notFound => 'غير موجود';

  @override
  String get alreadyCollected => 'تم الجمع بالفعل';

  @override
  String get wrongLocation => 'موقع خاطئ';

  @override
  String get unsafeLocation => 'موقع غير آمن';

  @override
  String get other => 'أخرى';

  @override
  String get cancellationReasons => 'أسباب الإلغاء';

  @override
  String get cancellationReason => 'سبب الإلغاء';

  @override
  String get accountTemporarilyLocked => 'الحساب مؤقتًا مقفل';

  @override
  String get accountLockedReason =>
      'تم قفل حسابك لمدة 24 ساعة بسبب 5 تحذيرات من انتهاء وقت الجمع.';

  @override
  String unlocksIn(String time) {
    return 'يفتح خلال $time';
  }

  @override
  String get lockExpired => 'انتهى القفل';

  @override
  String get hour => 'ساعة';

  @override
  String get hours => 'ساعات';

  @override
  String get minute => 'دقيقة';

  @override
  String get minutes => 'دقائق';

  @override
  String get second => 'ثانية';

  @override
  String get seconds => 'ثواني';

  @override
  String availableAgainAt(String time) {
    return 'متاح مرة أخرى في $time';
  }

  @override
  String get accountLockedInfo =>
      'لا يزال بإمكانك تصفح النقاط واستخدام الميزات الأخرى، لكن لا يمكنك قبول نقاط جديدة حتى يتم فتح القفل.';

  @override
  String get iUnderstand => 'فهمت';

  @override
  String get orderApproved => 'تم الموافقة على الطلب';

  @override
  String orderApprovedMessage(String orderId) {
    return 'تمت الموافقة على طلبك $orderId وهو قيد المعالجة.';
  }

  @override
  String get orderRejected => 'تم رفض الطلب';

  @override
  String orderRejectedMessage(String reason) {
    return 'تم رفض طلبك. السبب: $reason';
  }

  @override
  String get orderShipped => 'تم شحن الطلب';

  @override
  String orderShippedMessage(String tracking) {
    return 'تم شحن طلبك. رقم التتبع: $tracking';
  }

  @override
  String get orderDelivered => 'تم تسليم الطلب';

  @override
  String get orderDeliveredMessage => 'تم تسليم طلبك بنجاح.';

  @override
  String get pointsEarnedTitle => 'نقاط مكتسبة';

  @override
  String pointsEarnedMessage(int points) {
    final intl.NumberFormat pointsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String pointsString = pointsNumberFormat.format(points);

    return 'لقد ربحت $pointsString نقطة!';
  }

  @override
  String get applicationApproved => 'تمت الموافقة على الطلب';

  @override
  String get applicationApprovedMessage =>
      'تهانينا! تمت الموافقة على طلب المجمع الخاص بك.';

  @override
  String get applicationReversed => 'تم عكس الطلب';

  @override
  String get applicationReversedMessage => 'تم عكس حالة طلب المجمع الخاص بك.';

  @override
  String get dropAccepted => 'تم قبول النقطة';

  @override
  String get dropAcceptedMessage => 'قبل مجمع نقطتك.';

  @override
  String get dropCollectedMessage => 'تم جمع نقطتك بنجاح.';

  @override
  String get dropCollectedWithRewards => 'تم جمع النقطة';

  @override
  String dropCollectedWithRewardsMessage(int points) {
    final intl.NumberFormat pointsNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String pointsString = pointsNumberFormat.format(points);

    return 'تم جمع نقطتك! لقد ربحت $pointsString نقطة.';
  }

  @override
  String get dropCollectedWithTierUpgrade => 'تم جمع النقطة';

  @override
  String get dropCollectedWithTierUpgradeMessage =>
      'تهانينا! تم جمع نقطتك وتم ترقيتك إلى مستوى أعلى!';

  @override
  String get dropCancelled => 'تم إلغاء النقطة';

  @override
  String get dropCancelledMessage => 'تم إلغاء نقطتك.';

  @override
  String get dropExpired => 'انتهت صلاحية النقطة';

  @override
  String get dropExpiredMessage => 'انتهت صلاحية نقطتك ولم تعد متاحة.';

  @override
  String get dropNearExpiring => 'النقطة على وشك الانتهاء';

  @override
  String get dropNearExpiringMessage => 'نقطتك على وشك الانتهاء قريبًا.';

  @override
  String get dropCensored => 'تم حذف النقطة';

  @override
  String get dropCensoredMessage => 'تم حذف نقطتك بسبب محتوى غير مناسب.';

  @override
  String get ticketMessage => 'رسالة تذكرة جديدة';

  @override
  String get ticketMessageNotification =>
      'لديك رسالة جديدة في تذكرة الدعم الخاصة بك.';

  @override
  String get accountUnlocked => 'تم فتح الحساب';

  @override
  String get accountUnlockedMessage =>
      'تم فتح حسابك. يمكنك الآن البدء في جمع النقاط مرة أخرى!';

  @override
  String get userDeleted => 'تم حذف الحساب';

  @override
  String get userDeletedMessage => 'تم حذف حسابك.';

  @override
  String get trackOrder => 'تتبع الطلب';

  @override
  String get viewOrder => 'عرض الطلب';

  @override
  String get shopAgain => 'تسوق مرة أخرى';

  @override
  String get viewRewards => 'عرض المكافآت';

  @override
  String get tapToViewRejectionReason => 'اضغط لعرض سبب الرفض';

  @override
  String get gettingStarted => 'البدء';

  @override
  String get advancedFeatures => 'الميزات المتقدمة';

  @override
  String get troubleshooting => 'استكشاف الأخطاء وإصلاحها';

  @override
  String get bestPractices => 'أفضل الممارسات';

  @override
  String get payments => 'المدفوعات';

  @override
  String get help => 'مساعدة';

  @override
  String get advanced => 'متقدم';

  @override
  String get story => 'القصة';

  @override
  String get totalDrops => 'إجمالي القطرات';

  @override
  String get aluminumCans => 'علب الألمنيوم';

  @override
  String get recycled => 'معاد تدويره';

  @override
  String recycledBottles(String count) {
    return 'تم إعادة تدوير $count زجاجة';
  }

  @override
  String recycledCans(String count) {
    return 'تم إعادة تدوير $count علبة';
  }

  @override
  String get totalItemsRecycled => 'إجمالي العناصر المعاد تدويرها';

  @override
  String get dropsCollected => 'القطرات المجمعة';

  @override
  String get monday => 'الاثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get january => 'يناير';

  @override
  String get february => 'فبراير';

  @override
  String get march => 'مارس';

  @override
  String get april => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get june => 'يونيو';

  @override
  String get july => 'يوليو';

  @override
  String get august => 'أغسطس';

  @override
  String get september => 'سبتمبر';

  @override
  String get october => 'أكتوبر';

  @override
  String get november => 'نوفمبر';

  @override
  String get december => 'ديسمبر';

  @override
  String get todaysTotal => 'إجمالي اليوم';

  @override
  String get earnings => 'الأرباح';

  @override
  String get collections => 'المجموعات';

  @override
  String get noEarningsHistoryYet => 'لا يوجد سجل أرباح بعد';

  @override
  String get earningsWillAppearHere =>
      'ستظهر أرباحك هنا بمجرد إكمال عمليات الجمع';

  @override
  String get totalEarnings => 'إجمالي الأرباح';

  @override
  String errorLoadingEarnings(String error) {
    return 'خطأ في تحميل الأرباح: $error';
  }

  @override
  String get noCompletedCollectionsYet => 'لا توجد مجموعات مكتملة بعد';

  @override
  String get performanceMetrics => 'مقاييس الأداء';

  @override
  String get expired => 'منتهي الصلاحية';

  @override
  String get collectionsOverTime => 'المجموعات مع مرور الوقت';

  @override
  String get expiredOverTime => 'منتهي الصلاحية مع مرور الوقت';

  @override
  String get cancelledOverTime => 'ملغي مع مرور الوقت';

  @override
  String get totalThisWeek => 'إجمالي هذا الأسبوع';

  @override
  String get totalThisMonth => 'إجمالي هذا الشهر';

  @override
  String get totalThisYear => 'إجمالي هذه السنة';

  @override
  String get mon => 'الاثنين';

  @override
  String get tue => 'الثلاثاء';

  @override
  String get wed => 'الأربعاء';

  @override
  String get thu => 'الخميس';

  @override
  String get fri => 'الجمعة';

  @override
  String get sat => 'السبت';

  @override
  String get sun => 'الأحد';

  @override
  String get jan => 'يناير';

  @override
  String get feb => 'فبراير';

  @override
  String get mar => 'مارس';

  @override
  String get apr => 'أبريل';

  @override
  String get jun => 'يونيو';

  @override
  String get jul => 'يوليو';

  @override
  String get aug => 'أغسطس';

  @override
  String get sep => 'سبتمبر';

  @override
  String get oct => 'أكتوبر';

  @override
  String get nov => 'نوفمبر';

  @override
  String get dec => 'ديسمبر';

  @override
  String daysAgoShort(int days) {
    return 'منذ $days يوم';
  }

  @override
  String get at => 'في';

  @override
  String get total => 'الإجمالي';

  @override
  String get noDropsCreatedYet => 'لم يتم إنشاء أي قطرات بعد';

  @override
  String get createYourFirstDropToGetStarted => 'أنشئ أول قطرة للبدء';

  @override
  String get noActiveDrops => 'لا توجد قطرات نشطة';

  @override
  String get noCollectedDrops => 'لا توجد قطرات مجمعة بعد';

  @override
  String get noStaleDrops => 'لا توجد قطرات قديمة';

  @override
  String get noCensoredDrops => 'لا توجد قطرات محذوفة';

  @override
  String get noFlaggedDrops => 'لا توجد قطرات معلقة';

  @override
  String get noDropsMatchYourFilters =>
      'لا توجد قطرات تطابق المرشحات الخاصة بك';

  @override
  String get tryAdjustingYourFilters => 'حاول تعديل المرشحات الخاصة بك';

  @override
  String get noDropsAvailable => 'لا توجد قطرات متاحة';

  @override
  String get checkBackLaterForNewDrops => 'تحقق لاحقًا للحصول على قطرات جديدة';

  @override
  String get note => 'ملاحظة';

  @override
  String get outside => 'خارج';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get last30Days => 'آخر 30 يوم';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get within1Km => 'ضمن 1 كم';

  @override
  String get within3Km => 'ضمن 3 كم';

  @override
  String get within5Km => 'ضمن 5 كم';

  @override
  String get within10Km => 'ضمن 10 كم';

  @override
  String get rewardHistory => 'سجل المكافآت';

  @override
  String get noRewardHistoryYet => 'لا يوجد سجل مكافآت بعد';

  @override
  String get points => 'النقاط';

  @override
  String get tier => 'المستوى';

  @override
  String get tierUp => 'ترقية المستوى!';

  @override
  String get acceptDrop => 'قبول القطرة';

  @override
  String get completeCurrentDropFirst => 'أكمل القطرة الحالية أولاً';

  @override
  String get distanceUnavailable => 'المسافة غير متاحة';

  @override
  String get away => 'بعيد';

  @override
  String get meters => 'م';

  @override
  String get minutesShort => 'د';

  @override
  String get hoursShort => 'س';

  @override
  String get current => 'الحالي';

  @override
  String earnPointsPerDrop(int points) {
    return 'اكسب $points نقطة لكل قطرة';
  }

  @override
  String dropsRequired(int count) {
    return 'مطلوب $count قطرة';
  }

  @override
  String get start => 'ابدأ';

  @override
  String get filterHistory => 'تصفية السجل';

  @override
  String get searchHistory => 'البحث في السجل';

  @override
  String get searchByNotesBottleTypeOrCancellationReason =>
      'البحث حسب الملاحظات أو نوع الزجاجة أو سبب الإلغاء...';

  @override
  String get viewType => 'نوع العرض';

  @override
  String get itemType => 'نوع العنصر';

  @override
  String get last3Months => 'آخر 3 أشهر';

  @override
  String get last6Months => 'آخر 6 أشهر';

  @override
  String get allItems => 'جميع العناصر';

  @override
  String get bottlesOnly => 'زجاجات فقط';

  @override
  String get cansOnly => 'علب فقط';

  @override
  String get allTypes => 'جميع الأنواع';

  @override
  String get activeFilters => 'نشط';

  @override
  String get waitingForCollector => 'في انتظار المجمع';

  @override
  String get liveCollectorOnTheWay => '🟢 مباشر - المجمع في الطريق';

  @override
  String get collectorWasOnTheWay => 'كان المجمع في الطريق';

  @override
  String get wasOnTheWay => 'كان في الطريق';

  @override
  String get accepted => 'تم القبول';

  @override
  String get sessionTime => 'وقت الجلسة';

  @override
  String get completed => 'مكتمل';

  @override
  String get pleaseLoginToViewYourDrops => 'يرجى تسجيل الدخول لعرض إسقاطاتك';

  @override
  String errorLoadingUserData(String error) {
    return 'خطأ في تحميل بيانات المستخدم: $error';
  }

  @override
  String get earn500Points => 'اكسب 500 نقطة';

  @override
  String get forEachFriendWhoJoins => 'لكل صديق ينضم';

  @override
  String get yourReferralCode => 'رمز الإحالة الخاص بك';

  @override
  String get referralCodeCopiedToClipboard => 'تم نسخ رمز الإحالة إلى الحافظة';

  @override
  String get shareVia => 'مشاركة عبر';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get sms => 'رسالة نصية';

  @override
  String get more => 'المزيد';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get shareYourCode => 'شارك رمزك';

  @override
  String get shareYourUniqueReferralCodeWithFriends =>
      'شارك رمز الإحالة الفريد الخاص بك مع الأصدقاء';

  @override
  String get friendSignsUp => 'يسجل الصديق';

  @override
  String get yourFriendCreatesAnAccountUsingYourCode =>
      'ينشئ صديقك حسابًا باستخدام رمزك';

  @override
  String get earnRewards => 'اكسب المكافآت';

  @override
  String get get500PointsWhenTheyCompleteFirstActivity =>
      'احصل على 500 نقطة عند إكمالهم النشاط الأول';

  @override
  String get trainingCenterInfo => 'مركز التدريب';

  @override
  String get trainingCenterInfoHousehold =>
      'الوصول إلى محتوى التدريب المخصص لمستخدمي الأسر. تعلم كيفية استخدام Botleji بفعالية!';

  @override
  String get trainingCenterInfoCollector =>
      'الوصول إلى محتوى التدريب للمجمعين. أتقن تقنيات الجمع وأفضل الممارسات!';

  @override
  String get filter => 'تصفية';

  @override
  String get search => 'بحث';

  @override
  String get clear => 'مسح';

  @override
  String get glass => 'زجاج';

  @override
  String get aluminum => 'ألومنيوم';

  @override
  String get dropProgress => 'تقدم الإسقاط';

  @override
  String get collectionIssues => 'مشاكل الجمع';

  @override
  String cancelledTimes(int count) {
    return 'تم الإلغاء $count مرات';
  }

  @override
  String get dropAcceptedByCollector => 'تم قبول الإسقاط من قبل المجمع';

  @override
  String get acceptedDropForCollection => 'تم قبول الإسقاط للجمع';

  @override
  String get applicationIssue => 'مشكلة في الطلب';

  @override
  String get paymentIssue => 'مشكلة في الدفع';

  @override
  String get accountIssue => 'مشكلة في الحساب';

  @override
  String get technicalIssue => 'مشكلة تقنية';

  @override
  String get generalSupportRequest => 'طلب دعم عام';

  @override
  String get supportRequest => 'طلب دعم';

  @override
  String get noDescriptionProvided => 'لم يتم تقديم وصف';

  @override
  String get welcome => 'مرحبًا';

  @override
  String get idVerification => 'التحقق من الهوية';

  @override
  String get selfieWithId => 'سيلفي مع الهوية';

  @override
  String get reviewAndSubmit => 'المراجعة والإرسال';

  @override
  String get welcomeToCollectorProgram => 'مرحبًا بك في برنامج الجامعين!';

  @override
  String get joinOurCommunityOfEcoConsciousCollectors =>
      'انضم إلى مجتمعنا من الجامعين الواعيين بيئيًا وساعد في إحداث فرق في إعادة التدوير.';

  @override
  String get earnMoney => 'اكسب المال';

  @override
  String get getPaidForEveryBottleAndCan =>
      'احصل على أجر مقابل كل زجاجة وعلبة تجمعها';

  @override
  String get flexibleHours => 'ساعات مرنة';

  @override
  String get collectWheneverAndWherever => 'اجمع متى وأينما تريد';

  @override
  String get helpTheEnvironment => 'ساعد البيئة';

  @override
  String get contributeToCleanerGreenerWorld => 'ساهم في عالم أنظف وأكثر خضرة';

  @override
  String get requirements => 'المتطلبات';

  @override
  String get mustBe18YearsOrOlder => '• يجب أن يكون عمرك 18 عامًا أو أكثر';

  @override
  String get validNationalIdCard => '• بطاقة هوية وطنية صالحة';

  @override
  String get clearPhotosOfIdAndSelfie => '• صور واضحة للهوية والسيلفي';

  @override
  String get goodStandingInCommunity => '• سمعة جيدة في المجتمع';

  @override
  String get idCardVerification => 'التحقق من بطاقة الهوية';

  @override
  String pleaseProvideYourIdCardInformation(String idType) {
    return 'يرجى تقديم معلومات $idType الخاصة بك والتقاط صور واضحة';
  }

  @override
  String get idCardDetails => 'تفاصيل بطاقة الهوية';

  @override
  String get passportDetails => 'تفاصيل جواز السفر';

  @override
  String get idCardType => 'نوع بطاقة الهوية';

  @override
  String get selectYourIdCardType => 'اختر نوع بطاقة الهوية الخاصة بك';

  @override
  String get nationalId => 'الهوية الوطنية';

  @override
  String get passport => 'جواز السفر';

  @override
  String get pleaseSelectAnIdCardType => 'يرجى اختيار نوع بطاقة الهوية';

  @override
  String get passportNumber => 'رقم جواز السفر';

  @override
  String get enterYourPassportNumber => 'أدخل رقم جواز السفر الخاص بك';

  @override
  String get selectIssueDate => 'اختر تاريخ الإصدار';

  @override
  String get issueDateLabel => 'تاريخ الإصدار';

  @override
  String issueDate(String date) {
    return 'تاريخ الإصدار: $date';
  }

  @override
  String get selectExpiryDate => 'اختر تاريخ الانتهاء';

  @override
  String get expiryDateLabel => 'تاريخ الانتهاء';

  @override
  String expiryDate(String date) {
    return 'تاريخ الانتهاء: $date';
  }

  @override
  String get issuingAuthority => 'السلطة المصدرة';

  @override
  String get egMinistryOfForeignAffairs => 'مثال: وزارة الشؤون الخارجية';

  @override
  String get idCardNumber => 'رقم بطاقة الهوية';

  @override
  String get idCardNumberPlaceholder => '12345678';

  @override
  String get idCardNumberIsRequired => 'رقم بطاقة الهوية مطلوب';

  @override
  String get idCardNumberMustBe8Digits =>
      'يجب أن يكون رقم بطاقة الهوية 8 أرقام';

  @override
  String get idCardNumberMustContainOnlyDigits =>
      'يجب أن يحتوي رقم بطاقة الهوية على أرقام فقط';

  @override
  String get idCardPhotos => 'صور بطاقة الهوية';

  @override
  String get passportPhotos => 'صور جواز السفر';

  @override
  String get noPassportMainPagePhoto =>
      'لا توجد صورة للصفحة الرئيسية لجواز السفر';

  @override
  String get takePhotoOfMainPageWithDetails =>
      'التقط صورة للصفحة الرئيسية مع تفاصيلك';

  @override
  String get retakePhoto => 'إعادة التقاط الصورة';

  @override
  String get takePassportMainPagePhoto =>
      'التقط صورة للصفحة الرئيسية لجواز السفر';

  @override
  String get noIdCardFrontPhoto => 'لا توجد صورة لوجه بطاقة الهوية';

  @override
  String get takePhotoOfFrontOfIdCard => 'التقط صورة لوجه بطاقة الهوية';

  @override
  String get retakeFrontPhoto => 'إعادة التقاط صورة الوجه';

  @override
  String get takeIdCardFrontPhoto => 'التقط صورة لوجه بطاقة الهوية';

  @override
  String get noIdCardBackPhoto => 'لا توجد صورة لظهر بطاقة الهوية';

  @override
  String get takePhotoOfBackOfIdCard => 'التقط صورة لظهر بطاقة الهوية';

  @override
  String get retakeBackPhoto => 'إعادة التقاط صورة الظهر';

  @override
  String get takeIdCardBackPhoto => 'التقط صورة لظهر بطاقة الهوية';

  @override
  String get continueButton => 'متابعة';

  @override
  String get selfieWithIdCard => 'سيلفي مع بطاقة الهوية';

  @override
  String get pleaseTakeSelfieWhileHoldingId =>
      'يرجى التقاط سيلفي أثناء حمل بطاقة الهوية بجانب وجهك';

  @override
  String get noSelfiePhoto => 'لا توجد صورة سيلفي';

  @override
  String get takeSelfie => 'التقط سيلفي';

  @override
  String get reviewAndSubmitTitle => 'المراجعة والإرسال';

  @override
  String get pleaseReviewYourApplication => 'يرجى مراجعة طلبك قبل الإرسال';

  @override
  String get idCardInformation => 'معلومات بطاقة الهوية';

  @override
  String get idType => 'نوع الهوية';

  @override
  String get idNumber => 'رقم الهوية';

  @override
  String get notProvided => 'غير مقدم';

  @override
  String get idCard => 'بطاقة الهوية';

  @override
  String get selfie => 'سيلفي';

  @override
  String get whatHappensNext => 'ماذا يحدث بعد ذلك؟';

  @override
  String get applicationReviewProcess =>
      '• سيتم مراجعة طلبك من قبل فريقنا\n• تستغرق المراجعة عادة من 1 إلى 3 أيام عمل\n• ستصلك إشعار بمجرد المراجعة\n• في حالة الموافقة، يمكنك البدء في الجمع فورًا';

  @override
  String get submitting => 'جاري الإرسال...';

  @override
  String get submitApplication => 'إرسال الطلب';

  @override
  String get pleaseTakeBothPhotosBeforeSubmitting =>
      'يرجى التقاط كلتا الصورتين قبل الإرسال';

  @override
  String get pleaseFillInAllRequiredPassportInformation =>
      'يرجى ملء جميع معلومات جواز السفر المطلوبة';

  @override
  String get pleaseFillInAllRequiredIdCardInformation =>
      'يرجى ملء جميع معلومات بطاقة الهوية المطلوبة (رقم الهوية والنوع)';

  @override
  String get applicationUpdatedSuccessfully => 'تم تحديث الطلب بنجاح!';

  @override
  String get applicationSubmittedSuccessfully => 'تم إرسال الطلب بنجاح!';

  @override
  String errorSubmittingApplication(String error) {
    return 'خطأ في إرسال الطلب: $error';
  }

  @override
  String get errorLoadingApplication => 'خطأ في تحميل الطلب';

  @override
  String get noApplicationFound => 'لم يتم العثور على طلب';

  @override
  String get youHaventSubmittedApplicationYet => 'لم تقم بتقديم طلب جامع بعد.';

  @override
  String get pendingReview => 'قيد المراجعة';

  @override
  String get yourApplicationIsBeingReviewed => 'يتم مراجعة طلبك من قبل فريقنا.';

  @override
  String get congratulationsApplicationApproved =>
      'تهانينا! تمت الموافقة على طلبك.';

  @override
  String get applicationNotApprovedCanApplyAgain =>
      'لم تتم الموافقة على طلبك. يمكنك التقديم مرة أخرى.';

  @override
  String get applicationStatusUnknown => 'حالة الطلب غير معروفة.';

  @override
  String get applicationDetails => 'تفاصيل الطلب';

  @override
  String get applicationId => 'معرف الطلب';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get appliedOn => 'تم التقديم في';

  @override
  String get reviewedOn => 'تمت المراجعة في';

  @override
  String get rejectionReason => 'سبب الرفض';

  @override
  String get reviewNotes => 'ملاحظات المراجعة';

  @override
  String get applyAgain => 'تقديم مرة أخرى';

  @override
  String get applicationInReview => 'الطلب قيد المراجعة';

  @override
  String get applicationInReviewDialogContent =>
      'يتم حاليًا مراجعة طلبك من قبل فريقنا. تستغرق هذه العملية عادة من 1 إلى 3 أيام عمل. سيتم إشعارك بمجرد اتخاذ القرار.';

  @override
  String get reviewProcess => 'عملية المراجعة';
}
