import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/filters.dart';

/// Optimized filter cache for fast event matching.
///
/// Pre-compiles filters into lookup structures for O(1) exact matching
/// and reduced complexity for prefix/complex matching.
class FilterCache {
  /// Event types for exact matching (O(1) lookup)
  final Set<String> _exactTypes = {};

  /// Event type prefixes for wildcard matching
  final List<String> _prefixTypes = [];

  /// Complex filters requiring individual evaluation
  final List<WidgetEventFilter> _complexFilters = [];

  /// Cache of state filters indexed by event type
  final Map<String, List<WidgetEventFilter>> _stateFilters = {};

  /// Cache of message filters indexed by event type
  final Map<String, List<WidgetEventFilter>> _messageFilters = {};

  FilterCache(List<WidgetEventFilter> filters) {
    _compileFilters(filters);
  }

  /// Compile filters into optimized lookup structures
  void _compileFilters(List<WidgetEventFilter> filters) {
    for (final filter in filters) {
      switch (filter) {
        case MessageLikeWithType():
          _addMessageFilter(filter);
          break;

        case StateWithType():
          _addStateFilter(filter);
          break;

        case StateWithTypeAndStateKey():
          // Complex filter - needs full evaluation
          _complexFilters.add(filter);
          break;

        case ToDeviceWithType():
          // To-device events handled separately
          _exactTypes.add(filter.eventType);
          break;

        case RoomMessageWithMsgtype():
          // Room messages with msgtype
          _messageFilters.putIfAbsent('m.room.message', () => []).add(filter);
          break;

        default:
          // Unknown filter type - add to complex
          _complexFilters.add(filter);
      }
    }
  }

  /// Add message-like filter to optimized structures
  void _addMessageFilter(MessageLikeWithType filter) {
    final eventType = filter.eventType;

    if (eventType.endsWith('*')) {
      // Wildcard pattern - add prefix
      _prefixTypes.add(eventType.substring(0, eventType.length - 1));
    } else {
      // Exact type - add to set
      _exactTypes.add(eventType);
      _messageFilters.putIfAbsent(eventType, () => []).add(filter);
    }
  }

  /// Add state filter to optimized structures
  void _addStateFilter(StateWithType filter) {
    final eventType = filter.eventType;

    if (eventType.endsWith('*')) {
      // Wildcard pattern - add prefix
      _prefixTypes.add(eventType.substring(0, eventType.length - 1));
    } else {
      // Exact type - add to set
      _exactTypes.add(eventType);
      _stateFilters.putIfAbsent(eventType, () => []).add(filter);
    }
  }

  /// Check if an event matches any cached filter
  bool matches(MatrixEvent event) {
    // Fast path: check exact type match
    if (_exactTypes.contains(event.type)) {
      return true;
    }

    // Check prefix matches
    for (final prefix in _prefixTypes) {
      if (event.type.startsWith(prefix)) {
        return true;
      }
    }

    // Check complex filters
    for (final filter in _complexFilters) {
      if (filter.matches(event)) {
        return true;
      }
    }

    // Check message-specific filters
    if (_messageFilters.containsKey(event.type)) {
      final filters = _messageFilters[event.type]!;
      for (final filter in filters) {
        if (filter.matches(event)) {
          return true;
        }
      }
    }

    // Check state-specific filters if event has state key
    if (event.stateKey != null && _stateFilters.containsKey(event.type)) {
      final filters = _stateFilters[event.type]!;
      for (final filter in filters) {
        if (filter.matches(event)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Check if a specific event type is allowed (fast check)
  bool allowsEventType(String eventType) {
    // Exact match
    if (_exactTypes.contains(eventType)) {
      return true;
    }

    // Prefix match
    for (final prefix in _prefixTypes) {
      if (eventType.startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }

  /// Get statistics about the cache
  Map<String, int> get statistics => {
        'exactTypes': _exactTypes.length,
        'prefixTypes': _prefixTypes.length,
        'complexFilters': _complexFilters.length,
        'stateFilters': _stateFilters.length,
        'messageFilters': _messageFilters.length,
      };
}

/// Optimized crypto event filter using Set for O(1) lookup.
class OptimizedCryptoEventFilter {
  static const _cryptoPrefixes = {
    'm.room_key',
    'm.room_key_request',
    'm.forwarded_room_key',
    'm.secret.',
    'm.room.encrypted',
  };

  static const _cryptoExactTypes = {
    'm.room_key',
    'm.room_key_request',
    'm.forwarded_room_key',
    'm.room.encrypted',
  };

  /// Check if event type is a crypto event (optimized).
  static bool isCryptoEvent(String eventType) {
    // Quick exact match first
    if (_cryptoExactTypes.contains(eventType)) {
      return true;
    }

    // Check if starts with m.secret.
    if (eventType.startsWith('m.secret.')) {
      return true;
    }

    // Check other prefixes for sub-types
    if (eventType.startsWith('m.room_key.') ||
        eventType.startsWith('m.room_key_request.') ||
        eventType.startsWith('m.forwarded_room_key.')) {
      return true;
    }

    return false;
  }

  /// Filter crypto events from a list of events.
  static List<MatrixEvent> filterEvents(List<MatrixEvent> events) {
    return events.where((event) => !isCryptoEvent(event.type)).toList();
  }
}