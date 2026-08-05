import 'package:flutter/material.dart';

import 'investigation_theme.dart';
import 'post_filter_effect_section.dart';
import 'post_moderation_reports_section.dart';

/// Filter/effect metadata and user-submitted moderation reports for a post.
class PostDetailSupplementarySections extends StatelessWidget {
  const PostDetailSupplementarySections({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostFilterEffectSection(),
        SizedBox(height: InvestigationTheme.s8),
        PostModerationReportsSection(),
      ],
    );
  }
}
