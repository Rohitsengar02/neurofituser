import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/live_backend.dart';
import '../backend/me.dart';
import '../backend/media.dart';
import '../backend/sync_store.dart';

// Community feed: photo, before/after, workout and poll posts with likes,
// comments, saves, reports and the user's own posts. Everything is shared
// through the NeuroFit API (photos on Cloudflare R2) and cached offline.

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
  String id;
  Comment(this.name, this.text, this.at, {this.avatar, this.likes = 0, this.liked = false, String? id})
      : id = id ?? 'cmt_${DateTime.now().microsecondsSinceEpoch}';
  Map<String, dynamic> toJson() => {'n': name, 't': text, 'a': at.millisecondsSinceEpoch, 'av': avatar, 'l': likes, 'lk': liked, 'i': id};
  static Comment fromJson(Map<String, dynamic> j) =>
      Comment(j['n'], j['t'], DateTime.fromMillisecondsSinceEpoch(j['a']), avatar: j['av'], likes: j['l'] ?? 0, liked: j['lk'] ?? false, id: j['i']);
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

  /// Comments on the server (only the latest is loaded until opened).
  int serverComments = 0;
  int get commentCount => comments.length > serverComments ? comments.length : serverComments;

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
        'sc': serverComments,
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
      )..serverComments = j['sc'] ?? 0;
}

class CommunityStore extends ChangeNotifier {
  CommunityStore._() {
    _load();
    SyncStore.I.on('posts_updated', refresh);
  }
  static final CommunityStore I = CommunityStore._();
  static const _key = 'community_v2';

  final List<Post> posts = [];
  final Set<String> following = {};
  bool loaded = false;
  Future<void>? _loading;

  List<Post> get visible => posts.where((p) => !p.reported).toList();

  static void _bg(Future<Object?> f) => f.catchError((_) => null);
  static DateTime _at(Object? v) => DateTime.tryParse('${v ?? ''}')?.toLocal() ?? DateTime.now();

