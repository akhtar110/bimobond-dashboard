import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Provides a [BlocBase] that survives parent rebuilds (e.g. theme/locale changes).
///
/// Unlike [BlocProvider] in a [StatelessWidget.build], the bloc is created once
/// in [State.initState] and closed in [State.dispose].
class PersistentBlocProvider<T extends BlocBase<Object?>>
    extends StatefulWidget {
  const PersistentBlocProvider({
    super.key,
    required this.create,
    required this.child,
    this.debugLabel,
  });

  final T Function() create;
  final Widget child;

  /// When set, logs bloc creation, disposal, and provider rebuilds in debug mode.
  final String? debugLabel;

  @override
  State<PersistentBlocProvider<T>> createState() =>
      _PersistentBlocProviderState<T>();
}

class _PersistentBlocProviderState<T extends BlocBase<Object?>>
    extends State<PersistentBlocProvider<T>> {
  late final T _bloc = widget.create();

  @override
  void initState() {
    super.initState();
    if (kDebugMode && widget.debugLabel != null) {
      debugPrint('${widget.debugLabel} bloc created (${T.toString()})');
    }
  }

  @override
  void dispose() {
    if (kDebugMode && widget.debugLabel != null) {
      debugPrint('${widget.debugLabel} bloc disposed (${T.toString()})');
    }
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && widget.debugLabel != null) {
      debugPrint('${widget.debugLabel} provider rebuilt');
    }
    return BlocProvider<T>.value(value: _bloc, child: widget.child);
  }
}
