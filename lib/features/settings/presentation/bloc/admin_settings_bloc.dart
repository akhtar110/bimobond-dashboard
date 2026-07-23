import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_setting_entity.dart';
import '../../domain/entities/settings_admin_entities.dart';
import '../../domain/usecases/app_setting_usecases.dart';

enum AdminSettingsTab {
  overview,
  economy,
  appSettings,
  general,
  branding,
  commission,
  currencies,
  auction,
  promotion,
  features,
  notifications,
  uploads,
  defaults,
}

enum SettingsSortOption {
  alphabetical,
  category,
  recentlyUpdated,
  sortOrder,
}

enum SettingsVisibilityFilter {
  all,
  publicOnly,
  privateOnly,
}

// ── Events ───────────────────────────────────────────────────────────────────

abstract class AdminSettingsEvent extends Equatable {
  const AdminSettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminSettingsEvent extends AdminSettingsEvent {
  const LoadAdminSettingsEvent({this.refresh = false});
  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class ChangeAdminSettingsTabEvent extends AdminSettingsEvent {
  const ChangeAdminSettingsTabEvent(this.tab);
  final AdminSettingsTab tab;

  @override
  List<Object?> get props => [tab];
}

class UpdateSettingsSearchEvent extends AdminSettingsEvent {
  const UpdateSettingsSearchEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class ApplySettingsFiltersEvent extends AdminSettingsEvent {
  const ApplySettingsFiltersEvent({
    this.category,
    this.visibility = SettingsVisibilityFilter.all,
    this.type,
    this.sort = SettingsSortOption.sortOrder,
  });

  final String? category;
  final SettingsVisibilityFilter visibility;
  final String? type;
  final SettingsSortOption sort;

  @override
  List<Object?> get props => [category, visibility, type, sort];
}

class ClearSettingsFiltersEvent extends AdminSettingsEvent {
  const ClearSettingsFiltersEvent();
}

class SeedAdminSettingsEvent extends AdminSettingsEvent {
  const SeedAdminSettingsEvent();
}

class CreateAdminSettingEvent extends AdminSettingsEvent {
  const CreateAdminSettingEvent(this.setting);
  final AppSettingEntity setting;

  @override
  List<Object?> get props => [setting];
}

class UpdateAdminSettingEvent extends AdminSettingsEvent {
  const UpdateAdminSettingEvent(this.setting);
  final AppSettingEntity setting;

  @override
  List<Object?> get props => [setting];
}

class DeleteAdminSettingEvent extends AdminSettingsEvent {
  const DeleteAdminSettingEvent(this.key);
  final String key;

  @override
  List<Object?> get props => [key];
}

class UpdateAdminBrandingEvent extends AdminSettingsEvent {
  const UpdateAdminBrandingEvent({
    this.appName,
    this.tagline,
    this.supportEmail,
    this.logoUrl,
  });

  final String? appName;
  final String? tagline;
  final String? supportEmail;
  final String? logoUrl;

  @override
  List<Object?> get props => [appName, tagline, supportEmail, logoUrl];
}

class CreateAdminCurrencyEvent extends AdminSettingsEvent {
  const CreateAdminCurrencyEvent(this.currency);
  final AppCurrencyEntity currency;

  @override
  List<Object?> get props => [currency];
}

class UpdateAdminCurrencyEvent extends AdminSettingsEvent {
  const UpdateAdminCurrencyEvent(this.currency);
  final AppCurrencyEntity currency;

  @override
  List<Object?> get props => [currency];
}

class DeleteAdminCurrencyEvent extends AdminSettingsEvent {
  const DeleteAdminCurrencyEvent(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

class ClearAdminSettingsFeedbackEvent extends AdminSettingsEvent {
  const ClearAdminSettingsFeedbackEvent();
}

// ── State ────────────────────────────────────────────────────────────────────

class AdminSettingsState extends Equatable {
  const AdminSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.isSeeding = false,
    this.tab = AdminSettingsTab.overview,
    this.grouped = const {},
    this.categories = const [],
    this.settings = const [],
    this.defaults = const SettingsDefaultsEntity(),
    this.branding,
    this.currencies = const [],
    this.searchQuery = '',
    this.filterCategory,
    this.visibilityFilter = SettingsVisibilityFilter.all,
    this.filterType,
    this.sort = SettingsSortOption.sortOrder,
    this.error,
    this.message,
    this.messageIsError = false,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isSeeding;
  final AdminSettingsTab tab;
  final Map<String, List<AppSettingEntity>> grouped;
  final List<String> categories;
  final List<AppSettingEntity> settings;
  final SettingsDefaultsEntity defaults;
  final AppBrandingEntity? branding;
  final List<AppCurrencyEntity> currencies;
  final String searchQuery;
  final String? filterCategory;
  final SettingsVisibilityFilter visibilityFilter;
  final String? filterType;
  final SettingsSortOption sort;
  final String? error;
  final String? message;
  final bool messageIsError;

  int get totalSettings => settings.length;
  int get publicCount => settings.where((s) => s.isPublic).length;
  int get privateCount => settings.where((s) => !s.isPublic).length;
  int get currencyCount => currencies.length;
  int get featureFlagCount => settings
      .where(
        (s) =>
            s.isBoolean &&
            (s.category == AppSettingCategories.features ||
                s.category == AppSettingCategories.auction ||
                s.category == AppSettingCategories.promotion ||
                s.key.startsWith('NOTIFICATIONS_') ||
                s.key.endsWith('_ENABLED')),
      )
      .length;
  int get uploadSettingsCount => settings
      .where((s) => UploadSettingKeys.all.contains(s.key))
      .length;

  bool get hasActiveFilters =>
      (filterCategory != null && filterCategory!.isNotEmpty) ||
      visibilityFilter != SettingsVisibilityFilter.all ||
      (filterType != null && filterType!.isNotEmpty) ||
      sort != SettingsSortOption.sortOrder;

  List<AppSettingEntity> get filteredSettings {
    var list = List<AppSettingEntity>.from(settings);
    final q = searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.key.toLowerCase().contains(q) ||
            (s.label?.toLowerCase().contains(q) ?? false) ||
            (s.description?.toLowerCase().contains(q) ?? false) ||
            (s.category?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    if (filterCategory != null && filterCategory!.isNotEmpty) {
      list = list.where((s) => s.category == filterCategory).toList();
    }
    switch (visibilityFilter) {
      case SettingsVisibilityFilter.publicOnly:
        list = list.where((s) => s.isPublic).toList();
      case SettingsVisibilityFilter.privateOnly:
        list = list.where((s) => !s.isPublic).toList();
      case SettingsVisibilityFilter.all:
        break;
    }
    if (filterType != null && filterType!.isNotEmpty) {
      list = list
          .where((s) => s.type.toUpperCase() == filterType!.toUpperCase())
          .toList();
    }

    switch (sort) {
      case SettingsSortOption.alphabetical:
        list.sort(
          (a, b) => a.displayLabel.toLowerCase().compareTo(
                b.displayLabel.toLowerCase(),
              ),
        );
      case SettingsSortOption.category:
        list.sort((a, b) {
          final c = (a.category ?? '').compareTo(b.category ?? '');
          if (c != 0) return c;
          return a.sortOrder.compareTo(b.sortOrder);
        });
      case SettingsSortOption.recentlyUpdated:
        list.sort((a, b) {
          final aAt = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bAt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bAt.compareTo(aAt);
        });
      case SettingsSortOption.sortOrder:
        list.sort((a, b) {
          final c = a.sortOrder.compareTo(b.sortOrder);
          if (c != 0) return c;
          return a.key.compareTo(b.key);
        });
    }
    return list;
  }

  Map<String, List<AppSettingEntity>> get filteredGrouped {
    final map = <String, List<AppSettingEntity>>{};
    for (final setting in filteredSettings) {
      final cat = setting.category ?? AppSettingCategories.general;
      map.putIfAbsent(cat, () => []).add(setting);
    }
    return map;
  }

  AppSettingEntity? settingByKey(String key) {
    for (final s in settings) {
      if (s.key == key) return s;
    }
    return null;
  }

  List<AppSettingEntity> settingsForCategory(String category) {
    return filteredSettings.where((s) => s.category == category).toList();
  }

  List<AppSettingEntity> settingsByKeys(Iterable<String> keys) {
    final set = keys.toSet();
    return filteredSettings.where((s) => set.contains(s.key)).toList();
  }

  AdminSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSeeding,
    AdminSettingsTab? tab,
    Map<String, List<AppSettingEntity>>? grouped,
    List<String>? categories,
    List<AppSettingEntity>? settings,
    SettingsDefaultsEntity? defaults,
    AppBrandingEntity? branding,
    List<AppCurrencyEntity>? currencies,
    String? searchQuery,
    String? filterCategory,
    bool clearFilterCategory = false,
    SettingsVisibilityFilter? visibilityFilter,
    String? filterType,
    bool clearFilterType = false,
    SettingsSortOption? sort,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
    bool? messageIsError,
  }) {
    return AdminSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSeeding: isSeeding ?? this.isSeeding,
      tab: tab ?? this.tab,
      grouped: grouped ?? this.grouped,
      categories: categories ?? this.categories,
      settings: settings ?? this.settings,
      defaults: defaults ?? this.defaults,
      branding: branding ?? this.branding,
      currencies: currencies ?? this.currencies,
      searchQuery: searchQuery ?? this.searchQuery,
      filterCategory:
          clearFilterCategory ? null : (filterCategory ?? this.filterCategory),
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      sort: sort ?? this.sort,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
      messageIsError: messageIsError ?? this.messageIsError,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        isSeeding,
        tab,
        grouped,
        categories,
        settings,
        defaults,
        branding,
        currencies,
        searchQuery,
        filterCategory,
        visibilityFilter,
        filterType,
        sort,
        error,
        message,
        messageIsError,
      ];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

class AdminSettingsBloc extends Bloc<AdminSettingsEvent, AdminSettingsState> {
  AdminSettingsBloc({
    required LoadAdminSettingsBundleUseCase loadBundle,
    required SeedSettingsUseCase seedSettings,
    required CreateAppSettingUseCase createSetting,
    required UpdateAppSettingUseCase updateSetting,
    required DeleteAppSettingUseCase deleteSetting,
    required UpdateBrandingUseCase updateBranding,
    required CreateCurrencyUseCase createCurrency,
    required UpdateCurrencyUseCase updateCurrency,
    required DeleteCurrencyUseCase deleteCurrency,
  })  : _loadBundle = loadBundle,
        _seedSettings = seedSettings,
        _createSetting = createSetting,
        _updateSetting = updateSetting,
        _deleteSetting = deleteSetting,
        _updateBranding = updateBranding,
        _createCurrency = createCurrency,
        _updateCurrency = updateCurrency,
        _deleteCurrency = deleteCurrency,
        super(const AdminSettingsState()) {
    on<LoadAdminSettingsEvent>(_onLoad);
    on<ChangeAdminSettingsTabEvent>(_onChangeTab);
    on<UpdateSettingsSearchEvent>(_onSearch);
    on<ApplySettingsFiltersEvent>(_onApplyFilters);
    on<ClearSettingsFiltersEvent>(_onClearFilters);
    on<SeedAdminSettingsEvent>(_onSeed);
    on<CreateAdminSettingEvent>(_onCreateSetting);
    on<UpdateAdminSettingEvent>(_onUpdateSetting);
    on<DeleteAdminSettingEvent>(_onDeleteSetting);
    on<UpdateAdminBrandingEvent>(_onUpdateBranding);
    on<CreateAdminCurrencyEvent>(_onCreateCurrency);
    on<UpdateAdminCurrencyEvent>(_onUpdateCurrency);
    on<DeleteAdminCurrencyEvent>(_onDeleteCurrency);
    on<ClearAdminSettingsFeedbackEvent>(_onClearFeedback);
  }

  final LoadAdminSettingsBundleUseCase _loadBundle;
  final SeedSettingsUseCase _seedSettings;
  final CreateAppSettingUseCase _createSetting;
  final UpdateAppSettingUseCase _updateSetting;
  final DeleteAppSettingUseCase _deleteSetting;
  final UpdateBrandingUseCase _updateBranding;
  final CreateCurrencyUseCase _createCurrency;
  final UpdateCurrencyUseCase _updateCurrency;
  final DeleteCurrencyUseCase _deleteCurrency;

  Future<void> _onLoad(
    LoadAdminSettingsEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearMessage: true,
      ),
    );
    try {
      final bundle = await _loadBundle();
      emit(
        state.copyWith(
          isLoading: false,
          grouped: bundle.grouped.grouped,
          categories: bundle.grouped.categories,
          settings: bundle.grouped.flat,
          defaults: bundle.defaults,
          branding: bundle.branding,
          currencies: bundle.currencies,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  void _onChangeTab(
    ChangeAdminSettingsTabEvent event,
    Emitter<AdminSettingsState> emit,
  ) {
    emit(state.copyWith(tab: event.tab));
  }

  void _onSearch(
    UpdateSettingsSearchEvent event,
    Emitter<AdminSettingsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onApplyFilters(
    ApplySettingsFiltersEvent event,
    Emitter<AdminSettingsState> emit,
  ) {
    emit(
      state.copyWith(
        filterCategory: event.category,
        clearFilterCategory: event.category == null,
        visibilityFilter: event.visibility,
        filterType: event.type,
        clearFilterType: event.type == null,
        sort: event.sort,
      ),
    );
  }

  void _onClearFilters(
    ClearSettingsFiltersEvent event,
    Emitter<AdminSettingsState> emit,
  ) {
    emit(
      state.copyWith(
        clearFilterCategory: true,
        clearFilterType: true,
        visibilityFilter: SettingsVisibilityFilter.all,
        sort: SettingsSortOption.sortOrder,
        searchQuery: '',
      ),
    );
  }

  Future<void> _onSeed(
    SeedAdminSettingsEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSeeding: true, clearError: true, clearMessage: true));
    try {
      final result = await _seedSettings();
      final bundle = await _loadBundle();
      emit(
        state.copyWith(
          isSeeding: false,
          grouped: bundle.grouped.grouped,
          categories: bundle.grouped.categories,
          settings: bundle.grouped.flat,
          defaults: bundle.defaults,
          branding: bundle.branding,
          currencies: bundle.currencies,
          message: 'settingsSeedSuccess:${result.seeded}',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSeeding: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onCreateSetting(
    CreateAdminSettingEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await _createSetting(event.setting);
      final bundle = await _loadBundle();
      emit(
        state.copyWith(
          isSaving: false,
          grouped: bundle.grouped.grouped,
          categories: bundle.grouped.categories,
          settings: bundle.grouped.flat,
          message: 'settingCreated',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onUpdateSetting(
    UpdateAdminSettingEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      final updated = await _updateSetting(event.setting);
      final next = [
        for (final s in state.settings)
          if (s.key == updated.key) updated else s,
      ];
      final grouped = <String, List<AppSettingEntity>>{};
      for (final s in next) {
        grouped.putIfAbsent(s.category ?? AppSettingCategories.general, () => [])
            .add(s);
      }
      emit(
        state.copyWith(
          isSaving: false,
          settings: next,
          grouped: grouped,
          message: 'settingUpdated',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onDeleteSetting(
    DeleteAdminSettingEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await _deleteSetting(event.key);
      final next = state.settings.where((s) => s.key != event.key).toList();
      final grouped = <String, List<AppSettingEntity>>{};
      for (final s in next) {
        grouped
            .putIfAbsent(s.category ?? AppSettingCategories.general, () => [])
            .add(s);
      }
      emit(
        state.copyWith(
          isSaving: false,
          settings: next,
          grouped: grouped,
          message: 'settingDeleted',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onUpdateBranding(
    UpdateAdminBrandingEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      final branding = await _updateBranding(
        appName: event.appName,
        tagline: event.tagline,
        supportEmail: event.supportEmail,
        logoUrl: event.logoUrl,
      );
      emit(
        state.copyWith(
          isSaving: false,
          branding: branding,
          message: 'brandingUpdated',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onCreateCurrency(
    CreateAdminCurrencyEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      final created = await _createCurrency(event.currency);
      emit(
        state.copyWith(
          isSaving: false,
          currencies: [...state.currencies, created],
          message: 'currencyCreated',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onUpdateCurrency(
    UpdateAdminCurrencyEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      final updated = await _updateCurrency(event.currency);
      // If default flipped, clear others locally.
      final next = [
        for (final c in state.currencies)
          if (c.code == updated.code)
            updated
          else if (updated.isDefault)
            c.copyWith(isDefault: false)
          else
            c,
      ];
      emit(
        state.copyWith(
          isSaving: false,
          currencies: next,
          message: 'currencyUpdated',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  Future<void> _onDeleteCurrency(
    DeleteAdminCurrencyEvent event,
    Emitter<AdminSettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await _deleteCurrency(event.code);
      emit(
        state.copyWith(
          isSaving: false,
          currencies: state.currencies
              .where((c) => c.code.toUpperCase() != event.code.toUpperCase())
              .toList(),
          message: 'currencyDeleted',
          messageIsError: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          message: e.toString(),
          messageIsError: true,
        ),
      );
    }
  }

  void _onClearFeedback(
    ClearAdminSettingsFeedbackEvent event,
    Emitter<AdminSettingsState> emit,
  ) {
    emit(state.copyWith(clearMessage: true, clearError: true));
  }
}
