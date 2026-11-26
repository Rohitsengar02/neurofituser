part of '../wellness_tab_v3.dart';

// =====================================================================
//  SLEEP
// =====================================================================

class _SleepCard extends StatelessWidget {
  const _SleepCard();

  @override
  Widget build(BuildContext context) {
    const stages = [('Deep', 1.4, Color(0xFF4338CA)), ('Core', 3.6, Color(0xFF6366F1)), ('REM', 1.8, Color(0xFFA78BFA)), ('Awake', 0.4, Color(0xFFFBBF24))];
    const total = 7.2;
    return AkGlass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('7', style: akN(40)),
          Text('h ', style: akT(16, c: akMuted)),
          Text('12', style: akN(40)),
          Text('m', style: akT(16, c: akMuted)),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('11:20 PM – 6:42 AM', style: akT(12, c: akMuted)),
            const SizedBox(height: 4),
            _pill('Score 86', _indigo),
          ]),
        ]),
        const SizedBox(height: 16),
        AkSeen(
          builder: (_, t) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 18,
              child: Row(children: [
                for (final s in stages)
                  Expanded(
                    flex: (s.$2 * 100).round(),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(widthFactor: t, child: Container(color: s.$3)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          for (final s in stages)
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(s.$1, style: akT(11.5, c: akMuted)),
                ]),
                const SizedBox(height: 3),
                Text('${(s.$2 / total * 100).round()}%', style: akN(15)),
              ]),
            ),
        ]),
      ]),
    );
  }
}
