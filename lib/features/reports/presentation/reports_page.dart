import 'package:flutter/material.dart';

import '../../../core/localization/localization.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView.builder(
      padding: const EdgeInsetsDirectional.all(16),
      itemCount: 10,
      itemBuilder: (_, index) {
        return Card(
          margin: const EdgeInsetsDirectional.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.t('reportReason')}: Spam #$index'),
                Text('${l10n.t('reporter')}: user_${100 + index}'),
                Text('${l10n.t('target')}: video_${200 + index}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(onPressed: () {}, child: Text(l10n.t('ignore'))),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () {},
                      child: Text(l10n.t('delete')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () {}, child: Text(l10n.t('ban'))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
