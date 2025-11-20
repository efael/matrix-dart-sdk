import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/capabilities.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';

/// Get required permissions for Element Call widget.
///
/// Returns comprehensive capabilities needed for Element Call to function
/// properly, including MatrixRTC events, call member state, and encryption.
WidgetCapabilities getElementCallRequiredPermissions({
  required String userId,
  required String deviceId,
}) {
  // Generate device-specific state key patterns
  final stateKeyPatterns = _generateStateKeyPatterns(userId, deviceId);

  return WidgetCapabilities(
    read: [
      // State events
      const StateWithType('m.call.member'),
      const StateWithType('org.matrix.msc3401.call.member'),
      const StateWithType('m.room.name'),
      const StateWithType('m.room.member'),
      const StateWithType('m.room.encryption'),
      const StateWithType('m.room.create'),
      const StateWithType('org.matrix.msc3823.room_type'),

      // Message-like events
      const MessageLikeWithType('io.element.rageshake'),
      const MessageLikeWithType('io.element.call.encryption_keys'),
      const MessageLikeWithType('m.reaction'),
      const MessageLikeWithType('org.matrix.rageshake_request'),

      // MatrixRTC timeline events
      const MessageLikeWithType('org.matrix.msc3401.call.member'),
      const MessageLikeWithType('m.call.member'),
    ],
    send: [
      // Call notification events (deprecated and new)
      const MessageLikeWithType('m.call.notify'),
      const MessageLikeWithType('org.matrix.msc4143.rtc.notify'),

      // State events with device-specific keys
      ...stateKeyPatterns.map(
        (pattern) => StateWithTypeAndStateKey('m.call.member', pattern),
      ),
      ...stateKeyPatterns.map(
        (pattern) =>
            StateWithTypeAndStateKey('org.matrix.msc3401.call.member', pattern),
      ),

      // Reactions and rageshake
      const MessageLikeWithType('m.reaction'),
      const MessageLikeWithType('io.element.rageshake'),
      const MessageLikeWithType('org.matrix.rageshake_request'),

      // Encryption keys
      const MessageLikeWithType('io.element.call.encryption_keys'),
    ],
    requiresClient: true,
    updateDelayedEvent: true,
    sendDelayedEvent: true,
  );
}

/// Generate device-specific state key patterns for Element Call.
///
/// Supports multiple formats for compatibility:
/// - Legacy: `{userId}`
/// - MSC3779: `{userId}_{deviceId}`
/// - MSC3779 with suffix: `{userId}_{deviceId}_m.call`
/// - Underscore variant: `_{userId}_{deviceId}`
/// - Underscore with suffix: `_{userId}_{deviceId}_m.call`
List<String> _generateStateKeyPatterns(String userId, String deviceId) {
  return [
    // Legacy format
    userId,
    // MSC3779 format
    '${userId}_$deviceId',
    // MSC3779 with m.call suffix
    '${userId}_${deviceId}_m.call',
    // Underscore prefix variant
    '_${userId}_$deviceId',
    // Underscore prefix with suffix
    '_${userId}_${deviceId}_m.call',
  ];
}

/// Check if a user has granted all required Element Call permissions.
bool hasElementCallPermissions(
  WidgetCapabilities granted,
  String userId,
  String deviceId,
) {
  final required = getElementCallRequiredPermissions(
    userId: userId,
    deviceId: deviceId,
  );

  // Check if all required read permissions are granted
  for (final filter in required.read) {
    final hasPermission = granted.read.any((grantedFilter) {
      // Check if the granted filter matches or is broader than required
      return _filterMatches(grantedFilter, filter);
    });
    if (!hasPermission) return false;
  }

  // Check if all required send permissions are granted
  for (final filter in required.send) {
    final hasPermission = granted.send.any((grantedFilter) {
      return _filterMatches(grantedFilter, filter);
    });
    if (!hasPermission) return false;
  }

  // Check other required capabilities
  if (!granted.requiresClient) return false;
  if (!granted.updateDelayedEvent) return false;
  if (!granted.sendDelayedEvent) return false;

  return true;
}

/// Check if a granted filter matches or is broader than a required filter.
bool _filterMatches(WidgetEventFilter granted, WidgetEventFilter required) {
  // Exact match
  if (granted.toCapabilityString() == required.toCapabilityString()) {
    return true;
  }

  // Check for broader permissions
  if (granted is MessageLikeWithType && required is MessageLikeWithType) {
    // Check if granted type is a prefix (broader permission)
    return required.eventType.startsWith(granted.eventType);
  }

  if (granted is StateWithType && required is StateWithType) {
    return required.eventType.startsWith(granted.eventType);
  }

  if (granted is StateWithTypeAndStateKey &&
      required is StateWithTypeAndStateKey) {
    return required.eventType.startsWith(granted.eventType) &&
        required.stateKey == granted.stateKey;
  }

  return false;
}

/// Get minimal Element Call permissions for testing/development.
///
/// Returns a minimal set of permissions that allows basic Element Call
/// functionality without full MatrixRTC support.
WidgetCapabilities getMinimalElementCallPermissions() {
  return const WidgetCapabilities(
    read: [
      StateWithType('m.room.name'),
      StateWithType('m.room.member'),
      MessageLikeWithType('m.call.member'),
    ],
    send: [
      MessageLikeWithType('m.call.member'),
      MessageLikeWithType('m.call.notify'),
    ],
    requiresClient: true,
    updateDelayedEvent: false,
    sendDelayedEvent: false,
  );
}

/// Check if an event type is Element Call related.
bool isElementCallEvent(String eventType) {
  const elementCallPrefixes = [
    'm.call.',
    'org.matrix.msc3401.call.',
    'org.matrix.msc4143.rtc.',
    'io.element.call.',
  ];

  return elementCallPrefixes.any((prefix) => eventType.startsWith(prefix));
}

/// Check if a capability string is Element Call related.
bool isElementCallCapability(String capability) {
  // Check for Element Call namespaces
  if (capability.startsWith('io.element.call.')) return true;
  if (capability.startsWith('org.matrix.msc3401.')) return true;
  if (capability.startsWith('org.matrix.msc4143.')) return true;

  // Check for specific Element Call event types
  if (capability.contains('m.call.')) return true;
  if (capability.contains('rtc.')) return true;

  return false;
}