import 'package:flutter/material.dart';

import '../../domain/entities/app_setting_entity.dart';
import 'general_settings_tab.dart';

class PromotionSettingsTab extends StatelessWidget {
  const PromotionSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategorySettingsTab(
      category: AppSettingCategories.promotion,
      emptyIcon: Icons.campaign_outlined,
    );
  }
}
