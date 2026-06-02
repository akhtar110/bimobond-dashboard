import 'package:flutter/material.dart';

import '../../../core/localization/localization.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsetsDirectional.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: Text(l10n.t('sendAllUsersNotification')),
            trailing: const Icon(Icons.send),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text(l10n.t('sendSpecificUsersNotification')),
            trailing: const Icon(Icons.person_add_alt_1),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 20),

        Text(
          l10n.t('announcementComposer'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: l10n.t('writeAnnouncement'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              _controller.clear();
            },
            child: Text(l10n.t('send')),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
