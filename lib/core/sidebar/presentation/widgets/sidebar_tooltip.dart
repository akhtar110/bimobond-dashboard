import 'package:flutter/material.dart';

/// Custom tooltip for collapsed sidebar icons.
class SidebarTooltip extends StatefulWidget {
  const SidebarTooltip({
    super.key,
    required this.message,
    required this.child,
    this.enabled = true,
  });

  final String message;
  final Widget child;
  final bool enabled;

  @override
  State<SidebarTooltip> createState() => _SidebarTooltipState();
}

class _SidebarTooltipState extends State<SidebarTooltip> {
  OverlayEntry? _entry;
  final _layerLink = LayerLink();

  void _show() {
    if (!widget.enabled || widget.message.isEmpty || _entry != null) return;

    final overlay = Overlay.of(context);
    final scheme = Theme.of(context).colorScheme;

    _entry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(52, 0),
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 150),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-6 * (1 - value), 0),
                  child: child,
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: scheme.onInverseSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        cursor: SystemMouseCursors.click,
        child: widget.child,
      ),
    );
  }
}
