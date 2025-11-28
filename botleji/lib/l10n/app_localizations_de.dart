// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Bottleji';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get changeLanguage => 'App-Sprache ändern';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get english => 'Englisch';

  @override
  String get french => 'Französisch';

  @override
  String get german => 'Deutsch';

  @override
  String get arabic => 'Arabisch';

  @override
  String get location => 'Standort';

  @override
  String get manageLocationPreferences => 'Standortpräferenzen verwalten';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get manageNotificationPreferences =>
      'Benachrichtigungseinstellungen verwalten';

  @override
  String get displayTheme => 'Anzeigethema';

  @override
  String get changeAppAppearance => 'App-Erscheinungsbild ändern';

  @override
  String get comingSoon => 'Demnächst verfügbar';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get login => 'Anmelden';

  @override
  String get register => 'Registrieren';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get welcomeBack => 'Willkommen zurück!';

  @override
  String get signInToContinue => 'Melden Sie sich an, um fortzufahren';

  @override
  String get dontHaveAccount => 'Haben Sie noch kein Konto?';

  @override
  String get enterYourEmail => 'Geben Sie Ihre E-Mail ein';

  @override
  String get enterYourPassword => 'Geben Sie Ihr Passwort ein';

  @override
  String get pleaseEnterEmail => 'Bitte geben Sie Ihre E-Mail ein';

  @override
  String get pleaseEnterValidEmail => 'Bitte geben Sie eine gültige E-Mail ein';

  @override
  String get pleaseEnterPassword => 'Bitte geben Sie ein Passwort ein';

  @override
  String get passwordMinLength =>
      'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get invalidEmailOrPassword =>
      'Ungültige E-Mail oder Passwort. Bitte versuchen Sie es erneut.';

  @override
  String get loginFailed =>
      'Anmeldung fehlgeschlagen. Bitte überprüfen Sie Ihre Anmeldedaten und versuchen Sie es erneut.';

  @override
  String get connectionTimeout =>
      'Verbindungszeitüberschreitung. Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get networkError =>
      'Netzwerkfehler. Bitte überprüfen Sie Ihre Internetverbindung.';

  @override
  String get requestTimeout =>
      'Anfragezeitüberschreitung. Bitte versuchen Sie es erneut.';

  @override
  String get serverError =>
      'Serverfehler. Bitte versuchen Sie es später erneut.';

  @override
  String get accountDeleted => 'Konto gelöscht';

  @override
  String get accountDeletedMessage =>
      'Ihr Konto wurde von einem Administrator gelöscht.\n\nWenn Sie glauben, dass dies ein Fehler ist, wenden Sie sich bitte an unser Support-Team:\n\n📧 E-Mail: support@bottleji.com\n📱 Support-Zeiten: 9-18 Uhr (GMT+1)\n\nWir entschuldigen uns für die Unannehmlichkeiten.';

  @override
  String get reason => 'Grund';

  @override
  String get youWillBeRedirectedToLoginScreen =>
      'Sie werden zur Anmeldeseite weitergeleitet.';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get enterEmailToReceiveResetCode =>
      'Geben Sie Ihre E-Mail-Adresse ein, um einen Reset-Code zu erhalten';

  @override
  String get sendResetCode => 'Reset-Code senden';

  @override
  String get resetCodeSentToEmail => 'Reset-Code wurde an Ihre E-Mail gesendet';

  @override
  String get enterResetCode => 'Reset-Code eingeben';

  @override
  String weHaveSentResetCodeTo(String email) {
    return 'Wir haben einen Reset-Code gesendet an\n$email';
  }

  @override
  String get verify => 'Überprüfen';

  @override
  String get didntReceiveCode => 'Code nicht erhalten?';

  @override
  String get resend => 'Erneut senden';

  @override
  String resendIn(int seconds) {
    return 'Erneut senden in ${seconds}s';
  }

  @override
  String get resetCodeResentSuccessfully =>
      'Reset-Code erfolgreich erneut gesendet!';

  @override
  String get createNewPassword => 'Neues Passwort erstellen';

  @override
  String get pleaseEnterNewPassword => 'Bitte geben Sie Ihr neues Passwort ein';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get enterNewPassword => 'Geben Sie Ihr neues Passwort ein';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get confirmNewPassword => 'Bestätigen Sie Ihr neues Passwort';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Das Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get pleaseConfirmPassword => 'Bitte bestätigen Sie Ihr Passwort';

  @override
  String get passwordsDoNotMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get passwordResetSuccessful =>
      'Passwort erfolgreich zurückgesetzt! Bitte melden Sie sich mit Ihrem neuen Passwort an.';

  @override
  String get verifyYourEmail => 'E-Mail bestätigen';

  @override
  String get pleaseEnterOtpSentToEmail =>
      'Bitte geben Sie den an Ihre E-Mail gesendeten OTP-Code ein';

  @override
  String get verifyOtp => 'OTP-Code überprüfen';

  @override
  String get resendOtp => 'OTP-Code erneut senden';

  @override
  String resendOtpIn(int seconds) {
    return 'OTP-Code erneut senden in $seconds Sekunden';
  }

  @override
  String get otpVerifiedSuccessfully => 'OTP-Code erfolgreich überprüft';

  @override
  String get invalidVerificationResponse =>
      'Fehler: Ungültige Verifizierungsantwort';

  @override
  String get otpResentSuccessfully => 'OTP-Code erfolgreich erneut gesendet!';

  @override
  String get startYourBottlejiJourney => 'Beginnen Sie Ihre Bottleji-Reise';

  @override
  String get createAccountToGetStarted =>
      'Erstellen Sie ein Konto, um zu beginnen';

  @override
  String get createAPassword => 'Passwort erstellen';

  @override
  String get confirmYourPassword => 'Bestätigen Sie Ihr Passwort';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get alreadyHaveAccount => 'Haben Sie bereits ein Konto?';

  @override
  String get registrationSuccessful => 'Registrierung erfolgreich';

  @override
  String get skip => 'Überspringen';

  @override
  String get next => 'Weiter';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get welcomeToBottleji => 'Willkommen bei Bottleji';

  @override
  String get yourSustainableWasteManagementSolution =>
      'Ihre nachhaltige Abfallmanagement-Lösung';

  @override
  String get joinThousandsOfUsersMakingDifference =>
      'Schließen Sie sich Tausenden von Benutzern an, die einen Unterschied machen, indem sie Flaschen und Dosen recyceln und dabei Belohnungen verdienen.';

  @override
  String get createAndTrackDrops => 'Abgaben erstellen und verfolgen';

  @override
  String get forHouseholdUsers => 'Für Haushaltsbenutzer';

  @override
  String get easilyCreateDropRequests =>
      'Erstellen Sie einfach Abgabewünsche für Ihre recycelbaren Flaschen und Dosen. Verfolgen Sie den Sammelstatus und erhalten Sie Benachrichtigungen, wenn Sammler sie abholen.';

  @override
  String get collectAndEarn => 'Sammeln und verdienen';

  @override
  String get forCollectors => 'Für Sammler';

  @override
  String get findNearbyDropsCollectRecyclables =>
      'Finden Sie nahegelegene Abgaben, sammeln Sie recycelbare Materialien und verdienen Sie Belohnungen. Helfen Sie beim Aufbau einer nachhaltigen Gemeinschaft und verdienen Sie dabei Geld.';

  @override
  String get realTimeUpdates => 'Echtzeit-Updates';

  @override
  String get stayConnected => 'Bleiben Sie verbunden';

  @override
  String get getInstantNotificationsAboutDrops =>
      'Erhalten Sie sofortige Benachrichtigungen über Ihre Abgaben, Sammlungen und wichtige Updates. Verpassen Sie nie eine Gelegenheit.';

  @override
  String get appPermissions => 'App-Berechtigungen';

  @override
  String get bottlejiRequiresAdditionalPermissions =>
      'Bottleji benötigt zusätzliche Berechtigungen, um ordnungsgemäß zu funktionieren';

  @override
  String get permissionsHelpProvideBestExperience =>
      'Diese Berechtigungen helfen uns, Ihnen die beste Erfahrung zu bieten.';

  @override
  String get locationServices => 'Standortdienste';

  @override
  String get accessLocationToShowNearbyDrops =>
      'Greifen Sie auf Ihren Standort zu, um nahegelegene Abgaben anzuzeigen und die Navigation für Sammler zu aktivieren.';

  @override
  String get localNetworkAccess => 'Lokaler Netzwerkzugriff';

  @override
  String get allowAppToDiscoverServicesOnWifi =>
      'Erlauben Sie der App, Dienste in Ihrem Wi‑Fi für Echtzeit-Funktionen zu entdecken.';

  @override
  String get receiveRealTimeUpdatesAboutDrops =>
      'Erhalten Sie Echtzeit-Updates über Ihre Abgaben, Sammlungen und wichtige Ankündigungen.';

  @override
  String get photoStorage => 'Fotospeicher';

  @override
  String get saveAndAccessPhotosOfRecyclableItems =>
      'Speichern und greifen Sie auf Fotos Ihrer recycelbaren Artikel zu.';

  @override
  String get enable => 'Aktivieren';

  @override
  String get continueToApp => 'Zur App fortfahren';

  @override
  String get enableRequiredPermissions =>
      'Erforderliche Berechtigungen aktivieren';

  @override
  String get accountDisabled => 'Konto deaktiviert';

  @override
  String get accountDisabledMessage =>
      'Ihr Konto wurde aufgrund wiederholter Verstöße gegen die Community-Richtlinien von Bottleji dauerhaft deaktiviert.\n\nSie können nicht mehr auf dieses Konto zugreifen oder es verwenden.\n\nWenn Sie glauben, dass diese Entscheidung fälschlicherweise getroffen wurde, wenden Sie sich bitte an den Support:';

  @override
  String get supportEmail => 'support@bottleji.com';

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String get pleaseEmailSupport =>
      'Bitte senden Sie eine E-Mail an support@bottleji.com für Unterstützung';

  @override
  String get sessionExpired => 'Sitzung abgelaufen';

  @override
  String get sessionExpiredMessage =>
      'Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an, um fortzufahren.';

  @override
  String get home => 'Startseite';

  @override
  String get drops => 'Abgaben';

  @override
  String get rewards => 'Belohnungen';

  @override
  String get stats => 'Statistiken';

  @override
  String get history => 'Verlauf';

  @override
  String get profile => 'Profil';

  @override
  String get account => 'Konto';

  @override
  String get support => 'Support';

  @override
  String get termsAndConditions => 'Allgemeine Geschäftsbedingungen';

  @override
  String get logout => 'Abmelden';

  @override
  String get areYouSureLogout => 'Möchten Sie sich wirklich abmelden?';

  @override
  String errorDuringLogout(String error) {
    return 'Fehler beim Abmelden: $error';
  }

  @override
  String get close => 'Schließen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get retry => 'Wiederholen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get stay => 'Bleiben';

  @override
  String get leave => 'Verlassen';

  @override
  String get back => 'Zurück';

  @override
  String get previous => 'Zurück';

  @override
  String get done => 'Fertig';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get apply => 'Anwenden';

  @override
  String get filterDrops => 'Abgaben filtern';

  @override
  String get status => 'Status';

  @override
  String get all => 'Alle';

  @override
  String get date => 'Datum';

  @override
  String get distance => 'Entfernung';

  @override
  String get deleteDrop => 'Abgabe löschen';

  @override
  String get areYouSureDelete => 'Möchten Sie diese Abgabe wirklich löschen?';

  @override
  String get createDrop => 'Abgabe erstellen';

  @override
  String get editDrop => 'Abgabe bearbeiten';

  @override
  String get startCollection => 'Sammlung starten';

  @override
  String get resumeNavigation => 'Navigation fortsetzen';

  @override
  String get cancelCollection => 'Sammlung abbrechen';

  @override
  String get areYouSureCancelCollection =>
      'Möchten Sie diese Sammlung wirklich abbrechen?';

  @override
  String get yesCancel => 'Ja, abbrechen';

  @override
  String get leaveCollection => 'Sammlung verlassen?';

  @override
  String get areYouSureLeaveCollection =>
      'Möchten Sie wirklich gehen? Ihre Sammlung bleibt aktiv.';

  @override
  String get exitNavigation => 'Navigation beenden';

  @override
  String get areYouSureExitNavigation =>
      'Möchten Sie die Navigation wirklich beenden? Ihre Sammlung bleibt aktiv.';

  @override
  String get reportDrop => 'Abgabe melden';

  @override
  String get useCurrentLocation => 'Aktuellen Standort verwenden';

  @override
  String get setCollectionRadius => 'Sammelradius festlegen';

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
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get chooseFromGallery => 'Aus Galerie wählen';

  @override
  String get galleryIOSSimulatorIssue => 'Galerie (iOS-Simulator-Problem)';

  @override
  String get useCameraOrRealDevice => 'Kamera oder echtes Gerät verwenden';

  @override
  String get leaveOutsideDoor => 'Vor der Tür lassen';

  @override
  String get pleaseTakePhoto => 'Bitte machen Sie ein Foto Ihrer Flaschen';

  @override
  String get pleaseWaitLoading =>
      'Bitte warten Sie, während wir Ihre Kontoinformationen laden';

  @override
  String get mustBeLoggedIn =>
      'Sie müssen angemeldet sein, um eine Abgabe zu erstellen';

  @override
  String get authenticationIssue =>
      'Authentifizierungsproblem erkannt. Bitte melden Sie sich ab und wieder an.';

  @override
  String get dropCreatedSuccessfully => 'Abgabe erfolgreich erstellt!';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get reloadMap => 'Karte neu laden';

  @override
  String get thisHelpsUsShowNearby =>
      'Dies hilft uns, nahegelegene Abgaben anzuzeigen und genaue Sammeldienste anzubieten.';

  @override
  String errorLoadingUserMode(String error) {
    return 'Fehler beim Laden des Benutzermodus: $error';
  }

  @override
  String get tryAdjustingFilters => 'Versuchen Sie, Ihre Filter anzupassen';

  @override
  String get checkBackLater => 'Schauen Sie später für neue Abgaben vorbei';

  @override
  String get createFirstDrop =>
      'Erstellen Sie Ihre erste Abgabe, um zu beginnen';

  @override
  String get collectionInProgress => 'Sammlung läuft';

  @override
  String get resumeCollection => 'Sammlung fortsetzen';

  @override
  String get collectionTimeout => '⚠️ Sammelzeitüberschreitung';

  @override
  String get warningSystem => 'Warnsystem';

  @override
  String get warningAddedToAccount =>
      'Ihrem Konto wurde für diese Abgabe eine Warnung hinzugefügt. Bitte stellen Sie sicher, dass zukünftige Bilder den Community-Richtlinien entsprechen.';

  @override
  String get timerExpired => '⏰ Timer abgelaufen!';

  @override
  String get timerExpiredMessage =>
      'Der Sammeltimer ist abgelaufen. Der Navigationsbildschirm wird jetzt geschlossen.';

  @override
  String get applicationRejected => 'Bewerbung abgelehnt';

  @override
  String applicationRejectedMessage(String reason) {
    return 'Ihre Bewerbung wurde aus folgendem Grund abgelehnt:';
  }

  @override
  String get noSpecificReason => 'Kein spezifischer Grund angegeben';

  @override
  String get canEditApplication =>
      'Sie können Ihre Bewerbung bearbeiten und erneut einreichen.';

  @override
  String get editApplication => 'Bewerbung bearbeiten';

  @override
  String get pleaseLogInCollector =>
      'Bitte melden Sie sich an, um auf den Sammler-Modus zuzugreifen';

  @override
  String get tierSystem => 'Stufensystem';

  @override
  String get bySubscribingAgree =>
      'Durch das Abonnieren stimmen Sie unseren Nutzungsbedingungen\nund unserer Datenschutzrichtlinie zu';

  @override
  String get startProSubscription => 'PRO-Abonnement starten';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get lastUpdated => 'Zuletzt aktualisiert: 15. März 2024';

  @override
  String get acceptanceOfTerms => '1. Annahme der Bedingungen';

  @override
  String get acceptanceOfTermsContent =>
      'Durch den Zugriff auf und die Nutzung der Bottleji-Anwendung stimmen Sie diesen Allgemeinen Geschäftsbedingungen zu. Wenn Sie mit einem Teil dieser Bedingungen nicht einverstanden sind, dürfen Sie nicht auf die Anwendung zugreifen.';

  @override
  String get userResponsibilities => '2. Benutzerverantwortlichkeiten';

  @override
  String get userResponsibilitiesContent =>
      'Als Benutzer von Bottleji stimmen Sie zu:\n• Genaue und vollständige Informationen bereitzustellen\n• Die Sicherheit Ihres Kontos zu gewährleisten\n• Den Richtlinien zur Abfalltrennung zu folgen\n• Sammlungen verantwortungsbewusst zu planen\n• Den Service in Übereinstimmung mit den örtlichen Gesetzen zu nutzen';

  @override
  String get household => 'Haushalt';

  @override
  String get collector => 'Sammler';

  @override
  String get activeMode => 'Aktiver Modus';

  @override
  String get myAccount => 'Mein Konto';

  @override
  String get trainings => 'Schulungen';

  @override
  String get referAndEarn => 'Weiterempfehlen und verdienen';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get review => 'Überprüfung';

  @override
  String get rejected => 'Abgelehnt';

  @override
  String get becomeACollector => 'Sammler werden';

  @override
  String get applicationUnderReview =>
      'Ihre Bewerbung wird derzeit überprüft. Möchten Sie den Status Ihrer Bewerbung anzeigen?';

  @override
  String get viewStatus => 'Status anzeigen';

  @override
  String applicationRejectedReason(String rejectionReason) {
    return 'Ihre Bewerbung wurde aus folgendem Grund abgelehnt:\n\n\"$rejectionReason\"\n\nMöchten Sie Ihre Bewerbung bearbeiten und erneut einreichen?';
  }

  @override
  String get applicationApprovedSuspended =>
      'Ihre Bewerbung wurde genehmigt, aber Ihr Sammlerzugang wurde vorübergehend gesperrt. Bitte kontaktieren Sie den Support oder bewerben Sie sich erneut.';

  @override
  String get reapply => 'Erneut bewerben';

  @override
  String get needToApplyCollector =>
      'Sie müssen sich bewerben und genehmigt werden, um auf den Sammler-Modus zuzugreifen. Möchten Sie sich jetzt bewerben?';

  @override
  String get applyNow => 'Jetzt bewerben';

  @override
  String get householdMode => 'Haushaltsmodus';

  @override
  String get collectorMode => 'Sammler-Modus';

  @override
  String get householdModeDescription =>
      'Abgaben erstellen und Ihr Recycling verfolgen';

  @override
  String get collectorModeDescription =>
      'Flaschen sammeln und Belohnungen verdienen';

  @override
  String get sustainableWasteManagement => 'Nachhaltige Abfallwirtschaft';

  @override
  String get ecoFriendlyBottleCollection =>
      'Umweltfreundliche Flaschensammlung';

  @override
  String get bottleType => 'Flaschentyp';

  @override
  String get numberOfPlasticBottles => 'Anzahl der Plastikflaschen';

  @override
  String get numberOfCans => 'Anzahl der Dosen';

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get notes => 'Notizen';

  @override
  String get failedToCreateDrop =>
      'Abgabe konnte nicht erstellt werden. Bitte versuchen Sie es erneut.';

  @override
  String get imageSelectedSuccessfully => 'Bild erfolgreich ausgewählt!';

  @override
  String get errorSelectingImage => 'Fehler beim Auswählen des Bildes';

  @override
  String get permissionDeniedPhoto =>
      'Berechtigung verweigert. Bitte erlauben Sie den Foto-Zugriff in den Einstellungen.';

  @override
  String get galleryNotAvailableSimulator =>
      'Galerie auf dem Simulator nicht verfügbar. Versuchen Sie die Kamera oder verwenden Sie ein echtes Gerät.';

  @override
  String get profileInformation => 'Profilinformationen';

  @override
  String get fullName => 'Vollständiger Name';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get phone => 'Telefon';

  @override
  String get address => 'Adresse';

  @override
  String get collectorStatus => 'Sammler-Status';

  @override
  String get approvedCollector => 'Sie sind ein genehmigter Sammler';

  @override
  String get applicationStatus => 'Bewerbungsstatus';

  @override
  String get applicationUnderReviewStatus => 'Ihre Bewerbung wird überprüft';

  @override
  String get viewDetails => 'Details anzeigen';

  @override
  String get applicationRejectedTitle => 'Bewerbung abgelehnt';

  @override
  String get pleaseLoginToViewProfile =>
      'Bitte melden Sie sich an, um Ihr Profil anzuzeigen';

  @override
  String get bottlejiRequiresPermissions =>
      'Bottleji benötigt zusätzliche Berechtigungen, um ordnungsgemäß zu funktionieren';

  @override
  String galleryError(String error) {
    return 'Galeriefehler: $error';
  }

  @override
  String galleryNotAvailableIOS(String error) {
    return 'Galerie auf iOS-Simulator nicht verfügbar: $error';
  }

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get completeYourProfile => 'Vervollständigen Sie Ihr Profil';

  @override
  String get profilePhoto => 'Profilfoto';

  @override
  String get personalInformation => 'Persönliche Informationen';

  @override
  String get tapToChangePhoto => 'Tippen Sie, um das Foto zu ändern';

  @override
  String get saving => 'Wird gespeichert...';

  @override
  String get completeSetup => 'Einrichtung abschließen';

  @override
  String get saveProfile => 'Profil speichern';

  @override
  String get phoneNumberRequired => 'Bitte geben Sie die Telefonnummer ein';

  @override
  String get phoneNumberMustBe8Digits =>
      'Telefonnummer muss 8 Ziffern enthalten';

  @override
  String get phoneNumberMustContainOnlyDigits =>
      'Telefonnummer darf nur Ziffern enthalten';

  @override
  String get pleaseEnterYourFullName =>
      'Bitte geben Sie Ihren vollständigen Namen ein';

  @override
  String get pleaseEnterYourPhoneNumber =>
      'Bitte geben Sie Ihre Telefonnummer ein';

  @override
  String get pleaseEnterYourAddress => 'Bitte geben Sie Ihre Adresse ein';

  @override
  String get pleaseVerifyYourPhoneNumber =>
      'Bitte verifizieren Sie Ihre Telefonnummer vor dem Speichern';

  @override
  String get noChangesDetected =>
      'Keine Änderungen erkannt. Profil bleibt unverändert.';

  @override
  String get profileSetupCompletedSuccessfully =>
      'Profil-Einrichtung erfolgreich abgeschlossen! Willkommen bei Bottleji!';

  @override
  String get profileUpdatedSuccessfully => 'Profil erfolgreich aktualisiert!';

  @override
  String failedToUploadImage(String error) {
    return 'Fehler beim Hochladen des Bildes: $error';
  }

  @override
  String get smsCode => 'SMS-Code';

  @override
  String get enter6DigitCode => '6-stelligen Code eingeben';

  @override
  String get sendCode => 'Code senden';

  @override
  String get sending => 'Wird gesendet...';

  @override
  String get verifyCode => 'Code verifizieren';

  @override
  String get verifying => 'Wird verifiziert...';

  @override
  String get phoneNumberVerified => 'Telefonnummer verifiziert';

  @override
  String get phoneNumberNotVerified => 'Telefonnummer nicht verifiziert';

  @override
  String get phoneNumberNeedsVerification =>
      'Telefonnummer muss verifiziert werden';

  @override
  String get phoneNumberVerifiedSuccessfully =>
      'Telefonnummer erfolgreich verifiziert!';

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get fullNameRequired => 'Vollständiger Name ist erforderlich';

  @override
  String get addressRequired => 'Adresse ist erforderlich';

  @override
  String get searchAddress => 'Adresse suchen';

  @override
  String get tapToSearchAddress =>
      'Tippen Sie, um nach Ihrer Adresse zu suchen';

  @override
  String get typeToSearch => 'Tippen Sie zum Suchen...';

  @override
  String get noResultsFound => 'Keine Ergebnisse gefunden';

  @override
  String errorFetchingSuggestions(String error) {
    return 'Fehler beim Abrufen von Vorschlägen: $error';
  }

  @override
  String get pleaseEnterPhoneNumberFirst =>
      'Bitte geben Sie zuerst eine Telefonnummer ein';

  @override
  String get pleaseEnterValidPhoneNumber =>
      'Bitte geben Sie eine gültige Telefonnummer mit Ländercode ein (z. B. +49 123456789)';

  @override
  String get locationPermissionRequired =>
      'Standortberechtigung ist für Adressfunktionen erforderlich';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get noNotificationsYet => 'Noch keine Benachrichtigungen';

  @override
  String get failedToLoadNotifications =>
      'Benachrichtigungen konnten nicht geladen werden';

  @override
  String get createNewDrop => 'Neue Abgabe erstellen';

  @override
  String get photo => 'Foto';

  @override
  String get takePhotoOrChooseFromGallery =>
      'Machen Sie ein Foto oder wählen Sie aus der Galerie - zeigen Sie Ihre Flaschen klar, um Sammlern zu helfen';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get cameraOrGallery => 'Kamera oder Galerie';

  @override
  String get allDrops => 'Alle Abgaben';

  @override
  String get myDrops => 'Meine Abgaben';

  @override
  String get active => 'Aktiv';

  @override
  String get collected => 'Gesammelt';

  @override
  String get flagged => 'MARKIERT';

  @override
  String get censored => 'Zensiert';

  @override
  String get stale => 'Abgelaufen';

  @override
  String get dropsInThisFilterCollected =>
      'Abgaben in diesem Filter wurden erfolgreich von einem Sammler gesammelt. Diese Abgaben zeigen Ihre Recycling-Wirkung und können nicht bearbeitet werden.';

  @override
  String get dropsInThisFilterFlagged =>
      'Abgaben in diesem Filter wurden aufgrund mehrerer Stornierungen oder verdächtiger Aktivitäten markiert. Markierte Abgaben sind auf der Karte ausgeblendet und können nicht bearbeitet werden.';

  @override
  String get dropsInThisFilterCensored =>
      'Abgaben in diesem Filter wurden aufgrund unangemessener Inhalte zensiert. Zensierte Abgaben sind auf der Karte ausgeblendet und können nicht bearbeitet werden.';

  @override
  String get dropsInThisFilterStale =>
      'Abgaben in diesem Filter wurden als abgelaufen markiert, da sie älter als 3 Tage waren und wahrscheinlich von externen Sammlern gesammelt wurden. Abgelaufene Abgaben sind auf der Karte ausgeblendet und können nicht bearbeitet werden.';

  @override
  String get inActiveCollection =>
      'In aktiver Sammlung - Sammler ist unterwegs';

  @override
  String censoredInappropriateImage(String reason) {
    return 'Zensiert: $reason';
  }

  @override
  String get onTheWay => 'Unterwegs';

  @override
  String get collectorOnHisWay =>
      'Der Sammler ist auf dem Weg, um Ihre Abgabe abzuholen';

  @override
  String get waiting => 'Warten...';

  @override
  String get notYetCollected => 'Noch nicht gesammelt';

  @override
  String get yourPoints => 'Ihre Punkte';

  @override
  String pointsToGo(int points) {
    return '$points Punkte verbleibend';
  }

  @override
  String get progressToNextTier => 'Fortschritt zur nächsten Stufe';

  @override
  String get bronzeCollector => 'Bronze-Sammler';

  @override
  String get silverCollector => 'Silber-Sammler';

  @override
  String get goldCollector => 'Gold-Sammler';

  @override
  String get platinumCollector => 'Platin-Sammler';

  @override
  String get diamondCollector => 'Diamant-Sammler';

  @override
  String earnPointsPerDropCollected(int points) {
    return 'Verdienen Sie $points Punkte pro gesammelte Abgabe';
  }

  @override
  String earnPointsWhenDropsCollected(int points) {
    return 'Verdienen Sie $points Punkte, wenn Ihre Abgaben gesammelt werden';
  }

  @override
  String get rewardShop => 'Belohnungsshop';

  @override
  String get orderHistory => 'Bestellverlauf';

  @override
  String get noOrdersYet => 'Noch keine Bestellungen';

  @override
  String get yourOrderHistoryWillAppearHere =>
      'Ihr Bestellverlauf wird hier angezeigt';

  @override
  String get notEnoughPoints => 'Nicht genug Punkte';

  @override
  String get pts => 'Pkt';

  @override
  String get myStats => 'Meine Statistiken';

  @override
  String get timeRange => 'Zeitraum';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisMonth => 'Diesen Monat';

  @override
  String get thisYear => 'Dieses Jahr';

  @override
  String get allTime => 'Gesamte Zeit';

  @override
  String get overview => 'Übersicht';

  @override
  String get dropStatus => 'Abgabe-Status';

  @override
  String get pending => 'Ausstehend';

  @override
  String get collectionRate => 'Sammelrate';

  @override
  String get avgCollectionTime => 'Durchschnittliche Sammelzeit';

  @override
  String get recentCollections => 'Letzte Sammlungen';

  @override
  String get supportAndHelp => 'Support & Hilfe';

  @override
  String get howCanWeHelpYou => 'Wie können wir Ihnen helfen?';

  @override
  String get selectCategoryToGetStarted =>
      'Wählen Sie eine Kategorie, um zu beginnen';

  @override
  String get supportCategories => 'Support-Kategorien';

  @override
  String get whatDoYouNeedHelpWith => 'Wobei brauchen Sie Hilfe?';

  @override
  String get selectCategoryToContinue =>
      'Wählen Sie eine Kategorie, um fortzufahren';

  @override
  String get trainingCenter => 'Schulungszentrum';

  @override
  String todayAt(String time) {
    return 'Heute um $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Gestern um $time';
  }

  @override
  String daysAgo(int days) {
    return 'vor $days T';
  }

  @override
  String get leaveOutside => 'Draußen lassen';

  @override
  String get noImageAvailable => 'Kein Bild verfügbar';

  @override
  String get estTime => 'Geschätzte Zeit';

  @override
  String get estimatedTime => 'Geschätzte Ankunftszeit';

  @override
  String get yourLocation => 'Ihr Standort';

  @override
  String get dropLocation => 'Abgabe-Standort';

  @override
  String get routePreview => 'Routen-Vorschau';

  @override
  String get dropInformation => 'Abgabe-Informationen';

  @override
  String get plasticBottles => 'Plastikflaschen';

  @override
  String get cans => 'Dosen';

  @override
  String get plastic => 'Kunststoff';

  @override
  String get can => 'DOSE';

  @override
  String get mixed => 'Gemischt';

  @override
  String get totalItems => 'Gesamtartikel';

  @override
  String get estimatedValue => 'Geschätzter Wert';

  @override
  String get created => 'Erstellt';

  @override
  String get completeCurrentCollectionFirst =>
      'Schließen Sie Ihre aktuelle Sammlung ab, bevor Sie eine neue starten.';

  @override
  String get youAreOffline =>
      'Sie sind offline. Bitte überprüfen Sie Ihre Internetverbindung.';

  @override
  String errorColon(String error) {
    return 'Fehler: $error';
  }

  @override
  String get yourInformation => 'Ihre Informationen';

  @override
  String get createdBy => 'Erstellt von';

  @override
  String get youWillSeeNotificationsHere =>
      'Sie sehen Ihre Benachrichtigungen hier';

  @override
  String get pendingStatus => 'AUSSTEHEND';

  @override
  String get acceptedStatus => 'AKZEPTIERT';

  @override
  String get collectedStatus => 'GESAMMELT';

  @override
  String get cancelledStatus => 'STORNIERT';

  @override
  String get expiredStatus => 'ABGELAUFEN';

  @override
  String get staleStatus => 'VERALTET';

  @override
  String get howRewardsWork => 'Wie Belohnungen funktionieren';

  @override
  String get howRewardsWorkCollector =>
      '• Sammeln Sie Abgaben, um Punkte zu verdienen\n• Höhere Stufen = mehr Punkte pro Abgabe\n• Verwenden Sie Punkte im Belohnungsshop\n• Verfolgen Sie Ihren Fortschritt und Ihre Erfolge';

  @override
  String get howRewardsWorkHousehold =>
      '• Erstellen Sie Abgaben, um zum Recycling beizutragen\n• Verdienen Sie Punkte, wenn Sammler Ihre Abgaben abholen\n• Höhere Stufen = mehr Punkte pro gesammelte Abgabe\n• Verwenden Sie Punkte im Belohnungsshop';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get itemNotAvailable => 'Artikel ist nicht verfügbar';

  @override
  String get outOfStock => 'Nicht vorrätig';

  @override
  String get orderNow => 'Jetzt bestellen';

  @override
  String get pleaseLogInToViewOrderHistory =>
      'Bitte melden Sie sich an, um die Bestellhistorie anzuzeigen';

  @override
  String get failedToLoadOrderHistory =>
      'Laden der Bestellhistorie fehlgeschlagen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get pointsSpent => 'Ausgegebene Punkte';

  @override
  String get size => 'Größe';

  @override
  String get orderDate => 'Bestelldatum';

  @override
  String get tracking => 'Verfolgung';

  @override
  String get estimatedDelivery => 'Geschätzte Lieferung';

  @override
  String get deliveryAddress => 'Lieferadresse';

  @override
  String get adminNote => 'Admin-Hinweis';

  @override
  String get approved => 'Genehmigt';

  @override
  String get processing => 'In Bearbeitung';

  @override
  String get shipped => 'Versandt';

  @override
  String get delivered => 'Geliefert';

  @override
  String get cancelled => 'Abgebrochen';

  @override
  String available(int count) {
    return '$count verfügbar';
  }

  @override
  String get updateDrop => 'Abgabe aktualisieren';

  @override
  String get updating => 'Aktualisierung...';

  @override
  String get recyclingImpact => 'Recycling-Auswirkung';

  @override
  String get recentDrops => 'Letzte Abgaben';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get dropStatusDistribution => 'Abgabe-Status';

  @override
  String get co2VolumeSaved => 'CO₂-Volumen gespart';

  @override
  String totalCo2Saved(String amount) {
    return 'Gesamt CO₂ gespart: $amount kg';
  }

  @override
  String get dropActivity => 'Abgabe-Aktivität';

  @override
  String dropsCreated(String timeRange, int count) {
    return 'Abgaben erstellt ($timeRange): $count';
  }

  @override
  String errorPickingImage(String error) {
    return 'Fehler beim Auswählen des Bildes: $error';
  }

  @override
  String get dropUpdatedSuccessfully => 'Abgabe erfolgreich aktualisiert!';

  @override
  String errorUpdatingDrop(String error) {
    return 'Fehler beim Aktualisieren der Abgabe: $error';
  }

  @override
  String get areYouSureDeleteDrop =>
      'Sind Sie sicher, dass Sie diese Abgabe löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get dropDeletedSuccessfully => 'Abgabe erfolgreich gelöscht!';

  @override
  String errorDeletingDrop(String error) {
    return 'Fehler beim Löschen der Abgabe: $error';
  }

  @override
  String get pleaseEnterNumberOfBottles =>
      'Bitte geben Sie die Anzahl der Flaschen ein';

  @override
  String get pleaseEnterValidNumber => 'Bitte geben Sie eine gültige Zahl ein';

  @override
  String get pleaseEnterNumberOfCans =>
      'Bitte geben Sie die Anzahl der Dosen ein';

  @override
  String get anyAdditionalInstructions =>
      'Zusätzliche Anweisungen für den Sammler...';

  @override
  String get collectorCanLeaveOutside =>
      'Sammler kann Artikel draußen lassen, wenn niemand zu Hause ist';

  @override
  String get loadingAddress => 'Adresse wird geladen...';

  @override
  String locationFormat(String lat, String lng) {
    return 'Standort: $lat, $lng';
  }

  @override
  String get locationSelected => 'Standort ausgewählt';

  @override
  String get currentDropLocation => 'Aktueller Abgabe-Standort';

  @override
  String get tapConfirmToSetLocation =>
      'Tippen Sie auf \"Bestätigen\", um diesen Standort festzulegen';

  @override
  String get userNotFound => 'Benutzer nicht gefunden';

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
  String get collectorApplication => 'Sammler-Bewerbung';

  @override
  String get applied => 'Applied';

  @override
  String get items => 'items';

  @override
  String get drop => 'Drop';

  @override
  String get collection => 'Collection';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get justNow => 'Gerade eben';

  @override
  String hoursAgo(int hours) {
    return 'vor $hours Std';
  }

  @override
  String minutesAgo(int minutes) {
    return 'vor $minutes Min';
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
  String get description => 'Beschreibung';

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
      'Sammlung erfolgreich abgeschlossen';

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
  String get noAccess => 'Kein Zugang';

  @override
  String get notFound => 'Nicht gefunden';

  @override
  String get alreadyCollected => 'Bereits gesammelt';

  @override
  String get wrongLocation => 'Falscher Standort';

  @override
  String get unsafeLocation => 'Unsicherer Standort';

  @override
  String get other => 'Andere';

  @override
  String get cancellationReasons => 'Stornierungsgründe';

  @override
  String get cancellationReason => 'Stornierungsgrund';

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
  String orderRejectedPointsRefunded(int points) {
    return '$points points have been refunded to your account.';
  }

  @override
  String orderApprovedBeingPrepared(String trackingNumber) {
    return 'Ihre Bestellung wurde genehmigt und wird für den Versand vorbereitet. Tracking: $trackingNumber';
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
  String get gettingStarted => 'Erste Schritte';

  @override
  String get advancedFeatures => 'Erweiterte Funktionen';

  @override
  String get troubleshooting => 'Fehlerbehebung';

  @override
  String get bestPractices => 'Bewährte Praktiken';

  @override
  String get payments => 'Zahlungen';

  @override
  String get help => 'Hilfe';

  @override
  String get advanced => 'Erweitert';

  @override
  String get story => 'Geschichte';

  @override
  String get totalDrops => 'Gesamte Drops';

  @override
  String get aluminumCans => 'Aluminiumdosen';

  @override
  String get recycled => 'Recycelt';

  @override
  String recycledBottles(String count) {
    return '$count Flaschen recycelt';
  }

  @override
  String recycledCans(String count) {
    return '$count Dosen recycelt';
  }

  @override
  String get totalItemsRecycled => 'Gesamte Recycelte Artikel';

  @override
  String get dropsCollected => 'Gesammelte Drops';

  @override
  String get monday => 'Mo';

  @override
  String get tuesday => 'Di';

  @override
  String get wednesday => 'Mi';

  @override
  String get thursday => 'Do';

  @override
  String get friday => 'Fr';

  @override
  String get saturday => 'Sa';

  @override
  String get sunday => 'So';

  @override
  String get january => 'Jan';

  @override
  String get february => 'Feb';

  @override
  String get march => 'Mär';

  @override
  String get april => 'Apr';

  @override
  String get may => 'Mai';

  @override
  String get june => 'Jun';

  @override
  String get july => 'Jul';

  @override
  String get august => 'Aug';

  @override
  String get september => 'Sep';

  @override
  String get october => 'Okt';

  @override
  String get november => 'Nov';

  @override
  String get december => 'Dez';

  @override
  String get todaysTotal => 'Gesamt heute';

  @override
  String get earnings => 'Verdienste';

  @override
  String get collections => 'Sammlungen';

  @override
  String get noEarningsHistoryYet => 'Noch kein Verdienstverlauf';

  @override
  String get earningsWillAppearHere =>
      'Ihre Verdienste werden hier angezeigt, sobald Sie Sammlungen abgeschlossen haben';

  @override
  String get totalEarnings => 'Gesamtverdienste';

  @override
  String errorLoadingEarnings(String error) {
    return 'Fehler beim Laden der Verdienste: $error';
  }

  @override
  String get noCompletedCollectionsYet =>
      'Noch keine abgeschlossenen Sammlungen';

  @override
  String get performanceMetrics => 'Leistungsmetriken';

  @override
  String get expired => 'Abgelaufen';

  @override
  String get collectionsOverTime => 'Sammlungen im Zeitverlauf';

  @override
  String get expiredOverTime => 'Abgelaufen im Zeitverlauf';

  @override
  String get cancelledOverTime => 'Abgebrochen im Zeitverlauf';

  @override
  String get totalThisWeek => 'gesamt diese Woche';

  @override
  String get totalThisMonth => 'gesamt diesen Monat';

  @override
  String get totalThisYear => 'gesamt dieses Jahr';

  @override
  String get mon => 'Mo';

  @override
  String get tue => 'Di';

  @override
  String get wed => 'Mi';

  @override
  String get thu => 'Do';

  @override
  String get fri => 'Fr';

  @override
  String get sat => 'Sa';

  @override
  String get sun => 'So';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mär';

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
  String get oct => 'Okt';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dez';

  @override
  String daysAgoShort(int days) {
    return 'vor $days T';
  }

  @override
  String get at => 'um';

  @override
  String get total => 'Gesamt';

  @override
  String get noDropsCreatedYet => 'Noch keine Abgaben erstellt';

  @override
  String get createYourFirstDropToGetStarted =>
      'Erstellen Sie Ihre erste Abgabe, um zu beginnen';

  @override
  String get noActiveDrops => 'Keine aktiven Abgaben';

  @override
  String get noCollectedDrops => 'Noch keine gesammelten Abgaben';

  @override
  String get noStaleDrops => 'Keine abgelaufenen Abgaben';

  @override
  String get noCensoredDrops => 'Keine zensierten Abgaben';

  @override
  String get noFlaggedDrops => 'Keine markierten Abgaben';

  @override
  String get noDropsMatchYourFilters =>
      'Keine Abgaben entsprechen Ihren Filtern';

  @override
  String get tryAdjustingYourFilters => 'Versuchen Sie, Ihre Filter anzupassen';

  @override
  String get noDropsAvailable => 'Keine Abgaben verfügbar';

  @override
  String get checkBackLaterForNewDrops =>
      'Schauen Sie später nach neuen Abgaben';

  @override
  String get note => 'Hinweis';

  @override
  String get outside => 'Draußen';

  @override
  String get last7Days => 'Letzte 7 Tage';

  @override
  String get last30Days => 'Letzte 30 Tage';

  @override
  String get lastMonth => 'Letzten Monat';

  @override
  String get within1Km => 'Innerhalb von 1 km';

  @override
  String get within3Km => 'Innerhalb von 3 km';

  @override
  String get within5Km => 'Innerhalb von 5 km';

  @override
  String get within10Km => 'Innerhalb von 10 km';

  @override
  String get rewardHistory => 'Belohnungsverlauf';

  @override
  String get noRewardHistoryYet => 'Noch kein Belohnungsverlauf';

  @override
  String get points => 'Punkte';

  @override
  String get tier => 'Stufe';

  @override
  String get tierUp => 'Stufe aufgestiegen!';

  @override
  String get acceptDrop => 'Abgabe akzeptieren';

  @override
  String get completeCurrentDropFirst => 'Aktuelle Abgabe zuerst abschließen';

  @override
  String get distanceUnavailable => 'Entfernung nicht verfügbar';

  @override
  String get away => 'entfernt';

  @override
  String get meters => 'm';

  @override
  String get minutesShort => 'Min';

  @override
  String get hoursShort => 'Std';

  @override
  String get current => 'Aktuell';

  @override
  String earnPointsPerDrop(int points) {
    return 'Verdienen Sie $points Punkte pro Abgabe';
  }

  @override
  String dropsRequired(int count) {
    return '$count Abgaben erforderlich';
  }

  @override
  String get start => 'Starten';

  @override
  String get filterHistory => 'Verlauf filtern';

  @override
  String get searchHistory => 'Verlauf durchsuchen';

  @override
  String get searchByNotesBottleTypeOrCancellationReason =>
      'Nach Notizen, Flaschentyp oder Stornierungsgrund suchen...';

  @override
  String get viewType => 'Ansichtstyp';

  @override
  String get itemType => 'Artikeltyp';

  @override
  String get last3Months => 'Letzte 3 Monate';

  @override
  String get last6Months => 'Letzte 6 Monate';

  @override
  String get allItems => 'Alle Artikel';

  @override
  String get bottlesOnly => 'Nur Flaschen';

  @override
  String get cansOnly => 'Nur Dosen';

  @override
  String get allTypes => 'Alle Typen';

  @override
  String get activeFilters => 'AKTIV';

  @override
  String get waitingForCollector => 'Warten auf Sammler';

  @override
  String get liveCollectorOnTheWay => '🟢 Live - Sammler unterwegs';

  @override
  String get collectorWasOnTheWay => 'Der Sammler war unterwegs';

  @override
  String get wasOnTheWay => 'War unterwegs';

  @override
  String get accepted => 'Akzeptiert';

  @override
  String get sessionTime => 'Sitzungszeit';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get pleaseLoginToViewYourDrops =>
      'Bitte melden Sie sich an, um Ihre Abgaben anzuzeigen';

  @override
  String errorLoadingUserData(String error) {
    return 'Fehler beim Laden der Benutzerdaten: $error';
  }

  @override
  String get earn500Points => '500 Punkte verdienen';

  @override
  String get forEachFriendWhoJoins => 'Für jeden Freund, der beitritt';

  @override
  String get yourReferralCode => 'Ihr Empfehlungscode';

  @override
  String get referralCodeCopiedToClipboard =>
      'Empfehlungscode in die Zwischenablage kopiert';

  @override
  String get shareVia => 'Teilen über';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get sms => 'SMS';

  @override
  String get more => 'Mehr';

  @override
  String get howItWorks => 'So funktioniert\'s';

  @override
  String get shareYourCode => 'Teilen Sie Ihren Code';

  @override
  String get shareYourUniqueReferralCodeWithFriends =>
      'Teilen Sie Ihren eindeutigen Empfehlungscode mit Freunden';

  @override
  String get friendSignsUp => 'Freund meldet sich an';

  @override
  String get yourFriendCreatesAnAccountUsingYourCode =>
      'Ihr Freund erstellt ein Konto mit Ihrem Code';

  @override
  String get earnRewards => 'Belohnungen verdienen';

  @override
  String get get500PointsWhenTheyCompleteFirstActivity =>
      'Erhalten Sie 500 Punkte, wenn sie ihre erste Aktivität abschließen';

  @override
  String get trainingCenterInfo => 'Schulungszentrum';

  @override
  String get trainingCenterInfoHousehold =>
      'Zugriff auf Schulungsinhalte für Haushaltsbenutzer. Lernen Sie, Botleji effektiv zu nutzen!';

  @override
  String get trainingCenterInfoCollector =>
      'Zugriff auf Schulungsinhalte für Sammler. Meistern Sie Sammeltechniken und Best Practices!';

  @override
  String get filter => 'Filtern';

  @override
  String get search => 'Suchen';

  @override
  String get clear => 'Löschen';

  @override
  String get glass => 'Glas';

  @override
  String get aluminum => 'Aluminium';

  @override
  String get dropProgress => 'Abgabe-Fortschritt';

  @override
  String get collectionIssues => 'Sammelprobleme';

  @override
  String cancelledTimes(int count) {
    return '$count Mal storniert';
  }

  @override
  String get dropAcceptedByCollector => 'Abgabe vom Sammler akzeptiert';

  @override
  String get acceptedDropForCollection => 'Abgabe zur Sammlung akzeptiert';

  @override
  String get applicationIssue => 'Antragsproblem';

  @override
  String get paymentIssue => 'Zahlungsproblem';

  @override
  String get accountIssue => 'Kontoproblem';

  @override
  String get technicalIssue => 'Technisches Problem';

  @override
  String get generalSupportRequest => 'Allgemeine Supportanfrage';

  @override
  String get supportRequest => 'Supportanfrage';

  @override
  String get noDescriptionProvided => 'Keine Beschreibung angegeben';

  @override
  String get welcome => 'Willkommen';

  @override
  String get idVerification => 'ID-Verifizierung';

  @override
  String get selfieWithId => 'Selfie mit Ausweis';

  @override
  String get reviewAndSubmit => 'Überprüfen und einreichen';

  @override
  String get welcomeToCollectorProgram => 'Willkommen im Sammlerprogramm!';

  @override
  String get joinOurCommunityOfEcoConsciousCollectors =>
      'Treten Sie unserer Gemeinschaft umweltbewusster Sammler bei und helfen Sie mit, beim Recycling einen Unterschied zu machen.';

  @override
  String get earnMoney => 'Geld verdienen';

  @override
  String get getPaidForEveryBottleAndCan =>
      'Werden Sie für jede Flasche und Dose bezahlt, die Sie sammeln';

  @override
  String get flexibleHours => 'Flexible Arbeitszeiten';

  @override
  String get collectWheneverAndWherever =>
      'Sammeln Sie wann und wo Sie möchten';

  @override
  String get helpTheEnvironment => 'Helfen Sie der Umwelt';

  @override
  String get contributeToCleanerGreenerWorld =>
      'Tragen Sie zu einer saubereren, grüneren Welt bei';

  @override
  String get requirements => 'Anforderungen';

  @override
  String get mustBe18YearsOrOlder => '• Muss 18 Jahre oder älter sein';

  @override
  String get validNationalIdCard => '• Gültiger Personalausweis';

  @override
  String get clearPhotosOfIdAndSelfie =>
      '• Klare Fotos des Ausweises und Selfie';

  @override
  String get goodStandingInCommunity => '• Guter Ruf in der Gemeinschaft';

  @override
  String get idCardVerification => 'Personalausweis-Verifizierung';

  @override
  String pleaseProvideYourIdCardInformation(String idType) {
    return 'Bitte geben Sie Ihre $idType-Informationen an und machen Sie klare Fotos';
  }

  @override
  String get idCardDetails => 'Personalausweis-Details';

  @override
  String get passportDetails => 'Reisepass-Details';

  @override
  String get idCardType => 'Personalausweis-Typ';

  @override
  String get selectYourIdCardType => 'Wählen Sie Ihren Personalausweis-Typ';

  @override
  String get nationalId => 'Personalausweis';

  @override
  String get passport => 'Reisepass';

  @override
  String get pleaseSelectAnIdCardType =>
      'Bitte wählen Sie einen Personalausweis-Typ';

  @override
  String get passportNumber => 'Reisepassnummer';

  @override
  String get enterYourPassportNumber => 'Geben Sie Ihre Reisepassnummer ein';

  @override
  String get selectIssueDate => 'Ausstellungsdatum auswählen';

  @override
  String get issueDateLabel => 'Ausstellungsdatum';

  @override
  String issueDate(String date) {
    return 'Ausstellungsdatum: $date';
  }

  @override
  String get selectExpiryDate => 'Ablaufdatum auswählen';

  @override
  String get expiryDateLabel => 'Ablaufdatum';

  @override
  String expiryDate(String date) {
    return 'Ablaufdatum: $date';
  }

  @override
  String get issuingAuthority => 'Ausstellende Behörde';

  @override
  String get egMinistryOfForeignAffairs => 'z.B. Außenministerium';

  @override
  String get idCardNumber => 'Personalausweisnummer';

  @override
  String get idCardNumberPlaceholder => '12345678';

  @override
  String get idCardNumberIsRequired => 'Personalausweisnummer ist erforderlich';

  @override
  String get idCardNumberMustBe8Digits =>
      'Personalausweisnummer muss 8 Ziffern enthalten';

  @override
  String get idCardNumberMustContainOnlyDigits =>
      'Personalausweisnummer darf nur Ziffern enthalten';

  @override
  String get idCardPhotos => 'Personalausweis-Fotos';

  @override
  String get passportPhotos => 'Reisepass-Fotos';

  @override
  String get noPassportMainPagePhoto =>
      'Kein Foto der Hauptseite des Reisepasses';

  @override
  String get takePhotoOfMainPageWithDetails =>
      'Machen Sie ein Foto der Hauptseite mit Ihren Daten';

  @override
  String get retakePhoto => 'Foto erneut aufnehmen';

  @override
  String get takePassportMainPagePhoto =>
      'Foto der Hauptseite des Reisepasses aufnehmen';

  @override
  String get noIdCardFrontPhoto =>
      'Kein Foto der Vorderseite des Personalausweises';

  @override
  String get takePhotoOfFrontOfIdCard =>
      'Machen Sie ein Foto der Vorderseite Ihres Personalausweises';

  @override
  String get retakeFrontPhoto => 'Foto der Vorderseite erneut aufnehmen';

  @override
  String get takeIdCardFrontPhoto =>
      'Foto der Vorderseite des Personalausweises aufnehmen';

  @override
  String get noIdCardBackPhoto =>
      'Kein Foto der Rückseite des Personalausweises';

  @override
  String get takePhotoOfBackOfIdCard =>
      'Machen Sie ein Foto der Rückseite Ihres Personalausweises';

  @override
  String get retakeBackPhoto => 'Foto der Rückseite erneut aufnehmen';

  @override
  String get takeIdCardBackPhoto =>
      'Foto der Rückseite des Personalausweises aufnehmen';

  @override
  String get continueButton => 'Weiter';

  @override
  String get selfieWithIdCard => 'Selfie mit Personalausweis';

  @override
  String get pleaseTakeSelfieWhileHoldingId =>
      'Bitte machen Sie ein Selfie, während Sie Ihren Personalausweis neben Ihr Gesicht halten';

  @override
  String get noSelfiePhoto => 'Kein Selfie-Foto';

  @override
  String get takeSelfie => 'Selfie aufnehmen';

  @override
  String get reviewAndSubmitTitle => 'Überprüfen und einreichen';

  @override
  String get pleaseReviewYourApplication =>
      'Bitte überprüfen Sie Ihre Bewerbung vor der Einreichung';

  @override
  String get idCardInformation => 'Personalausweis-Informationen';

  @override
  String get idType => 'ID-Typ';

  @override
  String get idNumber => 'ID-Nummer';

  @override
  String get notProvided => 'Nicht angegeben';

  @override
  String get idCard => 'Personalausweis';

  @override
  String get selfie => 'Selfie';

  @override
  String get whatHappensNext => 'Was passiert als Nächstes?';

  @override
  String get applicationReviewProcess =>
      '• Ihre Bewerbung wird von unserem Team überprüft\n• Die Überprüfung dauert normalerweise 1-3 Werktage\n• Sie erhalten eine Benachrichtigung nach der Überprüfung\n• Wenn genehmigt, können Sie sofort mit dem Sammeln beginnen';

  @override
  String get submitting => 'Wird eingereicht...';

  @override
  String get submitApplication => 'Bewerbung einreichen';

  @override
  String get pleaseTakeBothPhotosBeforeSubmitting =>
      'Bitte machen Sie beide Fotos vor der Einreichung';

  @override
  String get pleaseFillInAllRequiredPassportInformation =>
      'Bitte füllen Sie alle erforderlichen Reisepass-Informationen aus';

  @override
  String get pleaseFillInAllRequiredIdCardInformation =>
      'Bitte füllen Sie alle erforderlichen Personalausweis-Informationen aus (ID-Nummer und Typ)';

  @override
  String get applicationUpdatedSuccessfully =>
      'Bewerbung erfolgreich aktualisiert!';

  @override
  String get applicationSubmittedSuccessfully =>
      'Bewerbung erfolgreich eingereicht!';

  @override
  String errorSubmittingApplication(String error) {
    return 'Fehler beim Einreichen der Bewerbung: $error';
  }

  @override
  String get errorLoadingApplication => 'Fehler beim Laden der Bewerbung';

  @override
  String get noApplicationFound => 'Keine Bewerbung gefunden';

  @override
  String get youHaventSubmittedApplicationYet =>
      'Sie haben noch keine Sammler-Bewerbung eingereicht.';

  @override
  String get pendingReview => 'Ausstehende Überprüfung';

  @override
  String get yourApplicationIsBeingReviewed =>
      'Ihre Bewerbung wird von unserem Team überprüft.';

  @override
  String get congratulationsApplicationApproved =>
      'Herzlichen Glückwunsch! Ihre Bewerbung wurde genehmigt.';

  @override
  String get applicationNotApprovedCanApplyAgain =>
      'Ihre Bewerbung wurde nicht genehmigt. Sie können sich erneut bewerben.';

  @override
  String get applicationStatusUnknown => 'Der Bewerbungsstatus ist unbekannt.';

  @override
  String get applicationDetails => 'Bewerbungsdetails';

  @override
  String get applicationId => 'Bewerbungs-ID';

  @override
  String get notSpecified => 'Nicht angegeben';

  @override
  String get appliedOn => 'Beworben am';

  @override
  String get reviewedOn => 'Überprüft am';

  @override
  String get rejectionReason => 'Ablehnungsgrund';

  @override
  String get reviewNotes => 'Überprüfungsnotizen';

  @override
  String get applyAgain => 'Erneut bewerben';

  @override
  String get applicationInReview => 'Bewerbung in Überprüfung';

  @override
  String get applicationInReviewDialogContent =>
      'Ihre Bewerbung wird derzeit von unserem Team überprüft. Dieser Prozess dauert normalerweise 1-3 Werktage. Sie werden benachrichtigt, sobald eine Entscheidung getroffen wurde.';

  @override
  String get reviewProcess => 'Überprüfungsprozess';

  @override
  String get tapToRedeem => 'Tippen zum Einlösen';

  @override
  String get confirmOrder => 'Bestellung bestätigen';

  @override
  String get placeOrder => 'Bestellung aufgeben';

  @override
  String get availability => 'Verfügbarkeit';

  @override
  String get streetAddress => 'Straßenadresse';

  @override
  String get streetAddressRequired => 'Bitte geben Sie die Straßenadresse ein';

  @override
  String get city => 'Stadt';

  @override
  String get cityRequired => 'Bitte geben Sie die Stadt ein';

  @override
  String get state => 'Bundesland/Provinz';

  @override
  String get stateRequired => 'Bitte geben Sie das Bundesland/die Provinz ein';

  @override
  String get zipCode => 'Postleitzahl';

  @override
  String get zipCodeRequired => 'Bitte geben Sie die Postleitzahl ein';

  @override
  String get country => 'Land';

  @override
  String get countryRequired => 'Bitte geben Sie das Land ein';

  @override
  String get additionalNotes => 'Zusätzliche Hinweise (optional)';

  @override
  String get additionalNotesHint => 'Besondere Lieferanweisungen...';

  @override
  String get sizeSelection => 'Größenauswahl';

  @override
  String get footwear => 'Schuhe';

  @override
  String get jackets => 'Jacken';

  @override
  String get bottoms => 'Hosen';

  @override
  String get pleaseSelectSize =>
      'Bitte wählen Sie eine Größe für diesen Artikel';

  @override
  String get thisItemNotAvailableForRedemption =>
      'Dieser Artikel ist nicht zum Einlösen verfügbar.';

  @override
  String get thisItemOutOfStock => 'Dieser Artikel ist nicht vorrätig.';

  @override
  String get youDontHaveEnoughPointsToRedeem =>
      'Sie haben nicht genug Punkte, um diesen Artikel einzulösen.';

  @override
  String get cannotRedeemThisItem =>
      'Dieser Artikel kann nicht eingelöst werden.';

  @override
  String orderPlacedSuccessfully(String itemName) {
    return 'Bestellung erfolgreich aufgegeben! $itemName wartet auf Genehmigung.';
  }

  @override
  String failedToPlaceOrder(String error) {
    return 'Bestellung fehlgeschlagen: $error';
  }

  @override
  String orderNowPoints(int points) {
    return 'Jetzt bestellen - $points Punkte';
  }

  @override
  String yourPointsValue(int points) {
    return 'Ihre Punkte: $points';
  }

  @override
  String get pointsLabel => 'Punkte:';

  @override
  String get sizeLabel => 'Größe:';

  @override
  String get orderDateLabel => 'Bestelldatum:';

  @override
  String get statusLabel => 'Status:';

  @override
  String get orderPendingApproval =>
      'Ihre Bestellung wartet auf Genehmigung. Sie werden benachrichtigt, sobald sie überprüft wurde.';

  @override
  String get noRewardsAvailable => 'Keine Belohnungen verfügbar';

  @override
  String get checkBackLaterForRewards =>
      'Schauen Sie später vorbei für aufregende Belohnungen!';

  @override
  String get streetAddressHint => '123 Hauptstraße';

  @override
  String get cityHint => 'Berlin';

  @override
  String get stateHint => 'Berlin';

  @override
  String get zipCodeHint => '10115';

  @override
  String get countryHint => 'Deutschland';

  @override
  String get phoneNumberHint => '+49 30 12345678';

  @override
  String get orderSuccessTitle => 'Bestellung erfolgreich aufgegeben!';

  @override
  String orderSuccessMessage(String itemName) {
    return 'Ihre Bestellung für $itemName wurde aufgegeben und wartet auf Genehmigung.';
  }

  @override
  String get viewOrderHistory => 'Bestellverlauf anzeigen';

  @override
  String get continueShopping => 'Weiter einkaufen';
}
