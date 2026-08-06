import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Clean Architecture service to persist and restore the active dashboard navigation state
/// (sidebar index, active route/detail screen, page filters, tab selection)
/// across browser refreshes, tab reopens, and app restarts.
class NavigationPersistenceService {
  NavigationPersistenceService(this._prefs);

  final SharedPreferences _prefs;

  static const String _pageIndexKey = 'last_dashboard_page_index';
  static const String _pageIdentifierKey = 'last_dashboard_page_identifier';
  static const String _activeRouteNameKey = 'active_route_name';
  static const String _activeRouteArgsKey = 'active_route_args';
  static const String _userFiltersKey = 'users_page_filters';
  static const String _userDetailTabKey = 'user_detail_tab';

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
    } catch (_) {}
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
    } catch (_) {}
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

  /// Save active route and optional argument JSON map (e.g. for User Detail or Post Detail)
  Future<void> saveActiveRoute(String routeName, {Map<String, dynamic>? args}) async {
    try {
      await _prefs.setString(_activeRouteNameKey, routeName);
      if (args != null) {
        await _prefs.setString(_activeRouteArgsKey, jsonEncode(args));
      } else {
        await _prefs.remove(_activeRouteArgsKey);
      }
    } catch (_) {}
  }

  /// Clear active detail route when popping back
  Future<void> clearActiveRoute() async {
    try {
      await _prefs.remove(_activeRouteNameKey);
      await _prefs.remove(_activeRouteArgsKey);
    } catch (_) {}
  }

  /// Retrieve saved active route name
  String? getSavedRouteName() {
    try {
      return _prefs.getString(_activeRouteNameKey);
    } catch (_) {
      return null;
    }
  }

  /// Retrieve saved active route args map
  Map<String, dynamic>? getSavedRouteArgs() {
    try {
      final jsonStr = _prefs.getString(_activeRouteArgsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Save filters for Users Page
  Future<void> saveUsersFilters(Map<String, dynamic> filters) async {
    try {
      await _prefs.setString(_userFiltersKey, jsonEncode(filters));
    } catch (_) {}
  }

  /// Retrieve saved filters for Users Page
  Map<String, dynamic>? getUsersFilters() {
    try {
      final jsonStr = _prefs.getString(_userFiltersKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Save User Details tab index
  Future<void> saveUserDetailTab(int tabIndex) async {
    try {
      await _prefs.setInt(_userDetailTabKey, tabIndex);
    } catch (_) {}
  }

  /// Get User Details tab index
  int getUserDetailTab() {
    try {
      return _prefs.getInt(_userDetailTabKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Clear saved navigation state (called on logout or session expiration).
  Future<void> clearLastPage() async {
    await clearAllPersistence();
  }

  /// Clear ALL persisted navigation data
  Future<void> clearAllPersistence() async {
    try {
      await _prefs.remove(_pageIndexKey);
      await _prefs.remove(_pageIdentifierKey);
      await _prefs.remove(_activeRouteNameKey);
      await _prefs.remove(_activeRouteArgsKey);
      await _prefs.remove(_userFiltersKey);
      await _prefs.remove(_userDetailTabKey);
    } catch (_) {}
  }
}
