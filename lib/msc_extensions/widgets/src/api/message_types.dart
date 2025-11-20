/// Supported Widget API versions.
///
/// Includes both numbered versions and MSC-specific version identifiers.
/// Based on MSC2762, MSC2871, MSC3819, and MSC4157.
const List<String> supportedApiVersions = [
  '0.0.1',
  '0.0.2',
  'MSC2762', // Widget API v1
  'MSC2871', // Widget API event sending/reading
  'MSC3819', // To-device messaging
  'MSC4157', // Delayed events
];

/// Direction of a widget API message.
enum MessageDirection {
  /// Message from widget to client.
  fromWidget('FromWidget'),

  /// Message from client to widget.
  toWidget('ToWidget');

  final String value;
  const MessageDirection(this.value);

  factory MessageDirection.fromString(String value) {
    return switch (value) {
      'FromWidget' => MessageDirection.fromWidget,
      'ToWidget' => MessageDirection.toWidget,
      _ => throw ArgumentError('Unknown message direction: $value'),
    };
  }
}

/// Base class for all widget API messages.
///
/// All messages follow the postMessage structure defined in MSC2762.
class WidgetMessage {
  /// Message direction ('FromWidget' or 'ToWidget').
  final MessageDirection api;

  /// Unique request identifier for request/response matching.
  ///
  /// Should be a UUID v4 string. Optional for notifications.
  final String? requestId;

  /// Widget identifier.
  final String widgetId;

  /// Action/event type of the message.
  final String action;

  /// Message payload data.
  final Map<String, dynamic> data;

  WidgetMessage({
    required this.api,
    this.requestId,
    required this.widgetId,
    required this.action,
    this.data = const {},
  });

  Map<String, dynamic> toJson() => {
        'api': api.value,
        if (requestId != null) 'requestId': requestId,
        'widgetId': widgetId,
        'action': action,
        'data': data,
      };

  factory WidgetMessage.fromJson(Map<String, dynamic> json) {
    return WidgetMessage(
      api: MessageDirection.fromString(json['api'] as String),
      requestId: json['requestId'] as String?,
      widgetId: json['widgetId'] as String,
      action: json['action'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Error response for widget API requests.
class WidgetError {
  /// Error code identifying the error type.
  final String code;

  /// Human-readable error message.
  final String message;

  /// Optional Matrix API error details.
  ///
  /// Included when the error originated from a Matrix API call.
  final Map<String, dynamic>? matrixError;

  WidgetError({
    required this.code,
    required this.message,
    this.matrixError,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (matrixError != null) 'matrix_error': matrixError,
      };

  factory WidgetError.fromJson(Map<String, dynamic> json) {
    return WidgetError(
      code: json['code'] as String,
      message: json['message'] as String,
      matrixError: json['matrix_error'] as Map<String, dynamic>?,
    );
  }
}

/// Standard widget API error codes.
class WidgetErrorCode {
  /// Operation not allowed due to missing capabilities.
  static const notAllowed = 'NOT_ALLOWED';

  /// Invalid request format or parameters.
  static const invalidRequest = 'INVALID_REQUEST';

  /// Request timed out.
  static const timeout = 'TIMEOUT';

  /// Transport layer error.
  static const transportError = 'TRANSPORT_ERROR';

  /// Error from Matrix API.
  static const matrixError = 'MATRIX_ERROR';

  /// Unknown or unexpected error.
  static const unknown = 'UNKNOWN';
}
