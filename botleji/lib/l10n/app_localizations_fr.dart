// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Bottleji';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get changeLanguage => 'Changer la langue de l\'application';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get english => 'Anglais';

  @override
  String get french => 'Français';

  @override
  String get german => 'Allemand';

  @override
  String get arabic => 'Arabe';

  @override
  String get location => 'Emplacement';

  @override
  String get manageLocationPreferences =>
      'Gérer les préférences de localisation';

  @override
  String get notifications => 'Notifications';

  @override
  String get manageNotificationPreferences =>
      'Gérer les préférences de notifications';

  @override
  String get displayTheme => 'Thème d\'affichage';

  @override
  String get changeAppAppearance => 'Changer l\'apparence de l\'application';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get loading => 'Chargement...';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get welcomeBack => 'Bon retour !';

  @override
  String get signInToContinue => 'Connectez-vous pour continuer';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get enterYourEmail => 'Entrez votre e-mail';

  @override
  String get enterYourPassword => 'Entrez votre mot de passe';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer un mot de passe';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get invalidEmailOrPassword =>
      'E-mail ou mot de passe invalide. Veuillez réessayer.';

  @override
  String get loginFailed =>
      'Échec de la connexion. Veuillez vérifier vos identifiants et réessayer.';

  @override
  String get connectionTimeout =>
      'Délai de connexion dépassé. Veuillez vérifier votre connexion Internet et réessayer.';

  @override
  String get networkError =>
      'Erreur réseau. Veuillez vérifier votre connexion Internet.';

  @override
  String get requestTimeout =>
      'Délai d\'attente de la requête dépassé. Veuillez réessayer.';

  @override
  String get serverError => 'Erreur serveur. Veuillez réessayer plus tard.';

  @override
  String get accountDeleted => 'Compte supprimé';

  @override
  String get accountDeletedMessage =>
      'Votre compte a été supprimé par un administrateur.\n\nSi vous pensez qu\'il s\'agit d\'une erreur, veuillez contacter notre équipe de support :\n\n📧 E-mail : support@bottleji.com\n📱 Heures de support : 9h - 18h (GMT+1)\n\nNous nous excusons pour le désagrément.';

  @override
  String get reason => 'Raison';

  @override
  String get youWillBeRedirectedToLoginScreen =>
      'Vous serez redirigé vers l\'écran de connexion.';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get enterEmailToReceiveResetCode =>
      'Entrez votre e-mail pour recevoir un code de réinitialisation';

  @override
  String get sendResetCode => 'Envoyer le code de réinitialisation';

  @override
  String get resetCodeSentToEmail =>
      'Code de réinitialisation envoyé à votre e-mail';

  @override
  String get enterResetCode => 'Entrez le code de réinitialisation';

  @override
  String weHaveSentResetCodeTo(String email) {
    return 'Nous avons envoyé un code de réinitialisation à\n$email';
  }

  @override
  String get verify => 'Vérifier';

  @override
  String get didntReceiveCode => 'Vous n\'avez pas reçu le code ?';

  @override
  String get resend => 'Renvoyer';

  @override
  String resendIn(int seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get resetCodeResentSuccessfully =>
      'Code de réinitialisation renvoyé avec succès !';

  @override
  String get createNewPassword => 'Créer un nouveau mot de passe';

  @override
  String get pleaseEnterNewPassword =>
      'Veuillez entrer votre nouveau mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get enterNewPassword => 'Entrez votre nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmNewPassword => 'Confirmez votre nouveau mot de passe';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordResetSuccessful =>
      'Réinitialisation du mot de passe réussie ! Veuillez vous connecter avec votre nouveau mot de passe.';

  @override
  String get verifyYourEmail => 'Vérifiez votre e-mail';

  @override
  String get pleaseEnterOtpSentToEmail =>
      'Veuillez entrer le code OTP envoyé à votre e-mail';

  @override
  String get verifyOtp => 'Vérifier le code OTP';

  @override
  String get resendOtp => 'Renvoyer le code OTP';

  @override
  String resendOtpIn(int seconds) {
    return 'Renvoyer le code OTP dans $seconds secondes';
  }

  @override
  String get otpVerifiedSuccessfully => 'Code OTP vérifié avec succès';

  @override
  String get invalidVerificationResponse =>
      'Erreur : Réponse de vérification invalide';

  @override
  String get otpResentSuccessfully => 'Code OTP renvoyé avec succès !';

  @override
  String get startYourBottlejiJourney => 'Commencez votre parcours Bottleji';

  @override
  String get createAccountToGetStarted => 'Créez un compte pour commencer';

  @override
  String get createAPassword => 'Créer un mot de passe';

  @override
  String get confirmYourPassword => 'Confirmez votre mot de passe';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get registrationSuccessful => 'Inscription réussie';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get welcomeToBottleji => 'Bienvenue sur Bottleji';

  @override
  String get yourSustainableWasteManagementSolution =>
      'Votre solution de gestion durable des déchets';

  @override
  String get joinThousandsOfUsersMakingDifference =>
      'Rejoignez des milliers d\'utilisateurs qui font la différence en recyclant des bouteilles et des canettes tout en gagnant des récompenses.';

  @override
  String get createAndTrackDrops => 'Créer et suivre les dépôts';

  @override
  String get forHouseholdUsers => 'Pour les utilisateurs domestiques';

  @override
  String get easilyCreateDropRequests =>
      'Créez facilement des demandes de dépôt pour vos bouteilles et canettes recyclables. Suivez le statut de collecte et recevez des notifications lorsque les collecteurs les récupèrent.';

  @override
  String get collectAndEarn => 'Collecter et gagner';

  @override
  String get forCollectors => 'Pour les collecteurs';

  @override
  String get findNearbyDropsCollectRecyclables =>
      'Trouvez des dépôts à proximité, collectez des matériaux recyclables et gagnez des récompenses. Aidez à construire une communauté durable tout en gagnant de l\'argent.';

  @override
  String get realTimeUpdates => 'Mises à jour en temps réel';

  @override
  String get stayConnected => 'Restez connecté';

  @override
  String get getInstantNotificationsAboutDrops =>
      'Recevez des notifications instantanées sur vos dépôts, collectes et mises à jour importantes. Ne manquez jamais une opportunité.';

  @override
  String get appPermissions => 'Autorisations de l\'application';

  @override
  String get bottlejiRequiresAdditionalPermissions =>
      'Bottleji nécessite des autorisations supplémentaires pour fonctionner correctement';

  @override
  String get permissionsHelpProvideBestExperience =>
      'Ces autorisations nous aident à vous offrir la meilleure expérience.';

  @override
  String get locationServices => 'Services de localisation';

  @override
  String get accessLocationToShowNearbyDrops =>
      'Accédez à votre localisation pour afficher les dépôts à proximité et activer la navigation pour les collecteurs.';

  @override
  String get localNetworkAccess => 'Accès au réseau local';

  @override
  String get allowAppToDiscoverServicesOnWifi =>
      'Autorisez l\'application à découvrir les services sur votre Wi‑Fi pour les fonctionnalités en temps réel.';

  @override
  String get receiveRealTimeUpdatesAboutDrops =>
      'Recevez des mises à jour en temps réel sur vos dépôts, collectes et annonces importantes.';

  @override
  String get photoStorage => 'Stockage de photos';

  @override
  String get saveAndAccessPhotosOfRecyclableItems =>
      'Enregistrez et accédez aux photos de vos articles recyclables.';

  @override
  String get enable => 'Activer';

  @override
  String get continueToApp => 'Continuer vers l\'application';

  @override
  String get enableRequiredPermissions => 'Activer les autorisations requises';

  @override
  String get accountDisabled => 'Compte désactivé';

  @override
  String get accountDisabledMessage =>
      'Votre compte a été définitivement désactivé en raison de violations répétées des directives communautaires de Bottleji.\n\nVous ne pouvez plus accéder à ce compte ou l\'utiliser.\n\nSi vous pensez que cette décision a été prise par erreur, veuillez contacter le support :';

  @override
  String get supportEmail => 'support@bottleji.com';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get pleaseEmailSupport =>
      'Veuillez envoyer un e-mail à support@bottleji.com pour obtenir de l\'aide';

  @override
  String get sessionExpired => 'Session expirée';

  @override
  String get sessionExpiredMessage =>
      'Votre session a expiré. Veuillez vous reconnecter pour continuer.';

  @override
  String get home => 'Accueil';

  @override
  String get drops => 'Dépôts';

  @override
  String get rewards => 'Récompenses';

  @override
  String get stats => 'Statistiques';

  @override
  String get history => 'Historique';

  @override
  String get profile => 'Profil';

  @override
  String get account => 'Compte';

  @override
  String get support => 'Support';

  @override
  String get termsAndConditions => 'Conditions générales';

  @override
  String get logout => 'Déconnexion';

  @override
  String get areYouSureLogout => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String errorDuringLogout(String error) {
    return 'Erreur lors de la déconnexion : $error';
  }

  @override
  String get close => 'Fermer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get retry => 'Réessayer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get stay => 'Rester';

  @override
  String get leave => 'Partir';

  @override
  String get back => 'Retour';

  @override
  String get previous => 'Précédent';

  @override
  String get done => 'Terminé';

  @override
  String get gotIt => 'Compris';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get apply => 'Appliquer';

  @override
  String get filterDrops => 'Filtrer les chutes';

  @override
  String get status => 'Statut';

  @override
  String get all => 'Tout';

  @override
  String get date => 'Date';

  @override
  String get distance => 'Distance';

  @override
  String get deleteDrop => 'Supprimer le dépôt';

  @override
  String get areYouSureDelete =>
      'Êtes-vous sûr de vouloir supprimer ce dépôt ?';

  @override
  String get createDrop => 'Créer un dépôt';

  @override
  String get editDrop => 'Modifier le dépôt';

  @override
  String get startCollection => 'Démarrer la collecte';

  @override
  String get resumeNavigation => 'Reprendre la navigation';

  @override
  String get cancelCollection => 'Annuler la collecte';

  @override
  String get areYouSureCancelCollection =>
      'Êtes-vous sûr de vouloir annuler cette collecte ?';

  @override
  String get yesCancel => 'Oui, annuler';

  @override
  String get leaveCollection => 'Quitter la collecte ?';

  @override
  String get areYouSureLeaveCollection =>
      'Êtes-vous sûr de vouloir partir ? Votre collecte restera active.';

  @override
  String get exitNavigation => 'Quitter la navigation';

  @override
  String get areYouSureExitNavigation =>
      'Êtes-vous sûr de vouloir quitter la navigation ? Votre collecte restera active.';

  @override
  String get reportDrop => 'Signaler le dépôt';

  @override
  String get useCurrentLocation => 'Utiliser l\'emplacement actuel';

  @override
  String get setCollectionRadius => 'Définir le rayon de collecte';

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
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get galleryIOSSimulatorIssue => 'Galerie (problème simulateur iOS)';

  @override
  String get useCameraOrRealDevice =>
      'Utiliser l\'appareil photo ou un appareil réel';

  @override
  String get leaveOutsideDoor => 'Laisser devant la porte';

  @override
  String get pleaseTakePhoto => 'Veuillez prendre une photo de vos bouteilles';

  @override
  String get pleaseWaitLoading =>
      'Veuillez patienter pendant le chargement de vos informations de compte';

  @override
  String get mustBeLoggedIn => 'Vous devez être connecté pour créer un dépôt';

  @override
  String get authenticationIssue =>
      'Problème d\'authentification détecté. Veuillez vous déconnecter et vous reconnecter.';

  @override
  String get dropCreatedSuccessfully => 'Dépôt créé avec succès !';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get reloadMap => 'Recharger la carte';

  @override
  String get thisHelpsUsShowNearby =>
      'Cela nous aide à afficher les dépôts à proximité et à fournir des services de collecte précis.';

  @override
  String errorLoadingUserMode(String error) {
    return 'Erreur lors du chargement du mode utilisateur : $error';
  }

  @override
  String get tryAdjustingFilters => 'Essayez d\'ajuster vos filtres';

  @override
  String get checkBackLater => 'Revenez plus tard pour de nouveaux dépôts';

  @override
  String get createFirstDrop => 'Créez votre premier dépôt pour commencer';

  @override
  String get collectionInProgress => 'Collecte en cours';

  @override
  String get resumeCollection => 'Reprendre la collecte';

  @override
  String get collectionTimeout => '⚠️ Délai de collecte dépassé';

  @override
  String get warningSystem => 'Système d\'avertissement';

  @override
  String get warningAddedToAccount =>
      'Un avertissement a été ajouté à votre compte pour ce dépôt. Veuillez vous assurer que les images futures respectent les directives de la communauté.';

  @override
  String get timerExpired => '⏰ Minuteur expiré !';

  @override
  String get timerExpiredMessage =>
      'Le minuteur de collecte a expiré. L\'écran de navigation va maintenant se fermer.';

  @override
  String get applicationRejected => 'Candidature rejetée';

  @override
  String applicationRejectedMessage(String reason) {
    return 'Votre candidature a été rejetée pour la raison suivante :';
  }

  @override
  String get noSpecificReason => 'Aucune raison spécifique fournie';

  @override
  String get canEditApplication =>
      'Vous pouvez modifier votre candidature et la soumettre à nouveau.';

  @override
  String get editApplication => 'Modifier la candidature';

  @override
  String get pleaseLogInCollector =>
      'Veuillez vous connecter pour accéder au mode collecteur';

  @override
  String get tierSystem => 'Système de niveaux';

  @override
  String get bySubscribingAgree =>
      'En vous abonnant, vous acceptez nos Conditions de service\net notre Politique de confidentialité';

  @override
  String get startProSubscription => 'Commencer l\'abonnement PRO';

  @override
  String get termsOfService => 'Conditions de service';

  @override
  String get lastUpdated => 'Dernière mise à jour : 15 mars 2024';

  @override
  String get acceptanceOfTerms => '1. Acceptation des conditions';

  @override
  String get acceptanceOfTermsContent =>
      'En accédant et en utilisant l\'application Bottleji, vous acceptez d\'être lié par ces Conditions générales. Si vous n\'êtes pas d\'accord avec une partie de ces conditions, vous ne pouvez pas accéder à l\'application.';

  @override
  String get userResponsibilities => '2. Responsabilités de l\'utilisateur';

  @override
  String get userResponsibilitiesContent =>
      'En tant qu\'utilisateur de Bottleji, vous acceptez de :\n• Fournir des informations exactes et complètes\n• Maintenir la sécurité de votre compte\n• Suivre les directives de tri des déchets\n• Planifier les collectes de manière responsable\n• Utiliser le service conformément aux lois locales';

  @override
  String get household => 'Ménage';

  @override
  String get collector => 'Collecteur';

  @override
  String get activeMode => 'Mode actif';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get trainings => 'Formations';

  @override
  String get referAndEarn => 'Parrainer et gagner';

  @override
  String get upgrade => 'Mettre à niveau';

  @override
  String get review => 'En révision';

  @override
  String get rejected => 'Rejeté';

  @override
  String get becomeACollector => 'Devenir un collecteur';

  @override
  String get applicationUnderReview =>
      'Votre candidature est actuellement en cours d\'examen. Souhaitez-vous consulter le statut de votre candidature ?';

  @override
  String get viewStatus => 'Voir le statut';

  @override
  String applicationRejectedReason(String rejectionReason) {
    return 'Votre candidature a été rejetée pour la raison suivante :\n\n\"$rejectionReason\"\n\nSouhaitez-vous modifier votre candidature et la soumettre à nouveau ?';
  }

  @override
  String get applicationApprovedSuspended =>
      'Votre candidature a été approuvée mais votre accès collecteur a été temporairement suspendu. Veuillez contacter le support ou postuler à nouveau.';

  @override
  String get reapply => 'Repostuler';

  @override
  String get needToApplyCollector =>
      'Vous devez postuler et être approuvé pour accéder au mode collecteur. Souhaitez-vous postuler maintenant ?';

  @override
  String get applyNow => 'Postuler maintenant';

  @override
  String get householdMode => 'Mode ménage';

  @override
  String get collectorMode => 'Mode collecteur';

  @override
  String get householdModeDescription =>
      'Créer des dépôts et suivre votre recyclage';

  @override
  String get collectorModeDescription =>
      'Collecter des bouteilles et gagner des récompenses';

  @override
  String get sustainableWasteManagement => 'Gestion durable des déchets';

  @override
  String get ecoFriendlyBottleCollection => 'Collecte de bouteilles écologique';

  @override
  String get bottleType => 'Type de bouteille';

  @override
  String get numberOfPlasticBottles => 'Nombre de bouteilles en plastique';

  @override
  String get numberOfCans => 'Nombre de canettes';

  @override
  String get notesOptional => 'Notes (optionnel)';

  @override
  String get notes => 'Notes';

  @override
  String get failedToCreateDrop =>
      'Échec de la création du dépôt. Veuillez réessayer.';

  @override
  String get imageSelectedSuccessfully => 'Image sélectionnée avec succès !';

  @override
  String get errorSelectingImage => 'Erreur lors de la sélection de l\'image';

  @override
  String get permissionDeniedPhoto =>
      'Permission refusée. Veuillez autoriser l\'accès aux photos dans les paramètres.';

  @override
  String get galleryNotAvailableSimulator =>
      'Galerie non disponible sur le simulateur. Essayez l\'appareil photo ou utilisez un appareil réel.';

  @override
  String get profileInformation => 'Informations du profil';

  @override
  String get fullName => 'Nom complet';

  @override
  String get notSet => 'Non défini';

  @override
  String get phone => 'Téléphone';

  @override
  String get address => 'Adresse';

  @override
  String get collectorStatus => 'Statut collecteur';

  @override
  String get approvedCollector => 'Vous êtes un collecteur approuvé';

  @override
  String get applicationStatus => 'Statut de la demande';

  @override
  String get applicationUnderReviewStatus =>
      'Votre candidature est en cours d\'examen';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get applicationRejectedTitle => 'Candidature rejetée';

  @override
  String get pleaseLoginToViewProfile =>
      'Veuillez vous connecter pour voir votre profil';

  @override
  String get bottlejiRequiresPermissions =>
      'Bottleji nécessite des permissions supplémentaires pour fonctionner correctement';

  @override
  String galleryError(String error) {
    return 'Erreur de galerie : $error';
  }

  @override
  String galleryNotAvailableIOS(String error) {
    return 'Galerie non disponible sur le simulateur iOS : $error';
  }

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get completeYourProfile => 'Complétez votre profil';

  @override
  String get profilePhoto => 'Photo de profil';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get tapToChangePhoto => 'Appuyez pour changer la photo';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get completeSetup => 'Terminer la configuration';

  @override
  String get saveProfile => 'Enregistrer le profil';

  @override
  String get phoneNumberRequired => 'Veuillez entrer le numéro de téléphone';

  @override
  String get phoneNumberMustBe8Digits =>
      'Le numéro de téléphone doit contenir 8 chiffres';

  @override
  String get phoneNumberMustContainOnlyDigits =>
      'Le numéro de téléphone ne doit contenir que des chiffres';

  @override
  String get pleaseEnterYourFullName => 'Veuillez entrer votre nom complet';

  @override
  String get pleaseEnterYourPhoneNumber =>
      'Veuillez entrer votre numéro de téléphone';

  @override
  String get pleaseEnterYourAddress => 'Veuillez entrer votre adresse';

  @override
  String get pleaseVerifyYourPhoneNumber =>
      'Veuillez vérifier votre numéro de téléphone avant d\'enregistrer';

  @override
  String get noChangesDetected =>
      'Aucun changement détecté. Le profil reste inchangé.';

  @override
  String get profileSetupCompletedSuccessfully =>
      'Configuration du profil terminée avec succès ! Bienvenue sur Bottleji !';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès !';

  @override
  String failedToUploadImage(String error) {
    return 'Échec du téléchargement de l\'image : $error';
  }

  @override
  String get smsCode => 'Code SMS';

  @override
  String get enter6DigitCode => 'Entrez le code à 6 chiffres';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get sending => 'Envoi...';

  @override
  String get verifyCode => 'Vérifier le code';

  @override
  String get verifying => 'Vérification...';

  @override
  String get phoneNumberVerified => 'Numéro de téléphone vérifié';

  @override
  String get phoneNumberNotVerified => 'Numéro de téléphone non vérifié';

  @override
  String get phoneNumberNeedsVerification =>
      'Le numéro de téléphone doit être vérifié';

  @override
  String get phoneNumberVerifiedSuccessfully =>
      'Numéro de téléphone vérifié avec succès!';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get fullNameRequired => 'Le nom complet est requis';

  @override
  String get addressRequired => 'L\'adresse est requise';

  @override
  String get searchAddress => 'Rechercher une adresse';

  @override
  String get tapToSearchAddress => 'Appuyez pour rechercher votre adresse';

  @override
  String get typeToSearch => 'Tapez pour rechercher...';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String errorFetchingSuggestions(String error) {
    return 'Erreur lors de la récupération des suggestions: $error';
  }

  @override
  String get pleaseEnterPhoneNumberFirst =>
      'Veuillez d\'abord entrer un numéro de téléphone';

  @override
  String get pleaseEnterValidPhoneNumber =>
      'Veuillez entrer un numéro de téléphone valide avec l\'indicatif du pays (ex: +49 123456789)';

  @override
  String get locationPermissionRequired =>
      'L\'autorisation de localisation est requise pour les fonctionnalités d\'adresse';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get noNotificationsYet => 'Aucune notification pour le moment';

  @override
  String get failedToLoadNotifications =>
      'Échec du chargement des notifications';

  @override
  String get createNewDrop => 'Créer un nouveau dépôt';

  @override
  String get photo => 'Photo';

  @override
  String get takePhotoOrChooseFromGallery =>
      'Prenez une photo ou choisissez dans la galerie - montrez clairement vos bouteilles pour aider les collecteurs';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get cameraOrGallery => 'Appareil photo ou galerie';

  @override
  String get allDrops => 'Tous les dépôts';

  @override
  String get myDrops => 'Mes dépôts';

  @override
  String get active => 'Actif';

  @override
  String get collected => 'Collecté';

  @override
  String get flagged => 'SIGNALÉ';

  @override
  String get censored => 'Censuré';

  @override
  String get stale => 'Périmé';

  @override
  String get dropsInThisFilterCollected =>
      'Les dépôts de ce filtre ont été collectés avec succès par un collecteur. Ces dépôts montrent votre impact sur le recyclage et ne peuvent pas être modifiés.';

  @override
  String get dropsInThisFilterFlagged =>
      'Les dépôts de ce filtre ont été signalés en raison de multiples annulations ou d\'activités suspectes. Les dépôts signalés sont masqués de la carte et ne peuvent pas être modifiés.';

  @override
  String get dropsInThisFilterCensored =>
      'Les dépôts de ce filtre ont été censurés en raison de contenu inapproprié. Les dépôts censurés sont masqués de la carte et ne peuvent pas être modifiés.';

  @override
  String get dropsInThisFilterStale =>
      'Les dépôts de ce filtre ont été marqués comme périmés car ils étaient plus anciens que 3 jours et probablement collectés par des collecteurs externes. Les dépôts périmés sont masqués de la carte et ne peuvent pas être modifiés.';

  @override
  String get inActiveCollection =>
      'En collecte active - Le collecteur est en route';

  @override
  String censoredInappropriateImage(String reason) {
    return 'Censuré : $reason';
  }

  @override
  String get onTheWay => 'En route';

  @override
  String get collectorOnHisWay =>
      'Le collecteur est en route pour récupérer votre dépôt';

  @override
  String get waiting => 'En attente...';

  @override
  String get notYetCollected => 'Pas encore collecté';

  @override
  String get yourPoints => 'Vos points';

  @override
  String pointsToGo(int points) {
    return '$points points restants';
  }

  @override
  String get progressToNextTier => 'Progression vers le niveau suivant';

  @override
  String get bronzeCollector => 'Collecteur Bronze';

  @override
  String get silverCollector => 'Collecteur Argent';

  @override
  String get goldCollector => 'Collecteur Or';

  @override
  String get platinumCollector => 'Collecteur Platine';

  @override
  String get diamondCollector => 'Collecteur Diamant';

  @override
  String earnPointsPerDropCollected(int points) {
    return 'Gagnez $points points par dépôt collecté';
  }

  @override
  String earnPointsWhenDropsCollected(int points) {
    return 'Gagnez $points points lorsque vos dépôts sont collectés';
  }

  @override
  String get rewardShop => 'Boutique de récompenses';

  @override
  String get orderHistory => 'Historique des commandes';

  @override
  String get noOrdersYet => 'Aucune commande pour le moment';

  @override
  String get yourOrderHistoryWillAppearHere =>
      'Votre historique de commandes apparaîtra ici';

  @override
  String get notEnoughPoints => 'Points insuffisants';

  @override
  String get pts => 'pts';

  @override
  String get myStats => 'Mes statistiques';

  @override
  String get timeRange => 'Plage de temps';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get thisYear => 'Cette année';

  @override
  String get allTime => 'Tout le temps';

  @override
  String get overview => 'Aperçu';

  @override
  String get dropStatus => 'Statut des dépôts';

  @override
  String get pending => 'En attente';

  @override
  String get collectionRate => 'Taux de collecte';

  @override
  String get avgCollectionTime => 'Temps de collecte moyen';

  @override
  String get recentCollections => 'Collectes récentes';

  @override
  String get supportAndHelp => 'Support et aide';

  @override
  String get howCanWeHelpYou => 'Comment pouvons-nous vous aider ?';

  @override
  String get selectCategoryToGetStarted =>
      'Sélectionnez une catégorie pour commencer';

  @override
  String get supportCategories => 'Catégories de support';

  @override
  String get whatDoYouNeedHelpWith => 'De quoi avez-vous besoin d\'aide ?';

  @override
  String get selectCategoryToContinue =>
      'Sélectionnez une catégorie pour continuer';

  @override
  String get trainingCenter => 'Centre de formation';

  @override
  String todayAt(String time) {
    return 'Aujourd\'hui à $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Hier à $time';
  }

  @override
  String daysAgo(int days) {
    return 'Il y a $days j';
  }

  @override
  String get leaveOutside => 'Laisser à l\'extérieur';

  @override
  String get noImageAvailable => 'Aucune image disponible';

  @override
  String get estTime => 'Temps estimé';

  @override
  String get estimatedTime => 'Heure d\'arrivée estimée';

  @override
  String get yourLocation => 'Votre emplacement';

  @override
  String get dropLocation => 'Emplacement du dépôt';

  @override
  String get routePreview => 'Aperçu de l\'itinéraire';

  @override
  String get dropInformation => 'Informations sur le dépôt';

  @override
  String get plasticBottles => 'Bouteilles en plastique';

  @override
  String get cans => 'Canettes';

  @override
  String get plastic => 'Plastique';

  @override
  String get can => 'CANETTE';

  @override
  String get mixed => 'Mixte';

  @override
  String get totalItems => 'Total des articles';

  @override
  String get estimatedValue => 'Valeur Estimée';

  @override
  String get created => 'Créé';

  @override
  String get completeCurrentCollectionFirst =>
      'Terminez votre collecte actuelle avant d\'en commencer une nouvelle.';

  @override
  String get youAreOffline =>
      'Vous êtes hors ligne. Veuillez vérifier votre connexion Internet.';

  @override
  String errorColon(String error) {
    return 'Erreur : $error';
  }

  @override
  String get yourInformation => 'Vos informations';

  @override
  String get createdBy => 'Créé par';

  @override
  String get youWillSeeNotificationsHere => 'Vous verrez vos notifications ici';

  @override
  String get pendingStatus => 'EN ATTENTE';

  @override
  String get acceptedStatus => 'ACCEPTÉ';

  @override
  String get collectedStatus => 'COLLECTÉ';

  @override
  String get cancelledStatus => 'ANNULÉ';

  @override
  String get expiredStatus => 'EXPIRÉ';

  @override
  String get staleStatus => 'OBSOLÈTE';

  @override
  String get howRewardsWork => 'Comment fonctionnent les récompenses';

  @override
  String get howRewardsWorkCollector =>
      '• Collectez des dépôts pour gagner des points\n• Des niveaux plus élevés = plus de points par dépôt\n• Utilisez vos points dans la boutique de récompenses\n• Suivez vos progrès et réalisations';

  @override
  String get howRewardsWorkHousehold =>
      '• Créez des dépôts pour contribuer au recyclage\n• Gagnez des points lorsque les collecteurs récupèrent vos dépôts\n• Des niveaux plus élevés = plus de points par dépôt collecté\n• Utilisez vos points dans la boutique de récompenses';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get itemNotAvailable => 'L\'article n\'est pas disponible';

  @override
  String get outOfStock => 'Rupture de stock';

  @override
  String get orderNow => 'Commander maintenant';

  @override
  String get pleaseLogInToViewOrderHistory =>
      'Veuillez vous connecter pour voir l\'historique des commandes';

  @override
  String get failedToLoadOrderHistory =>
      'Échec du chargement de l\'historique des commandes';

  @override
  String get refresh => 'Actualiser';

  @override
  String get pointsSpent => 'Points dépensés';

  @override
  String get size => 'Taille';

  @override
  String get orderDate => 'Date de commande';

  @override
  String get tracking => 'Suivi';

  @override
  String get estimatedDelivery => 'Livraison estimée';

  @override
  String get deliveryAddress => 'Adresse de livraison';

  @override
  String get adminNote => 'Note de l\'administrateur';

  @override
  String get approved => 'Approuvé';

  @override
  String get processing => 'En cours de traitement';

  @override
  String get shipped => 'Expédié';

  @override
  String get delivered => 'Livré';

  @override
  String get cancelled => 'Annulé';

  @override
  String available(int count) {
    return '$count disponible';
  }

  @override
  String get updateDrop => 'Mettre à jour le dépôt';

  @override
  String get updating => 'Mise à jour...';

  @override
  String get recyclingImpact => 'Impact du recyclage';

  @override
  String get recentDrops => 'Dépôts récents';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get dropStatusDistribution => 'Statut des dépôts';

  @override
  String get co2VolumeSaved => 'Volume de CO₂ économisé';

  @override
  String totalCo2Saved(String amount) {
    return 'Total CO₂ économisé : $amount kg';
  }

  @override
  String get dropActivity => 'Activité des dépôts';

  @override
  String dropsCreated(String timeRange, int count) {
    return 'Dépôts créés ($timeRange) : $count';
  }

  @override
  String errorPickingImage(String error) {
    return 'Erreur lors de la sélection de l\'image : $error';
  }

  @override
  String get dropUpdatedSuccessfully => 'Dépôt mis à jour avec succès !';

  @override
  String errorUpdatingDrop(String error) {
    return 'Erreur lors de la mise à jour du dépôt : $error';
  }

  @override
  String get areYouSureDeleteDrop =>
      'Êtes-vous sûr de vouloir supprimer ce dépôt ? Cette action ne peut pas être annulée.';

  @override
  String get dropDeletedSuccessfully => 'Dépôt supprimé avec succès !';

  @override
  String errorDeletingDrop(String error) {
    return 'Erreur lors de la suppression du dépôt : $error';
  }

  @override
  String get pleaseEnterNumberOfBottles =>
      'Veuillez entrer le nombre de bouteilles';

  @override
  String get pleaseEnterValidNumber => 'Veuillez entrer un nombre valide';

  @override
  String get pleaseEnterNumberOfCans => 'Veuillez entrer le nombre de canettes';

  @override
  String get anyAdditionalInstructions =>
      'Toutes instructions supplémentaires pour le collecteur...';

  @override
  String get collectorCanLeaveOutside =>
      'Le collecteur peut laisser les articles à l\'extérieur si personne n\'est à la maison';

  @override
  String get loadingAddress => 'Chargement de l\'adresse...';

  @override
  String locationFormat(String lat, String lng) {
    return 'Emplacement : $lat, $lng';
  }

  @override
  String get locationSelected => 'Emplacement sélectionné';

  @override
  String get currentDropLocation => 'Emplacement actuel du dépôt';

  @override
  String get tapConfirmToSetLocation =>
      'Appuyez sur \"Confirmer\" pour définir cet emplacement';

  @override
  String get userNotFound => 'Utilisateur introuvable';

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
  String get collectorApplication => 'Demande de collecteur';

  @override
  String get applied => 'Applied';

  @override
  String get items => 'items';

  @override
  String get drop => 'Drop';

  @override
  String get collection => 'Collection';

  @override
  String get unknown => 'Inconnu';

  @override
  String get justNow => 'À l\'instant';

  @override
  String hoursAgo(int hours) {
    return 'Il y a $hours h';
  }

  @override
  String minutesAgo(int minutes) {
    return 'Il y a $minutes min';
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
      'Collecte terminée avec succès';

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
  String get noAccess => 'Pas d\'accès';

  @override
  String get notFound => 'Introuvable';

  @override
  String get alreadyCollected => 'Déjà collecté';

  @override
  String get wrongLocation => 'Mauvais emplacement';

  @override
  String get unsafeLocation => 'Emplacement dangereux';

  @override
  String get other => 'Autre';

  @override
  String get cancellationReasons => 'Raisons d\'annulation';

  @override
  String get cancellationReason => 'Raison d\'annulation';

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
  String get gettingStarted => 'Pour commencer';

  @override
  String get advancedFeatures => 'Fonctionnalités avancées';

  @override
  String get troubleshooting => 'Dépannage';

  @override
  String get bestPractices => 'Meilleures pratiques';

  @override
  String get payments => 'Paiements';

  @override
  String get help => 'Aide';

  @override
  String get advanced => 'Avancé';

  @override
  String get story => 'Histoire';

  @override
  String get totalDrops => 'Total des Drops';

  @override
  String get aluminumCans => 'Cannettes en Aluminium';

  @override
  String get recycled => 'Recyclé';

  @override
  String recycledBottles(String count) {
    return '$count bouteilles recyclées';
  }

  @override
  String recycledCans(String count) {
    return '$count cannettes recyclées';
  }

  @override
  String get totalItemsRecycled => 'Total des Articles Recyclés';

  @override
  String get dropsCollected => 'Drops Collectés';

  @override
  String get monday => 'Lun';

  @override
  String get tuesday => 'Mar';

  @override
  String get wednesday => 'Mer';

  @override
  String get thursday => 'Jeu';

  @override
  String get friday => 'Ven';

  @override
  String get saturday => 'Sam';

  @override
  String get sunday => 'Dim';

  @override
  String get january => 'Jan';

  @override
  String get february => 'Fév';

  @override
  String get march => 'Mar';

  @override
  String get april => 'Avr';

  @override
  String get may => 'Mai';

  @override
  String get june => 'Jun';

  @override
  String get july => 'Jul';

  @override
  String get august => 'Aoû';

  @override
  String get september => 'Sep';

  @override
  String get october => 'Oct';

  @override
  String get november => 'Nov';

  @override
  String get december => 'Déc';

  @override
  String get todaysTotal => 'Total d\'aujourd\'hui';

  @override
  String get earnings => 'Gains';

  @override
  String get collections => 'Collectes';

  @override
  String get noEarningsHistoryYet => 'Aucun historique de gains pour le moment';

  @override
  String get earningsWillAppearHere =>
      'Vos gains apparaîtront ici une fois que vous aurez terminé les collectes';

  @override
  String get totalEarnings => 'Gains totaux';

  @override
  String errorLoadingEarnings(String error) {
    return 'Erreur lors du chargement des gains : $error';
  }

  @override
  String get noCompletedCollectionsYet =>
      'Aucune collecte terminée pour le moment';

  @override
  String get performanceMetrics => 'Métriques de performance';

  @override
  String get expired => 'Expiré';

  @override
  String get collectionsOverTime => 'Collectes au fil du temps';

  @override
  String get expiredOverTime => 'Expiré au fil du temps';

  @override
  String get cancelledOverTime => 'Annulé au fil du temps';

  @override
  String get totalThisWeek => 'total cette semaine';

  @override
  String get totalThisMonth => 'total ce mois';

  @override
  String get totalThisYear => 'total cette année';

  @override
  String get mon => 'Lun';

  @override
  String get tue => 'Mar';

  @override
  String get wed => 'Mer';

  @override
  String get thu => 'Jeu';

  @override
  String get fri => 'Ven';

  @override
  String get sat => 'Sam';

  @override
  String get sun => 'Dim';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Fév';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Avr';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aoû';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Déc';

  @override
  String daysAgoShort(int days) {
    return 'il y a ${days}j';
  }

  @override
  String get at => 'à';

  @override
  String get total => 'Total';

  @override
  String get noDropsCreatedYet => 'Aucune chute créée pour le moment';

  @override
  String get createYourFirstDropToGetStarted =>
      'Créez votre première chute pour commencer';

  @override
  String get noActiveDrops => 'Aucune chute active';

  @override
  String get noCollectedDrops => 'Aucune chute collectée pour le moment';

  @override
  String get noStaleDrops => 'Aucune chute périmée';

  @override
  String get noCensoredDrops => 'Aucune chute censurée';

  @override
  String get noFlaggedDrops => 'Aucune chute signalée';

  @override
  String get noDropsMatchYourFilters =>
      'Aucune chute ne correspond à vos filtres';

  @override
  String get tryAdjustingYourFilters => 'Essayez d\'ajuster vos filtres';

  @override
  String get noDropsAvailable => 'Aucune chute disponible';

  @override
  String get checkBackLaterForNewDrops =>
      'Revenez plus tard pour de nouvelles chutes';

  @override
  String get note => 'Note';

  @override
  String get outside => 'Extérieur';

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get last30Days => '30 derniers jours';

  @override
  String get lastMonth => 'Mois dernier';

  @override
  String get within1Km => 'Dans 1 km';

  @override
  String get within3Km => 'Dans 3 km';

  @override
  String get within5Km => 'Dans 5 km';

  @override
  String get within10Km => 'Dans 10 km';

  @override
  String get rewardHistory => 'Historique des récompenses';

  @override
  String get noRewardHistoryYet =>
      'Aucun historique de récompenses pour le moment';

  @override
  String get points => 'Points';

  @override
  String get tier => 'Niveau';

  @override
  String get tierUp => 'Niveau supérieur!';

  @override
  String get acceptDrop => 'Accepter la chute';

  @override
  String get completeCurrentDropFirst => 'Terminez d\'abord la chute actuelle';

  @override
  String get distanceUnavailable => 'Distance indisponible';

  @override
  String get away => 'loin';

  @override
  String get meters => 'm';

  @override
  String get minutesShort => 'min';

  @override
  String get hoursShort => 'h';

  @override
  String get current => 'Actuel';

  @override
  String earnPointsPerDrop(int points) {
    return 'Gagnez $points points par chute';
  }

  @override
  String dropsRequired(int count) {
    return '$count chutes requises';
  }

  @override
  String get start => 'Commencer';

  @override
  String get filterHistory => 'Filtrer l\'historique';

  @override
  String get searchHistory => 'Rechercher dans l\'historique';

  @override
  String get searchByNotesBottleTypeOrCancellationReason =>
      'Rechercher par notes, type de bouteille ou raison d\'annulation...';

  @override
  String get viewType => 'Type de vue';

  @override
  String get itemType => 'Type d\'article';

  @override
  String get last3Months => '3 derniers mois';

  @override
  String get last6Months => '6 derniers mois';

  @override
  String get allItems => 'Tous les articles';

  @override
  String get bottlesOnly => 'Bouteilles uniquement';

  @override
  String get cansOnly => 'Cannettes uniquement';

  @override
  String get allTypes => 'Tous les types';

  @override
  String get activeFilters => 'ACTIF';

  @override
  String get waitingForCollector => 'En attente du collecteur';

  @override
  String get liveCollectorOnTheWay => '🟢 En direct - Collecteur en route';

  @override
  String get collectorWasOnTheWay => 'Le collecteur était en route';

  @override
  String get wasOnTheWay => 'Était en route';

  @override
  String get accepted => 'Accepté';

  @override
  String get sessionTime => 'Durée de la session';

  @override
  String get completed => 'Terminé';

  @override
  String get pleaseLoginToViewYourDrops =>
      'Veuillez vous connecter pour voir vos dépôts';

  @override
  String errorLoadingUserData(String error) {
    return 'Erreur lors du chargement des données utilisateur : $error';
  }

  @override
  String get earn500Points => 'Gagnez 500 points';

  @override
  String get forEachFriendWhoJoins => 'Pour chaque ami qui rejoint';

  @override
  String get yourReferralCode => 'Votre code de parrainage';

  @override
  String get referralCodeCopiedToClipboard =>
      'Code de parrainage copié dans le presse-papiers';

  @override
  String get shareVia => 'Partager via';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get sms => 'SMS';

  @override
  String get more => 'Plus';

  @override
  String get howItWorks => 'Comment ça marche';

  @override
  String get shareYourCode => 'Partagez votre code';

  @override
  String get shareYourUniqueReferralCodeWithFriends =>
      'Partagez votre code de parrainage unique avec vos amis';

  @override
  String get friendSignsUp => 'L\'ami s\'inscrit';

  @override
  String get yourFriendCreatesAnAccountUsingYourCode =>
      'Votre ami crée un compte en utilisant votre code';

  @override
  String get earnRewards => 'Gagnez des récompenses';

  @override
  String get get500PointsWhenTheyCompleteFirstActivity =>
      'Obtenez 500 points lorsqu\'ils terminent leur première activité';

  @override
  String get trainingCenterInfo => 'Centre de formation';

  @override
  String get trainingCenterInfoHousehold =>
      'Accédez au contenu de formation adapté aux utilisateurs des ménages. Apprenez à utiliser Botleji efficacement !';

  @override
  String get trainingCenterInfoCollector =>
      'Accédez au contenu de formation pour les collecteurs. Maîtrisez les techniques de collecte et les meilleures pratiques !';

  @override
  String get filter => 'Filtrer';

  @override
  String get search => 'Rechercher';

  @override
  String get clear => 'Effacer';

  @override
  String get glass => 'Verre';

  @override
  String get aluminum => 'Aluminium';

  @override
  String get dropProgress => 'Progression du dépôt';

  @override
  String get collectionIssues => 'Problèmes de collecte';

  @override
  String cancelledTimes(int count) {
    return 'Annulé $count fois';
  }

  @override
  String get dropAcceptedByCollector => 'Dépôt accepté par le collecteur';

  @override
  String get acceptedDropForCollection => 'Dépôt accepté pour collecte';

  @override
  String get applicationIssue => 'Problème d\'application';

  @override
  String get paymentIssue => 'Problème de paiement';

  @override
  String get accountIssue => 'Problème de compte';

  @override
  String get technicalIssue => 'Problème technique';

  @override
  String get generalSupportRequest => 'Demande de support générale';

  @override
  String get supportRequest => 'Demande de support';

  @override
  String get noDescriptionProvided => 'Aucune description fournie';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get idVerification => 'Vérification d\'identité';

  @override
  String get selfieWithId => 'Selfie avec pièce d\'identité';

  @override
  String get reviewAndSubmit => 'Révision et soumission';

  @override
  String get welcomeToCollectorProgram =>
      'Bienvenue dans le programme de collecteurs !';

  @override
  String get joinOurCommunityOfEcoConsciousCollectors =>
      'Rejoignez notre communauté de collecteurs soucieux de l\'environnement et aidez à faire la différence dans le recyclage.';

  @override
  String get earnMoney => 'Gagner de l\'argent';

  @override
  String get getPaidForEveryBottleAndCan =>
      'Soyez payé pour chaque bouteille et canette que vous collectez';

  @override
  String get flexibleHours => 'Heures flexibles';

  @override
  String get collectWheneverAndWherever => 'Collectez quand et où vous voulez';

  @override
  String get helpTheEnvironment => 'Aider l\'environnement';

  @override
  String get contributeToCleanerGreenerWorld =>
      'Contribuez à un monde plus propre et plus vert';

  @override
  String get requirements => 'Exigences';

  @override
  String get mustBe18YearsOrOlder => '• Doit avoir 18 ans ou plus';

  @override
  String get validNationalIdCard => '• Carte d\'identité nationale valide';

  @override
  String get clearPhotosOfIdAndSelfie =>
      '• Photos claires de la pièce d\'identité et du selfie';

  @override
  String get goodStandingInCommunity => '• Bonne réputation dans la communauté';

  @override
  String get idCardVerification => 'Vérification de la carte d\'identité';

  @override
  String pleaseProvideYourIdCardInformation(String idType) {
    return 'Veuillez fournir vos informations $idType et prendre des photos claires';
  }

  @override
  String get idCardDetails => 'Détails de la carte d\'identité';

  @override
  String get passportDetails => 'Détails du passeport';

  @override
  String get idCardType => 'Type de carte d\'identité';

  @override
  String get selectYourIdCardType =>
      'Sélectionnez votre type de carte d\'identité';

  @override
  String get nationalId => 'Carte d\'identité nationale';

  @override
  String get passport => 'Passeport';

  @override
  String get pleaseSelectAnIdCardType =>
      'Veuillez sélectionner un type de carte d\'identité';

  @override
  String get passportNumber => 'Numéro de passeport';

  @override
  String get enterYourPassportNumber => 'Entrez votre numéro de passeport';

  @override
  String get selectIssueDate => 'Sélectionner la date d\'émission';

  @override
  String get issueDateLabel => 'Date d\'émission';

  @override
  String issueDate(String date) {
    return 'Date d\'émission : $date';
  }

  @override
  String get selectExpiryDate => 'Sélectionner la date d\'expiration';

  @override
  String get expiryDateLabel => 'Date d\'expiration';

  @override
  String expiryDate(String date) {
    return 'Date d\'expiration : $date';
  }

  @override
  String get issuingAuthority => 'Autorité émettrice';

  @override
  String get egMinistryOfForeignAffairs =>
      'ex. Ministère des Affaires étrangères';

  @override
  String get idCardNumber => 'Numéro de carte d\'identité';

  @override
  String get idCardNumberPlaceholder => '12345678';

  @override
  String get idCardNumberIsRequired =>
      'Le numéro de carte d\'identité est requis';

  @override
  String get idCardNumberMustBe8Digits =>
      'Le numéro de carte d\'identité doit contenir 8 chiffres';

  @override
  String get idCardNumberMustContainOnlyDigits =>
      'Le numéro de carte d\'identité ne doit contenir que des chiffres';

  @override
  String get idCardPhotos => 'Photos de la carte d\'identité';

  @override
  String get passportPhotos => 'Photos du passeport';

  @override
  String get noPassportMainPagePhoto =>
      'Aucune photo de la page principale du passeport';

  @override
  String get takePhotoOfMainPageWithDetails =>
      'Prenez une photo de la page principale avec vos détails';

  @override
  String get retakePhoto => 'Reprendre la photo';

  @override
  String get takePassportMainPagePhoto =>
      'Prendre une photo de la page principale du passeport';

  @override
  String get noIdCardFrontPhoto =>
      'Aucune photo du recto de la carte d\'identité';

  @override
  String get takePhotoOfFrontOfIdCard =>
      'Prenez une photo du recto de votre carte d\'identité';

  @override
  String get retakeFrontPhoto => 'Reprendre la photo du recto';

  @override
  String get takeIdCardFrontPhoto =>
      'Prendre une photo du recto de la carte d\'identité';

  @override
  String get noIdCardBackPhoto =>
      'Aucune photo du verso de la carte d\'identité';

  @override
  String get takePhotoOfBackOfIdCard =>
      'Prenez une photo du verso de votre carte d\'identité';

  @override
  String get retakeBackPhoto => 'Reprendre la photo du verso';

  @override
  String get takeIdCardBackPhoto =>
      'Prendre une photo du verso de la carte d\'identité';

  @override
  String get continueButton => 'Continuer';

  @override
  String get selfieWithIdCard => 'Selfie avec carte d\'identité';

  @override
  String get pleaseTakeSelfieWhileHoldingId =>
      'Veuillez prendre un selfie en tenant votre carte d\'identité à côté de votre visage';

  @override
  String get noSelfiePhoto => 'Aucune photo selfie';

  @override
  String get takeSelfie => 'Prendre un selfie';

  @override
  String get reviewAndSubmitTitle => 'Révision et soumission';

  @override
  String get pleaseReviewYourApplication =>
      'Veuillez réviser votre demande avant de la soumettre';

  @override
  String get idCardInformation => 'Informations sur la carte d\'identité';

  @override
  String get idType => 'Type d\'identité';

  @override
  String get idNumber => 'Numéro d\'identité';

  @override
  String get notProvided => 'Non fourni';

  @override
  String get idCard => 'Carte d\'identité';

  @override
  String get selfie => 'Selfie';

  @override
  String get whatHappensNext => 'Que se passe-t-il ensuite ?';

  @override
  String get applicationReviewProcess =>
      '• Votre demande sera examinée par notre équipe\n• L\'examen prend généralement 1 à 3 jours ouvrables\n• Vous recevrez une notification une fois examinée\n• Si approuvée, vous pouvez commencer à collecter immédiatement';

  @override
  String get submitting => 'Soumission en cours...';

  @override
  String get submitApplication => 'Soumettre la demande';

  @override
  String get pleaseTakeBothPhotosBeforeSubmitting =>
      'Veuillez prendre les deux photos avant de soumettre';

  @override
  String get pleaseFillInAllRequiredPassportInformation =>
      'Veuillez remplir toutes les informations de passeport requises';

  @override
  String get pleaseFillInAllRequiredIdCardInformation =>
      'Veuillez remplir toutes les informations de carte d\'identité requises (numéro et type d\'identité)';

  @override
  String get applicationUpdatedSuccessfully =>
      'Demande mise à jour avec succès !';

  @override
  String get applicationSubmittedSuccessfully =>
      'Demande soumise avec succès !';

  @override
  String errorSubmittingApplication(String error) {
    return 'Erreur lors de la soumission de la demande : $error';
  }

  @override
  String get errorLoadingApplication =>
      'Erreur lors du chargement de la demande';

  @override
  String get noApplicationFound => 'Aucune demande trouvée';

  @override
  String get youHaventSubmittedApplicationYet =>
      'Vous n\'avez pas encore soumis de demande de collecteur.';

  @override
  String get pendingReview => 'En attente d\'examen';

  @override
  String get yourApplicationIsBeingReviewed =>
      'Votre demande est en cours d\'examen par notre équipe.';

  @override
  String get congratulationsApplicationApproved =>
      'Félicitations ! Votre demande a été approuvée.';

  @override
  String get applicationNotApprovedCanApplyAgain =>
      'Votre demande n\'a pas été approuvée. Vous pouvez postuler à nouveau.';

  @override
  String get applicationStatusUnknown => 'Le statut de la demande est inconnu.';

  @override
  String get applicationDetails => 'Détails de la demande';

  @override
  String get applicationId => 'ID de la demande';

  @override
  String get notSpecified => 'Non spécifié';

  @override
  String get appliedOn => 'Postulé le';

  @override
  String get reviewedOn => 'Examiné le';

  @override
  String get rejectionReason => 'Raison du rejet';

  @override
  String get reviewNotes => 'Notes d\'examen';

  @override
  String get applyAgain => 'Postuler à nouveau';

  @override
  String get applicationInReview => 'Demande en cours d\'examen';

  @override
  String get applicationInReviewDialogContent =>
      'Votre demande est actuellement en cours d\'examen par notre équipe. Ce processus prend généralement 1 à 3 jours ouvrables. Vous serez notifié une fois qu\'une décision aura été prise.';

  @override
  String get reviewProcess => 'Processus d\'examen';

  @override
  String get tapToRedeem => 'Appuyer pour échanger';

  @override
  String get confirmOrder => 'Confirmer la commande';

  @override
  String get placeOrder => 'Passer la commande';

  @override
  String get availability => 'Disponibilité';

  @override
  String get streetAddress => 'Adresse de la rue';

  @override
  String get streetAddressRequired => 'Veuillez entrer l\'adresse de la rue';

  @override
  String get city => 'Ville';

  @override
  String get cityRequired => 'Veuillez entrer la ville';

  @override
  String get state => 'État/Province';

  @override
  String get stateRequired => 'Veuillez entrer l\'état/la province';

  @override
  String get zipCode => 'Code postal';

  @override
  String get zipCodeRequired => 'Veuillez entrer le code postal';

  @override
  String get country => 'Pays';

  @override
  String get countryRequired => 'Veuillez entrer le pays';

  @override
  String get additionalNotes => 'Notes supplémentaires (optionnel)';

  @override
  String get additionalNotesHint => 'Instructions de livraison spéciales...';

  @override
  String get sizeSelection => 'Sélection de la taille';

  @override
  String get footwear => 'Chaussures';

  @override
  String get jackets => 'Vestes';

  @override
  String get bottoms => 'Pantalons';

  @override
  String get pleaseSelectSize =>
      'Veuillez sélectionner une taille pour cet article';

  @override
  String get thisItemNotAvailableForRedemption =>
      'Cet article n\'est pas disponible pour l\'échange.';

  @override
  String get thisItemOutOfStock => 'Cet article est en rupture de stock.';

  @override
  String get youDontHaveEnoughPointsToRedeem =>
      'Vous n\'avez pas assez de points pour échanger cet article.';

  @override
  String get cannotRedeemThisItem => 'Impossible d\'échanger cet article.';

  @override
  String orderPlacedSuccessfully(String itemName) {
    return 'Commande passée avec succès ! $itemName est en attente d\'approbation.';
  }

  @override
  String failedToPlaceOrder(String error) {
    return 'Échec de la commande : $error';
  }

  @override
  String orderNowPoints(int points) {
    return 'Commander maintenant - $points points';
  }

  @override
  String yourPointsValue(int points) {
    return 'Vos points : $points';
  }

  @override
  String get pointsLabel => 'Points :';

  @override
  String get sizeLabel => 'Taille :';

  @override
  String get orderDateLabel => 'Date de commande :';

  @override
  String get statusLabel => 'Statut :';

  @override
  String get orderPendingApproval =>
      'Votre commande est en attente d\'approbation.';

  @override
  String orderApprovedBeingPrepared(String trackingNumber) {
    return 'Votre commande a été approuvée et est en cours de préparation pour l\'expédition. Suivi : $trackingNumber';
  }

  @override
  String get noRewardsAvailable => 'Aucune récompense disponible';

  @override
  String get checkBackLaterForRewards =>
      'Revenez plus tard pour des récompenses passionnantes !';

  @override
  String get streetAddressHint => '123 Rue Principale';

  @override
  String get cityHint => 'Paris';

  @override
  String get stateHint => 'Île-de-France';

  @override
  String get zipCodeHint => '75001';

  @override
  String get countryHint => 'France';

  @override
  String get phoneNumberHint => '+33 1 23 45 67 89';
}
