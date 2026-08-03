import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/search_debounce.dart';
import '../../../../injection_container.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../post_management/domain/usecases/get_managed_post_by_id.dart';
import '../../../posts/domain/entities/post_filters.dart';
import '../../../posts/domain/usecases/get_all_posts_usecase.dart';

const int _kMaxResults = 6;
const double _kItemHeight = 52;

/// Searchable post picker — admin searches by description/author; [postId] is resolved from the selection.
class AuctionPostSearchField extends StatefulWidget {
  const AuctionPostSearchField({
    super.key,
    required this.onPostSelected,
    this.selectedPost,
    this.initialPostId,
    this.label,
    this.hintText,
  });

  final ValueChanged<ManagedPostEntity?> onPostSelected;
  final ManagedPostEntity? selectedPost;
  final String? initialPostId;
  final String? label;
  final String? hintText;

  @override
  State<AuctionPostSearchField> createState() => _AuctionPostSearchFieldState();
}

class _AuctionPostSearchFieldState extends State<AuctionPostSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _searchGuard = SearchRequestGuard();
  Timer? _debounce;

  bool _showDropdown = false;
  bool _loading = false;
  bool _searched = false;
  bool _resolvingInitial = false;
  bool _replacing = false;
  bool _dropdownPointerDown = false;
  List<ManagedPostEntity> _results = [];

  GetAllPosts get _getAllPosts => sl<GetAllPosts>();
  GetManagedPostById get _getPostById => sl<GetManagedPostById>();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    if (widget.selectedPost != null) {
      _controller.text = postDisplayLabel(widget.selectedPost!);
    } else if (widget.initialPostId != null &&
        widget.initialPostId!.trim().isNotEmpty) {
      _resolveInitial(widget.initialPostId!.trim());
    }
  }

  @override
  void didUpdateWidget(covariant AuctionPostSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPost?.id == oldWidget.selectedPost?.id) return;
    if (widget.selectedPost != null) {
      _replacing = false;
      _controller.text = postDisplayLabel(widget.selectedPost!);
      setState(() {
        _showDropdown = false;
        _results = [];
      });
      return;
    }
    if (!_replacing) {
      _controller.clear();
    }
  }

  Future<void> _resolveInitial(String postId) async {
    setState(() => _resolvingInitial = true);
    try {
      final post = await _getPostById(postId);
      if (!mounted) return;
      widget.onPostSelected(post);
      _controller.text = postDisplayLabel(post);
    } catch (_) {
      if (!mounted) return;
      _controller.text = context.l10n.tOr('linkedPost', 'Linked post');
    } finally {
      if (mounted) setState(() => _resolvingInitial = false);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.trim().isNotEmpty && widget.selectedPost == null) {
        setState(() => _showDropdown = true);
      }
      return;
    }
    if (!_showDropdown || _dropdownPointerDown) return;
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _focusNode.hasFocus || _dropdownPointerDown) return;
      setState(() => _showDropdown = false);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (widget.selectedPost != null) {
      _replacing = true;
      widget.onPostSelected(null);
    }

    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchGuard.next();
      setState(() {
        _showDropdown = false;
        _loading = false;
        _searched = false;
        _results = [];
      });
      return;
    }

    setState(() => _showDropdown = true);
    _debounce = Timer(dashboardSearchDebounce, () async {
      final token = _searchGuard.next();
      if (!mounted) return;
      setState(() {
        _loading = true;
        _searched = false;
      });
      try {
        final page = await _getAllPosts(
          page: 1,
          limit: _kMaxResults,
          filters: PostFilters(search: trimmed),
        );
        if (!mounted || !_searchGuard.isCurrent(token)) return;
        setState(() {
          _results = page.posts.take(_kMaxResults).toList();
          _loading = false;
          _searched = true;
        });
      } catch (_) {
        if (!mounted || !_searchGuard.isCurrent(token)) return;
        setState(() {
          _results = [];
          _loading = false;
          _searched = true;
        });
      }
    });
  }

  void _select(ManagedPostEntity post) {
    _replacing = false;
    widget.onPostSelected(post);
    _controller.text = postDisplayLabel(post);
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
      _searched = false;
    });
    _focusNode.unfocus();
  }

  void _clear() {
    _replacing = false;
    _controller.clear();
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
      _searched = false;
    });
    widget.onPostSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = widget.label ?? l10n.tOr('linkedPost', 'Linked post');
    final hint = widget.hintText ??
        l10n.tOr('searchPostHint', 'Search by description or author…');
    final showDropdown = _showDropdown &&
        (widget.selectedPost == null || _replacing) &&
        (_loading || _searched || _controller.text.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onTap: () {
            if (_controller.text.trim().isNotEmpty) {
              setState(() => _showDropdown = true);
            }
          },
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(
              Icons.video_file_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading || _resolvingInitial)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (widget.selectedPost != null ||
                    _controller.text.trim().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: scheme.onSurfaceVariant,
                    tooltip: l10n.t('clear'),
                    onPressed: _clear,
                  ),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        if (showDropdown)
          Listener(
            onPointerDown: (_) => _dropdownPointerDown = true,
            onPointerUp: (_) => _dropdownPointerDown = false,
            onPointerCancel: (_) => _dropdownPointerDown = false,
            child: _PostDropdown(
              loading: _loading,
              results: _results,
              searched: _searched,
              onSelected: _select,
            ),
          ),
      ],
    );
  }
}

String postDisplayLabel(ManagedPostEntity post) {
  final desc = post.description?.trim();
  final author = post.userName?.trim();
  final descPart = (desc != null && desc.isNotEmpty)
      ? (desc.length > 48 ? '${desc.substring(0, 48)}…' : desc)
      : 'Untitled post';
  if (author != null && author.isNotEmpty) {
    return '$descPart · @$author';
  }
  return descPart;
}

class _PostDropdown extends StatelessWidget {
  const _PostDropdown({
    required this.loading,
    required this.results,
    required this.searched,
    required this.onSelected,
  });

  final bool loading;
  final List<ManagedPostEntity> results;
  final bool searched;
  final ValueChanged<ManagedPostEntity> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4),
      child: Material(
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: 0.14),
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _kMaxResults * _kItemHeight + 8),
            child: loading
                ? const SizedBox(
                    height: _kItemHeight,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : results.isEmpty
                    ? SizedBox(
                        height: _kItemHeight,
                        child: Center(
                          child: Text(
                            searched
                                ? l10n.tOr('noPostsFound', 'No posts found')
                                : l10n.tOr(
                                    'searchPostHint',
                                    'Search by description or author…',
                                  ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                        itemBuilder: (context, index) {
                          final post = results[index];
                          final thumb = post.displayThumbnailUrl;
                          final author = post.userName;
                          return InkWell(
                            onTap: () => onSelected(post),
                            child: SizedBox(
                              height: _kItemHeight,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: thumb != null
                                            ? Image.network(
                                                thumb,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    ColoredBox(
                                                  color: scheme
                                                      .surfaceContainerHighest,
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    size: 16,
                                                    color: scheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              )
                                            : ColoredBox(
                                                color: scheme
                                                    .surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.image_outlined,
                                                  size: 16,
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.description?.trim().isNotEmpty ==
                                                    true
                                                ? post.description!.trim()
                                                : l10n.tOr(
                                                    'untitledPost',
                                                    'Untitled post',
                                                  ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          if (author != null &&
                                              author.isNotEmpty)
                                            Text(
                                              '@$author',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11.5,
                                                    color: scheme
                                                        .onSurfaceVariant,
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
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
