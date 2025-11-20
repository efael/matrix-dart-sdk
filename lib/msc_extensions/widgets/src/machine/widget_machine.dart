import 'package:matrix/msc_extensions/widgets/src/api/from_widget_messages.dart';
import 'package:matrix/msc_extensions/widgets/src/api/message_types.dart';
import 'package:matrix/msc_extensions/widgets/src/api/to_widget_messages.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/capabilities.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/capability_parser.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';
import 'package:matrix/msc_extensions/widgets/src/models/openid.dart'
    as widget_openid;
import 'package:matrix/msc_extensions/widgets/src/models/pending_requests.dart';

/// Capability negotiation state.
enum CapabilityState {
  /// No capabilities have been requested or negotiated.
  unset,

  /// Capabilities have been requested and are awaiting user approval.
  negotiating,

  /// Capabilities have been approved and negotiated.
  negotiated,
}

/// Actions emitted by the state machine for the driver to execute.
sealed class WidgetAction {}

/// Send a message to the widget.
class SendToWidget extends WidgetAction {
  final String requestId;
  final String action;
  final Map<String, dynamic> data;

  SendToWidget({
    required this.requestId,
    required this.action,
    required this.data,
  });
}

/// Request user approval for capabilities.
class RequestCapabilities extends WidgetAction {
  final String requestId;
  final List<String> requested;

  RequestCapabilities({
    required this.requestId,
    required this.requested,
  });
}

/// Request OpenID credentials from user/homeserver.
class RequestOpenId extends WidgetAction {
  final String requestId;

  RequestOpenId({required this.requestId});
}

/// Send an event to the Matrix room.
class SendMatrixEvent extends WidgetAction {
  final String requestId;
  final String type;
  final Map<String, dynamic> content;
  final String? stateKey;

  SendMatrixEvent({
    required this.requestId,
    required this.type,
    required this.content,
    this.stateKey,
  });
}

/// Read events from the Matrix room.
class ReadMatrixEvents extends WidgetAction {
  final String requestId;
  final String? type;
  final String? stateKey;
  final int? limit;

  ReadMatrixEvents({
    required this.requestId,
    this.type,
    this.stateKey,
    this.limit,
  });
}

/// Send a to-device message.
class SendToDeviceMessage extends WidgetAction {
  final String requestId;
  final String type;
  final bool encrypted;
  final Map<String, Map<String, Map<String, dynamic>>> messages;

  SendToDeviceMessage({
    required this.requestId,
    required this.type,
    required this.encrypted,
    required this.messages,
  });
}

/// Update a delayed event.
class UpdateDelayedEvent extends WidgetAction {
  final String requestId;
  final String action;
  final String delayId;

  UpdateDelayedEvent({
    required this.requestId,
    required this.action,
    required this.delayId,
  });
}

/// Navigate to a URL.
class Navigate extends WidgetAction {
  final String requestId;
  final String uri;

  Navigate({
    required this.requestId,
    required this.uri,
  });
}

/// State of the widget state machine.
class WidgetMachineState {
  /// Current capability negotiation state.
  final CapabilityState capabilityState;

  /// Capabilities requested by the widget (before approval).
  final WidgetCapabilities? requestedCapabilities;

  /// Capabilities approved by the user.
  final WidgetCapabilities approvedCapabilities;

  /// Cached OpenID state.
  final widget_openid.OpenIdState? openIdState;

  /// Pending requests awaiting responses.
  final PendingRequests<String> pendingRequests;

  const WidgetMachineState({
    required this.capabilityState,
    this.requestedCapabilities,
    required this.approvedCapabilities,
    this.openIdState,
    required this.pendingRequests,
  });

  /// Create initial state.
  factory WidgetMachineState.initial() {
    return WidgetMachineState(
      capabilityState: CapabilityState.unset,
      approvedCapabilities: const WidgetCapabilities.empty(),
      pendingRequests: PendingRequests<String>(),
    );
  }

