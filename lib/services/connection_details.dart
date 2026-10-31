import 'dart:convert';

import 'package:http/http.dart' as http;

// Used when the user enters a bare room name instead of a full room link.
final Uri defaultRoomsHost = Uri.parse('https://englishmans.duckdns.org');

class ConnectionDetails {
  final String serverUrl;
  final String roomName;
  final String participantName;
  final String participantToken;

  const ConnectionDetails({
    required this.serverUrl,
    required this.roomName,
    required this.participantName,
    required this.participantToken,
  });

  factory ConnectionDetails.fromJson(Map<String, dynamic> json) => ConnectionDetails(
    serverUrl: json['serverUrl'] as String,
    roomName: json['roomName'] as String,
    participantName: json['participantName'] as String,
    participantToken: json['participantToken'] as String,
  );
}

class RoomLink {
  final Uri host;
  final String roomName;

  const RoomLink({required this.host, required this.roomName});

  /// Accepts either a full room link (`https://host/rooms/<roomName>`) or a bare room name.
  /// Returns null if the input can't be interpreted as a room.
  static RoomLink? parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final roomsIndex = segments.indexOf('rooms');
      if (roomsIndex == -1 || roomsIndex + 1 >= segments.length) return null;
      return RoomLink(
        host: Uri(scheme: uri.scheme, host: uri.host, port: uri.hasPort ? uri.port : null),
        roomName: segments[roomsIndex + 1],
      );
    }

    if (text.contains('/') || text.contains(' ')) return null;
    return RoomLink(host: defaultRoomsHost, roomName: text);
  }
}

class ConnectionDetailsException implements Exception {
  final String message;
  const ConnectionDetailsException(this.message);

  @override
  String toString() => message;
}

/// Requests a participant token from the same endpoint the web client (LiveKit Meet) uses.
Future<ConnectionDetails> fetchConnectionDetails({
  required RoomLink link,
  required String participantName,
}) async {
  final url = link.host.replace(
    path: '/api/connection-details',
    queryParameters: {
      'roomName': link.roomName,
      'participantName': participantName,
    },
  );

  final http.Response response;
  try {
    response = await http.get(url).timeout(const Duration(seconds: 15));
  } catch (error) {
    throw ConnectionDetailsException('Could not reach ${link.host.host}: $error');
  }

  if (response.statusCode != 200) {
    final body = response.body.trim();
    throw ConnectionDetailsException(body.isNotEmpty ? body : 'Server returned ${response.statusCode}');
  }

  return ConnectionDetails.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}
