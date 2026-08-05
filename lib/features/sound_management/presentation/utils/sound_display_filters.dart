import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';

/// Client-side display list for the library table (group + local query).
///
/// Status is always applied locally. Many backends treat `isActive=false` as
/// falsy and skip the Hidden filter, while `isActive=true` still works — so
/// without a client filter, Hidden keeps showing Active sounds.
List<SoundEntity> soundsForDisplay({
  required List<SoundEntity> librarySounds,
  required SoundsQuery query,
  SoundGroupEntity? selectedGroup,
}) {
  Iterable<SoundEntity> list;
  if (selectedGroup != null) {
    list = selectedGroup.sounds.map((m) => m.sound);
  } else {
    list = librarySounds;
  }

  final search = query.search?.trim().toLowerCase() ?? '';
  if (search.isNotEmpty && selectedGroup != null) {
    list = list.where(
      (s) =>
          s.name.toLowerCase().contains(search) ||
          s.author.toLowerCase().contains(search),
    );
  }

  // Active / Hidden (isActive false = deactivated). Always enforce in UI.
  if (query.isActive != null) {
    list = list.where((s) => s.isActive == query.isActive);
  }

  if (query.isFromDashboard != null) {
    list = list.where((s) => s.isFromDashboard == query.isFromDashboard);
  }

  final sorted = list.toList();
  if (selectedGroup != null) {
    switch (query.sort) {
      case SoundSortMode.trending:
        sorted.sort((a, b) => b.useCount.compareTo(a.useCount));
      case SoundSortMode.recent:
        sorted.sort((a, b) {
          final aD = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bD = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bD.compareTo(aD);
        });
      case SoundSortMode.alphabetical:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
  }

  return sorted;
}

int soundsAppliedFilterCount(SoundsQuery query) {
  var count = 0;
  if (query.isActive != true) count++;
  if (query.isFromDashboard != null) count++;
  if (query.sort != SoundSortMode.trending) count++;
  return count;
}
