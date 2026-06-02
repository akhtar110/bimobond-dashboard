import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/create_post_field.dart';
import '../bloc/create_post_bloc.dart';

/// Dispatches [UpdateField] from child sections — no form logic in widgets.
typedef CreatePostFieldUpdater = void Function(CreatePostField field, Object? value);

CreatePostFieldUpdater createPostFieldUpdater(BuildContext context) {
  return (field, value) {
    context.read<CreatePostBloc>().add(UpdateField(field, value));
  };
}
