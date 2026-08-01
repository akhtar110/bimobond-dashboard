import '../../../../core/localization/localization.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/post_filters.dart';

String postSortLabel(
  AppLocalizations l10n,
  String? sort, {
  UserEntity? anchorUser,
  PostFilters? filters,
}) =>
    switch (sort) {
      PostFilters.sortPopular => l10n.t('postFilterSortPopular'),
      PostFilters.sortLatest => l10n.t('postFilterSortLatest'),
      PostFilters.sortAuthorAsc => l10n.t('postFilterSortAuthorAsc'),
      PostFilters.sortAuthorDesc => l10n.t('postFilterSortAuthorDesc'),
      PostFilters.sortCreatedAsc => l10n.t('postFilterSortCreatedAsc'),
      _ => l10n.t('postFilterSortCreatedDesc'),
    };
