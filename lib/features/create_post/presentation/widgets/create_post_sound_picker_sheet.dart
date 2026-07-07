import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../sound_management/domain/entities/sound_entities.dart';
import '../../../sound_management/presentation/services/sound_preview_service.dart';
import '../../../sound_management/presentation/utils/sound_audio_duration_web.dart';
import '../../../sound_management/presentation/utils/sound_file_picker_web.dart';
import '../../../sound_management/presentation/widgets/sound_preview_scope.dart';
import '../../../sound_management/presentation/widgets/sound_preview_widgets.dart';
import '../../domain/entities/create_post_sound_selection_entity.dart';
import '../bloc/create_post_bloc.dart';

typedef CreatePostSoundUploadCallback = void Function(
  List<int> bytes,
  String filename,
  String name,
  int duration,
);

Future<void> showCreatePostSoundPicker({
  required BuildContext context,
  required CreatePostSoundSelectionEntity? selected,
  required ValueChanged<SoundEntity> onSelect,
  required CreatePostSoundUploadCallback onUpload,
  required VoidCallback onClear,
}) {
  final bloc = context.read<CreatePostBloc>();
  final width = MediaQuery.sizeOf(context).width;
  final isWide = width >= 720;

  if (isWide) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
            child: _CreatePostSoundPickerSheet(
              selected: selected,
              onSelect: (sound) {
                onSelect(sound);
                Navigator.of(ctx).pop();
              },
              onUpload: onUpload,
              onClear: () {
                onClear();
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (_, scrollController) => _CreatePostSoundPickerSheet(
            scrollController: scrollController,
            selected: selected,
            onSelect: (sound) {
              onSelect(sound);
              Navigator.of(ctx).pop();
            },
            onUpload: onUpload,
            onClear: () {
              onClear();
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    ),
  );
}

class _CreatePostSoundPickerSheet extends StatefulWidget {
  const _CreatePostSoundPickerSheet({
    required this.onSelect,
    required this.onUpload,
    required this.onClear,
    this.selected,
    this.scrollController,
  });

  final CreatePostSoundSelectionEntity? selected;
  final ValueChanged<SoundEntity> onSelect;
  final CreatePostSoundUploadCallback onUpload;
  final VoidCallback onClear;
  final ScrollController? scrollController;

  @override
  State<_CreatePostSoundPickerSheet> createState() =>
      _CreatePostSoundPickerSheetState();
}

class _CreatePostSoundPickerSheetState extends State<_CreatePostSoundPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;
  late final SoundPreviewService _preview = SoundPreviewService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreatePostBloc>().add(SearchSounds(trending: true));
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      context.read<CreatePostBloc>().add(SearchSounds(trending: true));
    } else {
      context.read<CreatePostBloc>().add(
            SearchSounds(query: _searchController.text.trim()),
          );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _preview.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<CreatePostBloc>().add(SearchSounds(query: query));
    });
  }

  Future<void> _pickAndUpload() async {
    final picked = await pickAudioFile();
    if (picked == null || !mounted) return;

    final duration = await probeAudioDurationFromBytes(
      picked.bytes,
      picked.name,
    );
    if (duration == null || duration < 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('createPostSoundDurationError'))),
      );
      return;
    }

    final name = picked.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    widget.onUpload(picked.bytes, picked.name, name, duration);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SoundPreviewScope(
      preview: _preview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  l10n.t('createPostSoundPickerTitle'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (widget.selected != null)
                  TextButton(
                    onPressed: widget.onClear,
                    child: Text(l10n.t('remove')),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.t('createPostSoundTrendingTab')),
              Tab(text: l10n.t('createPostSoundLibraryTab')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SoundListTab(
                  scrollController: widget.scrollController,
                  preview: _preview,
                  selectedId: widget.selected?.id,
                  onSelect: widget.onSelect,
                ),
                _SoundListTab(
                  scrollController: widget.scrollController,
                  preview: _preview,
                  selectedId: widget.selected?.id,
                  onSelect: widget.onSelect,
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _pickAndUpload,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l10n.t('createPostSoundUpload')),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundListTab extends StatelessWidget {
  const _SoundListTab({
    required this.preview,
    required this.onSelect,
    this.selectedId,
    this.searchController,
    this.onSearchChanged,
    this.scrollController,
  });

  final SoundPreviewService preview;
  final ValueChanged<SoundEntity> onSelect;
  final String? selectedId;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CreatePostBloc, CreatePostState>(
      buildWhen: (p, n) =>
          p.soundSearchResults != n.soundSearchResults ||
          p.soundsLoading != n.soundsLoading,
      builder: (context, state) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            if (searchController != null) ...[
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: l10n.t('createPostSoundSearchHint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.soundsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 12),
            ],
            if (state.soundSearchResults.isEmpty && !state.soundsLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.t('createPostSoundNoResults')),
                ),
              )
            else
              ...state.soundSearchResults.map(
                (sound) {
                  final selected = sound.id == selectedId;
                  final cover = resolveMediaUrl(sound.coverUrl);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: selected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.35,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: selected
                            ? theme.colorScheme.primary
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: ListTile(
                      leading: cover != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                cover,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.audiotrack,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                      title: Text(
                        sound.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${sound.author} · ${formatSoundPlaybackTime(Duration(seconds: sound.duration))}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SoundPreviewButton(
                            soundId: sound.id,
                            audioUrl: sound.audioUrl,
                            preview: preview,
                            compact: true,
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => onSelect(sound),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