  WidgetMachineState copyWith({
    CapabilityState? capabilityState,
    WidgetCapabilities? requestedCapabilities,
    WidgetCapabilities? approvedCapabilities,
    widget_openid.OpenIdState? openIdState,
    PendingRequests<String>? pendingRequests,
  }) {
    return WidgetMachineState(
      capabilityState: capabilityState ?? this.capabilityState,
      requestedCapabilities:
          requestedCapabilities ?? this.requestedCapabilities,
      approvedCapabilities: approvedCapabilities ?? this.approvedCapabilities,
      openIdState: openIdState ?? this.openIdState,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }
}

/// Result of processing a message through the state machine.
class ProcessResult {
  final WidgetMachineState state;
  final List<WidgetAction> actions;

  const ProcessResult({
    required this.state,
    required this.actions,
  });
}

/// Widget state machine.
///
/// Pure state machine following no-I/O pattern from Rust SDK.
/// Processes messages and emits actions for driver to execute.
class WidgetMachine {
  WidgetMachineState _state;

  WidgetMachine({WidgetMachineState? initialState})
      : _state = initialState ?? WidgetMachineState.initial();

  WidgetMachineState get state => _state;

  /// Cleanup resources when the widget machine is disposed.
  void dispose() {
    _state.pendingRequests.clear();
  }

  /// Process an incoming message from the widget.
  ProcessResult processFromWidget(WidgetMessage message) {
    final actions = <WidgetAction>[];

    switch (message.action) {
      case 'supported_api_versions':
        actions.add(_handleSupportedApiVersions(message));
        break;

      case 'content_loaded':
        // Widget loaded, send capabilities if negotiated
        if (_state.capabilityState == CapabilityState.negotiated) {
          actions.add(_sendCapabilitiesResponse(message.requestId!));
        }
        break;

      case 'get_openid':
        final result = _handleGetOpenId(message);
        actions.addAll(result.actions);
        _state = result.state;
        break;

      case 'send_event':
        final req = SendEventRequest.fromJson(message.data);
        if (_canSendEvent(req.type, req.stateKey)) {
          actions.add(SendMatrixEvent(
            requestId: message.requestId!,
            type: req.type,
            content: req.content,
            stateKey: req.stateKey,
          ));
        } else {
          actions.add(_sendError(
            message.requestId!,
            'M_FORBIDDEN',
            'Widget lacks capability to send this event',
          ));
        }
        break;

      case 'read_events':
        final req = ReadEventsRequest.fromJson(message.data);
        if (_canReadEvent(req.type)) {
          actions.add(ReadMatrixEvents(
            requestId: message.requestId!,
            type: req.type,
            stateKey: req.stateKey,
            limit: req.limit,
          ));
        } else {
          actions.add(_sendError(
            message.requestId!,
            'M_FORBIDDEN',
            'Widget lacks capability to read this event',
          ));
        }
        break;

      case 'send_to_device':
        if (_state.approvedCapabilities.send.any((f) => f is ToDeviceWithType)) {
          final req = SendToDeviceRequest.fromJson(message.data);
          actions.add(SendToDeviceMessage(
            requestId: message.requestId!,
            type: req.type,
            encrypted: req.encrypted,
            messages: req.messages,
          ));
        } else {
          actions.add(_sendError(
            message.requestId!,
            'M_FORBIDDEN',
            'Widget lacks to_device capability',
          ));
        }
        break;

      case 'update_delayed_event':
        if (_state.approvedCapabilities.updateDelayedEvent) {
          final req = UpdateDelayedEventRequest.fromJson(message.data);
          actions.add(UpdateDelayedEvent(
            requestId: message.requestId!,
            action: req.action,
            delayId: req.delayId,
          ));
        } else {
          actions.add(_sendError(
            message.requestId!,
            'M_FORBIDDEN',
            'Widget lacks update_delayed_event capability',
          ));
        }
        break;

      case 'navigate':
        final req = NavigateRequest.fromJson(message.data);
        actions.add(Navigate(
          requestId: message.requestId!,
          uri: req.uri,
        ));
        break;

      default:
        // Unknown action
        if (message.requestId != null) {
          actions.add(_sendError(
            message.requestId!,
            'M_UNRECOGNIZED',
            'Unknown action: ${message.action}',
          ));
        }
    }

    return ProcessResult(state: _state, actions: actions);
  }

