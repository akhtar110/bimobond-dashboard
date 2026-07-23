import 'package:flutter/material.dart';

import '../../domain/entities/app_setting_entity.dart';
import 'general_settings_tab.dart';

class CommissionTab extends StatelessWidget {
  const CommissionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategorySettingsTab(
      category: AppSettingCategories.commission,
      emptyIcon: Icons.pie_chart_outline_outlined,
    );
  }
}
