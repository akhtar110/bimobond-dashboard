import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../../create_post/presentation/utils/create_post_geolocation.dart';
import '../../../post_management/data/utils/managed_post_location_hydration.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/repositories/users_repository.dart';
import '../../../users/presentation/utils/user_location_list_utils.dart';
import '../../domain/entities/post_filters.dart';
import '../../domain/utils/post_location_filter.dart';
import '../bloc/posts_bloc.dart';

String postsLocationProximityLabel(AppLocalizations l10n, PostFilters filters) {
  final place = filters.locationCity?.trim();
  if (place != null && place.isNotEmpty) {
    final localized = l10n.tArgs('postFilterLocationNear', {'place': place});
    if (localized != 'postFilterLocationNear') return localized;
    return 'Near $place';
  }
  return l10n.t('postFilterLocationSearch');
}

PostFilters postsFiltersClearLocation(PostFilters base) {
  return base.copyWith(clearLocation: true);
}

({double latitude, double longitude})? postsUserLocationCoordinates(
  UserEntity? user,
) {
  final loc = user?.lastLocation;
  final lat = loc?.latitude;
  final lng = loc?.longitude;
  if (lat == null || lng == null) return null;
  return (latitude: lat, longitude: lng);
}

String postsUserLocationLabel(AppLocalizations l10n, UserEntity user) {
  final place = userListLocationLabel(user);
  if (place.isNotEmpty) {
    final localized = l10n.tArgs('postFilterNearestToUserPlace', {
      'user': user.username,
      'place': place,
    });
    if (localized != 'postFilterNearestToUserPlace') return localized;
    return '@${user.username} ($place)';
  }
  final localized = l10n.tArgs('postFilterNearestToUserNamed', {
    'user': user.username,
  });
  if (localized != 'postFilterNearestToUserNamed') return localized;
  return '@${user.username}';
}

String? postsLocationErrorMessage(
  AppLocalizations l10n,
  CreatePostGeolocationResult result,
) {
  if (result.hasRealPosition) return null;
  if (result.permissionDenied) {
    return l10n.t('postFilterLocationPermissionDenied');
  }
  if (result.serviceDisabled) {
    return l10n.t('postFilterLocationServiceDisabled');
  }
  return l10n.t('postFilterLocationUnavailable');
}

UserEntity? _resolveAnchorUser(BuildContext context) {
  final bloc = context.read<PostsBloc>();
  return switch (bloc.state) {
    PostsLoaded(:final filterUser) => filterUser,
    PostsEmpty(:final filterUser) => filterUser,
    _ => bloc.filterUser,
  };
}

void _showLocationSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<UserEntity?> _resolveUserWithLocation(UserEntity? user) async {
  if (user == null) return null;
  if (postsUserLocationCoordinates(user) != null) return user;
  try {
    final detail = await di.sl<UsersRepository>().getUserById(user.id);
    return detail.user;
  } on Object {
    return user;
  }
}

/// Applies a radius filter anchored at a post's resolved display location.
void applyPostLocationProximityFilter(
  BuildContext context,
  ManagedPostEntity post, {
  PostFilters? baseFilters,
  void Function(PostFilters filters)? onApplied,
}) {
  final coords = managedPostFilterCoordinates(post);
  if (coords == null) {
    _showLocationSnackBar(
      context,
      context.l10n.t('postFilterUserLocationUnavailable'),
    );
    return;
  }

  final base = baseFilters ?? context.read<PostsBloc>().activeFilters;
  final label = managedPostListLocationLabel(post);
  final place = label != null && label.isNotEmpty
      ? label
      : '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';

  final next = base.copyWith(
    locationLatitude: coords.latitude,
    locationLongitude: coords.longitude,
    locationCity: place,
  );

  if (onApplied != null) {
    onApplied(next);
    return;
  }
  context.read<PostsBloc>().add(UpdatePostFiltersEvent(next));
}

/// Applies a geographic radius filter using the filtered user or device GPS.
Future<void> applyUserLocationProximityFilter(
  BuildContext context, {
  PostFilters? baseFilters,
  UserEntity? anchorUser,
  void Function(PostFilters filters)? onApplied,
}) async {
  final l10n = context.l10n;
  final base = baseFilters ?? context.read<PostsBloc>().activeFilters;
  var user = anchorUser ?? _resolveAnchorUser(context);
  user = await _resolveUserWithLocation(user);
  if (!context.mounted) return;

  final userCoords = postsUserLocationCoordinates(user);
  if (userCoords != null && user != null) {
    final next = base.copyWith(
      locationLatitude: userCoords.latitude,
      locationLongitude: userCoords.longitude,
      locationCity: postsUserLocationLabel(l10n, user),
    );
    if (onApplied != null) {
      onApplied(next);
      return;
    }
    context.read<PostsBloc>().add(UpdatePostFiltersEvent(next));
    return;
  }

  if (user != null) {
    if (context.mounted) {
      _showLocationSnackBar(
        context,
        l10n.t('postFilterUserLocationUnavailable'),
      );
    }
    return;
  }

  final geolocation = const CreatePostGeolocation();
  final result = await geolocation.getCurrentPosition();
  if (!context.mounted) return;

  if (!result.hasRealPosition) {
    final message = postsLocationErrorMessage(l10n, result);
    if (message != null) {
      _showLocationSnackBar(context, message);
    }
    return;
  }

  final next = base.copyWith(
    locationLatitude: result.point.latitude,
    locationLongitude: result.point.longitude,
    locationCity: l10n.t('postFilterMyLocationAnchor'),
  );

  if (onApplied != null) {
    onApplied(next);
    return;
  }

  context.read<PostsBloc>().add(UpdatePostFiltersEvent(next));
}
