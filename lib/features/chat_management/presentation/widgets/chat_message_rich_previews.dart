import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/external_url_opener.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../injection_container.dart' as di;
import '../../../post_management/domain/entities/managed_post_author_enrichment.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../post_management/domain/usecases/get_managed_post_by_id.dart';
import '../../../post_management/presentation/utils/post_management_navigation.dart';
import '../../domain/entities/chat_entities.dart';

class ChatPostSharePreview extends StatefulWidget {
  const ChatPostSharePreview({
    super.key,
    required this.message,
    this.bubbleStyle = false,
  });

  final ChatMessageEntity message;
  final bool bubbleStyle;

  @override
  State<ChatPostSharePreview> createState() => _ChatPostSharePreviewState();
}

class _ChatPostSharePreviewState extends State<ChatPostSharePreview> {
  ManagedPostEntity? _fetchedPost;
  bool _loading = false;
  String? _error;

  String? get _postId =>
      widget.message.sharedPostId?.trim().isNotEmpty == true
          ? widget.message.sharedPostId
          : widget.message.sharedPost?.id;

  @override
  void initState() {
    super.initState();
    _maybeFetchPost();
  }

  @override
  void didUpdateWidget(covariant ChatPostSharePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.sharedPostId != widget.message.sharedPostId) {
      _fetchedPost = null;
      _error = null;
      _maybeFetchPost();
    }
  }

  Future<void> _maybeFetchPost() async {
    final postId = _postId;
    if (postId == null || postId.isEmpty) return;
    if (widget.message.sharedPost != null) return;
    if (_fetchedPost != null || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final post = await di.sl<GetManagedPostById>()(postId);
      if (!mounted) return;
      setState(() {
        _fetchedPost = post;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  ManagedPostEntity _navigationPost() {
    final postId = _postId ?? '';
    if (_fetchedPost != null) return _fetchedPost!;
    final summary = widget.message.sharedPost;
    if (summary != null) {
      return managedPostSeed(postId).copyWith(
        type: summary.type ?? 'VIDEO',
        description: summary.description,
        thumbnailUrl: summary.thumbnailUrl,
        userName: summary.userName,
        userFullName: summary.userFullName,
        userProfileImage: summary.userProfileImage,
      );
    }
    return managedPostSeed(postId);
  }

  String? _thumbnailUrl() {
    final fromFetched = _fetchedPost?.previewThumbnailUrl;
    if (fromFetched != null && fromFetched.trim().isNotEmpty) {
      return MediaUrlResolver.resolve(fromFetched);
    }
    final fromSummary = widget.message.sharedPost?.thumbnailUrl;
    if (fromSummary != null && fromSummary.trim().isNotEmpty) {
      return MediaUrlResolver.resolve(fromSummary);
    }
    return null;
  }

  String _title(BuildContext context) {
    final description = _fetchedPost?.description?.trim() ??
        widget.message.sharedPost?.description?.trim();
    if (description != null && description.isNotEmpty) return description;

    final author = _authorLabel();
    if (author != null) {
      return context.tr('chatSharedPostBy', {'author': author});
    }
    return context.l10n.t('chatMessagePostShare');
  }

  String? _authorLabel() {
    final fullName = _fetchedPost?.userFullName?.trim() ??
        widget.message.sharedPost?.userFullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    final userName = _fetchedPost?.userName?.trim() ??
        widget.message.sharedPost?.userName?.trim();
    if (userName != null && userName.isNotEmpty) return '@$userName';
    return null;
  }

  Future<void> _openPost(BuildContext context) async {
    final postId = _postId;
    if (postId == null || postId.isEmpty) return;
    await navigateToPostManagementDetail(context, post: _navigationPost());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final postId = _postId;
    final thumbnail = _thumbnailUrl();
    final author = _authorLabel();

    if (postId == null || postId.isEmpty) {
      return Text(widget.message.content ?? l10n.t('chatMessagePostShare'));
    }

    if (widget.bubbleStyle) {
      final screenW = MediaQuery.sizeOf(context).width;
      final mediaHeight = (screenW * 0.16).clamp(64.0, 96.0);

      return Material(
        color: scheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openPost(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: mediaHeight,
                child: _PostThumbnail(
                  thumbnailUrl: thumbnail,
                  expand: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.share_rounded,
                            size: 13, color: scheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l10n.t('chatMessagePostShare'),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (_loading)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _title(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                    if (author != null)
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    Text(
                      l10n.t('chatViewPost'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                    if (_error != null)
                      Text(
                        l10n.t('chatPostLoadFailed'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.error,
                              fontSize: 11,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: scheme.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _openPost(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PostThumbnail(thumbnailUrl: thumbnail),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.share_rounded, size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.t('chatMessagePostShare'),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (_loading)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _title(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (author != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('chatViewPost'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.t('chatPostLoadFailed'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.error,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  const _PostThumbnail({this.thumbnailUrl, this.expand = false});

  final String? thumbnailUrl;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 56.0;

    Widget placeholder({double? w, double? h}) => Container(
          width: w,
          height: h,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.play_circle_outline_rounded,
            color: scheme.primary,
            size: expand ? 36 : 24,
          ),
        );

    if (thumbnailUrl == null) {
      if (expand) return placeholder();
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: placeholder(w: size, h: size),
        ),
      );
    }

    final image = CachedNetworkImage(
      imageUrl: thumbnailUrl!,
      width: expand ? null : size,
      height: expand ? null : size,
      fit: BoxFit.cover,
      errorWidget: (_, e, st) => placeholder(w: expand ? null : size, h: expand ? null : size),
    );

    if (expand) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }
}

class ChatLocationSharePreview extends StatelessWidget {
  const ChatLocationSharePreview({
    super.key,
    required this.payload,
    this.bubbleStyle = false,
  });

  final ChatMessageLocationPayload payload;
  final bool bubbleStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final subtitle = payload.displaySubtitle;
    final coords =
        '${payload.latitude.toStringAsFixed(5)}, ${payload.longitude.toStringAsFixed(5)}';
    final showCoords = payload.displayTitle != coords;

    if (bubbleStyle) {
      final screenW = MediaQuery.sizeOf(context).width;
      final mediaHeight = (screenW * 0.14).clamp(52.0, 72.0);

      return Material(
        color: scheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openExternalUrl(payload.mapsQueryUrl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: mediaHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer.withValues(alpha: 0.85),
                      scheme.secondaryContainer.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      size: mediaHeight * 0.55,
                      color: scheme.primary.withValues(alpha: 0.18),
                    ),
                    Icon(
                      Icons.location_on_rounded,
                      size: mediaHeight * 0.38,
                      color: scheme.error,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.t('chatMessageLocation'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payload.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    if (showCoords)
                      Text(
                        coords,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10.5,
                            ),
                      ),
                    Text(
                      l10n.t('chatOpenInMaps'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: scheme.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => openExternalUrl(payload.mapsQueryUrl),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_on_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('chatMessageLocation'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payload.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (showCoords) ...[
                      const SizedBox(height: 4),
                      Text(
                        coords,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('chatOpenInMaps'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
