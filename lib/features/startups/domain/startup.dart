import 'package:cloud_firestore/cloud_firestore.dart';

/// Verification lifecycle; a startup can only post once an admin verifies it.
enum VerificationStatus { pending, verified, rejected }

extension VerificationStatusX on VerificationStatus {
  String get asString => name;
  static VerificationStatus fromString(String? v) {
    switch (v) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.pending:
        return 'Pending review';
    }
  }
}

/// Mirrors a document in `startups/{startupId}`.
class Startup {
  final String id;
  final String ownerUid; // the founder's user uid
  final String name;
  final String tagline;
  final String description;
  final String category; // Design / Engineering / Marketing / Data / Other
  final String? website;
  final String? logoUrl;
  final String aluAffiliation; // e.g. cohort / programme / registration ref
  final VerificationStatus status;
  final DateTime? createdAt;

  const Startup({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    this.website,
    this.logoUrl,
    this.aluAffiliation = '',
    this.status = VerificationStatus.pending,
    this.createdAt,
  });

  bool get isVerified => status == VerificationStatus.verified;

  factory Startup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Startup(
      id: doc.id,
      ownerUid: d['ownerUid'] as String? ?? '',
      name: d['name'] as String? ?? '',
      tagline: d['tagline'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: d['category'] as String? ?? 'Other',
      website: d['website'] as String?,
      logoUrl: d['logoUrl'] as String?,
      aluAffiliation: d['aluAffiliation'] as String? ?? '',
      status: VerificationStatusX.fromString(d['status'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'name': name,
        'tagline': tagline,
        'description': description,
        'category': category,
        'website': website,
        'logoUrl': logoUrl,
        'aluAffiliation': aluAffiliation,
        'status': status.asString,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Startup copyWith({
    String? name,
    String? tagline,
    String? description,
    String? category,
    String? website,
    String? logoUrl,
    String? aluAffiliation,
    VerificationStatus? status,
  }) {
    return Startup(
      id: id,
      ownerUid: ownerUid,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      category: category ?? this.category,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      aluAffiliation: aluAffiliation ?? this.aluAffiliation,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
