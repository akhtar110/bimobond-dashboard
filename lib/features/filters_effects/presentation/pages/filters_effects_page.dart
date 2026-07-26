import 'package:flutter/material.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../injection_container.dart' as di;
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../rbac/presentation/widgets/access_denied_view.dart';
import '../bloc/ar_overlays_bloc.dart';
import '../bloc/ar_overlays_event.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import 'filters_effects_management_page.dart';

class FiltersEffectsPage extends StatelessWidget {
  const FiltersEffectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureAccessBoundary(
      canAccess: PermissionManager.canManageCameraStudio,
      child: PersistentBlocProvider<FiltersEffectsBloc>(
        debugLabel: 'FiltersEffectsPage',
        create: () =>
            di.sl<FiltersEffectsBloc>()..add(const LoadFiltersEffects()),
        child: PersistentBlocProvider<ArOverlaysBloc>(
          debugLabel: 'ArOverlaysPage',
          create: () =>
              di.sl<ArOverlaysBloc>()..add(const LoadArOverlaysEvent()),
          child: const FiltersEffectsManagementPage(),
        ),
      ),
    );
  }
}
