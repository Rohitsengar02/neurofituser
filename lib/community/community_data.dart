import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../trainer/trainer_data.dart' show unsplash;

// Community feed: photo, before/after, workout and poll posts with likes,
// comments, saves, reports and the user's own posts (images included).

enum PostKind { photo, beforeAfter, workout, poll, text }

class Pic {
  final String url;
  final Uint8List? bytes;
  const Pic({this.url = '', this.bytes});
  Map<String, dynamic> toJson() => {'u': url, if (bytes != null) 'b': base64Encode(bytes!)};
  static Pic fromJson(Map<String, dynamic> j) => Pic(url: j['u'] ?? '', bytes: j['b'] == null ? null : base64Decode(j['b']));
}

class Comment {
  final String name, text;
  final String? avatar;
  final DateTime at;
  int likes;
  bool liked;
  Comment(this.name, this.text, this.at, {this.avatar, this.likes = 0, this.liked = false});
  Map<String, dynamic> toJson() => {'n': name, 't': text, 'a': at.millisecondsSinceEpoch, 'av': avatar, 'l': likes, 'lk': liked};
  static Comment fromJson(Map<String, dynamic> j) =>
      Comment(j['n'], j['t'], DateTime.fromMillisecondsSinceEpoch(j['a']), avatar: j['av'], likes: j['l'] ?? 0, liked: j['lk'] ?? false);
}

class Post {
  final String id, name, handle, text;
  final String? avatar; // unsplash id; null = me
  final bool coach, mine;
  final DateTime at;
  final PostKind kind;
  final List<Pic> pics; // photo: 1-4; beforeAfter: [before, after]
  final String? stat; // e.g. "-8 kg · 12 weeks"
  final String? workoutTitle;
  final List<(String, String)> exercises; // name, sets
  final List<String> options;
  final List<int> votes;
  int? myVote;
  int likes;
  bool liked, saved, reported, tried;
  final List<Comment> comments;
  final List<String> tags;

  Post({
    required this.id,
    required this.name,
    required this.handle,
    required this.text,
    required this.at,
    required this.kind,
    this.avatar,
    this.coach = false,
    this.mine = false,
    this.pics = const [],
    this.stat,
    this.workoutTitle,
    this.exercises = const [],
    this.options = const [],
    List<int>? votes,
    this.myVote,
    this.likes = 0,
    this.liked = false,
    this.saved = false,
    this.reported = false,
    this.tried = false,
    List<Comment>? comments,
    this.tags = const [],
  })  : votes = votes ?? List.filled(options.length, 0),
        comments = comments ?? [];

  int get totalVotes => votes.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'h': handle,
        't': text,
        'av': avatar,
        'c': coach,
        'm': mine,
        'at': at.millisecondsSinceEpoch,
        'k': kind.index,
        'p': pics.map((p) => p.toJson()).toList(),
        's': stat,
        'wt': workoutTitle,
        'ex': [for (final e in exercises) [e.$1, e.$2]],
        'o': options,
        'v': votes,
        'mv': myVote,
        'l': likes,
        'lk': liked,
        'sv': saved,
        'r': reported,
        'tr': tried,
        'cm': comments.map((c) => c.toJson()).toList(),
        'tg': tags,
      };

  static Post fromJson(Map<String, dynamic> j) => Post(
        id: j['id'],
        name: j['n'],
        handle: j['h'],
        text: j['t'],
        avatar: j['av'],
        coach: j['c'] ?? false,
        mine: j['m'] ?? false,
        at: DateTime.fromMillisecondsSinceEpoch(j['at']),
        kind: PostKind.values[j['k']],
        pics: [for (final p in j['p'] ?? []) Pic.fromJson(Map<String, dynamic>.from(p))],
        stat: j['s'],
        workoutTitle: j['wt'],
        exercises: [for (final e in j['ex'] ?? []) (e[0] as String, e[1] as String)],
        options: List<String>.from(j['o'] ?? []),
        votes: List<int>.from(j['v'] ?? []),
        myVote: j['mv'],
        likes: j['l'] ?? 0,
        liked: j['lk'] ?? false,
        saved: j['sv'] ?? false,
        reported: j['r'] ?? false,
        tried: j['tr'] ?? false,
        comments: [for (final c in j['cm'] ?? []) Comment.fromJson(Map<String, dynamic>.from(c))],
        tags: List<String>.from(j['tg'] ?? []),
      );
}