  /// Process capability approval from user.
  ProcessResult processCapabilityApproval(
    WidgetCapabilities approved,
    widget_openid.OpenIdResponse? openIdResponse,
  ) {
    final actions = <WidgetAction>[];

    _state = _state.copyWith(
      capabilityState: CapabilityState.negotiated,
      approvedCapabilities: approved,
    );

    // If there's a pending capabilities request, respond to it
    final pendingIds = _state.pendingRequests.pendingIds;
    final pending = pendingIds.isNotEmpty ? pendingIds.first : null;
    if (pending != null) {
      final requestId = _state.pendingRequests.extract(pending);
      if (requestId != null) {
        actions.add(_sendCapabilitiesResponse(requestId));
      }
    }

    // Handle OpenID if provided
    if (openIdResponse != null && openIdResponse is widget_openid.OpenIdAllowed) {
      _state = _state.copyWith(openIdState: openIdResponse.state);

      // Find pending OpenID request
      final pendingOpenIdList = _state.pendingRequests.pendingIds
          .where((id) => id.startsWith('openid:'))
          .toList();
      final pendingOpenId = pendingOpenIdList.isNotEmpty ? pendingOpenIdList.first : null;
      if (pendingOpenId != null) {
        final requestId = _state.pendingRequests.extract(pendingOpenId);
        if (requestId != null) {
          actions.add(_sendOpenIdResponse(
            requestId.replaceFirst('openid:', ''),
            openIdResponse,
          ));
        }
      }
    }

    return ProcessResult(state: _state, actions: actions);
  }

  WidgetAction _handleSupportedApiVersions(WidgetMessage message) {
    return SendToWidget(
      requestId: message.requestId!,
      action: 'supported_api_versions',
      data: SupportedApiVersionsResponse(
        supportedVersions: supportedApiVersions,
      ).toJson(),
    );
  }

  ProcessResult _handleGetOpenId(WidgetMessage message) {
    final actions = <WidgetAction>[];

    // Check if we have cached OpenID that's still valid
    if (_state.openIdState != null && !_state.openIdState!.isExpired) {
      actions.add(_sendOpenIdResponse(
        message.requestId!,
        widget_openid.OpenIdAllowed(_state.openIdState!),
      ));
      return ProcessResult(state: _state, actions: actions);
    }

    // Need to request new OpenID
    _state.pendingRequests.insert('openid:${message.requestId}', message.requestId!);
    actions.add(RequestOpenId(requestId: message.requestId!));

    return ProcessResult(state: _state, actions: actions);
  }

  bool _canSendEvent(String type, String? stateKey) {
    return _state.approvedCapabilities.canSendEventType(type, stateKey: stateKey);
  }

  bool _canReadEvent(String? type) {
    if (type == null) return true; // No filter means read all allowed
    return _state.approvedCapabilities.read
        .any((filter) => filter.toCapabilityString().startsWith(type));
  }

  WidgetAction _sendCapabilitiesResponse(String requestId) {
    return SendToWidget(
      requestId: requestId,
      action: 'capabilities',
      data: CapabilitiesResponse(
        capabilities: _state.approvedCapabilities,
      ).toJson(),
    );
  }

  WidgetAction _sendOpenIdResponse(
    String requestId,
    widget_openid.OpenIdResponse response,
  ) {
    return SendToWidget(
      requestId: requestId,
      action: 'openid_credentials',
      data: OpenIdCredentialsResponse(state: response).toJson(),
    );
  }

  WidgetAction _sendError(String requestId, String code, String message) {
    return SendToWidget(
      requestId: requestId,
      action: 'error',
      data: WidgetError(
        code: code,
        message: message,
      ).toJson(),
    );
  }
}
