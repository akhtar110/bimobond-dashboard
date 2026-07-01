import 'package:flutter/material.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../injection_container.dart' as di;
import '../../../promotions/presentation/bloc/location_intelligence_bloc.dart';
import '../widgets/user_location_intelligence_panel.dart';

class UserLocationsPage extends StatelessWidget {
  const UserLocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PersistentBlocProvider<LocationIntelligenceBloc>(
      debugLabel: 'UserLocationsPage',
      create: () => di.sl<LocationIntelligenceBloc>(),
      child: const UserLocationIntelligencePanel(
        enableMapZoomControls: true,
      ),
    );
  }
}
