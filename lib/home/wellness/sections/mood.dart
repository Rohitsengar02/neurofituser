part of '../wellness_tab_v3.dart';

// =====================================================================
//  MOOD
// =====================================================================

class _MoodCard extends StatelessWidget {
  const _MoodCard();

  @override
  Widget build(BuildContext context) {
    const moods = [('😣', 'Awful'), ('😕', 'Low'), ('😐', 'Okay'), ('😊', 'Good'), ('🤩', 'Great')];
    const tips = [
      'Rough day. Try the 4-7-8 breath below, it calms the body in a minute.',
      'Low energy is okay. A five-minute walk and some water can lift it.',
      'Steady. A short body scan can help you notice what you need.',
      'Nice. Note what went well in your journal so you can repeat it.',
      'Brilliant. Share it with the community or spend it on a strong workout.',
    ];
    return ValueListenableBuilder<int>(
      valueListenable: WellnessState.mood,
      builder: (_, m, _) => AkGlass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < moods.length; i++)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  WellnessState.mood.value = i;
                },
                child: Column(children: [
                  AnimatedScale(
                    scale: i == m ? 1.25 : 0.95,
                    duration: const Duration(milliseconds: 380),
                    curve: akSpring,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == m ? _amber.withValues(alpha: 0.18) : Colors.transparent,
                      ),
                      child: Text(moods[i].$1, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(moods[i].$2, style: akT(11.5, w: FontWeight.w700, c: i == m ? akInk : akMuted)),
                ]),
              ),
          ]),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(tips[m], key: ValueKey(m), style: akT(13.5, w: FontWeight.w500, c: akMuted, h: 1.4)),
          ),
        ]),
      ),
    );
  }
}
