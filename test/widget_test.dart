// Unit tests for the pure domain logic — the parts that carry the app's rules
// and can be tested without a Firebase connection. This is the fast, reliable
// core of the testing strategy described in the report.

import 'package:alu_ventures/features/applications/domain/application.dart';
import 'package:alu_ventures/features/auth/domain/app_user.dart';
import 'package:alu_ventures/features/opportunities/data/opportunity_repository.dart';
import 'package:alu_ventures/features/opportunities/domain/opportunity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('parses known and unknown values with a safe default', () {
      expect(UserRoleX.fromString('startup'), UserRole.startup);
      expect(UserRoleX.fromString('student'), UserRole.student);
      expect(UserRoleX.fromString(null), UserRole.student); // safe fallback
    });
  });

  group('Application', () {
    test('buildId is deterministic → prevents duplicate applications', () {
      final a = Application.buildId('opp123', 'userABC');
      final b = Application.buildId('opp123', 'userABC');
      expect(a, b);
      expect(a, 'opp123_userABC');
    });
  });

  group('Opportunity', () {
    test('toMap writes a lower-cased search key for prefix search', () {
      const opp = Opportunity(
        id: '1',
        startupId: 's1',
        startupName: 'Learnify',
        title: 'Flutter Developer',
        description: 'Build the app',
        category: 'Engineering',
        roleType: RoleType.partTime,
        locationType: LocationType.onCampus,
        commitment: '8-10 hrs/week',
      );
      final map = opp.toMap();
      expect(map['titleLower'], 'flutter developer');
      expect(map['roleType'], 'partTime');
    });
  });

  group('OpportunityFilter', () {
    test('isEmpty reflects whether any facet is active', () {
      const empty = OpportunityFilter();
      expect(empty.isEmpty, true);
      expect(empty.copyWith(category: 'Design').isEmpty, false);
    });

    test('clear flags reset individual facets', () {
      const f = OpportunityFilter(category: 'Design', query: 'ux');
      final cleared = f.copyWith(clearCategory: true);
      expect(cleared.category, isNull);
      expect(cleared.query, 'ux'); // query preserved
    });
  });
}
