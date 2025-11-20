import 'package:matrix/msc_extensions/widgets/src/capabilities/capabilities.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';

/// Exception thrown when a capability string cannot be parsed.
class CapabilityParseException implements Exception {
  final String message;
  final String capabilityString;

  CapabilityParseException(this.message, this.capabilityString);

  @override
  String toString() => 'CapabilityParseException: $message (in: $capabilityString)';
}

/// Parse widget capability strings into a [WidgetCapabilities] object.
///
/// Capability string formats (MSC2762, MSC2871, MSC3819, MSC4157):
///
/// Message-like events:
/// - `org.matrix.msc2762.send.event` - Send any message event
/// - `org.matrix.msc2762.send.event:m.room.message` - Send m.room.message
/// - `org.matrix.msc2762.send.event:m.room.message#m.text` - Send text messages
/// - `org.matrix.msc2762.read.event:m.room.message` - Read m.room.message
///
/// State events:
/// - `org.matrix.msc2762.send.state_event:m.room.topic` - Send topic state
/// - `org.matrix.msc2762.read.state_event:m.room.member` - Read member state
///
/// To-device events (MSC3819):
/// - `org.matrix.msc3819.send.to_device:m.custom` - Send to-device events
/// - `org.matrix.msc3819.read.to_device:m.custom` - Read to-device events
///
/// Delayed events (MSC4157):
/// - `org.matrix.msc4157.send.delayed_event` - Can send delayed events
/// - `org.matrix.msc4157.update.delayed_event` - Can update/cancel delayed events
///
/// Special:
/// - `require_client` - Requires full client functionality
class CapabilityParser {
  /// Parse a list of capability strings into a WidgetCapabilities object.
  ///
  /// Throws [CapabilityParseException] if any string is malformed.
  static WidgetCapabilities parse(List<String> capabilityStrings) {
    final readFilters = <WidgetEventFilter>[];
    final sendFilters = <WidgetEventFilter>[];
    var requiresClient = false;
    var updateDelayedEvent = false;
    var sendDelayedEvent = false;

    for (final capString in capabilityStrings) {
      // Special capabilities
      if (capString == 'require_client' || capString == 'io.element.require_client') {
        requiresClient = true;
        continue;
      }

      // Delayed event capabilities (MSC4157)
      if (capString == 'org.matrix.msc4157.send.delayed_event') {
        sendDelayedEvent = true;
        continue;
      }
      if (capString == 'org.matrix.msc4157.update.delayed_event') {
        updateDelayedEvent = true;
        continue;
      }

      // Parse structured capability strings
      try {
        final (operation, filter) = _parseCapabilityString(capString);

        switch (operation) {
          case 'send':
          case 'send.event':
          case 'send.state_event':
          case 'send.to_device':
            if (filter != null) sendFilters.add(filter);
            break;

          case 'read':
          case 'read.event':
          case 'read.state_event':
          case 'read.to_device':
            if (filter != null) readFilters.add(filter);
            break;

          default:
            // Unknown operation, skip
            break;
        }
      } catch (e) {
        // Ignore malformed capability strings
        // Widget will just not get that capability
        continue;
      }
    }

    return WidgetCapabilities(
      read: readFilters,
      send: sendFilters,
      requiresClient: requiresClient,
      updateDelayedEvent: updateDelayedEvent,
      sendDelayedEvent: sendDelayedEvent,
    );
  }

  /// Parse a single capability string into operation and filter.
  ///
  /// Returns (operation, filter) tuple.
  /// Throws [CapabilityParseException] if malformed.
  static (String operation, WidgetEventFilter? filter) _parseCapabilityString(String capString) {
    // Handle MSC format and Element Call formats
    if (capString.startsWith('org.matrix.msc2762.') ||
        capString.startsWith('org.matrix.msc3819.') ||
        capString.startsWith('org.matrix.msc3401.') ||
        capString.startsWith('org.matrix.msc4143.') ||
        capString.startsWith('io.element.')) {
      return _parseMscFormat(capString);
    }

    // Handle simple format like "send.event:m.room.message"
    final colonIndex = capString.indexOf(':');
    if (colonIndex == -1) {
      // No event type specified, just operation
      return (capString, null);
    }

    final operation = capString.substring(0, colonIndex);
    final eventPart = capString.substring(colonIndex + 1);

    final filter = _parseEventFilter(operation, eventPart);
    return (operation, filter);
  }

  /// Parse MSC-prefixed and Element-specific capability strings.
  static (String, WidgetEventFilter?) _parseMscFormat(String capString) {
    // org.matrix.msc2762.send.event:m.room.message#m.text
    // org.matrix.msc2762.send.state_event:m.room.topic
    // org.matrix.msc3819.send.to_device:m.custom
    // io.element.send.event:io.element.call.encryption_keys
    // io.element.read.event:io.element.rageshake

    // Split only on first colon to avoid breaking user IDs like @user:example.com
    final colonIndex = capString.indexOf(':');
    final prefix = colonIndex == -1 ? capString : capString.substring(0, colonIndex);
    final eventSpec = colonIndex == -1 ? null : capString.substring(colonIndex + 1);

    // Extract operation from prefix
    String operation;

    // Check for io.element patterns first (simpler structure)
    if (capString.startsWith('io.element.')) {
      if (prefix.contains('.send.')) {
        operation = 'send.event';
      } else if (prefix.contains('.read.')) {
        operation = 'read.event';
      } else {
        // Default to read for io.element capabilities
        operation = 'read.event';
      }
    } else if (prefix.contains('.send.event')) {
      operation = 'send.event';
    } else if (prefix.contains('.send.state_event')) {
      operation = 'send.state_event';
    } else if (prefix.contains('.read.event')) {
      operation = 'read.event';
    } else if (prefix.contains('.read.state_event')) {
      operation = 'read.state_event';
    } else if (prefix.contains('.send.to_device')) {
      operation = 'send.to_device';
    } else if (prefix.contains('.read.to_device')) {
      operation = 'read.to_device';
    } else {
      // For MSC3401/MSC4143 RTC events, default to appropriate operation
      if (prefix.contains('msc3401') || prefix.contains('msc4143')) {
        // These are typically timeline events
        operation = prefix.contains('.send.') ? 'send.event' : 'read.event';
      } else {
        throw CapabilityParseException('Unknown operation in MSC format', capString);
      }
    }

    if (eventSpec == null) {
      return (operation, null);
    }

    final filter = _parseEventFilter(operation, eventSpec);
    return (operation, filter);
  }

  /// Parse event filter from event specification.
  static WidgetEventFilter _parseEventFilter(String operation, String eventSpec) {
    final isState = operation.contains('state');
    final isToDevice = operation.contains('to_device');

    if (isToDevice) {
      // To-device event: just event type
      return ToDeviceWithType(eventSpec);
    } else if (isState) {
      // State event: type or type|state_key
      if (eventSpec.contains('|')) {
        final parts = eventSpec.split('|');
        return StateWithTypeAndStateKey(parts[0], parts[1]);
      } else {
        return StateWithType(eventSpec);
      }
    } else {
      // Message-like event: type or type#msgtype
      if (eventSpec.contains('#')) {
        final parts = eventSpec.split('#');
        // Special case for m.room.message with msgtype
        if (parts[0] == 'm.room.message') {
          return RoomMessageWithMsgtype(parts[1]);
        } else {
          // For other types, just use the base type
          return MessageLikeWithType(parts[0]);
        }
      } else {
        return MessageLikeWithType(eventSpec);
      }
    }
  }
}
