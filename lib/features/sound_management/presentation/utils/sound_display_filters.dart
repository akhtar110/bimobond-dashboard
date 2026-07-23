import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';

/// Client-side display list for the library table (group + local query).
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
    // Group view: apply search locally (library search is server-side).
    list = list.where(
      (s) =>
          s.name.toLowerCase().contains(search) ||
          s.author.toLowerCase().contains(search),
    );
  }

  if (query.isActive != null && selectedGroup != null) {
    list = list.where((s) => s.isActive == query.isActive);
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
  if (query.isActive != null) count++;
  if (query.sort != SoundSortMode.trending) count++;
  return count;
}
