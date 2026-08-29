import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staggered_slide_fade.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with TickerProviderStateMixin {
  int _badgeIconIndex = 0;
  Timer? _badgeIconTimer;

  final List<IconData> _badgeIcons = [
    Icons.favorite_rounded,
    Icons.people_alt_rounded,
    Icons.chat_bubble_rounded,
    Icons.auto_awesome_rounded,
  ];
  // Stories data
  final List<Map<String, dynamic>> _stories = [
    {
      'name': 'You',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop&q=80',
      'isYou': true,
      'hasStory': false,
    },
    {
      'name': 'Ananya',
      'image': 'https://images.unsplash.com/photo-1548690312-e3b507d8c110?w=300&auto=format&fit=crop&q=80',
      'isYou': false,
      'hasStory': true,
    },
    {
      'name': 'Rohit',
      'image': 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=300&auto=format&fit=crop&q=80',
      'isYou': false,
      'hasStory': true,
    },
    {
      'name': 'Sneha',
      'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=300&auto=format&fit=crop&q=80',
      'isYou': false,
      'hasStory': true,
    },
    {
      'name': 'Karan',
      'image': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=300&auto=format&fit=crop&q=80',
      'isYou': false,
      'hasStory': true,
    },
    {
      'name': 'Meera',
      'image': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300&auto=format&fit=crop&q=80',
      'isYou': false,
      'hasStory': true,
    },
  ];

  // Feed Posts with interactive state
  late List<Map<String, dynamic>> _posts;

  @override
  void initState() {
    super.initState();
    _badgeIconTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (mounted) {
        setState(() {
          _badgeIconIndex = (_badgeIconIndex + 1) % _badgeIcons.length;
        });
      }
    });
    _posts = [
      {
        'id': '1',
        'name': 'Aisha Verma',
        'handle': '@aishaverma_fit',
        'time': '2h ago',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
        'postImage': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=900&auto=format&fit=crop&q=80',
        'workoutTag': 'Leg Day',
        'workoutTagColor': const Color(0xFF16A34A),
        'likes': 1240,
        'isLiked': false,
        'isSaved': false,
        'shares': 42,
        'caption': 'Loved my morning workout! Consistency is the key 🔑\n#neurofit #legday #stronger #discipline',
        'comments': [
          {'user': 'Rohit Singh', 'text': 'Super form! Keep crushing it 💪', 'time': '1h ago', 'avatar': 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=150&auto=format&fit=crop&q=80'},
          {'user': 'Ananya Roy', 'text': 'Inspiring as always! 🔥', 'time': '45m ago', 'avatar': 'https://images.unsplash.com/photo-1548690312-e3b507d8c110?w=150&auto=format&fit=crop&q=80'},
          {'user': 'Karan Malhotra', 'text': 'What pre-workout do you use?', 'time': '20m ago', 'avatar': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=150&auto=format&fit=crop&q=80'},
        ],
      },
      {
        'id': '2',
        'name': 'Rohit Singh',
        'handle': '@rohit_fitness',
        'time': '3h ago',
        'avatar': 'https://images.unsplash.com/photo-1567013127542-490d757e51fc?w=200&auto=format&fit=crop&q=80',
        'postImage': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=900&auto=format&fit=crop&q=80',
        'workoutTag': 'Chest Workout',
        'workoutTagColor': const Color(0xFF8B5CF6),
        'likes': 942,
        'isLiked': true,
        'isSaved': true,
        'shares': 28,
        'caption': 'Progress is progress, no matter how small 💪\n#chestday #neurofit #fitnessmotivation',
        'comments': [
          {'user': 'Aisha Verma', 'text': 'Huge gains brother! 👏', 'time': '2h ago', 'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80'},
          {'user': 'Sneha Kapoor', 'text': 'Pure beast mode! 🚀', 'time': '1h ago', 'avatar': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=150&auto=format&fit=crop&q=80'},
        ],
      },
      {
        'id': '3',
        'name': 'Sneha Kapoor',
        'handle': '@snehakapoor_fit',
        'time': '4h ago',
        'avatar': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=200&auto=format&fit=crop&q=80',
        'postImage': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=900&auto=format&fit=crop&q=80',
        'workoutTag': 'Yoga & Mindfulness',
        'workoutTagColor': const Color(0xFF06B6D4),
        'likes': 815,
        'isLiked': false,
        'isSaved': false,
        'shares': 19,
        'caption': 'Nothing beats a morning yoga flow and deep breathwork session ✨🧘‍♀️\n#yoga #mindfulness #neurofit #wellness',
        'comments': [
          {'user': 'Meera Jain', 'text': 'So peaceful! Which mat is that?', 'time': '3h ago', 'avatar': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150&auto=format&fit=crop&q=80'},
        ],
      },
    ];
  }

  void _toggleLike(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      final post = _posts[index];
      if (post['isLiked'] as bool) {
        post['isLiked'] = false;
        post['likes'] = (post['likes'] as int) - 1;
      } else {
        post['isLiked'] = true;
        post['likes'] = (post['likes'] as int) + 1;
      }
    });
  }

  void _toggleSave(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      final post = _posts[index];
      post['isSaved'] = !(post['isSaved'] as bool);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _posts[index]['isSaved'] ? 'Saved to your bookmarks' : 'Removed from bookmarks',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF1E2638),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBFBFD),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110), // Padding for floating nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // 1. Header
              StaggeredSlideFade(
                index: 0,
                child: _buildHeader(),
              ),

              const SizedBox(height: 16),

              // 2. Stories Bar
              StaggeredSlideFade(
                index: 1,
                child: _buildStoriesSection(),
              ),

              const SizedBox(height: 18),

              // 3. Feed Posts
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return StaggeredSlideFade(
                    index: 2 + index,
                    child: _buildPostCard(index),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _badgeIconTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------
  // 1. TOP APP BAR (WITH ANIMATED ICON BADGE & BACKGROUND)
  // -------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Social',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildAnimatedHeaderBadge(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Connect. Share. Inspire. 💚',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Search & Notification with Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIcon(Icons.search_rounded),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeaderIcon(Icons.notifications_outlined),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '2',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeaderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8), Color(0xFFDCFCE7)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          _badgeIcons[_badgeIconIndex],
          key: ValueKey<int>(_badgeIconIndex),
          color: const Color(0xFFDB2777),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF0F172A), size: 19),
    );
  }

  // -------------------------------------------------------------
  // 2. STORIES BAR
  // -------------------------------------------------------------
  Widget _buildStoriesSection() {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];
          final bool isYou = story['isYou'] as bool;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showStoryViewer(story);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Story Gradient Ring
                      Container(
                        width: 66,
                        height: 66,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isYou
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFFEC4899),
                                    Color(0xFFF97316),
                                    Color(0xFFEAB308),
                                  ],
                                ),
                          border: isYou
                              ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5)
                              : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Image.network(
                              story['image'] as String,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Plus icon for 'You' or Online Dot
                      if (isYou)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. POST CARD COMPONENT
  // -------------------------------------------------------------
  Widget _buildPostCard(int index) {
    final post = _posts[index];
    final bool isLiked = post['isLiked'] as bool;
    final bool isSaved = post['isSaved'] as bool;
    final List comments = post['comments'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header (Avatar, Name, Verified, Time, More)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(post['avatar'] as String),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post['name'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 14),
                          ],
                        ),
                        Text(
                          '${post['handle']} • ${post['time']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showPostOptionsSheet(post);
                  },
                ),
              ],
            ),
          ),

          // 2. Post Image with Floating Workout Tag
          GestureDetector(
            onDoubleTap: () => _toggleLike(index),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 320,
                  child: Image.network(
                    post['postImage'] as String,
                    fit: BoxFit.cover,
                  ),
                ),

                // Floating Pill Badge (e.g. Leg Day Completed)
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: (post['workoutTagColor'] as Color).withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: post['workoutTagColor'] as Color,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post['workoutTag']} Completed',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Action Row (Like, Comment, Share, Bookmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Like Button
                    GestureDetector(
                      onTap: () => _toggleLike(index),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isLiked ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                            size: 24,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            post['likes'].toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 18),

                    // Comment Button
                    GestureDetector(
                      onTap: () => _showCommentsBottomSheet(index),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0F172A), size: 22),
                          const SizedBox(width: 5),
                          Text(
                            comments.length.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 18),

                    // Share Button
                    GestureDetector(
                      onTap: () => _showShareBottomSheet(post),
                      child: Row(
                        children: [
                          const Icon(Icons.send_rounded, color: Color(0xFF0F172A), size: 21),
                          const SizedBox(width: 5),
                          Text(
                            post['shares'].toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Save / Bookmark Button
                GestureDetector(
                  onTap: () => _toggleSave(index),
                  child: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isSaved ? const Color(0xFF22C55E) : const Color(0xFF0F172A),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // 4. Caption & Hashtags
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text(
              post['caption'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. WORKING COMMENTS BOTTOM SHEET / SLIDER
  // -------------------------------------------------------------
  void _showCommentsBottomSheet(int postIndex) {
    HapticFeedback.mediumImpact();
    final post = _posts[postIndex];
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List comments = post['comments'] as List;

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 30,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments (${comments.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Comments List
                  Expanded(
                    child: comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            itemCount: comments.length,
                            itemBuilder: (context, cIndex) {
                              final comment = comments[cIndex];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 17,
                                      backgroundImage: NetworkImage(comment['avatar'] as String),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment['user'] as String,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                comment['time'] as String,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  color: const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            comment['text'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: const Color(0xFF334155),
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF94A3B8)),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Comment Input Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.6))),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              controller: commentController,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (commentController.text.trim().isNotEmpty) {
                              HapticFeedback.lightImpact();
                              setModalState(() {
                                comments.add({
                                  'user': 'You',
                                  'text': commentController.text.trim(),
                                  'time': 'Just now',
                                  'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                                });
                              });
                              setState(() {}); // update parent post comments count
                              commentController.clear();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Post',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
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
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 5. WORKING SHARE BOTTOM SHEET
  // -------------------------------------------------------------
  void _showShareBottomSheet(Map<String, dynamic> post) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Share Post',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(Icons.send_rounded, 'Direct Message', const Color(0xFF3B82F6)),
                  _buildShareOption(Icons.copy_rounded, 'Copy Link', const Color(0xFF16A34A), onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Post link copied to clipboard!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  }),
                  _buildShareOption(Icons.camera_alt_rounded, 'Story', const Color(0xFFEC4899)),
                  _buildShareOption(Icons.share_rounded, 'More', const Color(0xFF8B5CF6)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. POST OPTIONS & STORY VIEWER
  // -------------------------------------------------------------
  void _showPostOptionsSheet(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_outline_rounded),
              title: Text('Save Post', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: Text('Copy Link', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.red),
              title: Text('Report Post', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(Map<String, dynamic> story) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                story['image'] as String,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: NetworkImage(story['image'] as String)),
                  const SizedBox(width: 10),
                  Text(
                    story['name'] as String,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