  static Post _fromServer(Map<String, dynamic> j) {
    final kind = PostKind.values.where((k) => k.name == j['kind']).firstOrNull ?? PostKind.text;
    final options = [for (final o in (j['options'] as List? ?? const [])) o.toString()];
    final votes = [for (final v in (j['votes'] as List? ?? const [])) (v as num).toInt()];
    final last = j['lastComment'];
    final avatar = (j['avatarUrl'] ?? '').toString();
    final mine = j['mine'] == true;
    return Post(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? 'Member').toString(),
      handle: (j['handle'] ?? '@member').toString(),
      text: (j['text'] ?? '').toString(),
      at: _at(j['createdAt']),
      kind: kind,
      avatar: mine && avatar.isEmpty ? null : avatar,
      coach: j['coach'] == true,
      mine: mine,
      pics: [for (final u in (j['pics'] as List? ?? const [])) Pic(url: u.toString())],
      stat: j['stat']?.toString(),
      workoutTitle: j['workoutTitle']?.toString(),
      exercises: [
        for (final e in (j['exercises'] as List? ?? const []))
          if (e is List && e.length >= 2) (e[0].toString(), e[1].toString()) else if (e is Map) ((e['name'] ?? '').toString(), (e['sets'] ?? '').toString()),
      ],
      options: options,
      votes: votes.length == options.length ? votes : null,
      myVote: (j['myVote'] as num?)?.toInt(),
      likes: (j['likes'] as num?)?.toInt() ?? 0,
      liked: j['liked'] == true,
      saved: j['saved'] == true,
      reported: j['reported'] == true,
      tried: j['tried'] == true,
      comments: [
        if (last is Map)
          Comment((last['name'] ?? 'Member').toString(), (last['text'] ?? '').toString(), _at(last['createdAt']),
              avatar: (last['avatarUrl'] ?? '').toString().isEmpty ? null : last['avatarUrl'].toString(), id: last['id']?.toString()),
      ],
      tags: [for (final t in (j['tags'] as List? ?? const [])) t.toString()],
    )..serverComments = (j['commentsCount'] as num?)?.toInt() ?? 0;
  }

  /// Latest posts from the server (own posts still uploading stay on top).
  Future<void> refresh() => _loading ??= _refresh().whenComplete(() => _loading = null);

  Future<void> _refresh() async {
    try {
      final j = await Api.get('/community/posts?limit=50');
      final fresh = [for (final p in Api.list(j)) _fromServer(p)];
      final ids = {for (final p in fresh) p.id};
      final pending = posts.where((p) => p.mine && !ids.contains(p.id) && _uploading.contains(p.id));
      posts
        ..clear()
        ..addAll([...pending, ...fresh]);
      loaded = true;
      notifyListeners();
      _save();
    } catch (_) {}
  }

  /// Opening a post's comments loads all of them.
  Future<void> loadComments(Post p) async {
    try {
      final j = await Api.get('/community/posts/${p.id}/comments');
      final list = [
        for (final c in Api.list(j))
          Comment((c['name'] ?? 'Member').toString(), (c['text'] ?? '').toString(), _at(c['createdAt']),
              avatar: (c['avatarUrl'] ?? '').toString().isEmpty ? null : c['avatarUrl'].toString(),
              likes: (c['likes'] as num?)?.toInt() ?? 0, liked: c['liked'] == true, id: c['id']?.toString()),
      ];
      p.comments
        ..clear()
        ..addAll(list);
      p.serverComments = list.length;
      notifyListeners();
    } catch (_) {}
  }

  void like(Post p, {bool only = false}) {
    if (only && p.liked) return;
    p.liked = !p.liked;
    p.likes += p.liked ? 1 : -1;
    _changed();
    _bg(Api.send('POST', '/community/posts/${p.id}/like', {'on': p.liked}));
  }

  void save(Post p) {
    p.saved = !p.saved;
    _changed();
    _bg(Api.send('POST', '/community/posts/${p.id}/save', {'on': p.saved}));
  }

  void vote(Post p, int i) {
    if (p.myVote != null) return;
    p.myVote = i;
    p.votes[i]++;
    _changed();
    _bg(Api.send('POST', '/community/posts/${p.id}/vote', {'option': i}));
  }

  void comment(Post p, String text) {
    final c = Comment(Me.first.isEmpty ? 'You' : Me.first, text, DateTime.now(), avatar: Me.photo.isEmpty ? null : Me.photo);
    p.comments.add(c);
    p.serverComments++;
    _changed();
    _bg(Api.send('POST', '/community/posts/${p.id}/comments', {'id': c.id, 'text': text}));
  }

  void likeComment(Comment c) {
    c.liked = !c.liked;
    c.likes += c.liked ? 1 : -1;
    _changed();
    _bg(Api.send('POST', '/community/comments/${c.id}/like'));
  }

  void report(Post p) {
    p.reported = true;
    _changed();
    _bg(Api.send('POST', '/community/posts/${p.id}/report'));
  }

  void tryWorkout(Post p) {
    p.tried = !p.tried;
    _changed();
    _bg(Api.send('POST', '/community/posts/${p.id}/try', {'on': p.tried}));
  }

  void delete(Post p) {
    posts.remove(p);
    _changed();
    _bg(Api.send('DELETE', '/community/posts/${p.id}'));
  }

  void toggleFollow(String handle) {
    following.contains(handle) ? following.remove(handle) : following.add(handle);
    _changed();
    SyncStore.I.put('community', 'following', {'handles': following.toList()});
  }

  final Set<String> _uploading = {};

  /// Shows the post at once, uploads its photos to R2, then publishes it.
  void add(Post p) {
    posts.insert(0, p);
    _uploading.add(p.id);
    _changed();
    () async {
      final urls = <String>[];
      for (final pic in p.pics) {
        if (pic.url.startsWith('http')) {
          urls.add(pic.url);
        } else if (pic.bytes != null) {
          final u = await Media.upload(pic.bytes!, folder: 'community');
          if (u != null) urls.add(u);
        }
      }
      try {
        await Api.send('POST', '/community/posts', {
          'id': p.id,
          'kind': p.kind.name,
          'text': p.text,
          'pics': urls,
          'stat': p.stat,
          'workoutTitle': p.workoutTitle,
          'exercises': [for (final e in p.exercises) [e.$1, e.$2]],
          'options': p.options,
          'tags': p.tags,
        });
      } catch (_) {}
      _uploading.remove(p.id);
    }();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    try {
      final pr = await SharedPreferences.getInstance();
      final raw = pr.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        posts.addAll([for (final p in j['posts'] ?? []) Post.fromJson(Map<String, dynamic>.from(p))]);
        following.addAll(List<String>.from(j['fol'] ?? const []));
        notifyListeners();
      }
      final f = await SyncStore.I.get('community', 'following');
      if (f != null) {
        following
          ..clear()
          ..addAll(List<String>.from(f['handles'] ?? const []));
      }
    } catch (_) {}
    refresh();
  }

  Future<void> _save() async {
    try {
      final pr = await SharedPreferences.getInstance();
      // The last 40 posts are kept for offline use; photos only as URLs.
      final keep = [
        for (final p in posts.take(40))
          if (p.pics.every((x) => x.bytes == null || x.url.isNotEmpty)) p.toJson()..['p'] = [for (final x in p.pics) {'u': x.url}],
      ];
      await pr.setString(_key, jsonEncode({'posts': keep, 'fol': following.toList()}));
    } catch (_) {}
  }
}
