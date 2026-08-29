import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VerticalRulerPicker extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final double step;
  final ValueChanged<double> onChanged;
  final String unit;
  final Color pointerColor;
  final double tickSpacing;

  const VerticalRulerPicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    this.step = 1.0,
    required this.onChanged,
    this.unit = 'cm',
    this.pointerColor = const Color(0xFF22C55E),
    this.tickSpacing = 16.0,
  });

  @override
  State<VerticalRulerPicker> createState() => _VerticalRulerPickerState();
}

class _VerticalRulerPickerState extends State<VerticalRulerPicker> {
  late ScrollController _scrollController;
  late double _currentValue;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;

    // In a vertical ruler, higher values are at the top (lower scroll offset).
    // offset 0 = maxValue, maxOffset = minValue
    final initialOffset = _valueToOffset(_currentValue);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(VerticalRulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minValue != widget.minValue ||
        oldWidget.maxValue != widget.maxValue ||
        oldWidget.step != widget.step ||
        (oldWidget.initialValue != widget.initialValue && !_isScrolling)) {
      _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
      final targetOffset = _valueToOffset(_currentValue);
      if (_scrollController.hasClients &&
          (_scrollController.offset - targetOffset).abs() > 1.0) {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  double _valueToOffset(double val) {
    final clamped = val.clamp(widget.minValue, widget.maxValue);
    final stepsFromMax = (widget.maxValue - clamped) / widget.step;
    return stepsFromMax * widget.tickSpacing;
  }

  double _offsetToValue(double offset) {
    final stepsFromMax = (offset / widget.tickSpacing).round();
    final val = widget.maxValue - (stepsFromMax * widget.step);
    return val.clamp(widget.minValue, widget.maxValue);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    _isScrolling = true;
    final offset = _scrollController.offset;
    final newValue = _offsetToValue(offset);

    if ((newValue - _currentValue).abs() >= (widget.step * 0.99)) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(_currentValue);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalTicks = ((widget.maxValue - widget.minValue) / widget.step).round() + 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final verticalPadding = height / 2;

        return SizedBox(
          width: 90,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: [
              // 1. Scrollable Ticks & Numbers (Right edge, 0 padding on right)
              NotificationListener<ScrollEndNotification>(
                onNotification: (notification) {
                  _isScrolling = false;
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: verticalPadding,
                    bottom: verticalPadding,
                    right: 0,
                  ),
                  itemCount: totalTicks,
                  itemBuilder: (context, index) {
                    // index 0 is maxValue, index totalTicks-1 is minValue
                    final tickValue = widget.maxValue - (index * widget.step);

                    // Determine major/minor tick rules depending on unit
                    bool isMajorTick = false;
                    bool isMediumTick = false;

                    if (widget.unit == 'cm') {
                      isMajorTick = (tickValue.round() % 10) == 0;
                      isMediumTick = (tickValue.round() % 5) == 0;
                    } else if (widget.unit == 'm') {
                      final cmVal = (tickValue * 100).round();
                      isMajorTick = (cmVal % 10) == 0;
                      isMediumTick = (cmVal % 5) == 0;
                    } else {
                      // feet
                      final tenths = (tickValue * 10).round();
                      isMajorTick = (tenths % 10) == 0;
                      isMediumTick = (tenths % 5) == 0;
                    }

                    String labelText = '';
                    if (isMajorTick) {
                      if (widget.unit == 'cm') {
                        labelText = tickValue.toInt().toString();
                      } else if (widget.unit == 'm') {
                        labelText = tickValue.toStringAsFixed(2);
                      } else {
                        labelText = tickValue.toStringAsFixed(1);
                      }
                    }

                    return SizedBox(
                      height: widget.tickSpacing,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Label on the left of tick
                          if (isMajorTick)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                labelText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),

                          // Tick line attached to the right edge
                          Container(
                            height: isMajorTick ? 2.4 : (isMediumTick ? 1.8 : 1.2),
                            width: isMajorTick ? 32.0 : (isMediumTick ? 20.0 : 12.0),
                            decoration: BoxDecoration(
                              color: isMajorTick
                                  ? const Color(0xFF475569)
                                  : (isMediumTick ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1)),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 2. Center Indicator Arrow & Glow Line
              Positioned(
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Triangle Pointer
                    CustomPaint(
                      size: const Size(10, 14),
                      painter: _TrianglePointerPainter(color: widget.pointerColor),
                    ),
                    // Pointer Bar extending from right edge
                    Container(
                      width: 42,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: widget.pointerColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.pointerColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;

  _TrianglePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePointerPainter oldDelegate) =>
      oldDelegate.color != color;
}
