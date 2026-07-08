import 'package:cloud_firestore/cloud_firestore.dart';

/// Fixed vocabularies for opportunities. Using enums (not free text) keeps the
/// data clean, makes filtering reliable, and means the discovery filters can be
/// generated from the same source of truth.
enum RoleType { partTime, fullTime, projectBased, volunteer }

extension RoleTypeX on RoleType {
  String get asString => name;
  String get label {
    switch (this) {
      case RoleType.partTime:
        return 'Part-time';
      case RoleType.fullTime:
        return 'Full-time';
      case RoleType.projectBased:
        return 'Project-based';
      case RoleType.volunteer:
        return 'Volunteer';
    }
  }

  static RoleType fromString(String? v) =>
      RoleType.values.firstWhere((e) => e.name == v,
          orElse: () => RoleType.partTime);
}

enum LocationType { remote, onCampus, hybrid }

extension LocationTypeX on LocationType {
  String get asString => name;
  String get label {
    switch (this) {
      case LocationType.remote:
        return 'Remote';
      case LocationType.onCampus:
        return 'On-campus';
      case LocationType.hybrid:
        return 'Hybrid';
    }
  }

  static LocationType fromString(String? v) =>
      LocationType.values.firstWhere((e) => e.name == v,
          orElse: () => LocationType.remote);
}

/// The categories used to "Browse by category" on the home screen.
const kCategories = ['Design', 'Engineering', 'Marketing', 'Data', 'Other'];

/// Mirrors a document in `opportunities/{oppId}`.
///
/// Startup name/logo are denormalised onto the opportunity so a discovery list
/// can render each card from a single document — no N extra reads per card.
/// This is a deliberate NoSQL modelling decision (read-optimised) worth calling
/// out in the report's scalability section.
class Opportunity {
  final String id;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String title;
  final String description;
  final String category;
  final RoleType roleType;
  final LocationType locationType;
  final String commitment; // e.g. "8–10 hrs/week"
  final List<String> skillsRequired;
  final bool isOpen;
  final int applicantCount; // denormalised counter for cheap display
  final DateTime? createdAt;

  const Opportunity({
    required this.id,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.roleType,
    required this.locationType,
    required this.commitment,
    this.skillsRequired = const [],
    this.isOpen = true,
    this.applicantCount = 0,
    this.createdAt,
  });

  factory Opportunity.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Opportunity(
      id: doc.id,
      startupId: d['startupId'] as String? ?? '',
      startupName: d['startupName'] as String? ?? '',
      startupLogoUrl: d['startupLogoUrl'] as String?,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: d['category'] as String? ?? 'Other',
      roleType: RoleTypeX.fromString(d['roleType'] as String?),
      locationType: LocationTypeX.fromString(d['locationType'] as String?),
      commitment: d['commitment'] as String? ?? '',
      skillsRequired:
          List<String>.from(d['skillsRequired'] as List? ?? const []),
      isOpen: d['isOpen'] as bool? ?? true,
      applicantCount: d['applicantCount'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'startupId': startupId,
        'startupName': startupName,
        'startupLogoUrl': startupLogoUrl,
        'title': title,
        // Lower-cased search key so we can do prefix search in Firestore, which
        // has no built-in full-text search. Explained in the report.
        'titleLower': title.toLowerCase(),
        'description': description,
        'category': category,
        'roleType': roleType.asString,
        'locationType': locationType.asString,
        'commitment': commitment,
        'skillsRequired': skillsRequired,
        'isOpen': isOpen,
        'applicantCount': applicantCount,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Opportunity copyWith({
    String? title,
    String? description,
    String? category,
    RoleType? roleType,
    LocationType? locationType,
    String? commitment,
    List<String>? skillsRequired,
    bool? isOpen,
    int? applicantCount,
  }) {
    return Opportunity(
      id: id,
      startupId: startupId,
      startupName: startupName,
      startupLogoUrl: startupLogoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      roleType: roleType ?? this.roleType,
      locationType: locationType ?? this.locationType,
      commitment: commitment ?? this.commitment,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      isOpen: isOpen ?? this.isOpen,
      applicantCount: applicantCount ?? this.applicantCount,
      createdAt: createdAt,
    );
  }
}