class CommunityStore extends ChangeNotifier {
  CommunityStore._() {
    _load();
  }
  static final CommunityStore I = CommunityStore._();
  static const _key = 'community_v1';

  final List<Post> posts = [];
  final Set<String> following = {'@rahul.lifts', '@anjali.fit'};

  List<Post> get visible => posts.where((p) => !p.reported).toList();

  void like(Post p, {bool only = false}) {
    if (only && p.liked) return;
    p.liked = !p.liked;
    p.likes += p.liked ? 1 : -1;
    _changed();
  }

  void save(Post p) {
    p.saved = !p.saved;
    _changed();
  }

  void vote(Post p, int i) {
    if (p.myVote != null) return;
    p.myVote = i;
    p.votes[i]++;
    _changed();
  }

  void comment(Post p, String text) {
    p.comments.add(Comment('Rohit', text, DateTime.now()));
    _changed();
  }

  void likeComment(Comment c) {
    c.liked = !c.liked;
    c.likes += c.liked ? 1 : -1;
    _changed();
  }

  void report(Post p) {
    p.reported = true;
    _changed();
  }

  void tryWorkout(Post p) {
    p.tried = !p.tried;
    _changed();
  }

  void delete(Post p) {
    posts.remove(p);
    _changed();
  }

  void toggleFollow(String handle) {
    following.contains(handle) ? following.remove(handle) : following.add(handle);
    _changed();
  }

