import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/users/domain/entities/user_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../bloc/notifications_bloc.dart';
import 'bulk_user_selector.dart';
import 'notification_type_dropdown.dart';
import 'send_confirmation_dialog.dart';
import 'user_selector.dart';

enum _ComposerTab { single, bulk, broadcast, broadcastAdmins }

class NotificationComposer extends StatefulWidget {
  const NotificationComposer({super.key});

  @override
  State<NotificationComposer> createState() => _NotificationComposerState();
}

class _NotificationComposerState extends State<NotificationComposer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _ComposerTab.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.send_rounded,
                      color: scheme.onPrimaryContainer, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('notificationComposerTitle'),
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        l10n.t('notificationComposerSubtitle'),
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
              labelStyle: textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: l10n.t('notificationTabSingleUser')),
                Tab(text: l10n.t('notificationTabBulkUsers')),
                Tab(text: l10n.t('notificationTabBroadcastAll')),
                Tab(text: l10n.t('notificationTabBroadcastAdmins')),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _SingleUserForm(),
                  _BulkForm(),
                  _BroadcastForm(adminsOnly: false),
                  _BroadcastForm(adminsOnly: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Shared form fields mixin
// ──────────────────────────────────────────────────────────

mixin _FormFields<T extends StatefulWidget> on State<T> {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final dataCtrl = TextEditingController();
  NotificationType selectedType = NotificationType.adminMessage;
  bool sendPush = true;
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    dataCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _parseData() {
    final raw = dataCtrl.text.trim();
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Widget buildTitleField(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
        controller: titleCtrl,
        maxLength: 100,
        decoration: InputDecoration(
          labelText: l10n.t('notificationFieldTitle'),
          hintText: l10n.t('notificationFieldTitleHint'),
          prefixIcon: const Icon(Icons.title_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          counterText: '${titleCtrl.text.length}/100',
        ),
        onChanged: (_) => setState(() {}),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? l10n.t('notificationTitleRequired')
            : null,
      );
  }

  Widget buildBodyField(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
        controller: bodyCtrl,
        maxLines: 3,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: l10n.t('notificationFieldBody'),
          hintText: l10n.t('notificationFieldBodyHint'),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Icon(Icons.message_outlined),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          counterText: '${bodyCtrl.text.length}/500',
        ),
        onChanged: (_) => setState(() {}),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? l10n.t('notificationBodyRequired')
            : null,
      );
  }

  Widget buildDataField(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: dataCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            labelText: l10n.t('notificationFieldJsonData'),
            hintText: l10n.t('notificationFieldJsonDataHint'),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.data_object_rounded),
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor:
                scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            suffixIcon: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: l10n.t('notificationCopyJson'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: dataCtrl.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('notificationJsonCopied')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            try {
              jsonDecode(v);
              return null;
            } catch (_) {
              return l10n.t('notificationInvalidJson');
            }
          },
        ),
      ],
    );
  }

  Widget buildSendPushToggle() => Builder(
        builder: (context) {
          final l10n = context.l10n;
          final scheme = Theme.of(context).colorScheme;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('notificationSendPushLabel'),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        l10n.t('notificationSendPushSubtitle'),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: sendPush,
                  onChanged: (v) => setState(() => sendPush = v),
                ),
              ],
            ),
          );
        },
      );

  Widget buildPreviewCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: scheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.preview_rounded,
              size: 16, color: scheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                if (body.isNotEmpty)
                  Text(body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Single User Form
// ──────────────────────────────────────────────────────────

class _SingleUserForm extends StatefulWidget {
  const _SingleUserForm();

  @override
  State<_SingleUserForm> createState() => _SingleUserFormState();
}

class _SingleUserFormState extends State<_SingleUserForm>
    with _FormFields<_SingleUserForm> {
  UserEntity? _selectedUser;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.hasSent) _resetForm();
      },
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserSelector(
                selectedUser: _selectedUser,
                onUserSelected: (u) => setState(() => _selectedUser = u),
              ),
              const SizedBox(height: 14),
              buildTitleField(context),
              const SizedBox(height: 14),
              buildBodyField(context),
              const SizedBox(height: 14),
              NotificationTypeDropdown(
                value: selectedType,
                onChanged: (t) => setState(() => selectedType = t),
              ),
              const SizedBox(height: 14),
              buildSendPushToggle(),
              const SizedBox(height: 14),
              buildDataField(context),
              const SizedBox(height: 10),
              buildPreviewCard(context),
              const SizedBox(height: 14),
              _SendButton(
                label: l10n.t('notificationSendButton'),
                icon: Icons.send_rounded,
                onSend: _onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    titleCtrl.clear();
    bodyCtrl.clear();
    dataCtrl.clear();
    setState(() {
      _selectedUser = null;
      selectedType = NotificationType.adminMessage;
      sendPush = true;
    });
  }

  void _onSend() {
    if (!formKey.currentState!.validate()) return;
    if (_selectedUser == null) return;

    context.read<NotificationsBloc>().add(
          SendNotificationRequested(
            userId: _selectedUser!.id,
            title: titleCtrl.text.trim(),
            body: bodyCtrl.text.trim(),
            type: selectedType,
            sendPush: sendPush,
            data: _parseData(),
          ),
        );
  }
}

