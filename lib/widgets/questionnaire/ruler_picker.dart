import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class RulerPicker extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final double step;
  final ValueChanged<double> onChanged;
  final String unit;
  final Color pointerColor;
  final double tickSpacing;

  const RulerPicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    this.step = 0.5,
    required this.onChanged,
    this.unit = 'kg',
    this.pointerColor = const Color(0xFF16A34A),
    this.tickSpacing = 14.0,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late ScrollController _scrollController;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;

    final initialOffset = ((_currentValue - widget.minValue) / widget.step) * widget.tickSpacing;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final totalSteps = (offset / widget.tickSpacing).round();
    final newValue = (widget.minValue + (totalSteps * widget.step)).clamp(widget.minValue, widget.maxValue);

    if ((newValue - _currentValue).abs() >= widget.step) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth / 2;

    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Scrollable Ticks & Numbers
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: totalTicks,
            itemBuilder: (context, index) {
              final tickValue = widget.minValue + (index * widget.step);
              final isMainTick = (tickValue % 1.0) == 0.0;
              final isMajorTick = (tickValue % 5.0) == 0.0 || (tickValue % 1.0 == 0.0 && widget.step >= 1.0);

              return SizedBox(
                width: widget.tickSpacing,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tick Bar
                    Container(
                      width: isMainTick ? 2.2 : 1.2,
                      height: isMajorTick ? 34.0 : (isMainTick ? 24.0 : 16.0),
                      decoration: BoxDecoration(
                        color: isMainTick ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Number Label on whole units
                    if (isMainTick)
                      Text(
                        tickValue.toInt().toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      )
                    else
                      const SizedBox(height: 17),
                  ],
                ),
              );
            },
          ),

          // 2. Center Indicator Needle / Pointer
          Positioned(
            top: 10,
            bottom: 30,
            child: IgnorePointer(
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: widget.pointerColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.pointerColor.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
