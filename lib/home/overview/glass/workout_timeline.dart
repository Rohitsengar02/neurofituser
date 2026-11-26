part of '../overview_glass.dart';

// =====================================================================
//  WORKOUT TIMELINE (month grid with checks)
// =====================================================================

class _WorkoutTimelineWidget extends StatefulWidget {
  const _WorkoutTimelineWidget();

  @override
  State<_WorkoutTimelineWidget> createState() => _WorkoutTimelineWidgetState();
}

class _WorkoutTimelineWidgetState extends State<_WorkoutTimelineWidget> {
  int? _sel;
  static const _m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  // Workouts done per month (goal 16). 0 = missed, -1 = not yet.
  static const _done = [6, 17, 16, 18, 15, 17, 16, 19, 4, 16, 12, -1];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final paid = _done.where((d) => d >= 15).length;
    return GlassPanel(
      tint: [const Color(0xFFF7FEE7).withValues(alpha: 0.9), const Color(0xFFECFCCB).withValues(alpha: 0.7)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workouts this year', style: _t(12.5, w: FontWeight.w500, c: _muted)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('156', style: _t(34, w: FontWeight.w700, ls: -1.2)),
                        const SizedBox(width: 6),
                        Text('sessions', style: _t(12, w: FontWeight.w600, c: _muted)),
                      ],
                    ),
                  ],
                ),
              ),
              _AnimRing(
                paid / 11,
                const Color(0xFF65A30D),
                size: 62,
                stroke: 5,
                center: Text('$paid/11', style: _t(13, w: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('${now.year}', style: _t(13, w: FontWeight.w700, c: _muted)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 5 * 6) / 6;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 12; i++)
                  _monthTile(i, w),
              ],
            );
          }),
          AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: _spring,
            child: _sel == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _done[_sel!] >= 15 ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
                            color: _done[_sel!] >= 15 ? const Color(0xFF65A30D) : _orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _done[_sel!] < 0
                                  ? '${_m[_sel!]} is coming up. Plan 16 sessions to keep the streak.'
                                  : '${_m[_sel!]}: ${_done[_sel!]} of 16 workouts${_done[_sel!] >= 15 ? ', goal reached!' : '. Missed the goal.'}',
                              style: _t(12.5, w: FontWeight.w600, h: 1.35),
                            ),
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

  Widget _monthTile(int i, double w) {
    final d = _done[i];
    final ok = d >= 15;
    final future = d < 0;
    final sel = _sel == i;
    return _Press(
      onTap: () => setState(() => _sel = sel ? null : i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: w,
        height: w * 1.15,
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white.withValues(alpha: future ? 0.35 : 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? const Color(0xFF65A30D) : Colors.white.withValues(alpha: 0.9),
            width: sel ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(_m[i], style: _t(10.5, w: FontWeight.w600, c: future ? _muted : _ink)),
            Container(
              width: w * 0.48,
              height: w * 0.48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ok ? _lime : (future ? Colors.transparent : const Color(0xFFE5E7EB)),
                border: future ? Border.all(color: const Color(0xFFD1D5DB)) : null,
              ),
              child: future
                  ? null
                  : Icon(ok ? Icons.check_rounded : Icons.close_rounded,
                      size: w * 0.3, color: ok ? const Color(0xFF365314) : _muted),
            ),
          ],
        ),
      ),
    );
  }
}
