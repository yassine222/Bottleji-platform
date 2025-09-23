import 'package:json_annotation/json_annotation.dart';

part 'collector_application.g.dart';

@JsonSerializable()
class CollectorApplication {
  final String id;
  final String userId;
  final String status;
  final String? idCardPhoto;
  final String? selfieWithIdPhoto;
  final String? idCardNumber;
  final String? idCardType;
  final DateTime? idCardExpiryDate;
  final String? idCardIssuingAuthority;
  final DateTime? passportIssueDate;
  final DateTime? passportExpiryDate;
  final String? passportMainPagePhoto;
  final String? idCardBackPhoto;
  final String? rejectionReason;
  final DateTime? appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectorApplication({
    required this.id,
    required this.userId,
    required this.status,
    this.idCardPhoto,
    this.selfieWithIdPhoto,
    this.idCardNumber,
    this.idCardType,
    this.idCardExpiryDate,
    this.idCardIssuingAuthority,
    this.passportIssueDate,
    this.passportExpiryDate,
    this.passportMainPagePhoto,
    this.idCardBackPhoto,
    this.rejectionReason,
    this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectorApplication.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB _id field mapping
    final id = json['_id'] ?? json['id'];
    if (id == null) {
      throw Exception('Application ID is required');
    }

    // Handle null fields that might cause casting issues
    final userId = json['userId']?.toString();
    if (userId == null) {
      throw Exception('User ID is required');
    }

    final status = json['status']?.toString();
    if (status == null) {
      throw Exception('Status is required');
    }

    return CollectorApplication(
      id: id.toString(),
      userId: userId,
      status: status,
      idCardPhoto: json['idCardPhoto']?.toString(),
      selfieWithIdPhoto: json['selfieWithIdPhoto']?.toString(),
      idCardNumber: json['idCardNumber']?.toString(),
      idCardType: json['idCardType']?.toString(),
      idCardExpiryDate: json['idCardExpiryDate'] != null 
          ? DateTime.parse(json['idCardExpiryDate'].toString())
          : null,
      idCardIssuingAuthority: json['idCardIssuingAuthority']?.toString(),
      passportIssueDate: json['passportIssueDate'] != null 
          ? DateTime.parse(json['passportIssueDate'].toString())
          : null,
      passportExpiryDate: json['passportExpiryDate'] != null 
          ? DateTime.parse(json['passportExpiryDate'].toString())
          : null,
      passportMainPagePhoto: json['passportMainPagePhoto']?.toString(),
      idCardBackPhoto: json['idCardBackPhoto']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      appliedAt: json['appliedAt'] != null 
          ? DateTime.parse(json['appliedAt'].toString())
          : null,
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.parse(json['reviewedAt'].toString())
          : null,
      reviewedBy: json['reviewedBy']?.toString(),
      reviewNotes: json['reviewNotes']?.toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() => _$CollectorApplicationToJson(this);

  CollectorApplication copyWith({
    String? id,
    String? userId,
    String? status,
    String? idCardPhoto,
    String? selfieWithIdPhoto,
    String? idCardNumber,
    String? idCardType,
    DateTime? idCardExpiryDate,
    String? idCardIssuingAuthority,
    DateTime? passportIssueDate,
    DateTime? passportExpiryDate,
    String? passportMainPagePhoto,
    String? idCardBackPhoto,
    String? rejectionReason,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollectorApplication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      idCardPhoto: idCardPhoto ?? this.idCardPhoto,
      selfieWithIdPhoto: selfieWithIdPhoto ?? this.selfieWithIdPhoto,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      idCardType: idCardType ?? this.idCardType,
      idCardExpiryDate: idCardExpiryDate ?? this.idCardExpiryDate,
      idCardIssuingAuthority: idCardIssuingAuthority ?? this.idCardIssuingAuthority,
      passportIssueDate: passportIssueDate ?? this.passportIssueDate,
      passportExpiryDate: passportExpiryDate ?? this.passportExpiryDate,
      passportMainPagePhoto: passportMainPagePhoto ?? this.passportMainPagePhoto,
      idCardBackPhoto: idCardBackPhoto ?? this.idCardBackPhoto,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 