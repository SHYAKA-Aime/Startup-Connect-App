import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/opportunity.dart';

/// Filters applied on the discovery screen. Kept as a small immutable value so
/// it can live in Riverpod state and be compared cheaply.
class OpportunityFilter {
  final String query;
  final String? category;
  final RoleType? roleType;
  final LocationType? locationType;

  const OpportunityFilter({
    this.query = '',
    this.category,
    this.roleType,
    this.locationType,
  });

  bool get isEmpty =>
      query.isEmpty &&
      category == null &&
      roleType == null &&
      locationType == null;

  OpportunityFilter copyWith({
    String? query,
    String? category,
    RoleType? roleType,
    LocationType? locationType,
    bool clearCategory = false,
    bool clearRole = false,
    bool clearLocation = false,
  }) {
    return OpportunityFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      roleType: clearRole ? null : (roleType ?? this.roleType),
      locationType: clearLocation ? null : (locationType ?? this.locationType),
    );
  }
}

/// Owns all reads/writes for the `opportunities` collection.
class OpportunityRepository {
  OpportunityRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('opportunities');

  /// Newest open opportunities — the home "Recent" feed. Streamed so a newly
  /// posted role appears on every student's phone in real time.
  Stream<List<Opportunity>> watchOpen({int limit = 30}) => _col
      .where('isOpen', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Opportunity.fromDoc).toList());

  /// All opportunities belonging to one startup — the startup's own dashboard.
  Stream<List<Opportunity>> watchByStartup(String startupId) => _col
      .where('startupId', isEqualTo: startupId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Opportunity.fromDoc).toList());

  Stream<Opportunity?> watchById(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Opportunity.fromDoc(d) : null);

  /// Discovery query. Firestore has no full-text search, so the category /
  /// role / location facets are pushed to the server and the free-text term is
  /// matched client-side over the already-narrow result set. This hybrid keeps
  /// reads cheap while still feeling like search — discussed in the report.
  Stream<List<Opportunity>> watchFiltered(OpportunityFilter f) {
    Query<Map<String, dynamic>> q = _col.where('isOpen', isEqualTo: true);
    if (f.category != null) q = q.where('category', isEqualTo: f.category);
    if (f.roleType != null) {
      q = q.where('roleType', isEqualTo: f.roleType!.asString);
    }
    if (f.locationType != null) {
      q = q.where('locationType', isEqualTo: f.locationType!.asString);
    }
    q = q.orderBy('createdAt', descending: true).limit(50);

    return q.snapshots().map((s) {
      var list = s.docs.map(Opportunity.fromDoc).toList();
      final term = f.query.trim().toLowerCase();
      if (term.isNotEmpty) {
        list = list
            .where((o) =>
                o.title.toLowerCase().contains(term) ||
                o.startupName.toLowerCase().contains(term) ||
                o.skillsRequired
                    .any((sk) => sk.toLowerCase().contains(term)))
            .toList();
      }
      return list;
    });
  }

  Future<String> create(Opportunity opp) async {
    final ref = await _col.add(opp.toMap());
    return ref.id;
  }

  /// Edits only the founder-editable content fields. Deliberately leaves
  /// `createdAt`, `applicantCount` and `isOpen` untouched so an edit never
  /// resets the post's age or its applicant counter.
  Future<void> update(Opportunity opp) => _col.doc(opp.id).update({
        'title': opp.title,
        'titleLower': opp.title.toLowerCase(),
        'description': opp.description,
        'category': opp.category,
        'roleType': opp.roleType.asString,
        'locationType': opp.locationType.asString,
        'commitment': opp.commitment,
        'skillsRequired': opp.skillsRequired,
      });

  Future<void> setOpen(String id, bool isOpen) =>
      _col.doc(id).update({'isOpen': isOpen});

  Future<void> delete(String id) => _col.doc(id).delete();
}
