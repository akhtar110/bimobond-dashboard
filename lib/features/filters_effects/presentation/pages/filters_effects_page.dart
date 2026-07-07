import 'package:flutter/material.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import 'filters_effects_management_page.dart';

class FiltersEffectsPage extends StatelessWidget {
  const FiltersEffectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PersistentBlocProvider<FiltersEffectsBloc>(
      debugLabel: 'FiltersEffectsPage',
      create: () => di.sl<FiltersEffectsBloc>()..add(const LoadFiltersEffects()),
      child: const FiltersEffectsManagementPage(),
    );
  }
}
