import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('CapabilityParser', () {
    test('Parse send message event capability', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.send.event:m.room.message',
      ]);

      expect(caps.send.length, 1);
      expect(caps.send.first, isA<MessageLikeWithType>());
      expect((caps.send.first as MessageLikeWithType).eventType, 'm.room.message');
    });

    test('Parse send message with msgtype capability', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.send.event:m.room.message#m.text',
      ]);

      expect(caps.send.length, 1);
      expect(caps.send.first, isA<RoomMessageWithMsgtype>());
      expect((caps.send.first as RoomMessageWithMsgtype).msgtype, 'm.text');
    });

    test('Parse read event capability', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.read.event:m.room.message',
      ]);

      expect(caps.read.length, 1);
      expect(caps.read.first, isA<MessageLikeWithType>());
    });

    test('Parse send state event capability', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.send.state_event:m.room.topic',
      ]);

      expect(caps.send.length, 1);
      expect(caps.send.first, isA<StateWithType>());
      expect((caps.send.first as StateWithType).eventType, 'm.room.topic');
    });

    test('Parse read state event capability', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.read.state_event:m.room.member',
      ]);

      expect(caps.read.length, 1);
      expect(caps.read.first, isA<StateWithType>());
    });

    test('Parse state event with state_key', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.send.state_event:m.room.member|@user:example.com',
      ]);

      expect(caps.send.length, 1);
      expect(caps.send.first, isA<StateWithTypeAndStateKey>());
      final filter = caps.send.first as StateWithTypeAndStateKey;
      expect(filter.eventType, 'm.room.member');
      expect(filter.stateKey, '@user:example.com');
    });

    test('Parse to-device event capability (MSC3819)', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc3819.send.to_device:m.custom',
      ]);

      expect(caps.send.length, 1);
      expect(caps.send.first, isA<ToDeviceWithType>());
      expect((caps.send.first as ToDeviceWithType).eventType, 'm.custom');
    });

    test('Parse require_client capability', () {
      final caps = CapabilityParser.parse(['require_client']);

      expect(caps.requiresClient, true);
    });

    test('Parse io.element.require_client capability', () {
      final caps = CapabilityParser.parse(['io.element.require_client']);

      expect(caps.requiresClient, true);
    });

    test('Parse send delayed event capability (MSC4157)', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc4157.send.delayed_event',
      ]);

      expect(caps.sendDelayedEvent, true);
    });

    test('Parse update delayed event capability (MSC4157)', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc4157.update.delayed_event',
      ]);

      expect(caps.updateDelayedEvent, true);
    });

    test('Parse multiple capabilities', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.send.event:m.room.message',
        'org.matrix.msc2762.read.event:m.room.message',
        'org.matrix.msc2762.send.state_event:m.room.topic',
        'org.matrix.msc2762.read.state_event:m.room.name',
        'require_client',
        'org.matrix.msc4157.send.delayed_event',
        'org.matrix.msc4157.update.delayed_event',
      ]);

      expect(caps.send.length, 2);
      expect(caps.read.length, 2);
      expect(caps.requiresClient, true);
      expect(caps.sendDelayedEvent, true);
      expect(caps.updateDelayedEvent, true);
    });

    test('Ignore malformed capabilities', () {
      final caps = CapabilityParser.parse([
        'org.matrix.msc2762.send.event:m.room.message',
        'invalid.capability.string',
        'org.matrix.msc2762.read.event:m.room.message',
      ]);

      expect(caps.send.length, 1);
      expect(caps.read.length, 1);
    });

    test('Parse empty list returns empty capabilities', () {
      final caps = CapabilityParser.parse([]);

      expect(caps.send, isEmpty);
      expect(caps.read, isEmpty);
      expect(caps.requiresClient, false);
      expect(caps.sendDelayedEvent, false);
      expect(caps.updateDelayedEvent, false);
    });

    test('Parse all common capability types', () {
      final caps = CapabilityParser.parse([
        // Message-like events
        'org.matrix.msc2762.send.event:m.room.message',
        'org.matrix.msc2762.send.event:m.room.message#m.text',
        'org.matrix.msc2762.send.event:m.reaction',

        // State events
        'org.matrix.msc2762.send.state_event:m.room.topic',
        'org.matrix.msc2762.send.state_event:m.room.member|@user:example.com',

        // To-device
        'org.matrix.msc3819.send.to_device:m.custom',
        'org.matrix.msc3819.read.to_device:m.custom',

        // Special
        'require_client',
        'org.matrix.msc4157.send.delayed_event',
        'org.matrix.msc4157.update.delayed_event',
      ]);

      expect(caps.send.length, 6);
      expect(caps.read.length, 1);
      expect(caps.requiresClient, true);
      expect(caps.sendDelayedEvent, true);
      expect(caps.updateDelayedEvent, true);
    });
  });
}
