import 'package:flutter/material.dart';

import '../../domain/entities/create_post_entity.dart';

/// Renders description with highlighted hashtags and @mentions.
class CreatePostRichDescription extends StatelessWidget {
  const CreatePostRichDescription({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;

  static final _tokenPattern = RegExp(r'(@\w+|#\w+)');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyLarge;
    final highlightColor = theme.colorScheme.primary;

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final token = match.group(0)!;
      final isMention = token.startsWith('@');
      spans.add(
        TextSpan(
          text: token,
          style: baseStyle?.copyWith(
            color: isMention ? highlightColor : highlightColor.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    if (spans.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines);
    }

    return RichText(
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

/// Convenience wrapper for preview sections.
class CreatePostRichDescriptionPreview extends StatelessWidget {
  const CreatePostRichDescriptionPreview({
    super.key,
    required this.form,
  });

  final CreatePostEntity form;

  @override
  Widget build(BuildContext context) {
    final description = form.description?.trim();
    if (description == null || description.isEmpty) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
    return CreatePostRichDescription(text: description);
  }
}
