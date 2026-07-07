import 'package:flutter/material.dart';

/// Instant admin detail route — no slide animation so the feed stays visible on pop.
class AdminDetailPageRoute<T> extends MaterialPageRoute<T> {
  AdminDetailPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}
