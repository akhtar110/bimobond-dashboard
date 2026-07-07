part of 'user_reports_bloc.dart';

sealed class UserReportsEvent extends Equatable {
  const UserReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadOverview extends UserReportsEvent {
  const LoadOverview({this.days = 30});
  final int days;

  @override
  List<Object?> get props => [days];
}

class LoadList extends UserReportsEvent {
  const LoadList({this.refresh = true});
  final bool refresh;

  @override
  List<Object?> get props => [refresh];
}

class LoadMore extends UserReportsEvent {
  const LoadMore();
}

class SearchChanged extends UserReportsEvent {
  const SearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class FilterChanged extends UserReportsEvent {
  const FilterChanged({
    this.isVerified,
    this.isBanned,
    this.role,
    this.clearVerified = false,
    this.clearBanned = false,
    this.clearRole = false,
  });

  final bool? isVerified;
  final bool? isBanned;
  final String? role;
  final bool clearVerified;
  final bool clearBanned;
  final bool clearRole;

  @override
  List<Object?> get props =>
      [isVerified, isBanned, role, clearVerified, clearBanned, clearRole];
}

class SortChanged extends UserReportsEvent {
  const SortChanged(this.sort);
  final UserReportSort sort;

  @override
  List<Object?> get props => [sort];
}

class GoToPage extends UserReportsEvent {
  const GoToPage(this.page);
  final int page;

  @override
  List<Object?> get props => [page];
}

class LoadDetail extends UserReportsEvent {
  const LoadDetail(this.userId, {this.days = 30});
  final String userId;
  final int days;

  @override
  List<Object?> get props => [userId, days];
}
