import 'dart:convert';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/api/from_widget_messages.dart';
import 'package:matrix/msc_extensions/widgets/src/api/to_widget_messages.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';
import 'package:matrix/msc_extensions/widgets/src/driver/filter_cache.dart';
import 'package:matrix/msc_extensions/widgets/src/errors/widget_exceptions.dart';
import 'package:matrix/msc_extensions/widgets/src/machine/widget_machine.dart';
import 'package:matrix/msc_extensions/widgets/src/models/openid.dart'
    as widget_openid;

/// Filters sensitive crypto events that should never be exposed to widgets.
///
/// Based on Rust SDK crypto event filtering:
/// - m.room_key.* (room encryption keys)
/// - m.room_key_request.* (key requests)
/// - m.forwarded_room_key.* (forwarded keys)
/// - m.secret.* (secret storage)
/// - m.room.encrypted (encrypted content)
///
/// Uses OptimizedCryptoEventFilter for better performance.
class CryptoEventFilter {
  /// Check if event type is a crypto event that should be filtered.
  static bool isCryptoEvent(String eventType) {
    return OptimizedCryptoEventFilter.isCryptoEvent(eventType);
  }

  /// Filter crypto events from a list of events.
  static List<MatrixEvent> filterEvents(List<MatrixEvent> events) {
    return OptimizedCryptoEventFilter.filterEvents(events);
  }
}

/// Driver for Matrix operations requested by widgets.
///
/// Executes actions emitted by WidgetMachine and interfaces with Matrix SDK.
class MatrixDriver {
  final Client client;
  final Room room;

  /// Cached filter for optimized event matching
  FilterCache? _filterCache;

  MatrixDriver({
    required this.client,
    required this.room,
  });

  /// Execute a SendMatrixEvent action.
  Future<SendEventResponse> sendEvent(SendMatrixEvent action) async {
    // Filter crypto events
    if (CryptoEventFilter.isCryptoEvent(action.type)) {
      throw SecurityViolationException.cryptoEvent(action.type);
    }

    String eventId;
    if (action.stateKey != null) {
      // Send state event
      eventId = await client.setRoomStateWithKey(
        room.id,
        action.type,
        action.stateKey!,
        action.content,
      );
    } else {
      // Send message-like event
      final result = await room.sendEvent(
        action.content,
        type: action.type,
      );
      eventId = result ?? '';
    }

    return SendEventResponse(
      eventId: eventId,
      roomId: room.id,
    );
  }

  /// Execute a ReadMatrixEvents action.
  Future<ReadEventsResponse> readEvents(ReadMatrixEvents action) async {
    final events = <MatrixEvent>[];

    if (action.stateKey != null && action.type != null) {
      // Read specific state event
      final state = room.getState(action.type!, action.stateKey!);
      if (state != null) {
        // Convert StrippedStateEvent to MatrixEvent
        events.add(MatrixEvent(
          type: state.type,
          content: state.content,
          senderId: state.senderId ?? '',
          stateKey: state.stateKey,
          eventId: '\$state:${state.type}:${state.stateKey}',
          originServerTs: DateTime.now(),
        ));
      }
    } else {
      // Read from timeline (needs Timeline instance - not directly accessible)
      // For now, read from recent events in the room
      // This is a simplified implementation - full impl would need Timeline
      final recentEvents = <MatrixEvent>[];

      // Get events from room state that match the filter
      if (action.type != null) {
        for (final state in room.states.values) {
          for (final event in state.values) {
            if (event.type == action.type) {
              events.add(MatrixEvent(
                type: event.type,
                content: event.content,
                senderId: event.senderId ?? '',
                stateKey: event.stateKey,
                eventId: '\$state:${event.type}:${event.stateKey}',
                originServerTs: DateTime.now(),
              ));
            }
          }
        }
      }
    }

    // Filter crypto events
    final filtered = CryptoEventFilter.filterEvents(events);

    return ReadEventsResponse(events: filtered.take(action.limit ?? 50).toList());
  }

  /// Execute a SendToDeviceMessage action.
  Future<SendToDeviceResponse> sendToDevice(SendToDeviceMessage action) async {
    // Filter crypto events
    if (CryptoEventFilter.isCryptoEvent(action.type)) {
      throw SecurityViolationException.cryptoEvent(action.type);
    }

    await client.sendToDevice(
      action.type,
      client.generateUniqueTransactionId(),
      action.messages,
    );

    return const SendToDeviceResponse();
  }

  /// Get OpenID credentials from homeserver.
  Future<OpenIdCredentialsResponse> getOpenIdCredentials() async {
    try {
      final credentials = await client.requestOpenIdToken(
        client.userID!,
        {},
      );

      final openIdCreds = widget_openid.OpenIdCredentials(
        accessToken: credentials.accessToken,
        expiresIn: Duration(seconds: credentials.expiresIn),
        matrixServerName: credentials.matrixServerName,
        tokenType: credentials.tokenType,
      );

      final state = widget_openid.OpenIdState(
        originalRequestId: '',
        credentials: openIdCreds,
      );

      return OpenIdCredentialsResponse(
        state: widget_openid.OpenIdAllowed(state),
      );
    } catch (e) {
      return OpenIdCredentialsResponse(
        state: const widget_openid.OpenIdBlocked(),
      );
    }
  }

  /// Check if an event should be forwarded to the widget.
  bool shouldForwardEvent(
    MatrixEvent event,
    List<WidgetEventFilter> readFilters,
  ) {
    // Never forward crypto events
    if (CryptoEventFilter.isCryptoEvent(event.type)) {
      return false;
    }

    // Create or update filter cache if needed
    if (_filterCache == null) {
      _filterCache = FilterCache(readFilters);
    }

    // Use optimized filter cache for matching
    return _filterCache!.matches(event);
  }

  /// Update the filter cache when filters change.
  void updateFilterCache(List<WidgetEventFilter> readFilters) {
    _filterCache = FilterCache(readFilters);
  }

  /// Create NotifyNewEventNotification for timeline events.
  NotifyNewEventNotification? createEventNotification(
    MatrixEvent event,
    List<WidgetEventFilter> readFilters,
  ) {
    if (!shouldForwardEvent(event, readFilters)) {
      return null;
    }

    return NotifyNewEventNotification(event: event);
  }

  /// Create NotifyStateUpdateNotification for state events.
  NotifyStateUpdateNotification? createStateNotification(
    MatrixEvent event,
    List<WidgetEventFilter> readFilters,
  ) {
    if (!shouldForwardEvent(event, readFilters)) {
      return null;
    }

    return NotifyStateUpdateNotification(event: event);
  }
}
