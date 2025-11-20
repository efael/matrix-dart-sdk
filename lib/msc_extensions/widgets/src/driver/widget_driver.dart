import 'dart:async';
import 'dart:convert';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/api/message_types.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/capabilities.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/capability_provider.dart';
import 'package:matrix/msc_extensions/widgets/src/driver/matrix_driver.dart';
import 'package:matrix/msc_extensions/widgets/src/machine/widget_machine.dart';
import 'package:matrix/msc_extensions/widgets/src/models/openid.dart'
    as widget_openid;
import 'package:matrix/msc_extensions/widgets/src/models/widget_settings.dart';
import 'package:matrix/msc_extensions/widgets/src/transport/widget_transport.dart';

/// Main widget driver orchestrating communication between widget and Matrix.
///
/// Combines WidgetMachine, MatrixDriver, and WidgetTransport to provide
/// complete widget functionality.
class WidgetDriver {
  final Client client;
  final Room room;
  final WidgetSettings settings;
  final WidgetTransport transport;
  final CapabilityProvider? capabilityProvider;

  late final WidgetMachine _machine;
  late final MatrixDriver _matrixDriver;

  StreamSubscription<String>? _transportSubscription;
  StreamSubscription<String>? _timelineSubscription;
  StreamSubscription<SyncUpdate>? _syncSubscription;

  bool _disposed = false;

  WidgetDriver({
    required this.client,
    required this.room,
    required this.settings,
    required this.transport,
    this.capabilityProvider,
  }) {
    _machine = WidgetMachine();
    _matrixDriver = MatrixDriver(client: client, room: room);
    _startListening();
  }

  /// Start listening to transport and room events.
  void _startListening() {
    // Listen to incoming messages from widget
    _transportSubscription = transport.incoming.listen(
      _handleIncomingMessage,
      onError: (error) {
        // Handle transport errors
      },
    );

    // Listen to timeline events for forwarding to widget
    _timelineSubscription = room.onUpdate.stream.listen((update) {
      _handleRoomUpdate();
    });
  }

  /// Handle incoming message from widget.
  Future<void> _handleIncomingMessage(String rawMessage) async {
    if (_disposed) return;

    try {
      final json = jsonDecode(rawMessage) as Map<String, dynamic>;
      final message = WidgetMessage.fromJson(json);

      // Process through state machine
      final result = _machine.processFromWidget(message);

      // Execute actions
      for (final action in result.actions) {
        await _executeAction(action);
      }
    } catch (e) {
      // Invalid message format, ignore
    }
  }

  /// Execute an action emitted by the state machine.
  Future<void> _executeAction(WidgetAction action) async {
    if (_disposed) return;

    try {
      switch (action) {
        case SendToWidget():
          _sendToWidget(action);
          break;

        case RequestCapabilities():
          await _handleCapabilityRequest(action);
          break;

        case RequestOpenId():
          await _handleOpenIdRequest(action);
          break;

        case SendMatrixEvent():
          await _handleSendEvent(action);
          break;

        case ReadMatrixEvents():
          await _handleReadEvents(action);
          break;

        case SendToDeviceMessage():
          await _handleSendToDevice(action);
          break;

        case UpdateDelayedEvent():
          await _handleUpdateDelayedEvent(action);
          break;

        case Navigate():
          await _handleNavigate(action);
          break;
      }
    } catch (e) {
      // Send error response
      if (action is! SendToWidget) {
        _sendError(_getRequestId(action), 'M_UNKNOWN', 'Action failed: $e');
      }
    }
  }

  String _getRequestId(WidgetAction action) {
    return switch (action) {
      SendToWidget() => action.requestId,
      RequestCapabilities() => action.requestId,
      RequestOpenId() => action.requestId,
      SendMatrixEvent() => action.requestId,
      ReadMatrixEvents() => action.requestId,
      SendToDeviceMessage() => action.requestId,
      UpdateDelayedEvent() => action.requestId,
      Navigate() => action.requestId,
    };
  }

  void _sendToWidget(SendToWidget action) {
    final message = WidgetMessage(
      api: MessageDirection.toWidget,
      requestId: action.requestId,
      widgetId: settings.widgetId,
      action: action.action,
      data: action.data,
    );

    transport.send(jsonEncode(message.toJson()));
  }

  Future<void> _handleCapabilityRequest(RequestCapabilities action) async {
    if (capabilityProvider == null) {
      // No provider, deny all
      final result = _machine.processCapabilityApproval(
        const WidgetCapabilities.empty(),
        null,
      );

      for (final responseAction in result.actions) {
        await _executeAction(responseAction);
      }
      return;
    }

    // Request user approval
    final request = CapabilityRequest(
      requested: action.requested,
      widgetId: settings.widgetId,
      widgetName: null,
      requestsOpenId: false,
    );

    final response = await capabilityProvider!.acquireCapabilities(request);

    // Process approval
    final result = _machine.processCapabilityApproval(
      response.approved,
      response.openId,
    );

    for (final responseAction in result.actions) {
      await _executeAction(responseAction);
    }
  }

