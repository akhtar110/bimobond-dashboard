import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../bloc/create_post_bloc.dart';
import 'create_post_page.dart';

/// Keeps create-post blocs alive for the pushed route lifetime.
class CreatePostRouteScope extends StatefulWidget {
  const CreatePostRouteScope({super.key});

  @override
  State<CreatePostRouteScope> createState() => _CreatePostRouteScopeState();
}

class _CreatePostRouteScopeState extends State<CreatePostRouteScope> {
  late final CreatePostBloc _createPostBloc;
  late final CategoriesBloc _categoriesBloc;

  @override
  void initState() {
    super.initState();
    _createPostBloc = di.sl<CreatePostBloc>()..add(CreatePostStarted());
    if (kDebugMode) {
      debugPrint('CreatePostBloc created — CreatePostStarted dispatched');
    }

    _categoriesBloc = di.sl<CategoriesBloc>()..add(LoadCategoriesEvent());
    if (kDebugMode) {
      debugPrint(
        'CategoriesBloc created (create post) — LoadCategories dispatched',
      );
    }
  }

  @override
  void dispose() {
    _createPostBloc.close();
    _categoriesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('CreatePostRouteScope rebuilt');
    return MultiBlocProvider(
      providers: [
        BlocProvider<CreatePostBloc>.value(value: _createPostBloc),
        BlocProvider<CategoriesBloc>.value(value: _categoriesBloc),
      ],
      child: const CreatePostPage(),
    );
  }
}
