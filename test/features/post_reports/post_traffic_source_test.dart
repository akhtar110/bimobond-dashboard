import 'package:flutter_test/flutter_test.dart';
import 'package:bimo_bond_dashboard/features/post_reports/domain/entities/post_report_entities.dart';

void main() {
  group('PostReportTrafficSourceBreakdown', () {
    test('normalizes canonical values and casing/whitespace', () {
      final breakdown = PostReportTrafficSourceBreakdown.fromMap({
        'for_you': 100,
        '  PROFILE  ': 50,
        'SEARCH': 30,
      });

      expect(breakdown.forYou, equals(100));
      expect(breakdown.profile, equals(50));
      expect(breakdown.search, equals(30));
      expect(breakdown.total, equals(180));
    });

    test('maps legacy server aliases correctly', () {
      final breakdown = PostReportTrafficSourceBreakdown.fromMap({
        'HASHTAG': 25,
        'SHARE_LINK': 15,
        'SHARE': 5,
        '': 10,
        'my_custom_tab': 7,
      });

      expect(breakdown.hashtags, equals(25));
      expect(breakdown.shares, equals(20)); // SHARE_LINK + SHARE merged
      expect(breakdown.forYou, equals(10)); // Empty string mapped to FOR_YOU
      expect(breakdown.other, equals(7)); // Unknown string mapped to OTHER
      expect(breakdown.total, equals(62));
    });

    test('returns sorted entries descending by view count', () {
      final breakdown = PostReportTrafficSourceBreakdown.fromMap({
        'FOR_YOU': 35000,
        'PROFILE': 8000,
        'SEARCH': 4000,
        'HASHTAGS': 2000,
        'SHARES': 1000,
        'OTHER': 50,
      });

      final entries = breakdown.sortedEntries;
      expect(entries.length, equals(6));
      expect(entries[0].key, equals('FOR_YOU'));
      expect(entries[0].value, equals(35000));
      expect(entries[1].key, equals('PROFILE'));
      expect(entries[1].value, equals(8000));
      expect(entries[5].key, equals('OTHER'));
      expect(entries[5].value, equals(50));
    });

    test('handles empty breakdown safely', () {
      const breakdown = PostReportTrafficSourceBreakdown();
      expect(breakdown.isEmpty, isTrue);
      expect(breakdown.total, equals(0));
      expect(breakdown.sortedEntries, isEmpty);
    });
  });
}
