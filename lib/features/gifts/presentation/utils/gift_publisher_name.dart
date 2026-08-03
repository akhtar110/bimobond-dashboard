import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/gift_entity.dart';

/// Resolves the publisher/admin full name for gift publish UI.
///
/// Prefers [GiftEntity.createdByName] from the API; falls back to the signed-in
/// admin full name (then username) when the gift has no creator metadata yet.
String? resolveGiftPublisherName(BuildContext context, [GiftEntity? gift]) {
  final fromGift = gift?.createdByName?.trim();
  if (fromGift != null && fromGift.isNotEmpty) return fromGift;

  final auth = context.read<AuthBloc>().state;
  if (auth is Authenticated) {
    final fullName = auth.user.displayFullName;
    if (fullName.isNotEmpty) return fullName;
  }
  return null;
}