  Future<void> _handleOpenIdRequest(RequestOpenId action) async {
    try {
      final response = await _matrixDriver.getOpenIdCredentials();

      if (response.state is widget_openid.OpenIdAllowed) {
        final allowed = response.state as widget_openid.OpenIdAllowed;
        final result = _machine.processCapabilityApproval(
          _machine.state.approvedCapabilities,
          widget_openid.OpenIdAllowed(allowed.state),
        );

        for (final responseAction in result.actions) {
          await _executeAction(responseAction);
        }
      } else {
        _sendError(action.requestId, 'M_FORBIDDEN', 'OpenID request denied');
      }
    } catch (e) {
      _sendError(action.requestId, 'M_UNKNOWN', 'Failed to get OpenID: $e');
    }
  }

  Future<void> _handleSendEvent(SendMatrixEvent action) async {
    try {
      final response = await _matrixDriver.sendEvent(action);
      _sendToWidget(SendToWidget(
        requestId: action.requestId,
        action: 'send_event',
        data: response.toJson(),
      ));
    } catch (e) {
      _sendError(action.requestId, 'M_UNKNOWN', 'Failed to send event: $e');
    }
  }

  Future<void> _handleReadEvents(ReadMatrixEvents action) async {
    try {
      final response = await _matrixDriver.readEvents(action);
      _sendToWidget(SendToWidget(
        requestId: action.requestId,
        action: 'read_events',
        data: response.toJson(),
      ));
    } catch (e) {
      _sendError(action.requestId, 'M_UNKNOWN', 'Failed to read events: $e');
    }
  }

  Future<void> _handleSendToDevice(SendToDeviceMessage action) async {
    try {
      final response = await _matrixDriver.sendToDevice(action);
      _sendToWidget(SendToWidget(
        requestId: action.requestId,
        action: 'send_to_device',
        data: response.toJson(),
      ));
    } catch (e) {
      _sendError(action.requestId, 'M_UNKNOWN', 'Failed to send to-device: $e');
    }
  }

  Future<void> _handleUpdateDelayedEvent(UpdateDelayedEvent action) async {
    // MSC4157 not implemented in SDK yet
    _sendError(action.requestId, 'M_UNRECOGNIZED', 'Delayed events not supported');
  }

  Future<void> _handleNavigate(Navigate action) async {
    // Navigation is application-specific
    // Just acknowledge for now
    _sendToWidget(SendToWidget(
      requestId: action.requestId,
      action: 'navigate',
      data: {},
    ));
  }

  void _sendError(String requestId, String code, String message) {
    _sendToWidget(SendToWidget(
      requestId: requestId,
      action: 'error',
      data: {
        'code': code,
        'message': message,
      },
    ));
  }

  /// Handle room updates for event forwarding.
  void _handleRoomUpdate() {
    if (_disposed) return;

    // Forward new events to widget based on capabilities
    final readFilters = _machine.state.approvedCapabilities.read;

    // Note: Full implementation would track seen events and only forward new ones
    // This is a simplified version
  }

  /// Dispose the driver and clean up resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _transportSubscription?.cancel();
    _timelineSubscription?.cancel();
    _syncSubscription?.cancel();
    _machine.dispose();
    transport.dispose();
  }

  /// Get current capability state.
  CapabilityState get capabilityState => _machine.state.capabilityState;

  /// Get approved capabilities.
  WidgetCapabilities get approvedCapabilities =>
      _machine.state.approvedCapabilities;
}

/// Handle for controlling a widget driver.
class WidgetDriverHandle {
  final WidgetDriver _driver;

  WidgetDriverHandle._(this._driver);

  /// Get current capability state.
  CapabilityState get capabilityState => _driver.capabilityState;

  /// Get approved capabilities.
  WidgetCapabilities get approvedCapabilities => _driver.approvedCapabilities;

  /// Dispose the driver.
  void dispose() => _driver.dispose();

  /// Create a driver handle.
  static WidgetDriverHandle create({
    required Client client,
    required Room room,
    required WidgetSettings settings,
    required WidgetTransport transport,
    CapabilityProvider? capabilityProvider,
  }) {
    final driver = WidgetDriver(
      client: client,
      room: room,
      settings: settings,
      transport: transport,
      capabilityProvider: capabilityProvider,
    );

    return WidgetDriverHandle._(driver);
  }
}

/// Extension on Room for widget convenience.
extension RoomWidgetExtension on Room {
  /// Create a widget driver for this room.
  WidgetDriverHandle createWidgetDriver({
    required WidgetSettings settings,
    required WidgetTransport transport,
    CapabilityProvider? capabilityProvider,
  }) {
    return WidgetDriverHandle.create(
      client: client,
      room: this,
      settings: settings,
      transport: transport,
      capabilityProvider: capabilityProvider,
    );
  }
}
