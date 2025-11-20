import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';
import 'package:matrix/msc_extensions/widgets/src/machine/widget_machine.dart';
import 'package:matrix/msc_extensions/widgets/src/models/openid.dart'
    as widget_openid;

void main() {
  group('WidgetMachineState', () {
    test('Create initial state', () {
      final state = WidgetMachineState.initial();

      expect(state.capabilityState, CapabilityState.unset);
      expect(state.requestedCapabilities, isNull);
      expect(state.approvedCapabilities.read, isEmpty);
      expect(state.approvedCapabilities.send, isEmpty);
      expect(state.openIdState, isNull);
      expect(state.pendingRequests.count, 0);
    });

    test('copyWith updates fields', () {
      final state = WidgetMachineState.initial();
      final updated = state.copyWith(
        capabilityState: CapabilityState.negotiated,
        approvedCapabilities: const WidgetCapabilities(
          read: [MessageLikeWithType('m.room.message')],
        ),
      );

      expect(updated.capabilityState, CapabilityState.negotiated);
      expect(updated.approvedCapabilities.read.length, 1);
      expect(state.capabilityState, CapabilityState.unset);
    });
  });

  group('WidgetMachine', () {
    test('Initial state is unset', () {
      final machine = WidgetMachine();

      expect(machine.state.capabilityState, CapabilityState.unset);
      expect(machine.state.approvedCapabilities.read, isEmpty);
    });

    test('Process supported_api_versions request', () {
      final machine = WidgetMachine();
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'supported_api_versions',
        data: {},
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.requestId, 'req_1');
      expect(action.action, 'supported_api_versions');
      expect(action.data['supported_versions'], isA<List>());
    });

    test('Process content_loaded when not negotiated does nothing', () {
      final machine = WidgetMachine();
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        widgetId: 'widget_1',
        action: 'content_loaded',
        data: {},
      );

      final result = machine.processFromWidget(message);

      expect(result.actions, isEmpty);
    });

    test('Process content_loaded when negotiated sends capabilities', () {
      final machine = WidgetMachine();
      final approved = const WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
      );

      // Negotiate capabilities first
      machine.processCapabilityApproval(approved, null);

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'content_loaded',
        data: {},
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.action, 'capabilities');
    });

    test('Process get_openid with cached valid token', () {
      final credentials = widget_openid.OpenIdCredentials(
        accessToken: 'token123',
        expiresIn: const Duration(hours: 1),
        matrixServerName: 'matrix.example.com',
      );
      final openIdState = widget_openid.OpenIdState(
        originalRequestId: 'req_0',
        credentials: credentials,
      );

      final machine = WidgetMachine(
        initialState: WidgetMachineState.initial().copyWith(
          openIdState: openIdState,
        ),
      );

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'get_openid',
        data: {},
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.action, 'openid_credentials');
      expect(action.data['state'], 'allowed');
      expect(action.data['access_token'], 'token123');
    });

    test('Process get_openid without cached token requests new', () {
      final machine = WidgetMachine();
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'get_openid',
        data: {},
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<RequestOpenId>());
      final action = result.actions[0] as RequestOpenId;
      expect(action.requestId, 'req_1');
    });

    test('Process send_event with permission', () {
      final approved = const WidgetCapabilities(
        send: [MessageLikeWithType('m.room.message')],
      );
      final machine = WidgetMachine();
      machine.processCapabilityApproval(approved, null);

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'send_event',
        data: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Hello'},
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendMatrixEvent>());
      final action = result.actions[0] as SendMatrixEvent;
      expect(action.type, 'm.room.message');
      expect(action.content['body'], 'Hello');
    });

    test('Process send_event without permission returns error', () {
      final machine = WidgetMachine();
      machine.processCapabilityApproval(
        const WidgetCapabilities.empty(),
        null,
      );

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'send_event',
        data: {
          'type': 'm.room.message',
          'content': {'msgtype': 'm.text', 'body': 'Hello'},
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.action, 'error');
      expect(action.data['code'], 'M_FORBIDDEN');
    });

    test('Process read_events with permission', () {
      final approved = const WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
      );
      final machine = WidgetMachine();
      machine.processCapabilityApproval(approved, null);

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'read_events',
        data: {
          'type': 'm.room.message',
          'limit': 50,
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<ReadMatrixEvents>());
      final action = result.actions[0] as ReadMatrixEvents;
      expect(action.type, 'm.room.message');
      expect(action.limit, 50);
    });

    test('Process read_events without permission returns error', () {
      final machine = WidgetMachine();
      machine.processCapabilityApproval(
        const WidgetCapabilities.empty(),
        null,
      );

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'read_events',
        data: {
          'type': 'm.room.message',
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.action, 'error');
      expect(action.data['code'], 'M_FORBIDDEN');
    });

    test('Process send_to_device with permission', () {
      final approved = const WidgetCapabilities(
        send: [ToDeviceWithType('m.room_key')],
      );
      final machine = WidgetMachine();
      machine.processCapabilityApproval(approved, null);

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'send_to_device',
        data: {
          'type': 'm.room_key',
          'encrypted': true,
          'messages': {
            '@alice:example.com': {
              'DEVICE1': {'foo': 'bar'},
            },
          },
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToDeviceMessage>());
      final action = result.actions[0] as SendToDeviceMessage;
      expect(action.type, 'm.room_key');
      expect(action.encrypted, true);
    });

    test('Process send_to_device without permission returns error', () {
      final machine = WidgetMachine();
      machine.processCapabilityApproval(
        const WidgetCapabilities.empty(),
        null,
      );

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'send_to_device',
        data: {
          'type': 'm.room_key',
          'encrypted': true,
          'messages': {},
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.action, 'error');
      expect(action.data['code'], 'M_FORBIDDEN');
    });

    test('Process update_delayed_event with permission', () {
      final approved = const WidgetCapabilities(
        updateDelayedEvent: true,
      );
      final machine = WidgetMachine();
      machine.processCapabilityApproval(approved, null);

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'update_delayed_event',
        data: {
          'action': 'cancel',
          'delay_id': 'delay_123',
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<UpdateDelayedEvent>());
      final action = result.actions[0] as UpdateDelayedEvent;
      expect(action.action, 'cancel');
      expect(action.delayId, 'delay_123');
    });

    test('Process update_delayed_event without permission returns error', () {
      final machine = WidgetMachine();
      machine.processCapabilityApproval(
        const WidgetCapabilities.empty(),
        null,
      );

      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'update_delayed_event',
        data: {
          'action': 'cancel',
          'delay_id': 'delay_123',
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.action, 'error');
      expect(action.data['code'], 'M_FORBIDDEN');
    });

    test('Process navigate', () {
      final machine = WidgetMachine();
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'navigate',
        data: {
          'uri': 'https://example.com',
        },
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<Navigate>());
      final action = result.actions[0] as Navigate;
      expect(action.uri, 'https://example.com');
    });

    test('Process unknown action returns error', () {
      final machine = WidgetMachine();
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_1',
        widgetId: 'widget_1',
        action: 'unknown_action',
        data: {},
      );

      final result = machine.processFromWidget(message);

      expect(result.actions.length, 1);
      expect(result.actions[0], isA<SendToWidget>());
      final action = result.actions[0] as SendToWidget;
      expect(action.action, 'error');
      expect(action.data['code'], 'M_UNRECOGNIZED');
    });

    test('Process capability approval updates state', () {
      final machine = WidgetMachine();
      final approved = const WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
      );

      final result = machine.processCapabilityApproval(approved, null);

      expect(result.state.capabilityState, CapabilityState.negotiated);
      expect(result.state.approvedCapabilities.read.length, 1);
    });

    test('Process capability approval with OpenID', () {
      final machine = WidgetMachine();
      final approved = const WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
      );
      final credentials = widget_openid.OpenIdCredentials(
        accessToken: 'token123',
        expiresIn: const Duration(hours: 1),
        matrixServerName: 'matrix.example.com',
      );
      final openIdState = widget_openid.OpenIdState(
        originalRequestId: 'req_1',
        credentials: credentials,
      );

      final result = machine.processCapabilityApproval(
        approved,
        widget_openid.OpenIdAllowed(openIdState),
      );

      expect(result.state.openIdState, isNotNull);
      expect(result.state.openIdState!.credentials.accessToken, 'token123');
    });
  });
}
