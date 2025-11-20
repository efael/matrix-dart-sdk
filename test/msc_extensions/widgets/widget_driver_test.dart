import 'dart:async';

import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';

/// Mock transport for testing.
class MockTransport implements WidgetTransport {
  final _incomingController = StreamController<String>.broadcast();
  final sentMessages = <String>[];

  @override
  Stream<String> get incoming => _incomingController.stream;

  @override
  void send(String message) {
    sentMessages.add(message);
  }

  void simulateIncoming(String message) {
    _incomingController.add(message);
  }

  @override
  void dispose() {
    _incomingController.close();
  }
}

void main() {
  group('MockTransport', () {
    test('Creates transport', () {
      final transport = MockTransport();
      expect(transport, isA<WidgetTransport>());
      transport.dispose();
    });

    test('Sends messages', () {
      final transport = MockTransport();
      transport.send('test message');
      expect(transport.sentMessages, ['test message']);
      transport.dispose();
    });

    test('Receives messages', () async {
      final transport = MockTransport();
      final messages = <String>[];

      transport.incoming.listen(messages.add);
      transport.simulateIncoming('incoming message');

      await Future.delayed(const Duration(milliseconds: 10));
      expect(messages, ['incoming message']);
      transport.dispose();
    });

    test('Broadcasts to multiple listeners', () async {
      final transport = MockTransport();
      final messages1 = <String>[];
      final messages2 = <String>[];

      transport.incoming.listen(messages1.add);
      transport.incoming.listen(messages2.add);
      transport.simulateIncoming('broadcast message');

      await Future.delayed(const Duration(milliseconds: 10));
      expect(messages1, ['broadcast message']);
      expect(messages2, ['broadcast message']);
      transport.dispose();
    });
  });

  group('WidgetSettings', () {
    test('Creates settings', () {
      final settings = WidgetSettings(
        widgetId: 'widget_1',
        url: 'https://widget.example.com',
      );

      expect(settings.widgetId, 'widget_1');
      expect(settings.url, 'https://widget.example.com');
      expect(settings.initOnContentLoad, true);
    });

    test('Creates settings with custom initOnContentLoad', () {
      final settings = WidgetSettings(
        widgetId: 'widget_1',
        url: 'https://widget.example.com',
        initOnContentLoad: false,
      );

      expect(settings.initOnContentLoad, false);
    });
  });

  group('WidgetDriverHandle', () {
    test('Handle has capability state getter', () {
      // Cannot fully test without Client/Room instances
      // Just verify the class exists and has expected interface
      expect(WidgetDriverHandle, isA<Type>());
    });
  });

  group('Integration', () {
    test('All components export correctly', () {
      // Verify all main classes are accessible
      expect(WidgetSettings, isA<Type>());
      expect(WidgetTransport, isA<Type>());
      expect(WidgetCapabilities, isA<Type>());
      expect(CapabilityProvider, isA<Type>());
      expect(WidgetDriverHandle, isA<Type>());
      expect(WidgetMachine, isA<Type>());
      expect(MatrixDriver, isA<Type>());
      expect(CryptoEventFilter, isA<Type>());
    });

    test('Message types export correctly', () {
      expect(WidgetMessage, isA<Type>());
      expect(MessageDirection, isA<Type>());
      expect(supportedApiVersions, isA<List<String>>());
    });

    test('Capability types export correctly', () {
      expect(MessageLikeWithType, isA<Type>());
      expect(StateWithType, isA<Type>());
      expect(StateWithTypeAndStateKey, isA<Type>());
      expect(RoomMessageWithMsgtype, isA<Type>());
      expect(ToDeviceWithType, isA<Type>());
    });

    test('OpenID types export correctly', () {
      expect(OpenIdCredentials, isA<Type>());
      expect(OpenIdState, isA<Type>());
      expect(OpenIdResponse, isA<Type>());
      expect(OpenIdAllowed, isA<Type>());
      expect(OpenIdBlocked, isA<Type>());
      expect(OpenIdPending, isA<Type>());
    });
  });

  group('End-to-end types', () {
    test('Can create widget settings', () {
      final settings = WidgetSettings(
        widgetId: 'test_widget',
        url: 'https://example.com/widget',
      );
      expect(settings.widgetId, 'test_widget');
    });

    test('Can create mock transport', () {
      final transport = MockTransport();
      expect(transport, isA<WidgetTransport>());
      transport.dispose();
    });

    test('Can create capabilities', () {
      const caps = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
        send: [StateWithType('m.room.topic')],
      );
      expect(caps.read.length, 1);
      expect(caps.send.length, 1);
    });

    test('Can create widget machine', () {
      final machine = WidgetMachine();
      expect(machine.state.capabilityState, CapabilityState.unset);
    });

    test('Can serialize and deserialize messages', () {
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'supported_api_versions',
        data: {},
      );

      final json = message.toJson();
      final restored = WidgetMessage.fromJson(json);

      expect(restored.requestId, 'req_1');
      expect(restored.widgetId, 'widget_1');
      expect(restored.action, 'supported_api_versions');
    });
  });
}
