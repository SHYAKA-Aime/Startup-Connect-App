import 'package:cloud_firestore/cloud_firestore.dart';

/// The lifecycle a student's application moves through (startup-driven).
enum ApplicationStatus { applied, underReview, shortlisted, accepted, rejected }

extension ApplicationStatusX on ApplicationStatus {
  String get asString => name;

  String get label {
    switch (this) {
      case ApplicationStatus.applied:
        return 'Applied';
      case ApplicationStatus.underReview:
        return 'Under review';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Not selected';
    }
  }

  static ApplicationStatus fromString(String? v) =>
      ApplicationStatus.values.firstWhere((e) => e.name == v,
          orElse: () => ApplicationStatus.applied);
}

/// Mirrors a document in `applications/{applicationId}`. Titles/names are
/// denormalised so the tracker and applicant list render without extra reads.
class Application {
  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String startupId;
  final String startupOwnerUid; // denormalised: lets the owner query applicants
  final String startupName;
  final String studentUid;
  final String studentName;
  final String studentHeadline;
  final String coverNote;
  final ApplicationStatus status;
  final DateTime? createdAt;

  const Application({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.startupId,
    this.startupOwnerUid = '',
    required this.startupName,
    required this.studentUid,
    required this.studentName,
    this.studentHeadline = '',
    this.coverNote = '',
    this.status = ApplicationStatus.applied,
    this.createdAt,
  });

  /// Deterministic id → prevents duplicate applications by construction.
  static String buildId(String opportunityId, String studentUid) =>
      '${opportunityId}_$studentUid';

  factory Application.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Application(
      id: doc.id,
      opportunityId: d['opportunityId'] as String? ?? '',
      opportunityTitle: d['opportunityTitle'] as String? ?? '',
      startupId: d['startupId'] as String? ?? '',
      startupOwnerUid: d['startupOwnerUid'] as String? ?? '',
      startupName: d['startupName'] as String? ?? '',
      studentUid: d['studentUid'] as String? ?? '',
      studentName: d['studentName'] as String? ?? '',
      studentHeadline: d['studentHeadline'] as String? ?? '',
      coverNote: d['coverNote'] as String? ?? '',
      status: ApplicationStatusX.fromString(d['status'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'opportunityId': opportunityId,
        'opportunityTitle': opportunityTitle,
        'startupId': startupId,
        'startupOwnerUid': startupOwnerUid,
        'startupName': startupName,
        'studentUid': studentUid,
        'studentName': studentName,
        'studentHeadline': studentHeadline,
        'coverNote': coverNote,
        'status': status.asString,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Application copyWith({ApplicationStatus? status}) => Application(
        id: id,
        opportunityId: opportunityId,
        opportunityTitle: opportunityTitle,
        startupId: startupId,
        startupOwnerUid: startupOwnerUid,
        startupName: startupName,
        studentUid: studentUid,
        studentName: studentName,
        studentHeadline: studentHeadline,
        coverNote: coverNote,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}
