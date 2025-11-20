import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/src/api/common_types.dart';
import 'package:matrix/msc_extensions/widgets/src/capabilities/capabilities.dart';
import 'package:matrix/msc_extensions/widgets/src/models/openid.dart'
    as widget_openid;

// Re-export empty response types from common_types
export 'common_types.dart'
    show SendToDeviceResponse, UpdateDelayedEventResponse, NavigateResponse;

/// ToWidget: supported_api_versions response
class SupportedApiVersionsResponse {
  final List<String> supportedVersions;

  SupportedApiVersionsResponse({required this.supportedVersions});

  Map<String, dynamic> toJson() => {
        'supported_versions': supportedVersions,
      };

  static SupportedApiVersionsResponse fromJson(Map<String, dynamic> json) =>
      SupportedApiVersionsResponse(
        supportedVersions: (json['supported_versions'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      );
}

/// ToWidget: capabilities response
class CapabilitiesResponse {
  final WidgetCapabilities capabilities;

  CapabilitiesResponse({required this.capabilities});

  Map<String, dynamic> toJson() => {
        'capabilities': capabilities.toJson(),
      };

  static CapabilitiesResponse fromJson(Map<String, dynamic> json) =>
      CapabilitiesResponse(
        capabilities:
            WidgetCapabilities.fromJson(json['capabilities'] as Map<String, dynamic>),
      );
}

/// ToWidget: notify_capabilities notification
class NotifyCapabilitiesNotification {
  final WidgetCapabilities requested;
  final WidgetCapabilities approved;

  NotifyCapabilitiesNotification({
    required this.requested,
    required this.approved,
  });

  Map<String, dynamic> toJson() => {
        'requested': requested.toJson(),
        'approved': approved.toJson(),
      };

  static NotifyCapabilitiesNotification fromJson(Map<String, dynamic> json) =>
      NotifyCapabilitiesNotification(
        requested: WidgetCapabilities.fromJson(
            json['requested'] as Map<String, dynamic>),
        approved: WidgetCapabilities.fromJson(
            json['approved'] as Map<String, dynamic>),
      );
}

/// ToWidget: openid_credentials response
class OpenIdCredentialsResponse {
  final widget_openid.OpenIdResponse state;

  OpenIdCredentialsResponse({required this.state});

  Map<String, dynamic> toJson() {
    if (state is widget_openid.OpenIdAllowed) {
      final allowed = state as widget_openid.OpenIdAllowed;
      return {
        'state': 'allowed',
        ...allowed.state.credentials.toJson(),
      };
    } else if (state is widget_openid.OpenIdBlocked) {
      return {'state': 'blocked'};
    } else {
      return {'state': 'request'};
    }
  }

  static OpenIdCredentialsResponse fromJson(Map<String, dynamic> json) {
    final stateStr = json['state'] as String;
    if (stateStr == 'allowed') {
      final credentials = widget_openid.OpenIdCredentials.fromJson(json);
      final state = widget_openid.OpenIdState(
        originalRequestId: json['request_id'] as String? ?? '',
        credentials: credentials,
      );
      return OpenIdCredentialsResponse(
          state: widget_openid.OpenIdAllowed(state));
    } else if (stateStr == 'blocked') {
      return OpenIdCredentialsResponse(
          state: const widget_openid.OpenIdBlocked());
    } else {
      return OpenIdCredentialsResponse(
          state: const widget_openid.OpenIdPending());
    }
  }
}

/// ToWidget: send_event response
class SendEventResponse {
  final String eventId;
  final String? roomId;

  SendEventResponse({
    required this.eventId,
    this.roomId,
  });

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        if (roomId != null) 'room_id': roomId,
      };

  static SendEventResponse fromJson(Map<String, dynamic> json) =>
      SendEventResponse(
        eventId: json['event_id'] as String,
        roomId: json['room_id'] as String?,
      );
}

/// ToWidget: read_events response
class ReadEventsResponse {
  final List<MatrixEvent> events;

  ReadEventsResponse({required this.events});

  Map<String, dynamic> toJson() => {
        'events': events.map((e) => e.toJson()).toList(),
      };

