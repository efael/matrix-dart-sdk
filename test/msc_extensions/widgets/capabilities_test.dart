import 'package:test/test.dart';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('WidgetCapabilities', () {
    test('Create empty capabilities', () {
      const caps = WidgetCapabilities.empty();

      expect(caps.read, isEmpty);
      expect(caps.send, isEmpty);
      expect(caps.requiresClient, false);
      expect(caps.updateDelayedEvent, false);
      expect(caps.sendDelayedEvent, false);
    });

    test('Create capabilities with filters', () {
      const caps = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
        send: [StateWithType('m.room.topic')],
        requiresClient: true,
        updateDelayedEvent: true,
        sendDelayedEvent: true,
      );

      expect(caps.read.length, 1);
      expect(caps.send.length, 1);
      expect(caps.requiresClient, true);
      expect(caps.updateDelayedEvent, true);
      expect(caps.sendDelayedEvent, true);
    });

    test('canRead checks filter presence', () {
      const caps = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
      );

      expect(caps.canRead(const MessageLikeWithType('m.room.message')), true);
      expect(caps.canRead(const MessageLikeWithType('m.reaction')), false);
    });

    test('canSend checks filter presence', () {
      const caps = WidgetCapabilities(
        send: [StateWithType('m.room.topic')],
      );

      expect(caps.canSend(const StateWithType('m.room.topic')), true);
      expect(caps.canSend(const StateWithType('m.room.name')), false);
    });

    test('canReadEvent checks if event matches any read filter', () {
      const caps = WidgetCapabilities(
        read: [
          MessageLikeWithType('m.room.message'),
          StateWithType('m.room.topic'),
        ],
      );

      final messageEvent = MatrixEvent(
        type: 'm.room.message',
        content: {'body': 'Hello'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
      );

      final topicEvent = MatrixEvent(
        type: 'm.room.topic',
        content: {'topic': 'Test'},
        senderId: '@user:example.com',
        stateKey: '',
        eventId: '\$event2',
        originServerTs: DateTime.now(),
      );

      final reactionEvent = MatrixEvent(
        type: 'm.reaction',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event3',
        originServerTs: DateTime.now(),
      );

      expect(caps.canReadEvent(messageEvent), true);
      expect(caps.canReadEvent(topicEvent), true);
      expect(caps.canReadEvent(reactionEvent), false);
    });

    test('canSendEventType checks message-like events', () {
      const caps = WidgetCapabilities(
        send: [MessageLikeWithType('m.room.message')],
      );

      expect(caps.canSendEventType('m.room.message'), true);
      expect(caps.canSendEventType('m.reaction'), false);
    });

    test('canSendEventType checks state events with type only', () {
      const caps = WidgetCapabilities(
        send: [StateWithType('m.room.topic')],
      );

      expect(caps.canSendEventType('m.room.topic', stateKey: ''), true);
      expect(caps.canSendEventType('m.room.topic', stateKey: 'any'), true);
      expect(caps.canSendEventType('m.room.name', stateKey: ''), false);
    });

    test('canSendEventType checks state events with type and state_key', () {
      const caps = WidgetCapabilities(
        send: [StateWithTypeAndStateKey('m.room.member', '@user:example.com')],
      );

      expect(
        caps.canSendEventType('m.room.member', stateKey: '@user:example.com'),
        true,
      );
      expect(
        caps.canSendEventType('m.room.member', stateKey: '@other:example.com'),
        false,
      );
    });

    test('canSendEventType handles RoomMessageWithMsgtype', () {
      const caps = WidgetCapabilities(
        send: [RoomMessageWithMsgtype('m.text')],
      );

      expect(caps.canSendEventType('m.room.message'), true);
    });

    test('toJson serializes capabilities', () {
      const caps = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
        send: [StateWithType('m.room.topic')],
        requiresClient: true,
        updateDelayedEvent: true,
        sendDelayedEvent: true,
      );

      final json = caps.toJson();
      expect(json['read'], ['m.room.message']);
      expect(json['send'], ['m.room.topic']);
      expect(json['requires_client'], true);
      expect(json['update_delayed_event'], true);
      expect(json['send_delayed_event'], true);
    });

    test('copyWith creates modified copy', () {
      const caps = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
        requiresClient: false,
      );

      final modified = caps.copyWith(
        send: [const StateWithType('m.room.topic')],
        requiresClient: true,
      );

      expect(modified.read, caps.read);
      expect(modified.send.length, 1);
      expect(modified.requiresClient, true);
    });

    test('Equality comparison works', () {
      const caps1 = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
        send: [StateWithType('m.room.topic')],
        requiresClient: true,
      );

      const caps2 = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
        send: [StateWithType('m.room.topic')],
        requiresClient: true,
      );

      const caps3 = WidgetCapabilities(
        read: [MessageLikeWithType('m.reaction')],
        send: [StateWithType('m.room.topic')],
        requiresClient: true,
      );

      expect(caps1 == caps2, true);
      expect(caps1 == caps3, false);
    });

    test('Default values are set correctly', () {
      const caps = WidgetCapabilities();

      expect(caps.read, isEmpty);
      expect(caps.send, isEmpty);
      expect(caps.requiresClient, false);
      expect(caps.updateDelayedEvent, false);
      expect(caps.sendDelayedEvent, false);
    });
  });
}
