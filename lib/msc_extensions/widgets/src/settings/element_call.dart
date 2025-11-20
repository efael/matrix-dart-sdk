import 'dart:convert';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/models/widget_settings.dart';

/// Encryption system for Element Call.
enum EncryptionSystem {
  /// No encryption.
  unencrypted('unencrypted'),

  /// Individual encryption per participant (default).
  perParticipantKeys('perParticipantKeys'),

  /// Password-protected calls with shared secret.
  sharedSecret('sharedSecret');

  final String value;
  const EncryptionSystem(this.value);

  factory EncryptionSystem.fromString(String value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => perParticipantKeys);
  }
}

/// Intent for initiating Element Call.
enum CallIntent {
  /// Start a new call.
  startCall('start_call'),

  /// Join an existing call.
  joinExisting('join'),

  /// Start a new DM call.
  startCallDm('start_call_dm'),

  /// Join an existing DM call.
  joinExistingDm('join_dm');

  final String value;
  const CallIntent(this.value);

  factory CallIntent.fromString(String value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => joinExisting);
  }
}

/// Header display style for Element Call.
enum HeaderStyle {
  /// Standard header.
  standard('standard'),

  /// App bar style.
  appBar('appBar'),

  /// No header.
  none('none');

  final String value;
  const HeaderStyle(this.value);

  factory HeaderStyle.fromString(String value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => standard);
  }
}

/// Notification type for Element Call.
enum NotificationType {
  /// Standard notification.
  notify('notify'),

  /// Ring notification.
  ring('ring');

  final String value;
  const NotificationType(this.value);

  factory NotificationType.fromString(String value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => notify);
  }
}

/// Required properties for Element Call widget.
class ElementCallWidgetProperties {
  /// Element Call application URL.
  final String elementCallUrl;

  /// Widget ID.
  final String widgetId;

  /// Parent URL for postMessage target.
  final String parentUrl;

  /// Encryption system to use.
  final EncryptionSystem encryption;

  /// Font scale for UI.
  final double? fontScale;

  /// Font family for UI.
  final String? font;

  /// PostHog analytics URL.
  final String? analyticsId;

  /// Sentry error reporting URL.
  final String? sentryUrl;

  /// Rageshake issue reporting URL.
  final String? rageshakeUrl;

  ElementCallWidgetProperties({
    required this.elementCallUrl,
    required this.widgetId,
    required this.parentUrl,
    this.encryption = EncryptionSystem.perParticipantKeys,
    this.fontScale,
    this.font,
    this.analyticsId,
    this.sentryUrl,
    this.rageshakeUrl,
  });
}

/// Optional configuration for Element Call widget.
class ElementCallWidgetConfig {
  /// Call initiation intent.
  final CallIntent? intent;

  /// Skip the lobby and join immediately.
  final bool? skipLobby;

  /// Header display style.
  final HeaderStyle? header;

  /// Auto-join on action.
  final bool? preload;

  /// Prompt to use native app.
  final bool? appPrompt;

  /// Confine calls list to current room.
  final bool? confineToRoom;

  /// Hide screensharing button.
  final bool? hideScreensharing;

  /// Use OS-level audio device control.
  final bool? controlledAudioDevices;

  /// Notification type for incoming calls.
  final NotificationType? sendNotificationType;

  /// Password for SharedSecret encryption.
  final String? password;

  ElementCallWidgetConfig({
    this.intent,
    this.skipLobby,
    this.header,
    this.preload,
    this.appPrompt,
    this.confineToRoom,
    this.hideScreensharing,
    this.controlledAudioDevices,
    this.sendNotificationType,
    this.password,
  });

