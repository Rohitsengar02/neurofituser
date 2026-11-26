import 'package:flutter/material.dart';

import '../trainer/trainers_page.dart' show YourTrainerCard;
import '../widgets/dashboard_overview_sections.dart' show AchievementsSection, ArticlesTipsSection;
import 'nutrition/nutrition_tab_v3.dart';
import 'overview/overview_glass.dart';
import 'overview/overview_home_cards.dart';
import 'shop/shop_tab_v3.dart';
import 'wellness/wellness_tab_v3.dart';
import 'workouts/workout_tab_v2.dart';

// The five home tabs (Overview, Workouts, Nutrition, Mental Health, Shop).
// Each tab is its own screen made of section components; every section
// lives in its own file under lib/home/<tab>/.

/// The section components of home tab [tab], top to bottom.
List<Widget> homeTabSections(BuildContext context, int tab) => switch (tab) {
      1 => WorkoutTabV2.sections,
      2 => NutritionTabV3.sections,
      3 => WellnessTabV3.sections,
      4 => ShopTabV3.sections(context),
      _ => const [
          SizedBox(height: 14),
          ...OverviewHomeCards.sections,
          SizedBox(height: 16),
          YourTrainerCard(),
          SizedBox(height: 12),
          OverviewGlassSections(),
          SizedBox(height: 28),
          AchievementsSection(),
          SizedBox(height: 24),
          ArticlesTipsSection(),
          SizedBox(height: 20),
        ],
    };

/// One home tab as its own screen: the shared header, then this tab's
/// section components built lazily as they scroll into view. Kept alive
/// after its first visit, so coming back is instant and keeps the scroll.
class HomeTabScreen extends StatefulWidget {
  final ScrollController controller;
  final Widget header;
  final List<Widget> sections;
  const HomeTabScreen({
    super.key,
    required this.controller,
    required this.header,
    required this.sections,
  });

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Sections fade in when the screen is first shown, not on later rebuilds.
  late final DateTime _born = DateTime.now();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sections = widget.sections;
    return CustomScrollView(
      controller: widget.controller,
      physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
      slivers: [
        SliverToBoxAdapter(child: widget.header),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 110), // Space for floating bottom nav
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _TabEnter(
                animate: DateTime.now().difference(_born).inMilliseconds < 500,
                child: sections[i],
              ),
              childCount: sections.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fade and slide in a section when its tab screen first opens; sections
/// built later while scrolling just appear.
class _TabEnter extends StatelessWidget {
  final bool animate;
  final Widget child;
  const _TabEnter({required this.animate, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: FractionalTranslation(translation: Offset(0.04 * (1 - v), 0), child: c),
      ),
    );
  }
}