// ──────────────────────────────────────────────────────────
// Bulk Form
// ──────────────────────────────────────────────────────────

class _BulkForm extends StatefulWidget {
  const _BulkForm();

  @override
  State<_BulkForm> createState() => _BulkFormState();
}

class _BulkFormState extends State<_BulkForm>
    with _FormFields<_BulkForm> {
  List<UserEntity> _selectedUsers = [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.hasSent) _resetForm();
      },
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BulkUserSelector(
                selectedUsers: _selectedUsers,
                onChanged: (users) => setState(() => _selectedUsers = users),
              ),
              const SizedBox(height: 14),
              buildTitleField(context),
              const SizedBox(height: 14),
              buildBodyField(context),
              const SizedBox(height: 14),
              NotificationTypeDropdown(
                value: selectedType,
                onChanged: (t) => setState(() => selectedType = t),
              ),
              const SizedBox(height: 14),
              buildSendPushToggle(),
              const SizedBox(height: 14),
              buildDataField(context),
              const SizedBox(height: 10),
              buildPreviewCard(context),
              const SizedBox(height: 14),
              _SendButton(
                label: l10n.tArgs(
                  'notificationSendBulkButtonCount',
                  {'count': '${_selectedUsers.length}'},
                ),
                icon: Icons.group_rounded,
                onSend: _onSend,
                disabled: _selectedUsers.isEmpty,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    titleCtrl.clear();
    bodyCtrl.clear();
    dataCtrl.clear();
    setState(() {
      _selectedUsers = [];
      selectedType = NotificationType.adminMessage;
      sendPush = true;
    });
  }

  void _onSend() {
    if (!formKey.currentState!.validate()) return;
    if (_selectedUsers.isEmpty) return;

    context.read<NotificationsBloc>().add(
          SendBulkNotificationRequested(
            userIds: _selectedUsers.map((u) => u.id).toList(),
            title: titleCtrl.text.trim(),
            body: bodyCtrl.text.trim(),
            type: selectedType,
            sendPush: sendPush,
            data: _parseData(),
          ),
        );
  }
}

// ──────────────────────────────────────────────────────────
// Broadcast Form (shared for all users & admins-only)
// ──────────────────────────────────────────────────────────

class _BroadcastForm extends StatefulWidget {
  const _BroadcastForm({required this.adminsOnly});
  final bool adminsOnly;

  @override
  State<_BroadcastForm> createState() => _BroadcastFormState();
}

