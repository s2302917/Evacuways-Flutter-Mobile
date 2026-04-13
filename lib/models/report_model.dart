class ReportModel {
  final int reportId;
  final String? reportType;
  final int? generatedBy;
  final DateTime generatedAt;

  ReportModel({
    required this.reportId,
    this.reportType,
    this.generatedBy,
    required this.generatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['report_id'] ?? 0,
      reportType: json['report_type'],
      generatedBy: json['generated_by'],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'report_id': reportId,
    'report_type': reportType,
    'generated_by': generatedBy,
    'generated_at': generatedAt.toIso8601String(),
  };
}
