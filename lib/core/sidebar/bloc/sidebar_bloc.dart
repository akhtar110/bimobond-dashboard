import 'package:flutter_bloc/flutter_bloc.dart';

import 'sidebar_event.dart';
import 'sidebar_state.dart';

export 'sidebar_event.dart';
export 'sidebar_state.dart';

class SidebarBloc extends Bloc<SidebarEvent, SidebarState> {
  SidebarBloc() : super(const SidebarState()) {
    on<ToggleSidebarEvent>(_onToggle);
    on<ExpandSidebarEvent>(_onExpand);
    on<CollapseSidebarEvent>(_onCollapse);
    on<SearchMenuEvent>(_onSearch);
    on<ToggleMenuGroupEvent>(_onToggleGroup);
  }

  void _onToggle(ToggleSidebarEvent event, Emitter<SidebarState> emit) {
    emit(state.copyWith(isCollapsed: !state.isCollapsed));
  }

  void _onExpand(ExpandSidebarEvent event, Emitter<SidebarState> emit) {
    if (!state.isCollapsed) return;
    emit(state.copyWith(isCollapsed: false));
  }

  void _onCollapse(CollapseSidebarEvent event, Emitter<SidebarState> emit) {
    if (state.isCollapsed) return;
    emit(state.copyWith(isCollapsed: true));
  }

  void _onSearch(SearchMenuEvent event, Emitter<SidebarState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onToggleGroup(ToggleMenuGroupEvent event, Emitter<SidebarState> emit) {
    final expanded = Set<String>.from(state.expandedGroups);
    if (expanded.contains(event.groupId)) {
      expanded.remove(event.groupId);
    } else {
      expanded.add(event.groupId);
    }
    emit(state.copyWith(expandedGroups: expanded));
  }
}
