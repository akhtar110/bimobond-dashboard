import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/create_post_entity.dart';
import '../../domain/entities/create_post_location_entity.dart';
import '../bloc/create_post_bloc.dart';
import 'create_post_location_picker_sheet.dart';

/// Card showing the selected location with add/edit/remove actions.
class CreatePostLocationCard extends StatelessWidget {
  const CreatePostLocationCard({super.key, required this.form});

  final CreatePostEntity form;

  CreatePostLocationEntity? get _displayLocation {
    if (form.location != null) return form.location;
    if (form.locationId != null && form.locationId!.trim().isNotEmpty) {
      return CreatePostLocationEntity(
        name: form.locationId!,
        latitude: 0,
        longitude: 0,
        id: form.locationId,
      );
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final bloc = context.read<CreatePostBloc>();
    await showCreatePostLocationPicker(
      context: context,
      initial: _displayLocation,
      onSelect: (location) => bloc.add(SetLocation(location)),
      onClear: () => bloc.add(ClearLocation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final location = _displayLocation;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.t('createPostLocation'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (location != null)
                  TextButton(
                    onPressed: () => context.read<CreatePostBloc>().add(
                          ClearLocation(),
                        ),
                    child: Text(l10n.t('remove')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (location != null) ...[
              Text(
                location.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (location.address != null && location.address!.isNotEmpty)
                Text(
                  location.address!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.grey.shade500
                        : const Color(0xFF6B7280),
                  ),
                ),
              if (location.city != null && location.city!.isNotEmpty)
                Text(
                  location.city!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? Colors.grey.shade500
                        : const Color(0xFF6B7280),
                  ),
                ),
            ] else
              Text(
                l10n.t('createPostLocationEmpty'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openPicker(context),
              icon: Icon(location != null ? Icons.edit_outlined : Icons.add),
              label: Text(
                location != null
                    ? l10n.t('createPostLocationEdit')
                    : l10n.t('createPostLocationAdd'),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
