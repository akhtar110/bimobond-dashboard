import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/user_detail_bloc.dart';
import '../widgets/user_detail_activity_tabs.dart';
import '../widgets/user_detail_header.dart';
import '../widgets/user_detail_stats_grid.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final UserEntity user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: scheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.t('userDetails'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<UserDetailBloc, UserDetailState>(
        builder: (context, state) {
          if (state is UserDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserDetailError) {
            return Center(child: Text(state.message));
          }

          if (state is UserDetailLoaded) {
            final user = state.userDetail.user;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserDetailHeader(user: user),
                  const SizedBox(height: 12),
                  UserDetailStatsGrid(user: user),
                  const SizedBox(height: 12),
                  UserDetailInfoActivitySection(
                    user: user,
                    isDark: isDark,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
