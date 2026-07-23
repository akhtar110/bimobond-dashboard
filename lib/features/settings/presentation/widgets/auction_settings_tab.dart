import 'package:flutter/material.dart';

import '../../domain/entities/app_setting_entity.dart';
import 'general_settings_tab.dart';

class AuctionSettingsTab extends StatelessWidget {
  const AuctionSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategorySettingsTab(
      category: AppSettingCategories.auction,
      emptyIcon: Icons.gavel_outlined,
    );
  }
}
