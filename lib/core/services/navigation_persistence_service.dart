import 'package:shared_preferences/shared_preferences.dart';

/// Clean Architecture service to persist and restore the active dashboard navigation state
/// across browser refreshes, tab reopens, and sessions on Flutter Web.
class NavigationPersistenceService {
  NavigationPersistenceService(this._prefs);

  final SharedPreferences _prefs;

  static const String _pageIndexKey = 'last_dashboard_page_index';
  static const String _pageIdentifierKey = 'last_dashboard_page_identifier';

  static const Map<int, String> indexToIdentifierMap = {
    0: 'analytics',
    1: 'search-management',
    2: 'users',
    3: 'user-locations',
    4: 'search-history',
    5: 'posts',
    6: 'stories',
    7: 'categories',
    8: 'chat-management',
    9: 'auctions',
    10: 'gifts',
    11: 'wallets',
    12: 'promotions',
    13: 'sounds',
    14: 'reports',
    15: 'notifications',
    16: 'filters-effects',
    17: 'settings',
    18: 'roles',
    19: 'logs',
    20: 'profile',
  };

  static final Map<String, int> identifierToIndexMap = {
    for (final entry in indexToIdentifierMap.entries) entry.value: entry.key,
  };

  /// Save the current active page index and human-readable identifier.
  Future<void> saveLastPageIndex(int index) async {
    try {
      await _prefs.setInt(_pageIndexKey, index);
      final identifier = indexToIdentifierMap[index] ?? 'analytics';
      await _prefs.setString(_pageIdentifierKey, identifier);
    } catch (_) {
      // Ignore storage errors to ensure app stability.
    }
  }

  /// Retrieve the saved page index if valid.
  int? getSavedPageIndex() {
    try {
      final savedIndex = _prefs.getInt(_pageIndexKey);
      if (savedIndex != null && indexToIdentifierMap.containsKey(savedIndex)) {
        return savedIndex;
      }
      final savedIdentifier = _prefs.getString(_pageIdentifierKey);
      if (savedIdentifier != null &&
          identifierToIndexMap.containsKey(savedIdentifier)) {
        return identifierToIndexMap[savedIdentifier];
      }
    } catch (_) {
      // Ignore reading errors to ensure app stability.
    }
    return null;
  }

  /// Retrieve the saved page identifier.
  String? getSavedPageIdentifier() {
    try {
      return _prefs.getString(_pageIdentifierKey);
    } catch (_) {
      return null;
    }
  }

  /// Clear saved navigation state (called on logout).
  Future<void> clearLastPage() async {
    try {
      await _prefs.remove(_pageIndexKey);
      await _prefs.remove(_pageIdentifierKey);
    } catch (_) {
      // Ignore deletion errors.
    }
  }
}
