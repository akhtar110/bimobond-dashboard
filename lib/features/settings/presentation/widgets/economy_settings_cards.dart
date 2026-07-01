import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/economy_setting_entity.dart';
import '../bloc/economy_settings_bloc.dart';
import 'settings_section.dart';

class EconomySettingsCards extends StatefulWidget {
  const EconomySettingsCards({
    super.key,
    this.canManage = true,
    this.embedded = false,
  });

  final bool canManage;
  final bool embedded;

  @override
  State<EconomySettingsCards> createState() => _EconomySettingsCardsState();
}

class _EconomySettingsCardsState extends State<EconomySettingsCards> {
  @override
  void initState() {
    super.initState();
    context.read<EconomySettingsBloc>().add(const LoadEconomySettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EconomySettingsBloc, EconomySettingsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        } else if (state.saveMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.saveMessage!)),
          );
        }
      },
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        final body = state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EconomySettingCard(
                    icon: Icons.percent_outlined,
                    title: 'Auction commission',
                    subtitle: 'Platform cut on gift bids (default 25%)',
                    value: state.commissionPercent ?? '—',
                    onEdit: !widget.canManage || state.isSaving
                        ? null
                        : () => _editSetting(
                              context,
                              key: EconomySettingKeys.auctionCommissionPercent,
                              title: 'Auction commission %',
                              current: state.commissionPercent ?? '25',
                              suffix: '%',
                            ),
                  ),
                  const SizedBox(height: 16),
                  _EconomySettingCard(
                    icon: Icons.currency_exchange_outlined,
                    title: 'Coins per price unit',
                    subtitle: 'Coins credited per 1 unit of host currency',
                    value: state.coinsPerPriceUnit ?? '—',
                    onEdit: !widget.canManage || state.isSaving
                        ? null
                        : () => _editSetting(
                              context,
                              key: EconomySettingKeys.coinsPerPriceUnit,
                              title: 'Coins per price unit',
                              current: state.coinsPerPriceUnit ?? '100',
                            ),
                  ),
                  if (state.isSaving) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(color: scheme.primary),
                  ],
                ],
              );

        if (widget.embedded) return body;

        return SettingsSection(
          title: 'Economy settings',
          description: 'Auction commission and coin conversion rate',
          child: body,
        );
      },
    );
  }

  Future<void> _editSetting(
    BuildContext context, {
    required String key,
    required String title,
    required String current,
    String? suffix,
  }) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Value',
              suffixText: suffix,
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: scheme.onSurface),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty || !context.mounted) return;
    final parsed = double.tryParse(result);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive number')),
      );
      return;
    }
    context.read<EconomySettingsBloc>().add(
          UpdateEconomySettingEvent(key: key, value: result),
        );
  }
}

class _EconomySettingCard extends StatelessWidget {
  const _EconomySettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onEdit,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        );

        final wideContent = Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
            ),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        );

        return Material(
          color: scheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: compact ? content : wideContent,
          ),
        );
      },
    );
  }
}
