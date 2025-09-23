import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/collector/data/models/collector_application.dart';
import 'package:botleji/features/collector/data/repositories/collector_application_repository.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/auth/data/models/user_data.dart' as auth_models;

final collectorApplicationRepositoryProvider = Provider<CollectorApplicationRepository>((ref) {
  return CollectorApplicationRepositoryImpl();
});

final collectorApplicationControllerProvider = StateNotifierProvider<CollectorApplicationController, AsyncValue<CollectorApplication?>>((ref) {
  return CollectorApplicationController(ref.watch(collectorApplicationRepositoryProvider), ref);
});

class CollectorApplicationController extends StateNotifier<AsyncValue<CollectorApplication?>> {
  final CollectorApplicationRepository _repository;
  final Ref _ref;

  CollectorApplicationController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createApplication({
    required String idCardPhoto,
    required String selfieWithIdPhoto,
    String? idCardNumber,
    String? idCardType,
    DateTime? idCardExpiryDate,
    String? idCardIssuingAuthority,
    DateTime? passportIssueDate,
    DateTime? passportExpiryDate,
    String? passportMainPagePhoto,
    String? idCardBackPhoto,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Check if user already has an application
      final existingApplication = await _repository.getMyApplication();
      if (existingApplication != null) {
        if (existingApplication.status.toLowerCase() == 'pending') {
          throw Exception('You already have a pending application. Please wait for it to be reviewed.');
        } else if (existingApplication.status.toLowerCase() == 'approved') {
          throw Exception('You are already an approved collector.');
        }
        // If rejected, allow them to edit the existing application
      }

      final application = await _repository.createApplication(
        idCardPhoto: idCardPhoto,
        selfieWithIdPhoto: selfieWithIdPhoto,
        idCardNumber: idCardNumber,
        idCardType: idCardType,
        idCardExpiryDate: idCardExpiryDate,
        idCardIssuingAuthority: idCardIssuingAuthority,
        passportIssueDate: passportIssueDate,
        passportExpiryDate: passportExpiryDate,
        passportMainPagePhoto: passportMainPagePhoto,
        idCardBackPhoto: idCardBackPhoto,
      );
      print('🔍 CollectorApplicationController: Application created successfully: ${application.id}');
      print('🔍 CollectorApplicationController: Application status: ${application.status}');
      
      // Update the application status in shared preferences
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      print('🔍 CollectorApplicationController: Updating shared preferences...');
      authNotifier.updateCollectorApplicationStatus(
        status: auth_models.CollectorApplicationStatus.pending,
        applicationId: application.id,
        appliedAt: application.appliedAt,
      );
      print('🔍 CollectorApplicationController: Shared preferences updated');
      
      state = AsyncValue.data(application);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> getMyApplication() async {
    print('🔍 CollectorApplicationController: Getting my application...');
    state = const AsyncValue.loading();
    try {
      final application = await _repository.getMyApplication();
      print('🔍 CollectorApplicationController: Application result: ${application?.status}');
      print('🔍 CollectorApplicationController: Application ID: ${application?.id}');
      print('🔍 CollectorApplicationController: Application applied at: ${application?.appliedAt}');
      state = AsyncValue.data(application);
    } catch (e) {
      print('🔍 CollectorApplicationController: Error getting application: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Test method to check if application exists
  Future<void> testApplicationExists() async {
    print('🔍 CollectorApplicationController: Testing if application exists...');
    try {
      final application = await _repository.getMyApplication();
      if (application != null) {
        print('🔍 CollectorApplicationController: Application EXISTS in database');
        print('🔍 CollectorApplicationController: Status: ${application.status}');
        print('🔍 CollectorApplicationController: ID: ${application.id}');
      } else {
        print('🔍 CollectorApplicationController: NO application found in database');
      }
    } catch (e) {
      print('🔍 CollectorApplicationController: Error testing application: $e');
    }
  }

  void clearApplication() {
    state = const AsyncValue.data(null);
  }

  Future<void> updateApplication({
    required String idCardPhoto,
    required String selfieWithIdPhoto,
    String? idCardNumber,
    String? idCardType,
    DateTime? idCardExpiryDate,
    String? idCardIssuingAuthority,
    DateTime? passportIssueDate,
    DateTime? passportExpiryDate,
    String? passportMainPagePhoto,
    String? idCardBackPhoto,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Get existing application
      final existingApplication = await _repository.getMyApplication();
      if (existingApplication == null) {
        throw Exception('No application found to update.');
      }

      if (existingApplication.status.toLowerCase() != 'rejected') {
        throw Exception('Only rejected applications can be updated.');
      }

      final application = await _repository.updateApplication(
        applicationId: existingApplication.id,
        idCardPhoto: idCardPhoto,
        selfieWithIdPhoto: selfieWithIdPhoto,
        idCardNumber: idCardNumber,
        idCardType: idCardType,
        idCardExpiryDate: idCardExpiryDate,
        idCardIssuingAuthority: idCardIssuingAuthority,
        passportIssueDate: passportIssueDate,
        passportExpiryDate: passportExpiryDate,
        passportMainPagePhoto: passportMainPagePhoto,
        idCardBackPhoto: idCardBackPhoto,
      );
      print('🔍 CollectorApplicationController: Application updated successfully: ${application.id}');
      print('🔍 CollectorApplicationController: Application status: ${application.status}');
      
      // Update the application status in shared preferences
      final authNotifier = _ref.read(authNotifierProvider.notifier);
      print('🔍 CollectorApplicationController: Updating shared preferences...');
      authNotifier.updateCollectorApplicationStatus(
        status: auth_models.CollectorApplicationStatus.pending,
        applicationId: application.id,
        appliedAt: application.appliedAt,
      );
      print('🔍 CollectorApplicationController: Shared preferences updated');
      
      state = AsyncValue.data(application);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
} 