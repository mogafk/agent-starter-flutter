import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/call_service.dart';
import '../services/connection_details.dart';

class AppCtrl extends ChangeNotifier {
  static final _logger = Logger('AppCtrl');
  static const _participantNameKey = 'participantName';

  final roomLinkCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  // A fresh RoomContext is used for every call: RoomContext keeps the pre-join
  // tracks from its last connect() and would try to republish them on the next one.
  late components.RoomContext roomContext = _createRoomContext();
  sdk.EventsListener<sdk.RoomEvent>? _roomListener;
  StreamSubscription<Uri>? _linkSubscription;

  bool isJoining = false;
  String? errorMessage;
  bool _hasCleanedUp = false;

  AppCtrl() {
    final format = DateFormat('HH:mm:ss');
    // configure logs for debugging
    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((record) {
      debugPrint('${format.format(record.time)}: ${record.message}');
    });

    roomLinkCtrl.addListener(notifyListeners);
    nameCtrl.addListener(notifyListeners);

    unawaited(_restoreParticipantName());
    // Room links opened from Telegram/browser (Android App Links), including the one that launched the app.
    _linkSubscription = AppLinks().uriLinkStream.listen(
      _handleIncomingLink,
      onError: (Object error) => _logger.warning('App link error: $error'),
    );
  }

  bool get canJoin => !isJoining && RoomLink.parse(roomLinkCtrl.text) != null && nameCtrl.text.trim().isNotEmpty;

  components.RoomContext _createRoomContext() => components.RoomContext(
    roomOptions: const sdk.RoomOptions(
      adaptiveStream: true,
      dynacast: true,
    ),
    onConnected: _handleConnected,
    onDisconnected: _handleDisconnected,
  );

  void _handleIncomingLink(Uri uri) {
    _logger.info('Opened with link: $uri');
    if (RoomLink.parse(uri.toString()) == null) return;
    // During a call the join form is hidden, so this just leaves the link ready for after leaving.
    roomLinkCtrl.text = uri.toString();
    errorMessage = null;
    notifyListeners();
  }

  void _handleConnected() {
    unawaited(CallService.start(title: 'Call in progress'));
    // Mic/camera permissions may be granted only after joining; refresh the service so it covers them.
    _roomListener = roomContext.room.createListener()
      ..on<sdk.LocalTrackPublishedEvent>((_) => CallService.start(title: 'Call in progress'));
  }

  void _handleDisconnected() {
    if (_hasCleanedUp) return;
    unawaited(CallService.stop());
    _replaceRoomContext();
  }

  void _replaceRoomContext() {
    final previous = roomContext;
    final previousListener = _roomListener;
    _roomListener = null;
    roomContext = _createRoomContext();
    notifyListeners();
    // Dispose outside of the RoomContext's own event callback.
    unawaited(
      Future(() async {
        await previousListener?.dispose();
        previous.dispose();
      }),
    );
  }

  Future<void> _restoreParticipantName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_participantNameKey);
      if (name != null && nameCtrl.text.isEmpty && !_hasCleanedUp) nameCtrl.text = name;
    } catch (error) {
      _logger.warning('Failed to restore participant name: $error');
    }
  }

  Future<void> _saveParticipantName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_participantNameKey, name);
    } catch (error) {
      _logger.warning('Failed to save participant name: $error');
    }
  }

  Future<void> cleanUp() async {
    if (_hasCleanedUp) return;
    _hasCleanedUp = true;

    await _linkSubscription?.cancel();
    await _roomListener?.dispose();
    await CallService.stop();
    // RoomContext.dispose() doesn't wait for its room, so dispose the room explicitly as well.
    final room = roomContext.room;
    roomContext.dispose();
    await room.dispose();
    roomLinkCtrl.dispose();
    nameCtrl.dispose();
  }

  @override
  void dispose() {
    unawaited(cleanUp());
    super.dispose();
  }

  Future<void> join() async {
    if (isJoining) {
      _logger.fine('Join attempt ignored: already joining.');
      return;
    }

    final link = RoomLink.parse(roomLinkCtrl.text);
    final name = nameCtrl.text.trim();
    if (link == null || name.isEmpty) return;

    isJoining = true;
    errorMessage = null;
    notifyListeners();
    unawaited(_saveParticipantName(name));

    try {
      _logger.info('Requesting connection details for room ${link.roomName} at ${link.host}');
      final details = await fetchConnectionDetails(link: link, participantName: name);

      _logger.info('Connecting to ${details.serverUrl}');
      final preJoinTracks = [roomContext.localAudioTrack, roomContext.localVideoTrack].nonNulls.toList();
      try {
        await roomContext.connect(url: details.serverUrl, token: details.participantToken);
      } catch (_) {
        // connect() has already detached the pre-join tracks from the context, so release them
        // here (otherwise the camera stays on) and start over with a clean context.
        for (final track in preJoinTracks) {
          await track.dispose();
        }
        _replaceRoomContext();
        rethrow;
      }
    } catch (error, stackTrace) {
      _logger.severe('Join error: $error', error, stackTrace);
      errorMessage = error.toString();
    } finally {
      isJoining = false;
      notifyListeners();
    }
  }

  Future<void> leave() async {
    await roomContext.disconnect();
  }

  void dismissError() {
    errorMessage = null;
    notifyListeners();
  }
}
