import 'dart:async';

/// Standard debounce for dashboard search fields (300–500 ms range).
const Duration dashboardSearchDebounce = Duration(milliseconds: 350);

/// Debounced callback runner shared by blocs and search widgets.
class SearchDebouncer {
  SearchDebouncer({this.delay = dashboardSearchDebounce});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => cancel();
}

/// Drops stale async search responses when a newer query was issued.
class SearchRequestGuard {
  int _generation = 0;

  int next() => ++_generation;

  bool isCurrent(int token) => token == _generation;
}
