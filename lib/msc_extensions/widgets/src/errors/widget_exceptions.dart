/// Widget API exception hierarchy for structured error handling.
library;

/// Base class for all widget-related exceptions.
sealed class WidgetException implements Exception {
  /// Error message describing what went wrong.
  final String message;

  /// Matrix error code (e.g., 'M_FORBIDDEN', 'M_NOT_FOUND').
  final String code;

  /// Optional additional details about the error.
  final Map<String, dynamic>? details;

  const WidgetException(
    this.message,
    this.code, {
    this.details,
  });

  @override
  String toString() => 'WidgetException($code): $message';

  /// Convert to JSON for sending error responses.
  Map<String, dynamic> toJson() => {
        'error': message,
        'errcode': code,
        if (details != null) 'details': details,
      };
}

/// Security violation when widget attempts unauthorized action.
class SecurityViolationException extends WidgetException {
  const SecurityViolationException(
    String message, {
    Map<String, dynamic>? details,
  }) : super(message, 'M_FORBIDDEN', details: details);

  /// Create for crypto event access attempt.
  factory SecurityViolationException.cryptoEvent(String eventType) {
    return SecurityViolationException(
      'Cannot access crypto event type: $eventType',
      details: {'event_type': eventType},
    );
  }

  /// Create for missing capability.
  factory SecurityViolationException.missingCapability(
    String capability, {
    String? action,
  }) {
    return SecurityViolationException(
      'Widget lacks required capability: $capability',
      details: {
        'required_capability': capability,
        if (action != null) 'attempted_action': action,
      },
    );
  }
}

/// Invalid request from widget.
class InvalidRequestException extends WidgetException {
  const InvalidRequestException(
    String message, {
    Map<String, dynamic>? details,
  }) : super(message, 'M_INVALID_REQUEST', details: details);

  /// Create for missing required field.
  factory InvalidRequestException.missingField(String fieldName) {
    return InvalidRequestException(
      'Missing required field: $fieldName',
      details: {'missing_field': fieldName},
    );
  }

  /// Create for invalid field value.
  factory InvalidRequestException.invalidValue(
    String fieldName,
    dynamic value, {
    String? expectedType,
  }) {
    return InvalidRequestException(
      'Invalid value for field: $fieldName',
      details: {
        'field': fieldName,
        'value': value,
        if (expectedType != null) 'expected_type': expectedType,
      },
    );
  }
}

/// Resource not found error.
class NotFoundException extends WidgetException {
  const NotFoundException(
    String message, {
    Map<String, dynamic>? details,
  }) : super(message, 'M_NOT_FOUND', details: details);

  /// Create for missing event.
  factory NotFoundException.event(String eventId) {
    return NotFoundException(
      'Event not found: $eventId',
      details: {'event_id': eventId},
    );
  }

  /// Create for missing state.
  factory NotFoundException.state(String eventType, String? stateKey) {
    return NotFoundException(
      'State not found: $eventType',
      details: {
        'event_type': eventType,
        if (stateKey != null) 'state_key': stateKey,
      },
    );
  }
}

/// Rate limit exceeded error.
class RateLimitException extends WidgetException {
  /// Number of seconds until next retry is allowed.
  final int? retryAfterSeconds;

  const RateLimitException(
    String message, {
    this.retryAfterSeconds,
    Map<String, dynamic>? details,
  }) : super(message, 'M_LIMIT_EXCEEDED', details: details);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (retryAfterSeconds != null) 'retry_after_ms': retryAfterSeconds! * 1000,
      };
}

/// Timeout error for long-running operations.
class TimeoutException extends WidgetException {
  /// The operation that timed out.
  final String operation;

  /// Timeout duration.
  final Duration timeout;

  TimeoutException(
    this.operation, {
    required this.timeout,
  }) : super(
          'Operation timed out: $operation',
          'M_TIMEOUT',
          details: {
            'operation': operation,
            'timeout_ms': timeout.inMilliseconds,
          },
        );
}

/// Transport/communication error.
class TransportException extends WidgetException {
  /// Whether reconnection should be attempted.
  final bool shouldReconnect;

  const TransportException(
    String message, {
    this.shouldReconnect = true,
    Map<String, dynamic>? details,
  }) : super(message, 'M_TRANSPORT_ERROR', details: details);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'should_reconnect': shouldReconnect,
      };
}

/// Widget state error (wrong state for operation).
class WidgetStateException extends WidgetException {
  /// Current state that prevented the operation.
  final String currentState;

  /// Expected state(s) for the operation.
  final List<String> expectedStates;

  WidgetStateException(
    String message, {
    required this.currentState,
    required this.expectedStates,
  }) : super(
          message,
          'M_INVALID_STATE',
          details: {
            'current_state': currentState,
            'expected_states': expectedStates,
          },
        );

  /// Create for capability state error.
  factory WidgetStateException.capabilityState(
    String currentState,
    List<String> expectedStates,
  ) {
    return WidgetStateException(
      'Invalid capability state: $currentState',
      currentState: currentState,
      expectedStates: expectedStates,
    );
  }
}

/// Too many pending requests error.
class TooManyRequestsException extends WidgetException {
  /// Maximum allowed pending requests.
  final int maxPending;

  /// Current number of pending requests.
  final int currentPending;

  TooManyRequestsException({
    required this.maxPending,
    required this.currentPending,
  }) : super(
          'Too many pending requests: $currentPending (max: $maxPending)',
          'M_TOO_MANY_REQUESTS',
          details: {
            'max_pending': maxPending,
            'current_pending': currentPending,
          },
        );
}

/// Helper to convert exception to error response.
class WidgetErrorHandler {
  /// Convert any exception to a WidgetException.
  static WidgetException fromException(Object error) {
    if (error is WidgetException) {
      return error;
    }

    // Convert standard exceptions
    if (error is ArgumentError) {
      return InvalidRequestException(
        error.message?.toString() ?? 'Invalid argument',
        details: {'argument': error.name},
      );
    }

    if (error is StateError) {
      return WidgetStateException(
        error.message,
        currentState: 'unknown',
        expectedStates: [],
      );
    }

    // Default to generic error
    return const InvalidRequestException(
      'An unexpected error occurred',
      details: {'error_type': 'unknown'},
    );
  }

  /// Check if error is retryable.
  static bool isRetryable(WidgetException error) {
    return error is TransportException ||
        error is TimeoutException ||
        (error is RateLimitException && error.retryAfterSeconds != null);
  }

  /// Get retry delay for an error.
  static Duration? getRetryDelay(WidgetException error) {
    if (error is RateLimitException && error.retryAfterSeconds != null) {
      return Duration(seconds: error.retryAfterSeconds!);
    }

    if (error is TimeoutException) {
      // Exponential backoff starting at 1 second
      return const Duration(seconds: 1);
    }

    if (error is TransportException && error.shouldReconnect) {
      return const Duration(seconds: 5);
    }

    return null;
  }
}