  /// Convert configuration to fragment parameters.
  Map<String, String> toFragmentParams() {
    final params = <String, String>{};

    if (intent != null) params['intent'] = intent!.value;
    if (skipLobby != null) params['skipLobby'] = skipLobby.toString();
    if (header != null) params['header'] = header!.value;
    if (preload != null) params['preload'] = preload.toString();
    if (appPrompt != null) params['appPrompt'] = appPrompt.toString();
    if (confineToRoom != null) {
      params['confineToRoom'] = confineToRoom.toString();
    }
    if (hideScreensharing != null) {
      params['hideScreensharing'] = hideScreensharing.toString();
    }
    if (controlledAudioDevices != null) {
      params['controlledAudioDevices'] = controlledAudioDevices.toString();
    }
    if (sendNotificationType != null) {
      params['sendNotificationType'] = sendNotificationType!.value;
    }
    if (password != null) params['password'] = password!;

    return params;
  }
}

/// Build Element Call widget URL with all parameters.
Future<String> buildElementCallWidgetUrl({
  required Client client,
  required Room room,
  required ElementCallWidgetProperties properties,
  ElementCallWidgetConfig? config,
}) async {
  // Start with base URL
  var url = properties.elementCallUrl;

  // Add room ID
  if (!url.contains('#')) {
    url += '#';
  } else {
    url += '&';
  }
  url += 'roomId=${Uri.encodeComponent(room.id)}';

  // Add widget ID
  url += '&widgetId=${Uri.encodeComponent(properties.widgetId)}';

  // Add parent URL
  url += '&parentUrl=${Uri.encodeComponent(properties.parentUrl)}';

  // Add encryption
  url += '&encryption=${properties.encryption.value}';

  // Add base URL (homeserver)
  url += '&baseUrl=${Uri.encodeComponent(client.homeserver.toString())}';

  // Add user ID
  url += '&userId=${Uri.encodeComponent(client.userID!)}';

  // Add device ID
  final deviceId = client.deviceID;
  if (deviceId != null) {
    url += '&deviceId=${Uri.encodeComponent(deviceId)}';
  }

  // Add display name
  final user = await client.fetchOwnProfile();
  if (user.displayName != null) {
    url += '&displayName=${Uri.encodeComponent(user.displayName!)}';
  }

  // Add avatar URL
  if (user.avatarUrl != null) {
    final avatarUrl = user.avatarUrl!.getThumbnail(
      client,
      width: 96,
      height: 96,
      method: ThumbnailMethod.scale,
    );
    url += '&avatarUrl=${Uri.encodeComponent(avatarUrl.toString())}';
  }

  // Add room name
  final roomName = room.getLocalizedDisplayname();
  url += '&roomName=${Uri.encodeComponent(roomName)}';

  // Add theme
  url += '&theme=${Uri.encodeComponent('light')}';

  // Add client ID
  url += '&clientId=${Uri.encodeComponent('matrix-dart-sdk')}';

  // Add client theme
  url += '&clientTheme=${Uri.encodeComponent('light')}';

  // Add language
  url += '&lang=${Uri.encodeComponent('en')}';

  // Add optional properties
  if (properties.fontScale != null) {
    url += '&fontScale=${properties.fontScale}';
  }
  if (properties.font != null) {
    url += '&font=${Uri.encodeComponent(properties.font!)}';
  }
  if (properties.analyticsId != null) {
    url += '&analyticsId=${Uri.encodeComponent(properties.analyticsId!)}';
  }
  if (properties.sentryUrl != null) {
    url += '&sentryUrl=${Uri.encodeComponent(properties.sentryUrl!)}';
  }
  if (properties.rageshakeUrl != null) {
    url += '&rageshakeUrl=${Uri.encodeComponent(properties.rageshakeUrl!)}';
  }

  // Add configuration as fragment parameters
  if (config != null) {
    final fragmentParams = config.toFragmentParams();
    for (final entry in fragmentParams.entries) {
      url += '&${entry.key}=${Uri.encodeComponent(entry.value)}';
    }
  }

  return url;
}

/// Create widget settings for Element Call.
Future<WidgetSettings> createElementCallWidgetSettings({
  required Client client,
  required Room room,
  required ElementCallWidgetProperties properties,
  ElementCallWidgetConfig? config,
}) async {
  final url = await buildElementCallWidgetUrl(
    client: client,
    room: room,
    properties: properties,
    config: config,
  );

  return WidgetSettings(
    widgetId: properties.widgetId,
    url: url,
    initOnContentLoad: config?.preload ?? true,
  );
}