import 'package:test/test.dart';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/capabilities.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/element_call_permissions.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';

void main() {
  group('getElementCallRequiredPermissions', () {
    test('Returns comprehensive permissions for Element Call', () {
      final caps = getElementCallRequiredPermissions(
        userId: '@user:example.com',
        deviceId: 'DEVICE123',
      );

      // Check read permissions
      expect(caps.read.length, greaterThan(10));
      expect(
        caps.read.any((f) => f is StateWithType && f.eventType == 'm.call.member'),
        true,
      );
      expect(
        caps.read.any((f) =>
            f is StateWithType && f.eventType == 'org.matrix.msc3401.call.member'),
        true,
      );
      expect(
        caps.read.any((f) => f is StateWithType && f.eventType == 'm.room.name'),
        true,
      );
      expect(
        caps.read.any((f) => f is StateWithType && f.eventType == 'm.room.member'),
        true,
      );
      expect(
        caps.read.any((f) =>
            f is MessageLikeWithType &&
            f.eventType == 'io.element.call.encryption_keys'),
        true,
      );

      // Check send permissions
      expect(caps.send.length, greaterThan(10));
      expect(
        caps.send.any((f) =>
            f is MessageLikeWithType && f.eventType == 'm.call.notify'),
        true,
      );
      expect(
        caps.send.any((f) =>
            f is MessageLikeWithType &&
            f.eventType == 'org.matrix.msc4143.rtc.notify'),
        true,
      );

      // Check other capabilities
      expect(caps.requiresClient, true);
      expect(caps.updateDelayedEvent, true);
      expect(caps.sendDelayedEvent, true);
    });

    test('Includes device-specific state key patterns', () {
      final userId = '@user:example.com';
      final deviceId = 'DEVICE123';
      final caps = getElementCallRequiredPermissions(
        userId: userId,
        deviceId: deviceId,
      );

      // Check for state events with device patterns
      final stateFilters = caps.send
          .whereType<StateWithTypeAndStateKey>()
          .map((f) => f.stateKey)
          .toList();

      // Should include all 5 pattern variations
      expect(stateFilters.contains(userId), true);
      expect(stateFilters.contains('${userId}_$deviceId'), true);
      expect(stateFilters.contains('${userId}_${deviceId}_m.call'), true);
      expect(stateFilters.contains('_${userId}_$deviceId'), true);
      expect(stateFilters.contains('_${userId}_${deviceId}_m.call'), true);
    });

    test('Includes both legacy and MSC3401 call member events', () {
      final caps = getElementCallRequiredPermissions(
        userId: '@user:example.com',
        deviceId: 'DEVICE123',
      );

      // Check for both m.call.member and org.matrix.msc3401.call.member
      final callMemberFilters = caps.send
          .whereType<StateWithTypeAndStateKey>()
          .where((f) => f.eventType == 'm.call.member' ||
              f.eventType == 'org.matrix.msc3401.call.member')
          .toList();

      // Should have patterns for both event types
      expect(callMemberFilters.length, greaterThan(5));
    });
  });

  group('hasElementCallPermissions', () {
    test('Returns true when all required permissions are granted', () {
      final userId = '@user:example.com';
      final deviceId = 'DEVICE123';

      final required = getElementCallRequiredPermissions(
        userId: userId,
        deviceId: deviceId,
      );

      // Grant exactly what's required
      final hasPerms = hasElementCallPermissions(
        required,
        userId,
        deviceId,
      );

      expect(hasPerms, true);
    });

    test('Returns false when missing read permissions', () {
      final userId = '@user:example.com';
      final deviceId = 'DEVICE123';

      // Grant partial permissions
      const granted = WidgetCapabilities(
        read: [
          StateWithType('m.room.name'),
          // Missing m.call.member and others
        ],
        send: [],
        requiresClient: true,
        updateDelayedEvent: true,
        sendDelayedEvent: true,
      );

      final hasPerms = hasElementCallPermissions(
        granted,
        userId,
        deviceId,
      );

      expect(hasPerms, false);
    });

    test('Returns false when missing send permissions', () {
      final userId = '@user:example.com';
      final deviceId = 'DEVICE123';

      final required = getElementCallRequiredPermissions(
        userId: userId,
        deviceId: deviceId,
      );

      // Grant all read but no send
      final granted = WidgetCapabilities(
        read: required.read,
        send: [], // Missing send permissions
        requiresClient: true,
        updateDelayedEvent: true,
        sendDelayedEvent: true,
      );

      final hasPerms = hasElementCallPermissions(
        granted,
        userId,
        deviceId,
      );

      expect(hasPerms, false);
    });

    test('Returns false when missing requiresClient', () {
      final userId = '@user:example.com';
      final deviceId = 'DEVICE123';

      final required = getElementCallRequiredPermissions(
        userId: userId,
        deviceId: deviceId,
      );

      // Grant everything except requiresClient
      final granted = WidgetCapabilities(
        read: required.read,
        send: required.send,
        requiresClient: false, // Missing this
        updateDelayedEvent: true,
        sendDelayedEvent: true,
      );

      final hasPerms = hasElementCallPermissions(
        granted,
        userId,
        deviceId,
      );

      expect(hasPerms, false);
    });

    test('Returns false when missing delayed event capabilities', () {
      final userId = '@user:example.com';
      final deviceId = 'DEVICE123';

      final required = getElementCallRequiredPermissions(
        userId: userId,
        deviceId: deviceId,
      );

      // Grant everything except delayed events
      final granted = WidgetCapabilities(
        read: required.read,
        send: required.send,
        requiresClient: true,
        updateDelayedEvent: false, // Missing this
        sendDelayedEvent: false, // Missing this
      );

      final hasPerms = hasElementCallPermissions(
        granted,
        userId,
        deviceId,
      );

      expect(hasPerms, false);
    });
  });

  group('getMinimalElementCallPermissions', () {
    test('Returns minimal permissions for testing', () {
      final caps = getMinimalElementCallPermissions();

      expect(caps.read.length, 3);
      expect(caps.send.length, 2);
      expect(caps.requiresClient, true);
      expect(caps.updateDelayedEvent, false);
      expect(caps.sendDelayedEvent, false);
    });

    test('Includes basic room and call events', () {
      final caps = getMinimalElementCallPermissions();

      expect(
        caps.read.any((f) => f is StateWithType && f.eventType == 'm.room.name'),
        true,
      );
      expect(
        caps.read.any((f) => f is StateWithType && f.eventType == 'm.room.member'),
        true,
      );
      expect(
        caps.read.any((f) =>
            f is MessageLikeWithType && f.eventType == 'm.call.member'),
        true,
      );
    });
  });

  group('isElementCallEvent', () {
    test('Identifies Element Call event types', () {
      expect(isElementCallEvent('m.call.member'), true);
      expect(isElementCallEvent('m.call.notify'), true);
      expect(isElementCallEvent('org.matrix.msc3401.call.member'), true);
      expect(isElementCallEvent('org.matrix.msc4143.rtc.notify'), true);
      expect(isElementCallEvent('io.element.call.encryption_keys'), true);
    });

    test('Rejects non-Element Call events', () {
      expect(isElementCallEvent('m.room.message'), false);
      expect(isElementCallEvent('m.room.topic'), false);
      expect(isElementCallEvent('m.reaction'), false);
    });

    test('Works with prefixes', () {
      expect(isElementCallEvent('m.call.member.something'), true);
      expect(isElementCallEvent('io.element.call.custom'), true);
      expect(isElementCallEvent('org.matrix.msc3401.call.custom'), true);
    });
  });

  group('isElementCallCapability', () {
    test('Identifies Element Call capability strings', () {
      expect(isElementCallCapability('io.element.call.send'), true);
      expect(isElementCallCapability('org.matrix.msc3401.read'), true);
      expect(isElementCallCapability('org.matrix.msc4143.send'), true);
    });

    test('Identifies capabilities with event types', () {
      expect(isElementCallCapability('send.event:m.call.member'), true);
      expect(isElementCallCapability('read.state:m.call.member'), true);
      expect(isElementCallCapability('org.matrix.msc2762.send.event:rtc.notify'), true);
    });

    test('Rejects non-Element Call capabilities', () {
      expect(isElementCallCapability('send.event:m.room.message'), false);
      expect(isElementCallCapability('read.state:m.room.topic'), false);
    });
  });

  group('Device pattern support', () {
    test('StateWithTypeAndStateKey supports template variables', () {
      const filter = StateWithTypeAndStateKey(
        'm.call.member',
        '{userId}_{deviceId}',
      );

      expect(filter.hasTemplateVariables, true);
      expect(
        filter.expandStateKey(
          userId: '@user:example.com',
          deviceId: 'DEVICE123',
        ),
        '@user:example.com_DEVICE123',
      );
    });

    test('StateWithTypeAndStateKey expands multiple patterns', () {
      const patterns = [
        StateWithTypeAndStateKey('m.call.member', '{userId}'),
        StateWithTypeAndStateKey('m.call.member', '{userId}_{deviceId}'),
        StateWithTypeAndStateKey('m.call.member', '_{userId}_{deviceId}_m.call'),
      ];

      final expanded = patterns.map((p) => p.expandStateKey(
            userId: '@user:example.com',
            deviceId: 'DEVICE123',
          ));

      expect(expanded.toList(), [
        '@user:example.com',
        '@user:example.com_DEVICE123',
        '_@user:example.com_DEVICE123_m.call',
      ]);
    });

    test('StateWithTypeAndStateKey matchesWithContext', () {
      const filter = StateWithTypeAndStateKey(
        'm.call.member',
        '{userId}_{deviceId}',
      );

      final event = MatrixEvent(
        type: 'm.call.member',
        content: {},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime.now(),
        stateKey: '@user:example.com_DEVICE123',
      );

      // Should match with correct context
      expect(
        filter.matchesWithContext(
          event,
          userId: '@user:example.com',
          deviceId: 'DEVICE123',
        ),
        true,
      );

      // Should not match with wrong context
      expect(
        filter.matchesWithContext(
          event,
          userId: '@other:example.com',
          deviceId: 'DEVICE123',
        ),
        false,
      );
    });
  });
}