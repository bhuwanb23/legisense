class ApiDocument {
  const ApiDocument({
    required this.id,
    required this.originalName,
    this.fileFormat,
    this.fileSize,
    this.processingStatus,
    this.uploadStatus,
    this.documentType,
    this.sourceType,
    this.countryCode,
    this.stateCode,
    this.createdAt,
    this.overallRiskScore,
    this.riskLevel,
    this.isFavorite = false,
  });

  final int id;
  final String originalName;
  final String? fileFormat;
  final int? fileSize;
  final String? processingStatus;
  final String? uploadStatus;
  final String? documentType;
  final String? sourceType;
  final String? countryCode;
  final String? stateCode;
  final String? createdAt;
  final int? overallRiskScore;
  final String? riskLevel;
  final bool isFavorite;

  factory ApiDocument.fromJson(Map<String, dynamic> json) {
    return ApiDocument(
      id: (json['id'] as num).toInt(),
      originalName: json['originalName'] as String? ??
          json['title'] as String? ??
          'Document',
      fileFormat: json['fileFormat'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      processingStatus: json['processingStatus'] as String?,
      uploadStatus: json['uploadStatus'] as String?,
      documentType: json['documentType'] as String?,
      sourceType: json['sourceType'] as String?,
      countryCode: json['countryCode'] as String?,
      stateCode: json['stateCode'] as String?,
      createdAt: json['createdAt'] as String?,
      overallRiskScore: (json['overallRiskScore'] as num?)?.toInt(),
      riskLevel: json['riskLevel'] as String?,
      isFavorite: json['isFavorite'] == true || json['is_favorite'] == true,
    );
  }

  bool get isAnalyzed => processingStatus == 'analyzed';
  bool get isFailed => processingStatus == 'failed';
  bool get isProcessing =>
      processingStatus == 'pending' ||
      processingStatus == 'processing' ||
      processingStatus == 'ocr_processing';
}

class UploadResult {
  const UploadResult({
    required this.documentId,
    this.jobId,
    this.ocrJobId,
    this.originalName,
    this.processingStatus,
    this.sourceType,
  });

  final int documentId;
  final dynamic jobId;
  final dynamic ocrJobId;
  final String? originalName;
  final String? processingStatus;
  final String? sourceType;

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      documentId: (json['documentId'] as num).toInt(),
      jobId: json['jobId'],
      ocrJobId: json['ocrJobId'],
      originalName: json['originalName'] as String?,
      processingStatus: json['processingStatus'] as String?,
      sourceType: json['sourceType'] as String?,
    );
  }
}

class DocumentStatus {
  const DocumentStatus({
    required this.processingStatus,
    this.job,
  });

  final String processingStatus;
  final Map<String, dynamic>? job;

  factory DocumentStatus.fromJson(Map<String, dynamic> json) {
    return DocumentStatus(
      processingStatus: json['processingStatus'] as String? ??
          json['status'] as String? ??
          'pending',
      job: json['job'] is Map<String, dynamic>
          ? json['job'] as Map<String, dynamic>
          : null,
    );
  }
}
