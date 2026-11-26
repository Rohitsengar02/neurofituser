part of '../wellness_tab_v3.dart';

// =====================================================================
//  JOURNAL
// =====================================================================

class _Journal extends StatelessWidget {
  const _Journal();

  static const _tagColor = {'Intention': _amber, 'Gratitude': _pink, 'Reflection': _violet, 'Note': _teal};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<JournalEntry>>(
      valueListenable: WellnessState.journal,
      builder: (_, list, _) => Column(children: [
        ScrollReveal(
          child: AkGlass(
            colors: const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
            onTap: () => _write(context),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("TODAY'S PROMPT", style: akT(11, w: FontWeight.w800, c: _violet, ls: 1.2)),
                  const SizedBox(height: 6),
                  Text('What is one small thing that made today lighter?', style: akT(16, w: FontWeight.w800, h: 1.3)),
                ]),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: _violet, shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        for (final j in list.reversed)
          ScrollReveal(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AkGlass(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: (_tagColor[j.tag] ?? _teal).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                    child: Text(j.mood, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(j.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: akT(14.5, w: FontWeight.w800))),
                        Text(j.time, style: akT(11.5, c: akFaint)),
                      ]),
                      const SizedBox(height: 4),
                      Text(j.body, style: akT(13, w: FontWeight.w500, c: akMuted, h: 1.4)),
                      const SizedBox(height: 8),
                      _pill(j.tag, _tagColor[j.tag] ?? _teal),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  static void _write(BuildContext context) {
    final ctl = TextEditingController();
    var mood = '😊';
    var tag = 'Note';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: LiquidGlass(
            style: LiquidGlassStyle.material,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 14),
              Text('New entry', style: akT(20, w: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(children: [
                for (final m in ['😣', '😕', '😐', '😊', '🤩'])
                  GestureDetector(
                    onTap: () => set(() => mood = m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: m == mood ? _amber.withValues(alpha: 0.2) : Colors.transparent),
                      child: Text(m, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final t in _tagColor.keys)
                  ChoiceChip(
                    label: Text(t, style: akT(12, w: FontWeight.w700)),
                    selected: t == tag,
                    onSelected: (_) => set(() => tag = t),
                  ),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: TextField(
                  controller: ctl,
                  maxLines: 4,
                  autofocus: true,
                  style: akT(15, w: FontWeight.w500),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Write freely…'),
                ),
              ),
              const SizedBox(height: 14),
              AkPress(
                onTap: () {
                  final t = ctl.text.trim();
                  if (t.isEmpty) return;
                  final n = TimeOfDay.now();
                  final time = '${n.hourOfPeriod == 0 ? 12 : n.hourOfPeriod}:${n.minute.toString().padLeft(2, '0')} ${n.period == DayPeriod.am ? 'AM' : 'PM'}';
                  WellnessState.journal.value = [
                    ...WellnessState.journal.value,
                    JournalEntry(time, mood, tag == 'Note' ? 'Quick note' : tag, t, tag),
                  ];
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _violet, borderRadius: BorderRadius.circular(16)),
                  child: Text('Save entry', style: akT(15, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
