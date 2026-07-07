import 'package:flutter/material.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/search_history_bloc.dart';
import '../bloc/search_history_event.dart';
import 'search_history_management_page.dart';

class SearchHistoryPage extends StatelessWidget {
  const SearchHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PersistentBlocProvider<SearchHistoryBloc>(
      debugLabel: 'SearchHistoryPage',
      create: () => di.sl<SearchHistoryBloc>()
        ..add(const SetSearchHistoryScope())
        ..add(const LoadSearchHistory()),
      child: const SearchHistoryManagementPage(),
    );
  }
}
