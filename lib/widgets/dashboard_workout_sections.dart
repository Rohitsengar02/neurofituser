import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../screens/workout_category_detail_screen.dart';
import '../screens/workout_detail_screen.dart';
import '../services/workout_layout_backend_service.dart';
import '../services/workout_category_backend_service.dart';
import '../services/category_backend_service.dart';
import '../services/workout_banners_backend_service.dart';
import '../services/workout_section_items_service.dart';

// =============================================================
// DESIGN TOKENS  (one accent, neutral slate base)
// =============================================================
const _kInk = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);
const _kFaint = Color(0xFF94A3B8);
const _kLine = Color(0xFFE2E8F0);
const _kSurface = Color(0xFFF8FAFC);
const _kAccent = Color(0xFF16A34A);
const _kAccentDeep = Color(0xFF15803D);
const _kAccentSoft = Color(0xFFDCFCE7);

TextStyle _t(
  double size, {
  FontWeight w = FontWeight.w700,
  Color c = _kInk,
  double ls = 0,
  double h = 1.2,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
      height: h,
    );

// =============================================================
// WORKOUTS TAB
// =============================================================
class DashboardWorkoutTabContent extends StatefulWidget {
  const DashboardWorkoutTabContent({super.key});

  @override
  State<DashboardWorkoutTabContent> createState() =>
      _DashboardWorkoutTabContentState();
}

class _DashboardWorkoutTabContentState extends State<DashboardWorkoutTabContent>
    with TickerProviderStateMixin {
  final Set<String> _bookmarked = {};
  final Set<String> _followed = {};

  final _layout = WorkoutLayoutBackendService();
  final _categories = WorkoutCategoryBackendService();
  final _banners = WorkoutBannersBackendService();
  final _items = WorkoutSectionItemsService.instance;

  late final AnimationController _shimmer;
  final Set<String> _revealed = {};
  bool _revealing = false;
  bool _prefetched = false;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _layout.addListener(_onData);
    _categories.addListener(_onData);
    _banners.addListener(_onData);
    _items.addListener(_onData);

    // Kick off every network call at once — nothing waits on anything else.
    _categories.fetchCategories();
    _banners.fetchWorkoutBanners();

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _layout.removeListener(_onData);
    _categories.removeListener(_onData);
    _banners.removeListener(_onData);
    _items.removeListener(_onData);
    _shimmer.dispose();
    super.dispose();
  }

  void _onData() {
    if (!mounted) return;
    setState(() {});
    _bootstrap();
  }

  // -------------------------------------------------------------
  // LOADING STRATEGY
  //  1. All section item queries fire in parallel as soon as the
  //     layout arrives.
  //  2. Sections are revealed top-to-bottom, each one only once its
  //     data is in and its first 3 images are decoded — so the user
  //     never sees a card pop in with a blank image.
  //  3. Everything above stays interactive; skeletons match the exact
  //     card dimensions so nothing shifts.
  // -------------------------------------------------------------
  void _bootstrap() {
    final sections = _layout.activeSections;
    if (sections.isEmpty) return;

    if (!_prefetched) {
      _prefetched = true;
      _items.prefetchAll(sections.map((s) => (id: s.id, type: s.type)));
    }
    if (!_revealing && _revealed.length < sections.length) {
      _revealSequentially();
    }
  }

  Future<void> _revealSequentially() async {
    _revealing = true;
    final sections = _layout.activeSections;

    for (final sec in sections) {
      if (!mounted) break;
      if (_revealed.contains(sec.id)) continue;

      await _waitForData(sec);
      if (!mounted) break;
      await _precache(_imagesFor(sec).take(3));
      if (!mounted) break;

      setState(() => _revealed.add(sec.id));
      await Future.delayed(const Duration(milliseconds: 90));
    }
    _revealing = false;
  }

  Future<void> _waitForData(WorkoutLayoutSectionModel sec) async {
    final needsItems =
        WorkoutSectionItemsService.collectionForType.containsKey(sec.type);
    bool ready() {
      switch (sec.type) {
        case 'categories':
          return _categories.activeCategories.isNotEmpty;
        case 'hero_banners':
          return _banners.banners.isNotEmpty;
        default:
          return !needsItems || _items.isLoaded(sec.id);
      }
    }

    final deadline = DateTime.now().add(const Duration(milliseconds: 2500));
    while (!ready() && DateTime.now().isBefore(deadline) && mounted) {
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> _precache(Iterable<String> urls) async {
    final targets = urls.where((u) => u.trim().isNotEmpty).toList();
    if (targets.isEmpty) return;
    await Future.wait(targets.map((u) {
      try {
        return precacheImage(_provider(u, width: 720), context)
            .timeout(const Duration(milliseconds: 700), onTimeout: () {});
      } catch (_) {
        return Future.value();
      }
    }));
  }

  List<String> _imagesFor(WorkoutLayoutSectionModel sec) {
    switch (sec.type) {
      case 'hero_banners':
        return _banners.banners
            .where((b) => b.isActive)
            .map((b) => b.imageUrl)
            .toList();
      case 'categories':
        return _visibleCategories(sec)
            .map((c) => CategoryBackendService.getDisplayableImageUrl(
                  c.mediaUrl,
                ))
            .toList();
      case 'custom_banner':
        return [
          CategoryBackendService.getDisplayableImageUrl(
            sec.customBannerImageUrl,
          ),
        ];
      default:
        return _itemsFor(sec)
            .map((i) => CategoryBackendService.getDisplayableImageUrl(
                  i.str('image', i.str('imageUrl', i.str('avatar'))),
                ))
            .toList();
    }
  }

  // -------------------------------------------------------------
  // DATA ACCESSORS
  // -------------------------------------------------------------
  List<WorkoutCategoryModel> _visibleCategories(
    WorkoutLayoutSectionModel? sec,
  ) {
    var cats = _categories.activeCategories.isNotEmpty
        ? _categories.activeCategories
        : _categories.getDefaultFallbackCategories();
    if (sec != null && sec.selectedItemIds.isNotEmpty) {
      final sel =
          cats.where((c) => sec.selectedItemIds.contains(c.id)).toList();
      if (sel.isNotEmpty) cats = sel;
    }
    return cats;
  }

  /// Items from Firestore; falls back to seed data only when the
  /// collection is empty so the tab never renders blank mid-migration.
  List<WorkoutSectionItem> _itemsFor(WorkoutLayoutSectionModel sec) {
    var list = _items.items(sec.id);
    if (list.isEmpty) list = _seed(sec.type);
    if (sec.selectedItemIds.isNotEmpty) {
      final sel = list.where((i) => sec.selectedItemIds.contains(i.id)).toList();
      if (sel.isNotEmpty) list = sel;
    }
    return list;
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final sections = _layout.activeSections;
    if (sections.isEmpty) return _InitialSkeleton(shimmer: _shimmer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _searchBar(),
        const SizedBox(height: 22),
        for (final sec in sections) ...[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _revealed.contains(sec.id)
                ? KeyedSubtree(
                    key: ValueKey('on_${sec.id}'),
                    child: RepaintBoundary(child: _section(sec)),
                  )
                : KeyedSubtree(
                    key: ValueKey('sk_${sec.id}'),
                    child: _SectionSkeleton(type: sec.type, shimmer: _shimmer),
                  ),
          ),
          const SizedBox(height: 28),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _section(WorkoutLayoutSectionModel sec) {
    switch (sec.type) {
      case 'hero_banners':
        return _heroBanners();
      case 'categories':
        return _categoriesSection(sec);
      case 'popular_programs':
        return _programs(sec);
      case 'bento_spotlight':
        return _spotlight(sec);
      case 'muscle_groups':
        return _muscleGroups(sec);
      case 'celebrity_coaches':
        return _coaches(sec);
      case 'equipment_training':
        return _equipment(sec);
      case 'trending_challenges':
        return _challenges(sec);
      case 'audio_beats':
        return _audio(sec);
      case 'custom_banner':
        return _customBanner(sec);
      default:
        return _programs(sec);
    }
  }

  // -------------------------------------------------------------
  // SEARCH  (light glass over the tab gradient)
  // -------------------------------------------------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Glass(
        radius: 18,
        blur: 12,
        padding: const EdgeInsets.only(left: 14, right: 6),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: _kFaint, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: _t(14, w: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Search workouts, coaches, body part',
                    hintStyle: _t(13.5, w: FontWeight.w500, c: _kFaint),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              _Tap(
                onTap: () => HapticFeedback.selectionClick(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kInk,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. HERO BANNERS
  // -------------------------------------------------------------
  Widget _heroBanners() {
    final active = _banners.banners.where((b) => b.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return _HeroBannerCarousel(
      banners: active
          .map((b) => _BannerVM(
                key: '${b.bannerId}_${b.imageUrl}',
                imageUrl: b.imageUrl,
                mediaType: b.mediaType,
                title: b.title,
                subtitle: b.subtitle,
                badge: b.badge,
                buttonText: b.buttonText,
                showTitle: b.showTitle,
              ))
          .toList(),
    );
  }

  // -------------------------------------------------------------
  // 2. CATEGORIES
  // -------------------------------------------------------------
  Widget _categoriesSection(WorkoutLayoutSectionModel sec) {
    final cats = _visibleCategories(sec);
    final title = sec.title.trim().isNotEmpty ? sec.title.trim() : 'Categories';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sec.showTitle)
          _Header(
            title: title,
            action: 'See all',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WorkoutCategoryDetailScreen(),
              ),
            ),
          ),
        SizedBox(
          height: 122,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final cat = cats[i];
              return _Tap(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutCategoryDetailScreen(
                      initialCategory: cat.name,
                    ),
                  ),
                ),
                child: _Card(
                  width: 122,
                  height: 122,
                  radius: 22,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CategoryMediaRenderer(
                        mediaUrl: cat.mediaUrl,
                        mediaType: cat.mediaType,
                      ),
                      _scrim(top: false, strength: 0.55),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: _Glass(
                          dark: true,
                          radius: 12,
                          blur: 10,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(11.5,
                                w: FontWeight.w800, c: Colors.white),
                          ),
                        ),
                      ),
                      if (cat.mediaType == 'video' || cat.mediaType == 'gif')
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _MediaBadge(type: cat.mediaType),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. POPULAR PROGRAMS
  // -------------------------------------------------------------
  Widget _programs(WorkoutLayoutSectionModel sec) {
    final items = _itemsFor(sec);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: sec.title.trim().isNotEmpty ? sec.title : 'Popular Programs',
          subtitle: sec.subtitle.trim().isNotEmpty ? sec.subtitle : null,
          action: 'See all',
          onTap: () {},
        ),
        SizedBox(
          height: 236,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final p = items[i];
              final saved = _bookmarked.contains(p.id);
              final image = _display(p.str('image', p.str('imageUrl')));

              return _Tap(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      title: p.str('title'),
                      subtitle: p.str('subtitle'),
                      image: image,
                      trainer: p.str('coach'),
                      duration: p.str('duration'),
                      level: p.str('level'),
                      rating: p.str('rating'),
                    ),
                  ),
                ),
                child: _Card(
                  width: 240,
                  radius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 138,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _NetImage(image, cacheWidth: 600),
                            _scrim(top: true, strength: 0.28),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: _RatingChip(p.str('rating', '4.9')),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: _IconGlassButton(
                                icon: saved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                active: saved,
                                onTap: () => _toggle(_bookmarked, p.id),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: Row(
                                children: [
                                  _Pill(
                                    p.str('duration', '30 min'),
                                    icon: Icons.schedule_rounded,
                                    dark: true,
                                  ),
                                  const SizedBox(width: 6),
                                  _Pill(p.str('level', 'All levels'),
                                      dark: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.str('title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(14, w: FontWeight.w900, ls: -0.3),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p.str('subtitle'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(11, w: FontWeight.w600, c: _kMuted),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 13, color: _kFaint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${p.str('coach', 'Coach')}  ·  ${p.str('episodes', '')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _t(10.5,
                                        w: FontWeight.w700, c: _kFaint),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 4. BENTO SPOTLIGHT
  // -------------------------------------------------------------
  Widget _spotlight(WorkoutLayoutSectionModel sec) {
    final items = _itemsFor(sec);
    final imgs = <String>[
      if (sec.customBannerImageUrl.isNotEmpty)
        _display(sec.customBannerImageUrl),
      ...items.map((i) => _display(i.str('image', i.str('imageUrl')))),
    ];
    while (imgs.length < 3) {
      imgs.add(_display('spotlight_${imgs.length + 1}.png'));
    }
    String label(int i) =>
        i < items.length ? items[i].str('title') : '';

    Widget tile(String img, String text, double radius) => _Card(
          radius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetImage(img, cacheWidth: 600),
              if (text.isNotEmpty) ...[
                _scrim(top: false, strength: 0.45),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: _Glass(
                    dark: true,
                    radius: 12,
                    blur: 10,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(11, w: FontWeight.w800, c: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: sec.title.trim().isNotEmpty ? sec.title : 'Workout Spotlight',
            action: 'Featured',
            padded: false,
          ),
          SizedBox(
            height: 222,
            child: Row(
              children: [
                Expanded(flex: 6, child: tile(imgs[0], label(0), 24)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(child: tile(imgs[1], label(1), 20)),
                      const SizedBox(height: 8),
                      Expanded(child: tile(imgs[2], label(2), 20)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. MUSCLE GROUPS
  // -------------------------------------------------------------
  Widget _muscleGroups(WorkoutLayoutSectionModel sec) {
    final items = _itemsFor(sec);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: sec.title.trim().isNotEmpty ? sec.title : 'Target Muscle Groups',
          action: 'Explore',
        ),
        SizedBox(
          height: 152,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final m = items[i];
              return _Tap(
                onTap: () => HapticFeedback.selectionClick(),
                child: _Card(
                  width: 166,
                  radius: 22,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NetImage(_display(m.str('image', m.str('imageUrl'))),
                          cacheWidth: 480),
                      _scrim(top: false, strength: 0.5),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: _Glass(
                          dark: true,
                          radius: 14,
                          blur: 12,
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m.str('name', m.str('title')),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(12.5,
                                    w: FontWeight.w900, c: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.str('exercises', m.str('count')),
                                style: _t(10,
                                    w: FontWeight.w600,
                                    c: Colors.white.withValues(alpha: 0.78)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 6. COACHES
  // -------------------------------------------------------------
  Widget _coaches(WorkoutLayoutSectionModel sec) {
    final items = _itemsFor(sec);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: sec.title.trim().isNotEmpty ? sec.title : 'Elite Coaches',
          action: 'View all',
        ),
        SizedBox(
          height: 188,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = items[i];
              final following = _followed.contains(c.id);
              final avatar = _display(c.str('avatar', c.str('image')));

              return _Card(
                width: 170,
                radius: 24,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Blurred avatar as ambient backdrop
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Opacity(
                        opacity: 0.35,
                        child: _NetImage(avatar, cacheWidth: 120),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [_kAccent, Color(0xFF4ADE80)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kAccent.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 23,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: _NetImage(avatar,
                                          cacheWidth: 160),
                                    ),
                                  ),
                                ),
                              ),
                              _RatingChip(c.str('rating', '4.9')),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            c.str('name'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(13.5, w: FontWeight.w900, ls: -0.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.str('specialty'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(10.5, w: FontWeight.w600, c: _kMuted),
                          ),
                          const SizedBox(height: 10),
                          _Tap(
                            onTap: () => _toggle(_followed, c.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: following ? _kAccentSoft : _kInk,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    following
                                        ? Icons.check_rounded
                                        : Icons.add_rounded,
                                    size: 14,
                                    color: following
                                        ? _kAccentDeep
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    following ? 'Following' : 'Follow',
                                    style: _t(11,
                                        w: FontWeight.w800,
                                        c: following
                                            ? _kAccentDeep
                                            : Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 7. EQUIPMENT
  // -------------------------------------------------------------
  Widget _equipment(WorkoutLayoutSectionModel sec) {
    final items = _itemsFor(sec);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: sec.title.trim().isNotEmpty ? sec.title : 'Workout by Equipment',
          action: 'Filter',
        ),
        SizedBox(
          height: 124,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final e = items[i];
              final color = _hex(e.str('color'), _kAccent);
              return _Tap(
                onTap: () => HapticFeedback.selectionClick(),
                child: _Card(
                  width: 150,
                  radius: 22,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -22,
                        top: -22,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_iconFor(e.str('icon')),
                                  color: color, size: 20),
                            ),
                            const Spacer(),
                            Text(
                              e.str('name', e.str('title')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _t(12.5, w: FontWeight.w900, ls: -0.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.str('count', e.str('subtitle')),
                              style: _t(10, w: FontWeight.w600, c: _kMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 8. CHALLENGES
  // -------------------------------------------------------------
  Widget _challenges(WorkoutLayoutSectionModel sec) {
    final items = _itemsFor(sec);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: sec.title.trim().isNotEmpty ? sec.title : 'Trending Challenges',
          action: 'Join',
        ),
        SizedBox(
          height: 182,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final ch = items[i];
              final progress = ch.dbl('progressRatio', 0.4).clamp(0.0, 1.0);
              return _Tap(
                onTap: () => HapticFeedback.selectionClick(),
                child: _Card(
                  width: 280,
                  radius: 24,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NetImage(_display(ch.str('image', ch.str('imageUrl'))),
                          cacheWidth: 720),
                      _scrim(top: false, strength: 0.55),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _Pill(ch.str('badge', '+500 XP'),
                            icon: Icons.bolt_rounded, accent: true),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _Pill(ch.str('joined', ''),
                            icon: Icons.groups_rounded, dark: true),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: _Glass(
                          dark: true,
                          radius: 16,
                          blur: 14,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ch.str('title'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _t(13.5,
                                    w: FontWeight.w900,
                                    c: Colors.white,
                                    ls: -0.2),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 5,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Color(0xFF4ADE80)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    ch.str('progress'),
                                    style: _t(10,
                                        w: FontWeight.w700,
                                        c: Colors.white
                                            .withValues(alpha: 0.85)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 9. MUSIC-SYNCED
  // -------------------------------------------------------------
  Widget _audio(WorkoutLayoutSectionModel sec) {
    final items = _itemsFor(sec);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          title: sec.title.trim().isNotEmpty ? sec.title : 'Music-Synced Workouts',
          action: 'Playlists',
        ),
        SizedBox(
          height: 156,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final tr = items[i];
              return _Tap(
                onTap: () => HapticFeedback.selectionClick(),
                child: _Card(
                  width: 184,
                  radius: 22,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _NetImage(_display(tr.str('image', tr.str('imageUrl'))),
                          cacheWidth: 480),
                      Container(
                        color: _kInk.withValues(alpha: 0.42),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _Pill(tr.str('bpm', ''),
                                    icon: Icons.graphic_eq_rounded,
                                    accent: true),
                                const _IconGlassButton(
                                  icon: Icons.play_arrow_rounded,
                                  active: false,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              tr.str('title'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _t(13,
                                  w: FontWeight.w900,
                                  c: Colors.white,
                                  ls: -0.2),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tr.str('duration'),
                              style: _t(10.5,
                                  w: FontWeight.w600,
                                  c: Colors.white.withValues(alpha: 0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 10. CUSTOM BANNER
  // -------------------------------------------------------------
  Widget _customBanner(WorkoutLayoutSectionModel sec) {
    final img = _display(sec.customBannerImageUrl);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Tap(
        onTap: () => HapticFeedback.selectionClick(),
        child: _Card(
          height: 168,
          radius: 26,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (img.isNotEmpty)
                _NetImage(img, cacheWidth: 900)
              else
                Container(color: _kInk),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _kInk.withValues(alpha: 0.75),
                      _kInk.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (sec.customBannerBadge.isNotEmpty) ...[
                      _Pill(sec.customBannerBadge, accent: true),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      sec.title,
                      maxLines: 2,
                      style: _t(17,
                          w: FontWeight.w900, c: Colors.white, ls: -0.4),
                    ),
                    if (sec.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        sec.subtitle,
                        maxLines: 2,
                        style: _t(11.5,
                            w: FontWeight.w600,
                            c: Colors.white.withValues(alpha: 0.78)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------
  void _toggle(Set<String> set, String id) {
    HapticFeedback.lightImpact();
    setState(() => set.contains(id) ? set.remove(id) : set.add(id));
  }

  String _display(String raw) =>
      raw.isEmpty ? '' : CategoryBackendService.getDisplayableImageUrl(raw);

  Widget _scrim({required bool top, double strength = 0.5}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          stops: const [0.0, 0.7],
          colors: [
            _kInk.withValues(alpha: strength),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  static Color _hex(String v, Color fallback) {
    if (v.isEmpty) return fallback;
    var s = v.replaceAll('#', '').trim();
    if (s.length == 6) s = 'FF$s';
    final n = int.tryParse(s, radix: 16);
    return n == null ? fallback : Color(n);
  }

  static IconData _iconFor(String name) {
    switch (name.toLowerCase()) {
      case 'bands':
      case 'album':
        return Icons.album_rounded;
      case 'kettlebell':
      case 'gymnastics':
        return Icons.sports_gymnastics_rounded;
      case 'bodyweight':
      case 'run':
        return Icons.directions_run_rounded;
      case 'bike':
        return Icons.directions_bike_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  /// Seed rows shown only while a Firestore collection is still empty.
  static List<WorkoutSectionItem> _seed(String type) {
    List<WorkoutSectionItem> rows(List<Map<String, dynamic>> l) => [
          for (var i = 0; i < l.length; i++)
            WorkoutSectionItem(id: 'seed_${type}_$i', data: l[i]),
        ];
    const u = 'https://images.unsplash.com/';
    switch (type) {
      case 'popular_programs':
        return rows([
          {'title': 'Body Wellness & Core', 'subtitle': 'Full body toning & condition', 'duration': '35 min', 'episodes': '18 episodes', 'level': 'Intermediate', 'rating': '4.9', 'coach': 'Coach Emma', 'image': '${u}photo-1574680096145-d05b474e2155?q=80&w=600&auto=format&fit=crop'},
          {'title': 'Lean Muscle Hypertrophy', 'subtitle': 'Dumbbell & compound mastery', 'duration': '45 min', 'episodes': '24 episodes', 'level': 'Advanced', 'rating': '5.0', 'coach': 'Coach David', 'image': '${u}photo-1583454110551-21f2fa2afe61?q=80&w=600&auto=format&fit=crop'},
          {'title': 'Morning Sun Vinyasa', 'subtitle': 'Flexibility & spine alignment', 'duration': '25 min', 'episodes': '14 episodes', 'level': 'All levels', 'rating': '4.8', 'coach': 'Coach Maya', 'image': '${u}photo-1506126613408-eca07ce68773?q=80&w=600&auto=format&fit=crop'},
        ]);
      case 'muscle_groups':
        return rows([
          {'name': 'Chest & Triceps', 'exercises': '14 exercises', 'image': '${u}photo-1581009146145-b5ef050c2e1e?q=80&w=400&auto=format&fit=crop'},
          {'name': 'Back & Biceps', 'exercises': '16 exercises', 'image': '${u}photo-1605296867304-46d5465a13f1?q=80&w=400&auto=format&fit=crop'},
          {'name': 'Legs & Glutes', 'exercises': '20 exercises', 'image': '${u}photo-1434682881908-b43d0467b798?q=80&w=400&auto=format&fit=crop'},
        ]);
      case 'celebrity_coaches':
        return rows([
          {'name': 'Elena Rostova', 'specialty': 'Olympic lifting & HIIT', 'rating': '4.9', 'avatar': '${u}photo-1548690312-e3b507d8c110?q=80&w=300&auto=format&fit=crop'},
          {'name': 'Marcus Vance', 'specialty': 'CrossFit & conditioning', 'rating': '5.0', 'avatar': '${u}photo-1568602471122-7832951cc4c5?q=80&w=300&auto=format&fit=crop'},
        ]);
      case 'equipment_training':
        return rows([
          {'name': 'Dumbbells only', 'count': '28 workouts', 'icon': 'dumbbell', 'color': '#16A34A'},
          {'name': 'Resistance bands', 'count': '16 workouts', 'icon': 'bands', 'color': '#0284C7'},
          {'name': 'Bodyweight', 'count': '35 workouts', 'icon': 'bodyweight', 'color': '#EA580C'},
        ]);
      case 'trending_challenges':
        return rows([
          {'title': '30-Day Summer Shred', 'joined': '14.2k', 'progress': 'Week 2 of 4', 'progressRatio': 0.5, 'badge': '+500 XP', 'image': '${u}photo-1517838277536-f5f99be501cd?q=80&w=600&auto=format&fit=crop'},
        ]);
      case 'audio_beats':
        return rows([
          {'title': 'High BPM HIIT Cardio', 'bpm': '145 BPM', 'duration': '30 min', 'image': '${u}photo-1518310383802-640c2de311b2?q=80&w=400&auto=format&fit=crop'},
          {'title': 'Deep House Strength', 'bpm': '128 BPM', 'duration': '45 min', 'image': '${u}photo-1581009146145-b5ef050c2e1e?q=80&w=400&auto=format&fit=crop'},
        ]);
      default:
        return const [];
    }
  }
}

// =============================================================
// SHARED BUILDING BLOCKS
// =============================================================

/// Frosted panel with a top-edge highlight to fake refraction.
class _Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final bool dark;
  final EdgeInsets padding;

  const _Glass({
    required this.child,
    this.radius = 16,
    this.blur = 12,
    this.dark = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final base = dark ? Colors.black : Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: base.withValues(alpha: dark ? 0.30 : 0.62),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.22 : 0.80),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: dark ? 0.14 : 0.55),
                Colors.white.withValues(alpha: dark ? 0.02 : 0.15),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// White card with hairline border and a wide, low-opacity diffusion shadow.
class _Card extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const _Card({
    required this.child,
    this.width,
    this.height,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _kLine.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _kInk.withValues(alpha: 0.06),
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Tactile press: scales to 0.97 on touch, haptic on release.
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Tap({required this.child, required this.onTap});

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onTap;
  final bool padded;

  const _Header({
    required this.title,
    this.subtitle,
    this.action,
    this.onTap,
    this.padded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padded ? 20 : 0, 0, padded ? 20 : 0, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3.5,
            height: subtitle == null ? 18 : 28,
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(17, w: FontWeight.w900, ls: -0.5),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(11.5, w: FontWeight.w600, c: _kMuted),
                  ),
              ],
            ),
          ),
          if (action != null)
            _Tap(
              onTap: onTap ?? () {},
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action!,
                        style: _t(12, w: FontWeight.w800, c: _kAccentDeep)),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 13, color: _kAccentDeep),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool dark;
  final bool accent;
  const _Pill(this.text, {this.icon, this.dark = false, this.accent = false});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final fg = accent ? _kAccentDeep : (dark ? Colors.white : _kInk);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
        ],
        Text(text, style: _t(10, w: FontWeight.w800, c: fg)),
      ],
    );
    if (accent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _kAccentSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: content,
      );
    }
    return _Glass(
      dark: dark,
      radius: 8,
      blur: 8,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: content,
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String rating;
  const _RatingChip(this.rating);

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 8,
      blur: 8,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
          const SizedBox(width: 2),
          Text(rating, style: _t(10.5, w: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _IconGlassButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  const _IconGlassButton({required this.icon, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = active
        ? Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: _kAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          )
        : _Glass(
            radius: 15,
            blur: 8,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Icon(icon, size: 16, color: _kInk),
            ),
          );
    return onTap == null ? body : _Tap(onTap: onTap!, child: body);
  }
}

class _MediaBadge extends StatelessWidget {
  final String type;
  const _MediaBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return _Glass(
      dark: true,
      radius: 8,
      blur: 8,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: type == 'video'
          ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 13)
          : Text('GIF', style: _t(8, w: FontWeight.w900, c: Colors.white)),
    );
  }
}

// -------------------------------------------------------------
// IMAGE  — decoded at cacheWidth to keep memory low, fades in once ready
// -------------------------------------------------------------
ImageProvider _provider(String path, {int? width}) {
  ImageProvider base;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    base = NetworkImage(path);
  } else if (path.startsWith('assets/')) {
    base = AssetImage(path);
  } else {
    base = AssetImage('assets/images/$path');
  }
  return width == null ? base : ResizeImage(base, width: width);
}

class _NetImage extends StatelessWidget {
  final String url;
  final int cacheWidth;
  const _NetImage(this.url, {this.cacheWidth = 600});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ImageFallback();
    return Image(
      image: _provider(url, width: cacheWidth),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, syncLoaded) {
        if (syncLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded, color: _kFaint, size: 26),
      ),
    );
  }
}

// -------------------------------------------------------------
// SKELETONS  — same dimensions as the real cards so nothing jumps
// -------------------------------------------------------------
class _ShimmerBox extends StatelessWidget {
  final Animation<double> shimmer;
  final double? width;
  final double? height;
  final double radius;
  const _ShimmerBox({
    required this.shimmer,
    this.width,
    this.height,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) {
        final p = shimmer.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3 * p, -0.3),
              end: Alignment(1.5 + 3 * p, 0.3),
              colors: const [Color(0xFFEDF1F5), Colors.white, Color(0xFFEDF1F5)],
              stops: const [0, 0.5, 1],
            ),
          ),
        );
      },
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final String type;
  final Animation<double> shimmer;
  const _SectionSkeleton({required this.type, required this.shimmer});

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShimmerBox(shimmer: shimmer, width: 150, height: 20, radius: 6),
            _ShimmerBox(shimmer: shimmer, width: 64, height: 26, radius: 13),
          ],
        ),
      );

  Widget _row(double h, double w, int n, double r) => SizedBox(
        height: h,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: n,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) =>
              _ShimmerBox(shimmer: shimmer, width: w, height: h, radius: r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'hero_banners':
        return _row(195, 320, 2, 26);
      case 'categories':
        return Column(children: [_header(), _row(122, 122, 4, 22)]);
      case 'popular_programs':
        return Column(children: [_header(), _row(236, 240, 2, 24)]);
      case 'bento_spotlight':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ShimmerBox(
                        shimmer: shimmer, width: 150, height: 20, radius: 6),
                    _ShimmerBox(
                        shimmer: shimmer, width: 64, height: 26, radius: 13),
                  ],
                ),
              ),
              SizedBox(
                height: 222,
                child: Row(
                  children: [
                    Expanded(
                        flex: 6,
                        child: _ShimmerBox(shimmer: shimmer, radius: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Expanded(
                              child: _ShimmerBox(shimmer: shimmer, radius: 20)),
                          const SizedBox(height: 8),
                          Expanded(
                              child: _ShimmerBox(shimmer: shimmer, radius: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'muscle_groups':
        return Column(children: [_header(), _row(152, 166, 3, 22)]);
      case 'celebrity_coaches':
        return Column(children: [_header(), _row(188, 170, 3, 24)]);
      case 'equipment_training':
        return Column(children: [_header(), _row(124, 150, 3, 22)]);
      case 'trending_challenges':
        return Column(children: [_header(), _row(182, 280, 2, 24)]);
      case 'audio_beats':
        return Column(children: [_header(), _row(156, 184, 3, 22)]);
      case 'custom_banner':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ShimmerBox(shimmer: shimmer, height: 168, radius: 26),
        );
      default:
        return Column(children: [_header(), _row(170, 200, 2, 22)]);
    }
  }
}

class _InitialSkeleton extends StatelessWidget {
  final Animation<double> shimmer;
  const _InitialSkeleton({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ShimmerBox(shimmer: shimmer, height: 52, radius: 18),
        ),
        const SizedBox(height: 22),
        _SectionSkeleton(type: 'hero_banners', shimmer: shimmer),
        const SizedBox(height: 28),
        _SectionSkeleton(type: 'categories', shimmer: shimmer),
        const SizedBox(height: 28),
        _SectionSkeleton(type: 'popular_programs', shimmer: shimmer),
        const SizedBox(height: 28),
      ],
    );
  }
}

// -------------------------------------------------------------
// HERO BANNER CAROUSEL  (glass caption, animated dots)
// -------------------------------------------------------------
class _BannerVM {
  final String key;
  final String imageUrl;
  final String mediaType;
  final String title;
  final String subtitle;
  final String badge;
  final String buttonText;
  final bool showTitle;
  const _BannerVM({
    required this.key,
    required this.imageUrl,
    required this.mediaType,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.buttonText,
    required this.showTitle,
  });
}

class _HeroBannerCarousel extends StatefulWidget {
  final List<_BannerVM> banners;
  const _HeroBannerCarousel({required this.banners});

  @override
  State<_HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<_HeroBannerCarousel> {
  final _pc = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant _HeroBannerCarousel old) {
    super.didUpdateWidget(old);
    if (old.banners.length != widget.banners.length) {
      if (_page >= widget.banners.length) _page = 0;
      _arm();
    }
  }

  void _arm() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pc.hasClients) return;
      _page = (_page + 1) % widget.banners.length;
      _pc.animateToPage(
        _page,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _pc,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.banners.length,
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              final hasText =
                  b.showTitle && (b.title.isNotEmpty || b.subtitle.isNotEmpty);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _Card(
                  radius: 26,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CategoryMediaRenderer(
                        key: ValueKey(b.key),
                        mediaUrl: b.imageUrl,
                        mediaType: b.mediaType,
                      ),
                      if (hasText) ...[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.35, 1],
                              colors: [
                                Colors.transparent,
                                _kInk.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _Glass(
                            dark: true,
                            radius: 18,
                            blur: 16,
                            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (b.badge.isNotEmpty) ...[
                                        _Pill(b.badge.toUpperCase(),
                                            accent: true),
                                        const SizedBox(height: 6),
                                      ],
                                      if (b.title.isNotEmpty)
                                        Text(
                                          b.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _t(15,
                                              w: FontWeight.w900,
                                              c: Colors.white,
                                              ls: -0.3),
                                        ),
                                      if (b.subtitle.isNotEmpty)
                                        Text(
                                          b.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _t(11,
                                              w: FontWeight.w600,
                                              c: Colors.white
                                                  .withValues(alpha: 0.78)),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: _kInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final on = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: on ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: on ? _kAccent : _kLine,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------
// MEDIA RENDERER  (image / gif / muted looping video)
// -------------------------------------------------------------
class _CategoryMediaRenderer extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;
  const _CategoryMediaRenderer({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  State<_CategoryMediaRenderer> createState() => _CategoryMediaRendererState();
}

class _CategoryMediaRendererState extends State<_CategoryMediaRenderer> {
  VideoPlayerController? _video;
  bool _ready = false;

  bool get _isVideo {
    final l = widget.mediaUrl.toLowerCase();
    return widget.mediaType == 'video' ||
        l.endsWith('.mp4') ||
        l.endsWith('.mov') ||
        l.endsWith('.webm');
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _CategoryMediaRenderer old) {
    super.didUpdateWidget(old);
    if (old.mediaUrl != widget.mediaUrl || old.mediaType != widget.mediaType) {
      _video?.dispose();
      _video = null;
      _ready = false;
      _init();
    }
  }

  void _init() {
    if (!_isVideo || widget.mediaUrl.isEmpty) return;
    final url = CategoryBackendService.getDisplayableImageUrl(widget.mediaUrl);
    _video = url.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.asset(
            url.startsWith('assets/') ? url : 'assets/videos/$url');
    _video!.initialize().then((_) {
      if (!mounted) return;
      _video!
        ..setVolume(0)
        ..setLooping(true)
        ..play();
      setState(() => _ready = true);
    }).catchError((e) => debugPrint('[video] $e'));
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      if (_video != null && _ready) {
        final s = _video!.value.size;
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: s.width > 0 ? s.width : 16,
              height: s.height > 0 ? s.height : 9,
              child: VideoPlayer(_video!),
            ),
          ),
        );
      }
      return Container(color: _kSurface);
    }
    return _NetImage(
      CategoryBackendService.getDisplayableImageUrl(widget.mediaUrl),
      cacheWidth: 720,
    );
  }
}
