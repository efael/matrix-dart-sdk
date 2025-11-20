/// Common types and type aliases for the Widget API.
library;

/// Empty message used for requests/responses with no data.
///
/// This class is used for all empty messages to reduce code duplication.
class EmptyMessage {
  const EmptyMessage();

  /// Convert to JSON (always returns empty map).
  Map<String, dynamic> toJson() => {};

  /// Create from JSON (always returns a new instance).
  static EmptyMessage fromJson(Map<String, dynamic> json) => const EmptyMessage();
}

// Empty request/response classes that extend EmptyMessage for type safety

/// Request for supported API versions.
class SupportedApiVersionsRequest extends EmptyMessage {
  const SupportedApiVersionsRequest();
  static SupportedApiVersionsRequest fromJson(Map<String, dynamic> json) =>
      const SupportedApiVersionsRequest();
}

/// Notification sent when widget content is loaded.
class ContentLoadedNotification extends EmptyMessage {
  const ContentLoadedNotification();
  static ContentLoadedNotification fromJson(Map<String, dynamic> json) =>
      const ContentLoadedNotification();
}

/// Request for OpenID credentials.
class GetOpenIdRequest extends EmptyMessage {
  const GetOpenIdRequest();
  static GetOpenIdRequest fromJson(Map<String, dynamic> json) =>
      const GetOpenIdRequest();
}

/// Response for send to-device message.
class SendToDeviceResponse extends EmptyMessage {
  const SendToDeviceResponse();
  static SendToDeviceResponse fromJson(Map<String, dynamic> json) =>
      const SendToDeviceResponse();
}

/// Response for update delayed event.
class UpdateDelayedEventResponse extends EmptyMessage {
  const UpdateDelayedEventResponse();
  static UpdateDelayedEventResponse fromJson(Map<String, dynamic> json) =>
      const UpdateDelayedEventResponse();
}

/// Response for navigate action.
class NavigateResponse extends EmptyMessage {
  const NavigateResponse();
  static NavigateResponse fromJson(Map<String, dynamic> json) =>
      const NavigateResponse();
}

/// Error response data.
class WidgetError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const WidgetError({
    required this.code,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'errcode': code,
        'error': message,
        if (details != null) 'details': details,
      };

  factory WidgetError.fromJson(Map<String, dynamic> json) => WidgetError(
        code: json['errcode'] as String,
        message: json['error'] as String,
        details: json['details'] as Map<String, dynamic>?,
      );
}