class _BroadcastFormState extends State<_BroadcastForm>
    with _FormFields<_BroadcastForm> {
  @override
  void initState() {
    super.initState();
    // Set the initial type to match the available items in the dropdown.
    selectedType = widget.adminsOnly
        ? NotificationType.adminMessage
        : NotificationType.broadcast;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<NotificationsBloc, NotificationsState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.hasSent) _resetForm();
      },
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (widget.adminsOnly
                          ? scheme.primaryContainer
                          : scheme.errorContainer)
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.adminsOnly
                        ? scheme.primary.withValues(alpha: 0.4)
                        : scheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.adminsOnly
                          ? Icons.admin_panel_settings_outlined
                          : Icons.campaign_rounded,
                      color: widget.adminsOnly
                          ? scheme.primary
                          : scheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.adminsOnly
                            ? l10n.t('notificationBroadcastAdminsWarning')
                            : l10n.t('notificationBroadcastAllWarning'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.adminsOnly
                                  ? scheme.onPrimaryContainer
                                  : scheme.onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              buildTitleField(context),
              const SizedBox(height: 14),
              buildBodyField(context),
              const SizedBox(height: 14),
              NotificationTypeDropdown(
                value: selectedType,
                onChanged: (t) => setState(() => selectedType = t),
                types: widget.adminsOnly
                    ? [NotificationType.adminMessage, NotificationType.system]
                    : [
                        NotificationType.broadcast,
                        NotificationType.system,
                      ],
              ),
              const SizedBox(height: 14),
              buildSendPushToggle(),
              const SizedBox(height: 14),
              buildDataField(context),
              const SizedBox(height: 10),
              buildPreviewCard(context),
              const SizedBox(height: 14),
              _SendButton(
                label: widget.adminsOnly
                    ? l10n.t('notificationBroadcastAdminsButton')
                    : l10n.t('notificationBroadcastAllButton'),
                icon: widget.adminsOnly
                    ? Icons.admin_panel_settings_rounded
                    : Icons.campaign_rounded,
                onSend: _onSend,
                isDanger: !widget.adminsOnly,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    titleCtrl.clear();
    bodyCtrl.clear();
    dataCtrl.clear();
    setState(() {
      selectedType = widget.adminsOnly
          ? NotificationType.adminMessage
          : NotificationType.broadcast;
      sendPush = true;
    });
  }

  Future<void> _onSend() async {
    if (!formKey.currentState!.validate()) return;
    final l10n = context.l10n;

    final confirmed = await SendConfirmationDialog.show(
      context,
      title: widget.adminsOnly
          ? l10n.t('notificationConfirmBroadcastAdminsTitle')
          : l10n.t('notificationConfirmBroadcastTitle'),
      message: widget.adminsOnly
          ? l10n.t('notificationConfirmBroadcastAdminsMessage')
          : l10n.t('notificationConfirmBroadcastMessage'),
      confirmLabel: widget.adminsOnly
          ? l10n.t('notificationSendToAdmins')
          : l10n.t('notificationBroadcastToAllShort'),
      isDanger: !widget.adminsOnly,
    );

    if (!confirmed) return;
    if (!mounted) return;

    if (widget.adminsOnly) {
      context.read<NotificationsBloc>().add(
            BroadcastAdminsRequested(
              title: titleCtrl.text.trim(),
              body: bodyCtrl.text.trim(),
              type: selectedType,
              sendPush: sendPush,
              data: _parseData(),
            ),
          );
    } else {
      context.read<NotificationsBloc>().add(
            BroadcastNotificationRequested(
              title: titleCtrl.text.trim(),
              body: bodyCtrl.text.trim(),
              type: selectedType,
              sendPush: sendPush,
              data: _parseData(),
            ),
          );
    }
  }
}

// ──────────────────────────────────────────────────────────
// Send button
// ──────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.label,
    required this.icon,
    required this.onSend,
    this.isDanger = false,
    this.disabled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSend;
  final bool isDanger;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (a, b) => a.isSending != b.isSending,
      builder: (context, state) {
        return FilledButton.icon(
          style: isDanger
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  minimumSize: const Size(double.infinity, 48),
                )
              : FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
          onPressed: (state.isSending || disabled) ? null : onSend,
          icon: state.isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
          label: Text(
            state.isSending ? l10n.t('notificationSending') : label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
