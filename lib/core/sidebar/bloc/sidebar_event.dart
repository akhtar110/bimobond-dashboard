import 'package:equatable/equatable.dart';

sealed class SidebarEvent extends Equatable {
  const SidebarEvent();

  @override
  List<Object?> get props => [];
}

class ToggleSidebarEvent extends SidebarEvent {
  const ToggleSidebarEvent();
}

class ExpandSidebarEvent extends SidebarEvent {
  const ExpandSidebarEvent();
}

class CollapseSidebarEvent extends SidebarEvent {
  const CollapseSidebarEvent();
}

class SearchMenuEvent extends SidebarEvent {
  const SearchMenuEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class ToggleMenuGroupEvent extends SidebarEvent {
  const ToggleMenuGroupEvent(this.groupId);
  final String groupId;

  @override
  List<Object?> get props => [groupId];
}
