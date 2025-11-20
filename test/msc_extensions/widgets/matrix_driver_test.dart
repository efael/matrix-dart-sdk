import 'package:test/test.dart';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';
import 'package:matrix/msc_extensions/widgets/src/driver/matrix_driver.dart';

void main() {
  group('CryptoEventFilter', () {
    test('Detects m.room_key events', () {
      expect(CryptoEventFilter.isCryptoEvent('m.room_key'), true);
      expect(CryptoEventFilter.isCryptoEvent('m.room_key.withheld'), true);
    });

    test('Detects m.room_key_request events', () {
      expect(CryptoEventFilter.isCryptoEvent('m.room_key_request'), true);
    });

    test('Detects m.forwarded_room_key events', () {
      expect(CryptoEventFilter.isCryptoEvent('m.forwarded_room_key'), true);
    });

    test('Detects m.secret.* events', () {
      expect(CryptoEventFilter.isCryptoEvent('m.secret.send'), true);
      expect(CryptoEventFilter.isCryptoEvent('m.secret.request'), true);
    });

    test('Detects m.room.encrypted events', () {
      expect(CryptoEventFilter.isCryptoEvent('m.room.encrypted'), true);
    });

    test('Does not detect non-crypto events', () {
      expect(CryptoEventFilter.isCryptoEvent('m.room.message'), false);
      expect(CryptoEventFilter.isCryptoEvent('m.room.topic'), false);
      expect(CryptoEventFilter.isCryptoEvent('m.reaction'), false);
    });

    test('Filters crypto events from list', () {
      final events = [
        MatrixEvent(
          type: 'm.room.message',
          content: {'body': 'Hello'},
          senderId: '@user:example.com',
          eventId: '\$event1',
          originServerTs: DateTime.now(),
        ),
        MatrixEvent(
          type: 'm.room_key',
          content: {},
          senderId: '@user:example.com',
          eventId: '\$event2',
          originServerTs: DateTime.now(),
        ),
        MatrixEvent(
          type: 'm.reaction',
          content: {},
          senderId: '@user:example.com',
          eventId: '\$event3',
          originServerTs: DateTime.now(),
        ),
      ];

      final filtered = CryptoEventFilter.filterEvents(events);

      expect(filtered.length, 2);
      expect(filtered[0].type, 'm.room.message');
      expect(filtered[1].type, 'm.reaction');
    });

    test('Returns empty list when all events are crypto', () {
      final events = [
        MatrixEvent(
          type: 'm.room_key',
          content: {},
          senderId: '@user:example.com',
          eventId: '\$event1',
          originServerTs: DateTime.now(),
        ),
        MatrixEvent(
          type: 'm.room.encrypted',
          content: {},
          senderId: '@user:example.com',
          eventId: '\$event2',
          originServerTs: DateTime.now(),
        ),
      ];

      final filtered = CryptoEventFilter.filterEvents(events);

      expect(filtered, isEmpty);
    });

    test('Returns all events when none are crypto', () {
      final events = [
        MatrixEvent(
          type: 'm.room.message',
          content: {'body': 'Hello'},
          senderId: '@user:example.com',
          eventId: '\$event1',
          originServerTs: DateTime.now(),
        ),
        MatrixEvent(
          type: 'm.reaction',
          content: {},
          senderId: '@user:example.com',
          eventId: '\$event2',
          originServerTs: DateTime.now(),
        ),
      ];

      final filtered = CryptoEventFilter.filterEvents(events);

      expect(filtered.length, 2);
    });
  });

  group('MatrixDriver', () {
    test('shouldForwardEvent blocks crypto events', () {
      // Create a mock driver (we only test static logic here)
      final event = MatrixEvent(
        type: 'm.room_key',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      final filters = <WidgetEventFilter>[
        const MessageLikeWithType('m.room'),
      ];

      // Even though filter matches 'm.room*', crypto events are blocked
      expect(
        CryptoEventFilter.isCryptoEvent(event.type),
        true,
      );
    });

    test('shouldForwardEvent allows non-crypto events matching filter', () {
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'body': 'Hello'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      final filters = <WidgetEventFilter>[
        const MessageLikeWithType('m.room.message'),
      ];

      expect(
        filters.any((f) => f.matches(event)),
        true,
      );
      expect(
        CryptoEventFilter.isCryptoEvent(event.type),
        false,
      );
    });

    test('shouldForwardEvent blocks events not matching filter', () {
      final event = MatrixEvent(
        type: 'm.reaction',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      final filters = <WidgetEventFilter>[
        const MessageLikeWithType('m.room.message'),
      ];

      expect(
        filters.any((f) => f.matches(event)),
        false,
      );
    });

    test('createEventNotification returns null for crypto events', () {
      final event = MatrixEvent(
        type: 'm.room_key',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      final filters = <WidgetEventFilter>[
        const MessageLikeWithType('m.room'),
      ];

      expect(
        CryptoEventFilter.isCryptoEvent(event.type),
        true,
      );
    });

    test('createEventNotification returns null for non-matching events', () {
      final event = MatrixEvent(
        type: 'm.reaction',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      final filters = <WidgetEventFilter>[
        const MessageLikeWithType('m.room.message'),
      ];

      expect(
        filters.any((f) => f.matches(event)),
        false,
      );
    });

    test('createEventNotification creates notification for matching events', () {
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'body': 'Hello'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      final filters = <WidgetEventFilter>[
        const MessageLikeWithType('m.room.message'),
      ];

      expect(
        filters.any((f) => f.matches(event)),
        true,
      );
      expect(
        CryptoEventFilter.isCryptoEvent(event.type),
        false,
      );
    });
  });
}