  static ReadEventsResponse fromJson(Map<String, dynamic> json) =>
      ReadEventsResponse(
        events: (json['events'] as List<dynamic>)
            .map((e) => MatrixEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// ToWidget: notify_new_event notification
class NotifyNewEventNotification {
  final MatrixEvent event;

  NotifyNewEventNotification({required this.event});

  Map<String, dynamic> toJson() => event.toJson();

  static NotifyNewEventNotification fromJson(Map<String, dynamic> json) =>
      NotifyNewEventNotification(
        event: MatrixEvent.fromJson(json),
      );
}

/// ToWidget: notify_state_update notification
class NotifyStateUpdateNotification {
  final MatrixEvent event;

  NotifyStateUpdateNotification({required this.event});

  Map<String, dynamic> toJson() => event.toJson();

  static NotifyStateUpdateNotification fromJson(Map<String, dynamic> json) =>
      NotifyStateUpdateNotification(
        event: MatrixEvent.fromJson(json),
      );
}

// Empty response types are imported from common_types.dart as type aliases
// SendToDeviceResponse, UpdateDelayedEventResponse, NavigateResponse

/// ToWidget: read_relations response
class ReadRelationsResponse {
  final List<MatrixEvent> chunk;
  final String? nextBatch;
  final String? prevBatch;

  ReadRelationsResponse({
    required this.chunk,
    this.nextBatch,
    this.prevBatch,
  });

  Map<String, dynamic> toJson() => {
        'chunk': chunk.map((e) => e.toJson()).toList(),
        if (nextBatch != null) 'next_batch': nextBatch,
        if (prevBatch != null) 'prev_batch': prevBatch,
      };

  static ReadRelationsResponse fromJson(Map<String, dynamic> json) =>
      ReadRelationsResponse(
        chunk: (json['chunk'] as List<dynamic>)
            .map((e) => MatrixEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextBatch: json['next_batch'] as String?,
        prevBatch: json['prev_batch'] as String?,
      );
}

/// ToWidget: get_user_directory_search response
class GetUserDirectorySearchResponse {
  final List<Map<String, dynamic>> results;
  final bool limited;

  GetUserDirectorySearchResponse({
    required this.results,
    required this.limited,
  });

  Map<String, dynamic> toJson() => {
        'results': results,
        'limited': limited,
      };

  static GetUserDirectorySearchResponse fromJson(Map<String, dynamic> json) =>
      GetUserDirectorySearchResponse(
        results: (json['results'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
        limited: json['limited'] as bool,
      );
}

/// ToWidget: read_state_event response
class ReadStateEventResponse {
  final Map<String, dynamic> content;

  ReadStateEventResponse({required this.content});

  Map<String, dynamic> toJson() => content;

  static ReadStateEventResponse fromJson(Map<String, dynamic> json) =>
      ReadStateEventResponse(content: json);
}

/// ToWidget: send_state_event response
class SendStateEventResponse {
  final String eventId;
  final String? roomId;

  SendStateEventResponse({
    required this.eventId,
    this.roomId,
  });

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        if (roomId != null) 'room_id': roomId,
      };

  static SendStateEventResponse fromJson(Map<String, dynamic> json) =>
      SendStateEventResponse(
        eventId: json['event_id'] as String,
        roomId: json['room_id'] as String?,
      );
}

/// ToWidget: get_media_config response
class GetMediaConfigResponse {
  final int uploadSize;

  GetMediaConfigResponse({required this.uploadSize});

  Map<String, dynamic> toJson() => {
        'm.upload.size': uploadSize,
      };

  static GetMediaConfigResponse fromJson(Map<String, dynamic> json) =>
      GetMediaConfigResponse(
        uploadSize: json['m.upload.size'] as int,
      );
}

/// ToWidget: upload_file response
class UploadFileResponse {
  final String contentUri;

  UploadFileResponse({required this.contentUri});

  Map<String, dynamic> toJson() => {
        'content_uri': contentUri,
      };

  static UploadFileResponse fromJson(Map<String, dynamic> json) =>
      UploadFileResponse(
        contentUri: json['content_uri'] as String,
      );
}

/// ToWidget: download_file response
class DownloadFileResponse {
  final String file;

  DownloadFileResponse({required this.file});

  Map<String, dynamic> toJson() => {
        'file': file,
      };

  static DownloadFileResponse fromJson(Map<String, dynamic> json) =>
      DownloadFileResponse(
        file: json['file'] as String,
      );
}
