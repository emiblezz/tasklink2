class ResumeModel {
  final int? id;
  final String applicantId;
  final String text;
  final DateTime? uploadedDate;
  final String? filename;

  ResumeModel({
    this.id,
    required this.applicantId,
    required this.text,
    this.uploadedDate,
    this.filename,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      id: json['resume_id'],
      applicantId: json['applicant_id'],
      text: json['text'] ?? '',
      uploadedDate: json['uploaded_date'] != null
          ? DateTime.parse(json['uploaded_date'])
          : null,
      filename: json['filename'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resume_id': id,
      'applicant_id': applicantId,
      'text': text,
      'uploaded_date': uploadedDate?.toIso8601String(),
      'filename': filename,
    };
  }
}