import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../services/step_tracker.dart';
import '../widgets/apple_kit.dart';
import '../widgets/liquid_glass.dart';

// Full-screen live walk: free OpenStreetMap/CARTO tiles in light and dark
// styles, the camera follows you, your route is drawn as you walk, and the
// steps come from the phone's step sensor. Controls sit on liquid glass
// over dark top and bottom gradients.

class _Style {
  final String name;
  final String url;
  final List<String> subs;
  final bool dark;
  final String credit;
  final List<double>? filter; // colour matrix applied to each tile
  const _Style(this.name, this.url, this.subs, this.dark, this.credit, [this.filter]);
}

// All styles use free OpenStreetMap-based tile servers that need no API key
// or sign-up. Light and Dark are OpenStreetMap tiles recoloured on device.
const _osm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmCredit = '© OpenStreetMap contributors';

const _styles = [
  _Style('Light', _osm, [], false, _osmCredit, <double>[
    0.55, 0.30, 0.08, 0, 30,
    0.22, 0.62, 0.08, 0, 30,
    0.22, 0.30, 0.42, 0, 42,
    0, 0, 0, 1, 0,
  ]),
  _Style('Dark', _osm, [], true, _osmCredit, <double>[
    -0.50, -0.30, -0.06, 0, 228,
    -0.22, -0.60, -0.06, 0, 232,
    -0.18, -0.30, -0.40, 0, 245,
    0, 0, 0, 1, 0,
  ]),
  _Style('Streets', _osm, [], false, _osmCredit),
  _Style('Humanitarian', 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', ['a', 'b', 'c'], false,
      '© OpenStreetMap contributors, HOT'),
  _Style('Terrain', 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', ['a', 'b', 'c'], false,
      '© OpenStreetMap contributors, SRTM © OpenTopoMap'),
];

class WalkMapScreen extends StatefulWidget {
  const WalkMapScreen({super.key});

  @override
  State<WalkMapScreen> createState() => _WalkMapScreenState();
}

class _WalkMapScreenState extends State<WalkMapScreen> with TickerProviderStateMixin {
  final _map = MapController();
  final _tracker = StepTracker.instance;
  final List<LatLng> _route = [];
  LatLng? _me;
  double _heading = 0;
  double _accuracy = 0;
  bool _ready = false, _follow = true, _paused = false, _locked = false;
  int _style = 0;
  String? _gpsError;

  late final int _startSteps = _tracker.today;
  int _pausedSteps = 0, _pauseMark = 0;
  double _meters = 0;
  int _secs = 0;
  Timer? _clock;
  StreamSubscription<Position>? _pos;

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  AnimationController? _cam;

  int get _steps => math.max(0, _tracker.today - _startSteps - _pausedSteps - (_paused ? _tracker.today - _pauseMark : 0));
  double get _km => math.max(_meters, _steps * StepTracker.strideM) / 1000;
  int get _kcal => (_steps * StepTracker.kcalPerStep + _km * 12).round();

