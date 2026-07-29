/// Client-side sort order for the location column (current result set).
enum UsersLocationSortOrder {
  none,
  ascending,
  descending;

  UsersLocationSortOrder get next => switch (this) {
        UsersLocationSortOrder.none => UsersLocationSortOrder.ascending,
        UsersLocationSortOrder.ascending => UsersLocationSortOrder.descending,
        UsersLocationSortOrder.descending => UsersLocationSortOrder.none,
      };
}
