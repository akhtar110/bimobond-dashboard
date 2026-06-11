import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/users_bloc.dart';
import '../widgets/users_filter_chips.dart';
import '../widgets/users_page_header.dart';
import '../widgets/users_search_bar.dart';
import '../widgets/users_table_panel.dart';

export '../users_ui_filter.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<UsersBloc>().add(LoadUsersEvent(refresh: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.scaffoldBackgroundColor,
                  const Color(0xFF0D1117),
                  primary.withValues(alpha: 0.04),
                ]
              : [
                  const Color(0xFFF7F9FC),
                  const Color(0xFFEEF2FF).withValues(alpha: 0.5),
                  Colors.white,
                ],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              MediaQuery.sizeOf(context).width < 600 ? 12 : 16,
              12,
              MediaQuery.sizeOf(context).width < 600 ? 12 : 16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UsersPageHeader(
                  onRefresh: () => context.read<UsersBloc>().add(
                        LoadUsersEvent(refresh: true),
                      ),
                ),
                SizedBox(height: MediaQuery.sizeOf(context).width < 600 ? 14 : 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 840;
                    final search = UsersSearchBar(
                      controller: _searchController,
                      onSubmitted: (value) => context.read<UsersBloc>().add(
                            SearchUsersEvent(value),
                          ),
                    );
                    final filters = UsersFilterChips(
                      onChanged: (filter) => context.read<UsersBloc>().add(
                            FilterUsersEvent(filter),
                          ),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          search,
                          const SizedBox(height: 14),
                          filters,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 5, child: search),
                        const SizedBox(width: 20),
                        Expanded(flex: 4, child: filters),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: UsersTablePanel(
                    horizontalScrollController: _horizontalScrollController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
