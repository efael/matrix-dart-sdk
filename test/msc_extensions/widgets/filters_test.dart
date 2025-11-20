import 'package:test/test.dart';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('MessageLikeWithType', () {
    test('Matches event with matching type', () {
      final filter = MessageLikeWithType('m.room.message');
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'body': 'Hello'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), true);
    });

    test('Matches event with type prefix', () {
      final filter = MessageLikeWithType('m.room');
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'body': 'Hello'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), true);
    });

    test('Does not match event with different type', () {
      final filter = MessageLikeWithType('m.room.message');
      final event = MatrixEvent(
        type: 'm.reaction',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('Does not match state events', () {
      final filter = MessageLikeWithType('m.room.topic');
      final event = MatrixEvent(
        type: 'm.room.topic',
        content: {'topic': 'Test'},
        senderId: '@user:example.com',
        stateKey: '',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('toCapabilityString returns event type', () {
      final filter = MessageLikeWithType('m.room.message');
      expect(filter.toCapabilityString(), 'm.room.message');
    });

    test('Equality comparison works', () {
      final filter1 = MessageLikeWithType('m.room.message');
      final filter2 = MessageLikeWithType('m.room.message');
      final filter3 = MessageLikeWithType('m.reaction');

      expect(filter1 == filter2, true);
      expect(filter1 == filter3, false);
    });
  });

  group('RoomMessageWithMsgtype', () {
    test('Matches m.room.message with correct msgtype', () {
      final filter = RoomMessageWithMsgtype('m.text');
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'msgtype': 'm.text', 'body': 'Hello'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), true);
    });

    test('Does not match m.room.message with different msgtype', () {
      final filter = RoomMessageWithMsgtype('m.text');
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'msgtype': 'm.image', 'body': 'photo.jpg'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('Does not match non-m.room.message events', () {
      final filter = RoomMessageWithMsgtype('m.text');
      final event = MatrixEvent(
        type: 'm.reaction',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('Does not match state events', () {
      final filter = RoomMessageWithMsgtype('m.text');
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'msgtype': 'm.text'},
        senderId: '@user:example.com',
        stateKey: '',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('toCapabilityString includes msgtype', () {
      final filter = RoomMessageWithMsgtype('m.text');
      expect(filter.toCapabilityString(), 'm.room.message#m.text');
    });
  });

  group('StateWithType', () {
    test('Matches state event with matching type', () {
      final filter = StateWithType('m.room.topic');
      final event = MatrixEvent(
        type: 'm.room.topic',
        content: {'topic': 'Test'},
        senderId: '@user:example.com',
        stateKey: '',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), true);
    });

    test('Matches regardless of state_key value', () {
      final filter = StateWithType('m.room.member');
      final event1 = MatrixEvent(
        type: 'm.room.member',
        content: {},
        senderId: '@user:example.com',
        stateKey: '@alice:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );
      final event2 = MatrixEvent(
        type: 'm.room.member',
        content: {},
        senderId: '@user:example.com',
        stateKey: '@bob:example.com',
        eventId: '\$event2',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event1), true);
      expect(filter.matches(event2), true);
    });

    test('Does not match message-like events', () {
      final filter = StateWithType('m.room.topic');
      final event = MatrixEvent(
        type: 'm.room.topic',
        content: {'topic': 'Test'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('Does not match different event type', () {
      final filter = StateWithType('m.room.topic');
      final event = MatrixEvent(
        type: 'm.room.name',
        content: {},
        senderId: '@user:example.com',
        stateKey: '',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('toCapabilityString returns event type', () {
      final filter = StateWithType('m.room.topic');
      expect(filter.toCapabilityString(), 'm.room.topic');
    });
  });

  group('StateWithTypeAndStateKey', () {
    test('Matches state event with exact type and state_key', () {
      final filter = StateWithTypeAndStateKey('m.room.member', '@user:example.com');
      final event = MatrixEvent(
        type: 'm.room.member',
        content: {},
        senderId: '@user:example.com',
        stateKey: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), true);
    });

    test('Does not match with different state_key', () {
      final filter = StateWithTypeAndStateKey('m.room.member', '@alice:example.com');
      final event = MatrixEvent(
        type: 'm.room.member',
        content: {},
        senderId: '@user:example.com',
        stateKey: '@bob:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('Does not match with different type', () {
      final filter = StateWithTypeAndStateKey('m.room.member', '@user:example.com');
      final event = MatrixEvent(
        type: 'm.room.topic',
        content: {},
        senderId: '@user:example.com',
        stateKey: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('toCapabilityString includes type and state_key', () {
      final filter = StateWithTypeAndStateKey('m.room.member', '@user:example.com');
      expect(filter.toCapabilityString(), 'm.room.member|@user:example.com');
    });
  });

  group('ToDeviceWithType', () {
    test('Matches event with exact type', () {
      final filter = ToDeviceWithType('m.room_key');
      final event = MatrixEvent(
        type: 'm.room_key',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), true);
    });

    test('Does not match different type', () {
      final filter = ToDeviceWithType('m.room_key');
      final event = MatrixEvent(
        type: 'm.custom',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      expect(filter.matches(event), false);
    });

    test('toCapabilityString returns event type', () {
      final filter = ToDeviceWithType('m.room_key');
      expect(filter.toCapabilityString(), 'm.room_key');
    });
  });
}
