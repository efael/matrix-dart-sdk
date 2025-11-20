import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';

/// Widget capabilities defining what operations and events are allowed.
///
/// Capabilities follow a permission-based model where widgets must explicitly
/// request and receive approval for each operation. Based on MSC2762, MSC2871,
/// MSC3819, and MSC4157.
class WidgetCapabilities {
  /// Events the widget is allowed to read/receive.
  ///
  /// These filters determine which events from the room timeline and state
  /// will be forwarded to the widget.
  final List<WidgetEventFilter> read;

  /// Events the widget is allowed to send.
  ///
  /// These filters determine which event types the widget can create
  /// in the room.
  final List<WidgetEventFilter> send;

  /// Whether the widget requires full client functionality.
  ///
  /// When true, the widget needs access to client-level operations beyond
  /// just room events. Default is false (room-scoped only).
  final bool requiresClient;

  /// Whether the widget can update delayed events (MSC4157).
  ///
  /// Allows modifying or canceling events that were scheduled for delayed
  /// delivery. Default is false.
  final bool updateDelayedEvent;

  /// Whether the widget can send delayed events (MSC4157).
  ///
  /// Allows scheduling events for delayed delivery using delay_ms parameter.
  /// Default is false.
  final bool sendDelayedEvent;

  const WidgetCapabilities({
    this.read = const [],
    this.send = const [],
    this.requiresClient = false,
    this.updateDelayedEvent = false,
    this.sendDelayedEvent = false,
  });

  /// Create an empty capabilities set (no permissions).
  const WidgetCapabilities.empty()
      : read = const [],
        send = const [],
        requiresClient = false,
        updateDelayedEvent = false,
        sendDelayedEvent = false;

  /// Check if the widget can read events matching this filter.
  bool canRead(WidgetEventFilter filter) => read.any((f) => f == filter);

  /// Check if the widget can send events matching this filter.
  bool canSend(WidgetEventFilter filter) => send.any((f) => f == filter);

  /// Check if the widget can read this specific event.
  bool canReadEvent(MatrixEvent event) => read.any((f) => f.matches(event));

  /// Check if the widget can send this specific event type.
  bool canSendEventType(String eventType, {String? stateKey}) {
    return send.any((filter) {
      if (stateKey != null && filter is StateEventFilter) {
        // State event - check if filter matches
        if (filter is StateWithType) {
          return filter.eventType == eventType;
        } else if (filter is StateWithTypeAndStateKey) {
          return filter.eventType == eventType && filter.stateKey == stateKey;
        }
      } else if (stateKey == null && filter is MessageLikeEventFilter) {
        // Message-like event - check if filter matches
        if (filter is MessageLikeWithType) {
          return eventType.startsWith(filter.eventType);
        } else if (filter is RoomMessageWithMsgtype) {
          return eventType == 'm.room.message';
        }
      }
      return false;
    });
  }

  Map<String, dynamic> toJson() => {
        'read': read.map((f) => f.toCapabilityString()).toList(),
        'send': send.map((f) => f.toCapabilityString()).toList(),
        'requires_client': requiresClient,
        'update_delayed_event': updateDelayedEvent,
        'send_delayed_event': sendDelayedEvent,
      };

  factory WidgetCapabilities.fromJson(Map<String, dynamic> json) {
    final readStrings = (json['read'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    final sendStrings = (json['send'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];

    return WidgetCapabilities(
      read: readStrings.map(_parseFilterString).toList(),
      send: sendStrings.map(_parseFilterString).toList(),
      requiresClient: json['requires_client'] as bool? ?? false,
      updateDelayedEvent: json['update_delayed_event'] as bool? ?? false,
      sendDelayedEvent: json['send_delayed_event'] as bool? ?? false,
    );
  }

  static WidgetEventFilter _parseFilterString(String str) {
    if (str.contains('|')) {
      final parts = str.split('|');
      return StateWithTypeAndStateKey(parts[0], parts[1]);
    } else if (str.contains('#')) {
      final parts = str.split('#');
      return RoomMessageWithMsgtype(parts[1]);
    } else {
      return MessageLikeWithType(str);
    }
  }

  WidgetCapabilities copyWith({
    List<WidgetEventFilter>? read,
    List<WidgetEventFilter>? send,
    bool? requiresClient,
    bool? updateDelayedEvent,
    bool? sendDelayedEvent,
  }) {
    return WidgetCapabilities(
      read: read ?? this.read,
      send: send ?? this.send,
      requiresClient: requiresClient ?? this.requiresClient,
      updateDelayedEvent: updateDelayedEvent ?? this.updateDelayedEvent,
      sendDelayedEvent: sendDelayedEvent ?? this.sendDelayedEvent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetCapabilities &&
          _listEquals(read, other.read) &&
          _listEquals(send, other.send) &&
          requiresClient == other.requiresClient &&
          updateDelayedEvent == other.updateDelayedEvent &&
          sendDelayedEvent == other.sendDelayedEvent;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(read),
        Object.hashAll(send),
        requiresClient,
        updateDelayedEvent,
        sendDelayedEvent,
      );

  /// Helper to compare filter lists for equality.
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