  void add(Post p) {
    posts.insert(0, p);
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    _seed();
    try {
      final pr = await SharedPreferences.getInstance();
      final raw = pr.getString(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final mine = [for (final p in j['mine'] ?? []) Post.fromJson(Map<String, dynamic>.from(p))];
      final state = Map<String, dynamic>.from(j['state'] ?? {});
      for (final p in posts) {
        final s = state[p.id];
        if (s == null) continue;
        p.liked = s['lk'] ?? false;
        p.likes = s['l'] ?? p.likes;
        p.saved = s['sv'] ?? false;
        p.reported = s['r'] ?? false;
        p.tried = s['tr'] ?? false;
        if (s['mv'] != null && p.myVote == null) {
          p.myVote = s['mv'];
          p.votes[p.myVote!]++;
        }
        for (final c in s['cm'] ?? []) {
          p.comments.add(Comment.fromJson(Map<String, dynamic>.from(c)));
        }
      }
      following
        ..clear()
        ..addAll(List<String>.from(j['fol'] ?? following));
      posts.insertAll(0, mine);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final pr = await SharedPreferences.getInstance();
      // Own posts (with photos) are capped so local storage stays small.
      final mine = posts.where((p) => p.mine).take(8).map((p) => p.toJson()).toList();
      final state = {
        for (final p in posts.where((p) => !p.mine))
          p.id: {
            'lk': p.liked,
            'l': p.likes,
            'sv': p.saved,
            'r': p.reported,
            'tr': p.tried,
            'mv': p.myVote,
            'cm': p.comments.where((c) => c.name == 'Rohit').map((c) => c.toJson()).toList(),
          }
      };
      await pr.setString(_key, jsonEncode({'mine': mine, 'state': state, 'fol': following.toList()}));
    } catch (_) {}
  }

  void _seed() {
    final now = DateTime.now();
    Comment c(String n, String t, int min, String av, [int l = 0]) => Comment(n, t, now.subtract(Duration(minutes: min)), avatar: av, likes: l);
    posts
      ..clear()
      ..addAll([
        Post(
          id: 's1',
          name: 'Anjali Mehta',
          handle: '@anjali.fit',
          avatar: '1548690312-e3b507d8c110',
          coach: true,
          at: now.subtract(const Duration(minutes: 38)),
          kind: PostKind.beforeAfter,
          text: 'My client Priya after 12 weeks of consistent training and simple Indian meals. No crash diets, just patience 💜',
          pics: [Pic(url: unsplash('1531746020798-e6953c6e8e04', 700)), Pic(url: unsplash('1544005313-94ddf0286df2', 700))],
          stat: '-9 kg · 12 weeks',
          likes: 2140,
          tags: ['#transformation', '#fatloss'],
          comments: [
            c('Riya', 'This is so motivating! 😍', 20, '1524504388940-b1c1722653e1', 24),
            c('Dev', 'What was the weekly split?', 12, '1567013127542-490d757e51fc', 3),
          ],
        ),
        Post(
          id: 's2',
          name: 'Rahul Sharma',
          handle: '@rahul.lifts',
          avatar: '1567013127542-490d757e51fc',
          coach: true,
          at: now.subtract(const Duration(hours: 2)),
          kind: PostKind.workout,
          text: 'Short on time? Here is my 30-minute push session. Save it and tag me when you try it 🔥',
          workoutTitle: '30-min push day',
          exercises: const [('Barbell bench press', '4 × 8'), ('Incline dumbbell press', '3 × 10'), ('Seated shoulder press', '3 × 10'), ('Triceps dip', '3 × 12')],
          likes: 860,
          tags: ['#workout', '#push'],
          comments: [c('Kunal', 'Did this today, chest is on fire', 50, '1583454110551-21f2fa2afe61', 11)],
        ),
        Post(
          id: 's3',
          name: 'Neha Patel',
          handle: '@neha.yoga',
          avatar: '1518611012118-696072aa579a',
          coach: true,
          at: now.subtract(const Duration(hours: 4)),
          kind: PostKind.poll,
          text: 'When do you like to train? 🧘',
          options: const ['Early morning', 'Lunch break', 'Evening', 'Late night'],
          votes: [412, 96, 538, 121],
          likes: 310,
          tags: ['#poll'],
        ),
        Post(
          id: 's4',
          name: 'Vikram Singh',
          handle: '@vikram.physique',
          avatar: '1583454110551-21f2fa2afe61',
          coach: true,
          at: now.subtract(const Duration(hours: 6)),
          kind: PostKind.photo,
          text: 'Leg day done. Remember: the squat rack is not a curl station 😂',
          pics: [Pic(url: unsplash('1534438327276-14e5300c3a48', 900))],
          likes: 1520,
          tags: ['#legday'],
          comments: [c('Sana', 'Haha so true', 120, '1534528741775-53994a69daeb', 8)],
        ),
        Post(
          id: 's5',
          name: 'Sara Khan',
          handle: '@sara.moves',
          avatar: '1534528741775-53994a69daeb',
          at: now.subtract(const Duration(hours: 9)),
          kind: PostKind.photo,
          text: 'Morning run views. 6 km before work, feeling unstoppable today ☀️',
          pics: [Pic(url: unsplash('1476480862126-209bfaa8edc8', 900)), Pic(url: unsplash('1571019613454-1cb2f99b2d8b', 900))],
          likes: 640,
          tags: ['#running'],
        ),
        Post(
          id: 's6',
          name: 'Arjun Kapoor',
          handle: '@arjun.hiit',
          avatar: '1571019613454-1cb2f99b2d8b',
          coach: true,
          at: now.subtract(const Duration(hours: 20)),
          kind: PostKind.beforeAfter,
          text: '16 weeks of lean bulking with my client Aman. Strength up on every lift.',
          pics: [Pic(url: unsplash('1567013127542-490d757e51fc', 700)), Pic(url: unsplash('1583454110551-21f2fa2afe61', 700))],
          stat: '+6 kg lean · 16 weeks',
          likes: 1930,
          tags: ['#musclegain'],
        ),
        Post(
          id: 's7',
          name: 'Isha Verma',
          handle: '@isha.eats',
          avatar: '1524504388940-b1c1722653e1',
          at: now.subtract(const Duration(days: 1, hours: 3)),
          kind: PostKind.text,
          text: 'Protein tip: a cup of roasted chana has about 15 g of protein and costs less than a chai. Snack smarter! 🌱',
          likes: 450,
          tags: ['#nutrition'],
        ),
      ]);
  }
}
