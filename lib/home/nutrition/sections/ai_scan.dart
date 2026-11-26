part of '../nutrition_tab_v3.dart';

// =====================================================================
//  AI SCAN
// =====================================================================

class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: BorderRadius.circular(28),
        colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        onTap: () => _openLog(context),
        child: LayoutBuilder(builder: (context, c) {
          final img = (c.maxWidth * 0.42).clamp(110.0, 180.0);
          return SizedBox(
          height: 150,
          child: Stack(children: [
            Positioned(
              right: -10,
              bottom: -6,
              width: img,
              child: Image.asset('assets/images/island/meal_scan.png', fit: BoxFit.contain),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 18, img - 14, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFFBAE6FD), size: 16),
                  const SizedBox(width: 6),
                  Text('AI MEAL SCAN', style: _t(11.5, w: FontWeight.w800, c: const Color(0xFFBAE6FD), ls: 1)),
                ]),
                const SizedBox(height: 8),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('Snap your plate,\nKemo counts it', style: _t(19, w: FontWeight.w800, c: Colors.white, h: 1.15))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.photo_camera_rounded, size: 16, color: _blue),
                    const SizedBox(width: 6),
                    Text('Scan meal', style: _t(13, w: FontWeight.w800, c: _blue)),
                  ]),
                ),
              ]),
            ),
          ]),
          );
        }),
      ),
    );
  }
}
