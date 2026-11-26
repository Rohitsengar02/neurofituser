import 'package:flutter/widgets.dart';

/// Pauses every animation below it while it is scrolled off screen.
///
/// Looping animations (pulsing dots, waves, spinning borders) keep the app
/// drawing frames even when nobody can see them. This mutes their tickers
/// with [TickerMode] once the child leaves the vertical viewport (plus a
/// small margin) and resumes them when it comes back.
class TickerGate extends StatefulWidget {
  final Widget child;
  final double margin;
  const TickerGate({super.key, required this.child, this.margin = 80});

  @override
  State<TickerGate> createState() => _TickerGateState();
}

class _TickerGateState extends State<TickerGate> {
  ScrollPosition? _pos;
  bool _on = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (pos != _pos) {
      _pos?.removeListener(_check);
      _pos = pos?..addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final view = Scrollable.maybeOf(context, axis: Axis.vertical)?.context.findRenderObject() as RenderBox?;
    if (box == null || view == null || !box.attached || !box.hasSize || !view.attached) return;
    final top = box.localToGlobal(Offset.zero, ancestor: view).dy;
    final on = top + box.size.height > -widget.margin && top < view.size.height + widget.margin;
    if (on != _on) setState(() => _on = on);
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TickerMode(enabled: _on, child: widget.child);
}
