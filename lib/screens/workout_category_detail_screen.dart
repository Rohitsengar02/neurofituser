import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';
import '../services/workout_category_backend_service.dart';
import '../services/workouts_backend_service.dart';
import '../services/category_backend_service.dart';
import 'workout_detail_screen.dart';

class WorkoutCategoryDetailScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialCategoryId;

  const WorkoutCategoryDetailScreen({
    super.key,
    this.initialCategory,
    this.initialCategoryId,
  });

  @override
  State<WorkoutCategoryDetailScreen> createState() =>
      _WorkoutCategoryDetailScreenState();
}

class _WorkoutCategoryDetailScreenState
    extends State<WorkoutCategoryDetailScreen> {
  int _selectedCategoryIndex = 0;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final Set<String> _savedWorkouts = {};

  final WorkoutCategoryBackendService _categoryService =
      WorkoutCategoryBackendService();
  final WorkoutsBackendService _workoutsService = WorkoutsBackendService();

  @override
  void initState() {
    super.initState();
    _categoryService.addListener(_onServiceUpdate);
    _workoutsService.addListener(_onServiceUpdate);

    if (_workoutsService.workouts.isEmpty) {
      _workoutsService.fetchWorkouts();
    }

    _resolveInitialCategory();
  }

  @override
  void dispose() {
    _categoryService.removeListener(_onServiceUpdate);
    _workoutsService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        _resolveInitialCategory();
      });
    }
  }

  void _resolveInitialCategory() {
    final categories = _allCategories;
    if (widget.initialCategory != null || widget.initialCategoryId != null) {
      final targetName = widget.initialCategory?.toLowerCase() ?? '';
      final targetId = widget.initialCategoryId ?? '';

      final idx = categories.indexWhere((c) {
        final cId = c['id']?.toString() ?? '';
        final cName = (c['name'] as String? ?? '').toLowerCase();
        return (targetId.isNotEmpty && cId == targetId) ||
            (targetName.isNotEmpty && cName.contains(targetName));
      });

      if (idx != -1) {
        _selectedCategoryIndex = idx;
      }
    }
  }

  void _toggleBookmark(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_savedWorkouts.contains(id)) {
        _savedWorkouts.remove(id);
      } else {
        _savedWorkouts.add(id);
      }
    });
  }

  List<Map<String, dynamic>> get _allCategories {
    final list = <Map<String, dynamic>>[];
    list.add({
      'id': 'all',
      'name': 'All Workouts',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFF16A34A),
      'count': '${_workoutsService.workouts.length} Plans',
      'tagline':
          'Explore full spectrum strength, cardio, and mobility programs.',
      'image':
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=800&auto=format&fit=crop',
    });

    final backendCategories = _categoryService.activeCategories;
    for (var bc in backendCategories) {
      final isVid =
          bc.mediaUrl.toLowerCase().endsWith('.mp4') ||
          bc.mediaUrl.toLowerCase().endsWith('.mov');
      list.add({
        'id': bc.id,
        'name': bc.name,
        'icon': isVid
            ? Icons.play_circle_fill_rounded
            : Icons.fitness_center_rounded,
        'color': const Color(0xFF6366F1),
        'count': 'Category Plan',
        'tagline': bc.description.isNotEmpty
            ? bc.description
            : 'Targeted fitness program',
        'image': bc.mediaUrl,
        'mediaType': bc.mediaType,
      });
    }

    return list;
  }

  List<WorkoutModel> get _filteredWorkouts {
    final categories = _allCategories;
    final selectedCat = _selectedCategoryIndex < categories.length
        ? categories[_selectedCategoryIndex]
        : categories[0];
    final selectedCatId = selectedCat['id'] as String? ?? 'all';
    final selectedCatName = (selectedCat['name'] as String? ?? '')
        .toLowerCase();

    return _workoutsService.workouts.where((w) {
      if (!w.isActive) return false;

      // 1. Category Filter
      if (selectedCatId != 'all') {
        final wCatId = w.workoutCategoryId;
        final wCatName = w.category.toLowerCase();
        final matchesId = wCatId.isNotEmpty && wCatId == selectedCatId;
        final matchesName =
            wCatName.contains(selectedCatName) ||
            selectedCatName.contains(wCatName);
        if (!matchesId && !matchesName) return false;
      }

      // 2. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = w.title.toLowerCase();
        final coach = w.coach.toLowerCase();
        final tags = w.tags.join(' ').toLowerCase();
        if (!title.contains(q) && !coach.contains(q) && !tags.contains(q)) {
          return false;
        }
      }

      // 3. Filter Pills
      if (_selectedFilter == 'Under 30 Min') {
        if (w.durationMinutes > 30) return false;
      } else if (_selectedFilter == 'Bodyweight') {
        final tags = w.tags.join(' ').toLowerCase();
        if (!tags.contains('bodyweight') && !tags.contains('no gear'))
          return false;
      } else if (_selectedFilter == 'Advanced') {
        if (w.level != 'Advanced') return false;
      } else if (_selectedFilter == 'Saved') {
        if (!_savedWorkouts.contains(w.id)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _allCategories;
    final currentCategory = _selectedCategoryIndex < categories.length
        ? categories[_selectedCategoryIndex]
        : categories[0];
    final filteredList = _filteredWorkouts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 1. Top Header Bar
            StaggeredSlideFade(index: 0, child: _buildTopHeader()),

            const SizedBox(height: 12),

            // Main Content Area
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 2. Search Bar
                  SliverToBoxAdapter(
                    child: StaggeredSlideFade(
                      index: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildSearchBar(),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // 3. Category Horizontal Carousel
                  SliverToBoxAdapter(
                    child: StaggeredSlideFade(
                      index: 2,
                      child: _buildCategoriesCarouselHeader(categories),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 4. Hero Banner of Selected Category
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // 5. Filter Chips & Results Count Bar
                  SliverToBoxAdapter(
                    child: StaggeredSlideFade(
                      index: 4,
                      child: _buildFilterChipsBar(filteredList.length),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 6. Workout Cards List
                  if (filteredList.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40.0,
                          horizontal: 20,
                        ),
                        child: _buildEmptyState(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final workout = filteredList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: StaggeredSlideFade(
                              index: 5 + (index % 4),
                              child: _buildWorkoutDetailCard(workout),
                            ),
                          );
                        }, childCount: filteredList.length),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. TOP HEADER BAR
  // -------------------------------------------------------------
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            'Workout Library',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF0F172A),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. SEARCH BAR
  // -------------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search workouts, muscle group, coach...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _searchQuery = ''),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. CATEGORIES CAROUSEL HEADER
  // -------------------------------------------------------------
  Widget _buildCategoriesCarouselHeader(
    List<Map<String, dynamic>> displayList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore Categories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${displayList.length} Categories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 125,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final cat = displayList[index];
              final isSelected = _selectedCategoryIndex == index;
              final imgUrl = cat['image'] as String? ?? '';
              final isVid =
                  cat['mediaType'] == 'video' ||
                  imgUrl.toLowerCase().endsWith('.mp4') ||
                  imgUrl.toLowerCase().endsWith('.mov');

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategoryIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 145,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail image / video preview
                      isVid
                          ? Container(
                              color: const Color(0xFF0F172A),
                              child: const Center(
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF38BDF8),
                                  size: 32,
                                ),
                              ),
                            )
                          : Image.network(
                              CategoryBackendService.getDisplayableImageUrl(
                                imgUrl,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1E293B),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white54,
                                ),
                              ),
                            ),

                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),

                      // Selection Badge & Text
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isSelected)
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat['count'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
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
  // 4. HERO BANNER OF CURRENT CATEGORY
  // -------------------------------------------------------------
  Widget _buildCategoryHeroCard(Map<String, dynamic> cat) {
    final imgUrl = cat['image'] as String? ?? '';
    final isVid =
        imgUrl.toLowerCase().endsWith('.mp4') ||
        imgUrl.toLowerCase().endsWith('.mov');

    return Container(
      width: double.infinity,
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0F172A),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVid)
            const Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF38BDF8),
                size: 44,
              ),
            )
          else if (imgUrl.isNotEmpty)
            Image.network(
              CategoryBackendService.getDisplayableImageUrl(imgUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.90),
                  Colors.black.withValues(alpha: 0.50),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (cat['count'] as String? ?? 'Category').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat['name'] as String? ?? 'Category',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cat['tagline'] as String? ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. FILTER CHIPS & RESULTS COUNT
  // -------------------------------------------------------------
  Widget _buildFilterChipsBar(int resultsCount) {
    final filters = ['All', 'Under 30 Min', 'Bodyweight', 'Advanced', 'Saved'];

    return Column(
      children: [
        SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedFilter = filter);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $resultsCount Workouts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Icon(
                Icons.sort_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 6. WORKOUT DETAIL CARD
  // -------------------------------------------------------------
  Widget _buildWorkoutDetailCard(WorkoutModel workout) {
    final isSaved = _savedWorkouts.contains(workout.id);
    final isVid =
        workout.mediaType == 'video' ||
        workout.imageUrl.toLowerCase().endsWith('.mp4') ||
        workout.imageUrl.toLowerCase().endsWith('.mov');

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailScreen(
              title: workout.title,
              subtitle: workout.subtitle,
              image: workout.imageUrl,
              trainer: workout.coach,
              duration: '${workout.durationMinutes} min',
              level: workout.level,
              rating: '${workout.rating}',
              calories: '${workout.caloriesBurn} kcal',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Image / Video Preview
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  isVid
                      ? Container(
                          color: const Color(0xFF0F172A),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF38BDF8),
                              size: 40,
                            ),
                          ),
                        )
                      : Image.network(
                          CategoryBackendService.getDisplayableImageUrl(
                            workout.imageUrl,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF0F172A),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.white54,
                              size: 36,
                            ),
                          ),
                        ),

                  // Bookmark Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _toggleBookmark(workout.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: isSaved
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        workout.category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text Info Details
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      _buildInfoPill(
                        Icons.timer_rounded,
                        '${workout.durationMinutes} min',
                        const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoPill(
                        Icons.local_fire_department_rounded,
                        '${workout.caloriesBurn} kcal',
                        const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoPill(
                        Icons.star_rounded,
                        '${workout.rating}',
                        const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 10,
                            backgroundColor: Color(0xFFE2E8F0),
                            child: Icon(
                              Icons.person,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            workout.coach,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${workout.exercises.isNotEmpty ? workout.exercises.length : workout.exercisesCount} Exercises',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
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
  }

  Widget _buildInfoPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            size: 40,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            'No Workouts Found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No workouts match the selected category or search filters.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
