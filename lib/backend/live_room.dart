import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'live_backend.dart';
import 'me.dart';

/// One LiveKit video room (free LiveKit Cloud plan). The coach publishes
/// camera and microphone; members watch and chat. The API hands out the
/// join tokens; video goes directly between the phones and LiveKit.
///
///   final room = LiveRoom();
///   await room.host(sessionId);           // coach
///   await room.join(sessionId);           // member
///   LiveRoomVideo(room: room)             // the picture
class LiveRoom extends ChangeNotifier {
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _events;

  /// Null while connecting; a message when it could not connect.
  String? error;
  bool connected = false;
  bool connecting = false;

  /// Chat and tips sent over the room's data channel: (name, text).
  final List<(String, String)> messages = [];
  int hearts = 0;
  int tips = 0;

  int get viewers => _room?.remoteParticipants.length ?? 0;
  bool get micOn => _room?.localParticipant?.isMicrophoneEnabled() ?? false;
  bool get camOn => _room?.localParticipant?.isCameraEnabled() ?? false;

  /// The picture to show: our own camera when hosting, else the coach's.
  lk.VideoTrack? get video {
    final r = _room;
    if (r == null) return null;
    final mine = r.localParticipant?.videoTrackPublications.where((p) => p.track != null).firstOrNull?.track;
    if (mine != null) return mine;
    for (final p in r.remoteParticipants.values) {
      for (final t in p.videoTrackPublications) {
        if (t.subscribed && t.track != null) return t.track as lk.VideoTrack;
      }
    }
    return null;
  }

  bool get isLocalVideo => _room?.localParticipant?.videoTrackPublications.any((p) => p.track != null) ?? false;

  /// Coach: start (or restart) a session and publish camera + mic.
  Future<bool> host(String sessionId, {String? url, String? token}) async {
    if (url == null || token == null) {
      try {
        final j = await Api.send('POST', '/live/sessions/$sessionId/start');
        url = j['url']?.toString();
        token = j['token']?.toString();
      } on ApiError catch (e) {
        return _fail(e.message);
      } catch (_) {
        return _fail('Could not reach the live server.');
      }
    }
    final ok = await _connect(url, token);
    if (ok) {
      try {
        await _room!.localParticipant?.setCameraEnabled(true);
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {
        error = 'Allow camera and microphone to go live.';
      }
      notifyListeners();
    }
    return ok;
  }

  /// Member: join a live session to watch and chat.
  Future<bool> join(String sessionId) async {
    try {
      final j = await Api.send('POST', '/live/sessions/$sessionId/join');
      return await _connect(j['url']?.toString(), j['token']?.toString());
    } on ApiError catch (e) {
      return _fail(e.message);
    } catch (_) {
      return _fail('Could not reach the live server.');
    }
  }

  /// 1:1 video call room (the room name must contain the caller's id).
  Future<bool> call(String room) async {
    try {
      final j = await Api.send('POST', '/live/token', {'room': room});
      final ok = await _connect(j['url']?.toString(), j['token']?.toString());
      if (ok) {
        await _room!.localParticipant?.setCameraEnabled(true);
        await _room!.localParticipant?.setMicrophoneEnabled(true);
        notifyListeners();
      }
      return ok;
    } on ApiError catch (e) {
      return _fail(e.message);
    } catch (_) {
      return _fail('Could not reach the live server.');
    }
  }

  bool _fail(String m) {
    error = m;
    connecting = false;
    notifyListeners();
    return false;
  }

  Future<bool> _connect(String? url, String? token) async {
    if (url == null || url.isEmpty || token == null || token.isEmpty) {
      return _fail('Live video is not set up yet.');
    }
    connecting = true;
    error = null;
    notifyListeners();
    try {
      final room = lk.Room(roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true));
      _room = room;
      room.addListener(notifyListeners);
      _events = room.createListener()
        ..on<lk.DataReceivedEvent>((e) {
          try {
            final j = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
            _onData(j, e.participant?.name ?? 'Member');
          } catch (_) {}
        })
        ..on<lk.RoomDisconnectedEvent>((_) {
          connected = false;
          notifyListeners();
        });
      await room.connect(url, token);
      connected = true;
      connecting = false;
      notifyListeners();
      return true;
    } catch (e) {
      return _fail('Could not join the live room.');
    }
  }

  void _onData(Map<String, dynamic> j, String from) {
    switch (j['k']) {
      case 'chat':
        messages.add(((j['n'] ?? from).toString(), (j['t'] ?? '').toString()));
      case 'heart':
        hearts++;
      case 'tip':
        tips += (j['v'] as num?)?.toInt() ?? 0;
        messages.add(((j['n'] ?? from).toString(), 'Sent a tip 💜'));
    }
    if (messages.length > 50) messages.removeAt(0);
    notifyListeners();
  }

  Future<void> _send(Map<String, dynamic> j) async {
    try {
      await _room?.localParticipant?.publishData(utf8.encode(jsonEncode({...j, 'n': Me.first})), reliable: true);
    } catch (_) {}
  }

  void sendChat(String text) {
    if (text.trim().isEmpty) return;
    messages.add((Me.first, text.trim()));
    notifyListeners();
    _send({'k': 'chat', 't': text.trim()});
  }

  void sendHeart() {
    hearts++;
    notifyListeners();
    _send({'k': 'heart'});
  }

  void sendTip(int amount) {
    tips += amount;
    notifyListeners();
    _send({'k': 'tip', 'v': amount});
  }

  Future<void> setMic(bool on) async {
    await _room?.localParticipant?.setMicrophoneEnabled(on);
    notifyListeners();
  }

  Future<void> setCam(bool on) async {
    await _room?.localParticipant?.setCameraEnabled(on);
    notifyListeners();
  }

  Future<void> leave() async {
    final r = _room;
    _room = null;
    connected = false;
    await _events?.dispose();
    _events = null;
    if (r != null) {
      r.removeListener(notifyListeners);
      try {
        await r.disconnect();
        await r.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    unawaited(leave());
    super.dispose();
  }
}

/// The room's picture, or [placeholder] until a video track is there.
class LiveRoomVideo extends StatelessWidget {
  const LiveRoomVideo({super.key, required this.room, required this.placeholder});
  final LiveRoom room;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: room,
      builder: (context, _) {
        final t = room.video;
        if (t == null) return placeholder;
        return lk.VideoTrackRenderer(
          t,
          fit: lk.VideoViewFit.cover,
          mirrorMode: room.isLocalVideo ? lk.VideoViewMirrorMode.mirror : lk.VideoViewMirrorMode.off,
        );
      },
    );
  }
}
