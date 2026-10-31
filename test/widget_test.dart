import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:englishmans_livekit/app.dart';
import 'package:englishmans_livekit/services/connection_details.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MeetApp());
    // Dispose resources started by the global controller to avoid pending timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await appCtrl.cleanUp();
    });
  });

  group('RoomLink.parse', () {
    test('parses a full room link', () {
      final link = RoomLink.parse('https://englishmans.duckdns.org/rooms/gpHJF75_87mFNjvqZy_iwg');
      expect(link?.host.toString(), 'https://englishmans.duckdns.org');
      expect(link?.roomName, 'gpHJF75_87mFNjvqZy_iwg');
    });

    test('ignores query and fragment', () {
      final link = RoomLink.parse(' https://example.com/rooms/abc?foo=1#secret ');
      expect(link?.host.toString(), 'https://example.com');
      expect(link?.roomName, 'abc');
    });

    test('treats a bare value as a room name on the default host', () {
      final link = RoomLink.parse('abc');
      expect(link?.host, defaultRoomsHost);
      expect(link?.roomName, 'abc');
    });

    test('rejects links without a room', () {
      expect(RoomLink.parse(''), isNull);
      expect(RoomLink.parse('https://example.com/'), isNull);
      expect(RoomLink.parse('https://example.com/rooms/'), isNull);
    });
  });
}
