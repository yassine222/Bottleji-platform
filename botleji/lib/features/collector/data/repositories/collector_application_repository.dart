import 'package:dio/dio.dart';
import 'package:botleji/core/api/api_client.dart';
import 'package:botleji/features/collector/data/models/collector_application.dart';

abstract class CollectorApplicationRepository {
  Future<CollectorApplication> createApplication({
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
  });

  Future<CollectorApplication?> getMyApplication();

  Future<CollectorApplication> updateApplication({
    required String applicationId,
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
  });
}

class CollectorApplicationRepositoryImpl implements CollectorApplicationRepository {
  final Dio _dio;

  CollectorApplicationRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClientConfig.createDio();
  
  static Future<CollectorApplicationRepositoryImpl> create() async {
    final dio = ApiClientConfig.createDio();
    return CollectorApplicationRepositoryImpl(dio: dio);
  }

  @override
  Future<CollectorApplication> createApplication({
    String? idCardPhoto,
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
    print('🔍 CollectorApplicationRepository: Creating application...');
    try {
      final response = await _dio.post(
        '/collector-applications',
        data: {
          'idCardPhoto': idCardPhoto,
          'selfieWithIdPhoto': selfieWithIdPhoto,
          'idCardNumber': idCardNumber,
          'idCardType': idCardType,
          'idCardExpiryDate': idCardExpiryDate?.toIso8601String(),
          'idCardIssuingAuthority': idCardIssuingAuthority,
          'passportIssueDate': passportIssueDate?.toIso8601String(),
          'passportExpiryDate': passportExpiryDate?.toIso8601String(),
          'passportMainPagePhoto': passportMainPagePhoto,
          'idCardBackPhoto': idCardBackPhoto,
        },
      );

      print('🔍 CollectorApplicationRepository: API response: ${response.data}');
      
      // Check if response.data is null or doesn't contain application
      if (response.data == null) {
        throw Exception('Server returned null response');
      }
      
      if (response.data['application'] == null) {
        throw Exception('Server response does not contain application data');
      }
      
      final application = CollectorApplication.fromJson(response.data['application']);
      print('🔍 CollectorApplicationRepository: Created application: ${application.id} with status: ${application.status}');
      print('🔍 CollectorApplicationRepository: Application parsed successfully!');
      return application;
    } catch (e) {
      print('🔍 CollectorApplicationRepository: Error creating application: $e');
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.message;
        
        if (statusCode == 401) {
          throw Exception('Authentication failed. Please log in again.');
        } else if (statusCode == 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to create application: $message');
        }
      }
      throw Exception('Failed to create application: $e');
    }
  }

  @override
  Future<CollectorApplication?> getMyApplication() async {
    print('🔍 CollectorApplicationRepository: Getting my application from API...');
    try {
      final response = await _dio.get('/collector-applications/my-application');
      print('🔍 CollectorApplicationRepository: API response: ${response.data}');
      
      if (response.data['application'] == null) {
        print('🔍 CollectorApplicationRepository: No application found');
        return null;
      }
      
      final application = CollectorApplication.fromJson(response.data['application']);
      print('🔍 CollectorApplicationRepository: Parsed application: ${application.status}');
      return application;
    } catch (e) {
      print('🔍 CollectorApplicationRepository: Error getting application: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          print('🔍 CollectorApplicationRepository: 404 - No application found');
          return null; // No application found
        }
        throw Exception('Failed to get application: ${e.response?.data?['message'] ?? e.message}');
      }
      throw Exception('Failed to get application: $e');
    }
  }

  @override
  Future<CollectorApplication> updateApplication({
    required String applicationId,
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
    print('🔍 CollectorApplicationRepository: Updating application $applicationId...');
    try {
      final response = await _dio.put(
        '/collector-applications/$applicationId',
        data: {
          'idCardPhoto': idCardPhoto,
          'selfieWithIdPhoto': selfieWithIdPhoto,
          'idCardNumber': idCardNumber,
          'idCardType': idCardType,
          'idCardExpiryDate': idCardExpiryDate?.toIso8601String(),
          'idCardIssuingAuthority': idCardIssuingAuthority,
          'passportIssueDate': passportIssueDate?.toIso8601String(),
          'passportExpiryDate': passportExpiryDate?.toIso8601String(),
          'passportMainPagePhoto': passportMainPagePhoto,
          'idCardBackPhoto': idCardBackPhoto,
        },
      );

      print('🔍 CollectorApplicationRepository: Update API response: ${response.data}');
      
      // Check if response.data is null or doesn't contain application
      if (response.data == null) {
        throw Exception('Server returned null response');
      }
      
      if (response.data['application'] == null) {
        throw Exception('Server response does not contain application data');
      }
      
      final application = CollectorApplication.fromJson(response.data['application']);
      print('🔍 CollectorApplicationRepository: Updated application: ${application.id} with status: ${application.status}');
      return application;
    } catch (e) {
      print('🔍 CollectorApplicationRepository: Error updating application: $e');
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.message;
        
        if (statusCode == 401) {
          throw Exception('Authentication failed. Please log in again.');
        } else if (statusCode == 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to update application: $message');
        }
      }
      throw Exception('Failed to update application: $e');
    }
  }
}