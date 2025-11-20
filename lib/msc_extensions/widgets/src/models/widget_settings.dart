import 'package:matrix/matrix.dart';

/// Configuration settings for a widget.
///
/// Contains the widget's identity, URL, and initialization behavior.
class WidgetSettings {
  /// Unique identifier for the widget.
  final String widgetId;

  /// Widget URL with optional template variables.
  ///
  /// Supports the following template variables (MSC2873, MSC4039):
  /// - `$matrix_user_id` - Current user's Matrix ID
  /// - `$matrix_room_id` - Room ID where widget is displayed
  /// - `$matrix_widget_id` - Widget ID
  /// - `$matrix_avatar_url` - Current user's avatar URL
  /// - `$matrix_display_name` - Current user's display name
  /// - `$org.matrix.msc2873.client_language` - Client language (e.g., 'en-US')
  /// - `$org.matrix.msc2873.client_theme` - Client theme ('light' or 'dark')
  /// - `$org.matrix.msc2873.client_id` - Client identifier
  /// - `$org.matrix.msc2873.matrix_device_id` - Matrix device ID
  /// - `$org.matrix.msc4039.matrix_base_url` - Homeserver base URL
  /// Element Call specific:
  /// - `$io.element.fontScale` - Font scale for UI
  /// - `$io.element.font` - Font family for UI
  final String url;

  /// Whether to initialize the widget when the content_loaded event is received.
  ///
  /// If true, the driver will start capability negotiation immediately when
  /// the widget sends the content_loaded message.
  /// If false, initialization must be triggered manually.
  final bool initOnContentLoad;

  WidgetSettings({
    required this.widgetId,
    required this.url,
    this.initOnContentLoad = true,
  });

  /// Build the final widget URL by replacing template variables.
  ///
  /// [client] - The Matrix client (for user info and homeserver URL)
  /// [room] - The room where the widget is displayed
  /// [language] - Client language (defaults to 'en-US')
  /// [theme] - Client theme (defaults to 'light')
  /// [clientId] - Client identifier (optional)
  /// [fontScale] - Font scale for UI (Element Call specific, optional)
  /// [font] - Font family for UI (Element Call specific, optional)
  ///
  /// Returns the URL with all template variables replaced and URI-encoded.
  Future<String> buildUrl(
    Client client,
    Room room, {
    String language = 'en-US',
    String theme = 'light',
    String? clientId,
    double? fontScale,
    String? font,
  }) async {
    // Get user profile for avatar and display name
    final userProfile = await client.getUserProfile(client.userID!);

    // Build replacement map for all template variables
    final replacements = <String, String>{
      // Basic template variables (MSC1236)
      '\$matrix_user_id': client.userID!,
      '\$matrix_room_id': room.id,
      '\$matrix_widget_id': widgetId,
      '\$matrix_avatar_url': userProfile.avatarUrl?.toString() ?? '',
      '\$matrix_display_name': userProfile.displayname ?? '',

      // MSC2873 template variables
      '\$org.matrix.msc2873.client_language': language,
      '\$org.matrix.msc2873.client_theme': theme,
      '\$org.matrix.msc2873.client_id': clientId ?? '',
      '\$org.matrix.msc2873.matrix_device_id': client.deviceID ?? '',

      // MSC4039 template variables
      '\$org.matrix.msc4039.matrix_base_url': client.homeserver.toString(),

      // Element Call specific template variables (only if provided)
      if (fontScale != null) '\$io.element.fontScale': fontScale.toString(),
      if (font != null) '\$io.element.font': font,
    };

    // Apply all replacements with URI encoding
    var result = url;
    for (final entry in replacements.entries) {
      result = result.replaceAll(
        entry.key,
        Uri.encodeComponent(entry.value),
      );
    }

    return result;
  }

  Map<String, dynamic> toJson() => {
        'widget_id': widgetId,
        'url': url,
        'init_on_content_load': initOnContentLoad,
      };

  factory WidgetSettings.fromJson(Map<String, dynamic> json) =>
      WidgetSettings(
        widgetId: json['widget_id'] as String,
        url: json['url'] as String,
        initOnContentLoad: json['init_on_content_load'] as bool? ?? true,
      );
}