  @override
  void initState() {
    super.initState();
    _style = DateTime.now().hour >= 19 || DateTime.now().hour < 6 ? 1 : 0;
    _tracker.start();
    _tracker.addListener(_onSteps);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) setState(() => _secs++);
    });
    _startGps();
  }

  void _onSteps() {
    if (mounted) setState(() {});
  }

  Future<void> _startGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _gpsError = 'Turn on location to see your route');
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _gpsError = 'Location permission is off');
        return;
      }
      // Last known fix is instant on phones (not supported in browsers).
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) _onPos(last, jump: true);
      } catch (_) {}
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      ).then((p) => _onPos(p, jump: _route.length < 2)).catchError((_) {});
      _pos = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 2),
      ).listen((p) => _onPos(p), onError: (_) {
        if (mounted) setState(() => _gpsError = 'Waiting for GPS signal');
      });
    } catch (_) {
      if (mounted) setState(() => _gpsError = 'Location is not available here');
    }
  }

  void _onPos(Position p, {bool jump = false}) {
    if (!mounted) return;
    final pt = LatLng(p.latitude, p.longitude);
    setState(() {
      _gpsError = null;
      _accuracy = p.accuracy;
      if (p.heading > 0) _heading = p.heading;
      if (!_paused && (p.accuracy < 35 || _route.isEmpty)) {
        if (_route.isNotEmpty) {
          final d = Geolocator.distanceBetween(_route.last.latitude, _route.last.longitude, pt.latitude, pt.longitude);
          if (d >= 2 && d < 120) {
            _meters += d;
            _route.add(pt);
          }
        } else {
          _route.add(pt);
        }
      }
      _me = pt;
    });
    if (_ready && _follow) _glide(pt, jump ? 17.5 : _map.camera.zoom, jump: jump || _route.length < 2);
  }

  /// Smoothly moves the camera so you stay centred as you walk.
  void _glide(LatLng to, double zoom, {bool jump = false}) {
    if (jump) {
      _map.move(to, zoom);
      return;
    }
    final from = _map.camera.center;
    final z0 = _map.camera.zoom;
    _cam?.dispose();
    final c = _cam = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    final a = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    c.addListener(() {
      final t = a.value;
      _map.move(
        LatLng(from.latitude + (to.latitude - from.latitude) * t, from.longitude + (to.longitude - from.longitude) * t),
        z0 + (zoom - z0) * t,
      );
    });
    c.forward();
  }

  void _togglePause() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_paused) {
        _pausedSteps += _tracker.today - _pauseMark;
      } else {
        _pauseMark = _tracker.today;
      }
      _paused = !_paused;
    });
  }

  @override
  void dispose() {
    _tracker.removeListener(_onSteps);
    _clock?.cancel();
    _pos?.cancel();
    _pulse.dispose();
    _cam?.dispose();
    super.dispose();
  }

  String get _time {
    final h = _secs ~/ 3600, m = (_secs % 3600) ~/ 60, s = _secs % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  String get _pace {
    if (_km < 0.02) return '--';
    final spk = _secs / _km;
    return "${spk ~/ 60}'${(spk % 60).round().toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    final st = _styles[_style];
    final dark = st.dark;
    final fg = dark ? Colors.white : akInk;
    final sub = dark ? Colors.white70 : akMuted;
    final glass = dark ? const [Color(0xC0111827), Color(0xB01F2937)] : null;
    final accent = dark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
    final pad = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0B0F15) : const Color(0xFFF2F2F2),
        body: Stack(children: [
          // ------------------------------------------------------- map
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _me ?? const LatLng(28.6139, 77.2090),
                initialZoom: _me == null ? 12 : 17.5,
                maxZoom: 19,
                minZoom: 3,
                interactionOptions: InteractionOptions(
                  flags: _locked ? InteractiveFlag.none : InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  _ready = true;
                  if (_me != null) _map.move(_me!, 17.5);
                },
                onPositionChanged: (cam, gesture) {
                  if (gesture && _follow) setState(() => _follow = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: st.url,
                  subdomains: st.subs,
                  userAgentPackageName: 'com.neurofit.app',
                  tileDisplay: const TileDisplay.fadeIn(),
                  tileBuilder: st.filter == null
                      ? null
                      : (context, tile, _) => ColorFiltered(colorFilter: ColorFilter.matrix(st.filter!), child: tile),
                ),
                if (_route.length > 1)
                  PolylineLayer(polylines: [
                    Polyline(points: _route, strokeWidth: 11, color: accent.withValues(alpha: 0.25)),
                    Polyline(
                      points: _route,
                      strokeWidth: 5.5,
                      gradientColors: dark
                          ? const [Color(0xFF22D3EE), Color(0xFF4ADE80)]
                          : const [Color(0xFF3B82F6), Color(0xFF16A34A)],
                      borderStrokeWidth: 1.5,
                      borderColor: Colors.white.withValues(alpha: 0.9),
                    ),
                  ]),
                if (_route.isNotEmpty)
                  MarkerLayer(markers: [
                    Marker(
                      point: _route.first,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF3B82F6), width: 5),
                        ),
                      ),
                    ),
                  ]),
                if (_me != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _me!,
                      width: 120,
                      height: 120,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => Stack(alignment: Alignment.center, children: [
                          Container(
                            width: 30 + 80 * _pulse.value,
                            height: 30 + 80 * _pulse.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.28 * (1 - _pulse.value)),
                            ),
                          ),
                          Transform.rotate(
                            angle: _heading * math.pi / 180,
                            child: CustomPaint(size: const Size(56, 56), painter: _Cone(accent)),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),
              ],
            ),
          ),

          // ------------------------------------------- top/bottom shade
          IgnorePointer(
            child: Column(children: [
              Container(
                height: pad.top + 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: dark ? 0.75 : 0.45), Colors.transparent],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 330,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: dark ? 0.85 : 0.55), Colors.transparent],
                  ),
                ),
              ),
            ]),
          ),

          // ------------------------------------------------------- top
          Positioned(
            top: pad.top + 10,
            left: 14,
            right: 14,
            child: Row(children: [
              _round(Icons.arrow_back_ios_new_rounded, () => Navigator.of(context).maybePop(), fg, glass),
              const SizedBox(width: 10),
              Expanded(
                child: LiquidGlass(
                  style: LiquidGlassStyle.regular,
                  colors: glass,
                  borderRadius: BorderRadius.circular(22),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(children: [
                    Icon(Icons.directions_walk_rounded, color: accent, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: _steps.toDouble()),
                          duration: const Duration(milliseconds: 500),
                          builder: (_, v, _) => Text('${v.round()}', style: akN(22, c: fg)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('steps', style: akT(12, c: sub)),
                    const Spacer(),
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 18),
                    const SizedBox(width: 3),
                    Text('$_kcal', style: akN(17, c: fg)),
                    const SizedBox(width: 3),
                    Text('kcal', style: akT(11.5, c: sub)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              _round(Icons.layers_rounded, _pickStyle, fg, glass),
            ]),
          ),

          // GPS state chip.
          Positioned(
            top: pad.top + 66,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: LiquidGlass(
                  key: ValueKey('$_gpsError$_paused${_accuracy.round() ~/ 10}'),
                  style: LiquidGlassStyle.regular,
                  colors: glass,
                  shadow: false,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _paused
                            ? const Color(0xFFF59E0B)
                            : _gpsError != null
                                ? const Color(0xFFEF4444)
                                : _accuracy <= 15
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _paused
                          ? 'Paused'
                          : _gpsError ?? (_me == null ? 'Finding you…' : 'GPS ±${_accuracy.round()} m · ${_styles[_style].name}'),
                      style: akT(12, w: FontWeight.w700, c: fg),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // Re-centre when you've panned away.
          Positioned(
            right: 14,
            bottom: pad.bottom + 236,
            child: AnimatedScale(
              scale: _follow ? 0 : 1,
              duration: const Duration(milliseconds: 380),
              curve: akSpring,
              child: _round(Icons.my_location_rounded, () {
                setState(() => _follow = true);
                if (_me != null) _glide(_me!, 17.5);
              }, accent, glass),
            ),
          ),

          // Tile credit (required by OpenStreetMap / CARTO).
          Positioned(
            left: 0,
            right: 0,
            bottom: pad.bottom + 1,
            child: IgnorePointer(
              child: Text(st.credit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
            ),
          ),

          // ---------------------------------------------------- bottom
          Positioned(
            left: 14,
            right: 14,
            bottom: pad.bottom + 16,
            child: LiquidGlass(
              style: LiquidGlassStyle.regular,
              colors: glass,
              borderRadius: BorderRadius.circular(32),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  _metric('Time', _time, fg, sub),
                  _metric('Distance', '${_km.toStringAsFixed(2)} km', fg, sub),
                  _metric('Pace', '$_pace /km', fg, sub),
                ]),
                const SizedBox(height: 14),
                Container(height: 1, color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                const SizedBox(height: 14),
                Row(children: [
                  _action(_locked ? Icons.lock_rounded : Icons.lock_open_rounded, _locked ? 'Locked' : 'Lock', () {
                    HapticFeedback.selectionClick();
                    setState(() => _locked = !_locked);
                  }, fg, sub, dark),
                  _action(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, dark ? 'Light' : 'Dark', () {
                    setState(() => _style = dark ? 0 : 1);
                  }, fg, sub, dark),
                  Expanded(
                    flex: 2,
                    child: AkPress(
                      onTap: _locked ? null : _togglePause,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _paused ? accent : const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: (_paused ? accent : const Color(0xFFF59E0B)).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 26),
                          const SizedBox(width: 4),
                          Text(_paused ? 'Resume' : 'Pause', style: akT(15, w: FontWeight.w800, c: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                  _action(Icons.stop_rounded, 'Finish', _locked ? () {} : _finish, const Color(0xFFEF4444), sub, dark),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _round(IconData i, VoidCallback onTap, Color c, List<Color>? glass) => LiquidGlass(
        style: LiquidGlassStyle.regular,
        shape: BoxShape.circle,
        colors: glass,
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(i, size: 19, color: c)),
      );

  Widget _metric(String l, String v, Color fg, Color sub) => Expanded(
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: akN(21, c: fg))),
          const SizedBox(height: 4),
          Text(l, style: akT(11.5, c: sub)),
        ]),
      );

  Widget _action(IconData i, String l, VoidCallback onTap, Color c, Color sub, bool dark) => Expanded(
        child: AkPress(
          onTap: onTap,
          child: Column(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.07),
              ),
              child: Icon(i, color: c, size: 21),
            ),
            const SizedBox(height: 4),
            Text(l, style: akT(11, w: FontWeight.w700, c: sub)),
          ]),
        ),
      );

  Widget _filtered(_Style s, Widget w) =>
      s.filter == null ? w : ColorFiltered(colorFilter: ColorFilter.matrix(s.filter!), child: w);

  void _pickStyle() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        colors: const [Colors.white, Color(0xFFF8FAFC)],
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 12),
          Text('Map style', style: akT(19, w: FontWeight.w800)),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _styles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = _styles[i];
                final sel = i == _style;
                final preview = s.url
                    .replaceAll('{s}', s.subs.isEmpty ? '' : s.subs.first)
                    .replaceAll('{z}', '15')
                    .replaceAll('{x}', '23409')
                    .replaceAll('{y}', '13626')
                    .replaceAll('{r}', '');
                return AkPress(
                  onTap: () {
                    setState(() => _style = i);
                    Navigator.of(ctx).pop();
                  },
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? const Color(0xFF16A34A) : Colors.transparent, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: _filtered(s, Image.network(
                          preview,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: s.dark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
                        )),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(s.name, style: akT(12, w: FontWeight.w700, c: sel ? const Color(0xFF16A34A) : akInk)),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _finish() {
    HapticFeedback.heavyImpact();
    final steps = _steps, km = _km, kcal = _kcal, time = _time, pace = _pace;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LiquidGlass(
        style: LiquidGlassStyle.material,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        colors: const [Colors.white, Color(0xFFF8FAFC)],
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 16),
          const Text('🎉', style: TextStyle(fontSize: 44)),
          Text('Walk complete', style: akT(22, w: FontWeight.w800)),
          const SizedBox(height: 18),
          Row(children: [
            _sum('Steps', '$steps', const Color(0xFF7C3AED)),
            _sum('Distance', '${km.toStringAsFixed(2)} km', const Color(0xFF3B82F6)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _sum('Time', time, const Color(0xFF16A34A)),
            _sum('Calories', '$kcal kcal', const Color(0xFFF97316)),
          ]),
          const SizedBox(height: 10),
          Row(children: [_sum('Avg pace', '$pace /km', const Color(0xFFEC4899))]),
          const SizedBox(height: 18),
          AkPress(
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: akInk, borderRadius: BorderRadius.circular(18)),
              child: Text('Done', style: akT(16, w: FontWeight.w800, c: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Keep walking', style: akT(14, c: akMuted))),
        ]),
      ),
    );
  }

  Widget _sum(String l, String v, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: akN(22))),
            const SizedBox(height: 4),
            Text(l, style: akT(12, c: akMuted)),
          ]),
        ),
      );
}

/// Soft heading cone in front of your location dot.
class _Cone extends CustomPainter {
  final Color c;
  _Cone(this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final o = Offset(size.width / 2, size.height / 2);
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..arcTo(Rect.fromCircle(center: o, radius: size.width / 2), -math.pi / 2 - 0.5, 1.0, false)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(colors: [c.withValues(alpha: 0.55), c.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: o, radius: size.width / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _Cone o) => o.c != c;
}
