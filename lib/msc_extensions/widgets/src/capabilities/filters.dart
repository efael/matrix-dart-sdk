import 'package:matrix/matrix.dart';

/// Base class for event filters used in widget capabilities.
///
/// Filters determine which events a widget can read or send based on
/// event type and other criteria.
sealed class WidgetEventFilter {
  const WidgetEventFilter();

  /// Check if this filter matches the given event.
  bool matches(MatrixEvent event);

  /// Convert filter to capability string format.
  ///
  /// Returns the capability identifier string (e.g., "m.room.message").
  String toCapabilityString();
}

/// Filter for message-like events (timeline events).
///
/// These are events that appear in the room timeline but are not state events.
sealed class MessageLikeEventFilter extends WidgetEventFilter {
  const MessageLikeEventFilter();
}

/// Matches message-like events by type prefix.
///
/// Example: WithType("m.room.message") matches all m.room.message events.
class MessageLikeWithType extends MessageLikeEventFilter {
  final String eventType;

  const MessageLikeWithType(this.eventType);

  @override
  bool matches(MatrixEvent event) {
    // Match if event type starts with the filter type
    // and event has no state_key (message-like, not state)
    return event.stateKey == null && event.type.startsWith(eventType);
  }

  @override
  String toCapabilityString() => eventType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageLikeWithType && eventType == other.eventType;

  @override
  int get hashCode => eventType.hashCode;
}

/// Matches m.room.message events with a specific msgtype.
///
/// Example: RoomMessageWithMsgtype("m.text") matches m.room.message events
/// where content.msgtype is "m.text".
class RoomMessageWithMsgtype extends MessageLikeEventFilter {
  final String msgtype;

  const RoomMessageWithMsgtype(this.msgtype);

  @override
  bool matches(MatrixEvent event) {
    if (event.stateKey != null) return false; // Must be message-like
    if (event.type != 'm.room.message') return false;

    final contentMsgtype = event.content['msgtype'];
    return contentMsgtype == msgtype;
  }

  @override
  String toCapabilityString() => 'm.room.message#$msgtype';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomMessageWithMsgtype && msgtype == other.msgtype;

  @override
  int get hashCode => msgtype.hashCode;
}

/// Filter for state events.
///
/// State events have a state_key and represent room state.
sealed class StateEventFilter extends WidgetEventFilter {
  const StateEventFilter();
}

/// Matches state events by type, ignoring state_key.
///
/// Example: WithType("m.room.topic") matches all m.room.topic state events
/// regardless of state_key.
class StateWithType extends StateEventFilter {
  final String eventType;

  const StateWithType(this.eventType);

  @override
  bool matches(MatrixEvent event) {
    // Match if event has state_key and type matches
    return event.stateKey != null && event.type == eventType;
  }

  @override
  String toCapabilityString() => eventType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateWithType && eventType == other.eventType;

  @override
  int get hashCode => eventType.hashCode;
}

/// Matches state events by both type and state_key.
///
/// Example: WithTypeAndStateKey("m.room.member", "@user:example.com")
/// matches only m.room.member events with that specific state_key.
///
/// Supports template variables in state keys for Element Call:
/// - `{userId}` - replaced with actual user ID
/// - `{deviceId}` - replaced with actual device ID
/// - Patterns like `{userId}_{deviceId}` for MSC3779
class StateWithTypeAndStateKey extends StateEventFilter {
  final String eventType;
  final String stateKey;

  const StateWithTypeAndStateKey(this.eventType, this.stateKey);

  /// Check if state key contains template variables.
  bool get hasTemplateVariables =>
      stateKey.contains('{userId}') || stateKey.contains('{deviceId}');

  /// Expand template variables in state key.
  String expandStateKey({String? userId, String? deviceId}) {
    var expanded = stateKey;
    if (userId != null) {
      expanded = expanded.replaceAll('{userId}', userId);
    }
    if (deviceId != null) {
      expanded = expanded.replaceAll('{deviceId}', deviceId);
    }
    return expanded;
  }

  @override
  bool matches(MatrixEvent event) {
    if (event.type != eventType) return false;
    if (event.stateKey == null) return false;

    // For patterns without templates, do exact match
    if (!hasTemplateVariables) {
      return event.stateKey == stateKey;
    }

    // For patterns with templates, we can't match without context
    // This would need to be handled by the driver with actual userId/deviceId
    // For now, return false as we can't match templates directly
    return false;
  }

  /// Check if this filter matches with given context.
  bool matchesWithContext(
    MatrixEvent event, {
    String? userId,
    String? deviceId,
  }) {
    if (event.type != eventType) return false;
    if (event.stateKey == null) return false;

    if (!hasTemplateVariables) {
      return event.stateKey == stateKey;
    }

    final expandedKey = expandStateKey(userId: userId, deviceId: deviceId);
    return event.stateKey == expandedKey;
  }

  @override
  String toCapabilityString() => '$eventType|$stateKey';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateWithTypeAndStateKey &&
          eventType == other.eventType &&
          stateKey == other.stateKey;

  @override
  int get hashCode => Object.hash(eventType, stateKey);
}

/// Filter for to-device events.
///
/// To-device events are sent directly to devices, not rooms.
sealed class ToDeviceEventFilter extends WidgetEventFilter {
  const ToDeviceEventFilter();
}

/// Matches to-device events by type.
///
/// Example: WithType("m.room.encrypted") matches encrypted to-device events.
class ToDeviceWithType extends ToDeviceEventFilter {
  final String eventType;

  const ToDeviceWithType(this.eventType);

  @override
  bool matches(MatrixEvent event) {
    // To-device events match by type only
    return event.type == eventType;
  }

  @override
  String toCapabilityString() => eventType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToDeviceWithType && eventType == other.eventType;

  @override
  int get hashCode => eventType.hashCode;
}
