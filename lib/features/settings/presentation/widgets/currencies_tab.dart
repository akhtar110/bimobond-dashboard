import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/settings_admin_entities.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_responsive.dart';

/// Currency management table/cards with CRUD and default toggle.
class CurrenciesTab extends StatelessWidget {
  const CurrenciesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canManage = PermissionManager.canManageCurrencies(context);
    final compact = SettingsLayoutMetrics(
      getSettingsDeviceType(MediaQuery.sizeOf(context).width),
    ).isCompact;

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.currencies != next.currencies ||
          prev.isLoading != next.isLoading ||
          prev.isSaving != next.isSaving,
      builder: (context, state) {
        if (state.isLoading && state.currencies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.currencies.isEmpty) {
          return EmptyStateCard(
            icon: Icons.payments_outlined,
            title: l10n.tOr('settingsNoCurrencies', 'No currencies'),
            message: l10n.tOr(
              'settingsNoCurrenciesMessage',
              'Add currencies to support multi-currency pricing.',
            ),
          );
        }

        final header = canManage
            ? Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () => _openCurrencyDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.tOr('addCurrency', 'Add currency')),
                ),
              )
            : null;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[header, const SizedBox(height: 12)],
              for (final currency in state.currencies) ...[
                _CurrencyCard(
                  currency: currency,
                  canManage: canManage,
                  isSaving: state.isSaving,
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }

        final columns = <DataColumn>[
          DataColumn(label: Text(l10n.tOr('currencyCode', 'Code'))),
          DataColumn(label: Text(l10n.tOr('currencyName', 'Name'))),
          DataColumn(label: Text(l10n.tOr('currencySymbol', 'Symbol'))),
          DataColumn(label: Text(l10n.tOr('currencyCoinsPerUnit', 'Coins/unit'))),
          DataColumn(label: Text(l10n.tOr('status', 'Status'))),
          if (canManage) DataColumn(label: Text(l10n.tOr('actions', 'Actions'))),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[header, const SizedBox(height: 12)],
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: ResponsiveDataTable(
                columns: columns,
                rows: [
                  for (final currency in state.currencies)
                    DataRow(
                      cells: [
                        DataCell(Text(currency.code)),
                        DataCell(Text(currency.name)),
                        DataCell(Text(currency.symbol ?? '—')),
                        DataCell(Text('${currency.coinsPerUnit ?? '—'}')),
                        DataCell(
                          Wrap(
                            spacing: 6,
                            children: [
                              if (currency.isDefault)
                                Chip(
                                  label: Text(l10n.tOr('defaultLabel', 'Default')),
                                  visualDensity: VisualDensity.compact,
                                ),
                              Chip(
                                label: Text(
                                  currency.isActive
                                      ? l10n.tOr('active', 'Active')
                                      : l10n.tOr('inactive', 'Inactive'),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        if (canManage)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.tOr('edit', 'Edit'),
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: state.isSaving
                                      ? null
                                      : () => _openCurrencyDialog(
                                            context,
                                            existing: currency,
                                          ),
                                ),
                                if (!currency.isDefault)
                                  IconButton(
                                    tooltip: l10n.tOr(
                                      'setDefaultCurrency',
                                      'Set default',
                                    ),
                                    icon: const Icon(Icons.star_outline),
                                    onPressed: state.isSaving
                                        ? null
                                        : () => context
                                            .read<AdminSettingsBloc>()
                                            .add(
                                              UpdateAdminCurrencyEvent(
                                                currency.copyWith(
                                                  isDefault: true,
                                                ),
                                              ),
                                            ),
                                  ),
                                IconButton(
                                  tooltip: currency.isActive
                                      ? l10n.tOr('deactivate', 'Deactivate')
                                      : l10n.tOr('activate', 'Activate'),
                                  icon: Icon(
                                    currency.isActive
                                        ? Icons.toggle_on_outlined
                                        : Icons.toggle_off_outlined,
                                  ),
                                  onPressed: state.isSaving
                                      ? null
                                      : () => context
                                          .read<AdminSettingsBloc>()
                                          .add(
                                            UpdateAdminCurrencyEvent(
                                              currency.copyWith(
                                                isActive: !currency.isActive,
                                              ),
                                            ),
                                          ),
                                ),
                                if (!currency.isDefault)
                                  IconButton(
                                    tooltip: l10n.tOr('delete', 'Delete'),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: scheme.error,
                                    ),
                                    onPressed: state.isSaving
                                        ? null
                                        : () => _confirmDelete(
                                              context,
                                              currency.code,
                                            ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
                mobileCards: [
                  for (final currency in state.currencies)
                    _CurrencyCard(
                      currency: currency,
                      canManage: canManage,
                      isSaving: state.isSaving,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String code) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tOr('deleteCurrencyTitle', 'Delete currency?')),
        content: Text(
          l10n
              .tOr('deleteCurrencyMessage', 'Remove currency {code}?')
              .replaceAll('{code}', code),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.tOr('cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.tOr('delete', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AdminSettingsBloc>().add(DeleteAdminCurrencyEvent(code));
    }
  }

  Future<void> _openCurrencyDialog(
    BuildContext context, {
    AppCurrencyEntity? existing,
  }) {
    final bloc = context.read<AdminSettingsBloc>();
    return showSettingsAdaptiveForm<void>(
      context: context,
      builder: (ctx) => BlocProvider<AdminSettingsBloc>.value(
        value: bloc,
        child: _CurrencyFormDialog(existing: existing),
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({
    required this.currency,
    required this.canManage,
    required this.isSaving,
  });

  final AppCurrencyEntity currency;
  final bool canManage;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${currency.code} · ${currency.name}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n
                  .tOr('currencyCardMeta', '{symbol} · {coins} coins/unit')
                  .replaceAll('{symbol}', currency.symbol ?? '—')
                  .replaceAll('{coins}', '${currency.coinsPerUnit ?? '—'}'),
            ),
            if (canManage) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            final bloc = context.read<AdminSettingsBloc>();
                            showSettingsAdaptiveForm<void>(
                              context: context,
                              builder: (ctx) =>
                                  BlocProvider<AdminSettingsBloc>.value(
                                value: bloc,
                                child: _CurrencyFormDialog(existing: currency),
                              ),
                            );
                          },
                    child: Text(l10n.tOr('edit', 'Edit')),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrencyFormDialog extends StatefulWidget {
  const _CurrencyFormDialog({this.existing});

  final AppCurrencyEntity? existing;

  @override
  State<_CurrencyFormDialog> createState() => _CurrencyFormDialogState();
}

class _CurrencyFormDialogState extends State<_CurrencyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _symbolController;
  late final TextEditingController _coinsController;
  late bool _isDefault;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _codeController = TextEditingController(text: c?.code ?? '');
    _nameController = TextEditingController(text: c?.name ?? '');
    _symbolController = TextEditingController(text: c?.symbol ?? '');
    _coinsController =
        TextEditingController(text: c?.coinsPerUnit?.toString() ?? '');
    _isDefault = c?.isDefault ?? false;
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    _coinsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<AdminSettingsBloc>();
    final coins = double.tryParse(_coinsController.text.trim());

    if (widget.existing != null) {
      bloc.add(
        UpdateAdminCurrencyEvent(
          widget.existing!.copyWith(
            name: _nameController.text.trim(),
            symbol: _symbolController.text.trim().isEmpty
                ? null
                : _symbolController.text.trim(),
            coinsPerUnit: coins,
            isDefault: _isDefault,
            isActive: _isActive,
          ),
        ),
      );
    } else {
      bloc.add(
        CreateAdminCurrencyEvent(
          AppCurrencyEntity(
            id: '',
            code: _codeController.text.trim().toUpperCase(),
            name: _nameController.text.trim(),
            symbol: _symbolController.text.trim().isEmpty
                ? null
                : _symbolController.text.trim(),
            coinsPerUnit: coins,
            isDefault: _isDefault,
            isActive: _isActive,
          ),
        ),
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final editing = widget.existing != null;

    final form = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing
                  ? l10n.tOr('editCurrencyTitle', 'Edit currency')
                  : l10n.tOr('addCurrencyTitle', 'Add currency'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              enabled: !editing,
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? l10n.tOr('currencyCodeRequired', 'Code is required')
                      : null,
              decoration: InputDecoration(
                labelText: l10n.tOr('currencyCode', 'Code'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              validator: (v) =>
                  v == null || v.trim().isEmpty
                      ? l10n.tOr('currencyNameRequired', 'Name is required')
                      : null,
              decoration: InputDecoration(
                labelText: l10n.tOr('currencyName', 'Name'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _symbolController,
              decoration: InputDecoration(
                labelText: l10n.tOr('currencySymbol', 'Symbol'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coinsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.tOr('currencyCoinsPerUnit', 'Coins per unit'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tOr('setAsDefault', 'Set as default')),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.tOr('active', 'Active')),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.tOr('cancel', 'Cancel')),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _save,
                  child: Text(l10n.tOr('save', 'Save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (compact) {
      return Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: form,
      );
    }

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: form,
      ),
    );
  }
}
