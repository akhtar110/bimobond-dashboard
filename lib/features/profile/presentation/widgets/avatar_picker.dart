import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/profile_entity.dart';
import '../utils/profile_avatar_picker.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.profile,
    required this.onPicked,
    this.uploading = false,
    this.size = 96,
    this.editable = true,
  });

  final ProfileEntity profile;
  final void Function(String filename, List<int> bytes) onPicked;
  final bool uploading;
  final double size;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final url = resolveMediaUrl(profile.avatarUrl) ?? profile.avatarUrl;
    final initial = profile.username.isNotEmpty
        ? profile.username[0].toUpperCase()
        : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: size / 2,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: url != null && url.isNotEmpty
                  ? NetworkImage(url)
                  : null,
              child: url == null || url.isEmpty
                  ? Text(
                      initial,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    )
                  : null,
            ),
            if (uploading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.scrim.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              )
            else if (editable)
              Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final picked = await pickProfileAvatarFile();
                    if (picked == null) return;
                    onPicked(picked.name, picked.bytes);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (editable) ...[
          const SizedBox(height: 8),
          Text(
            l10n.tOr('upload_avatar', 'Upload avatar'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}
