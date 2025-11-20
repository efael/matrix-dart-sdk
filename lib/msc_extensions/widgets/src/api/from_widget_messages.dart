import 'package:matrix/msc_extensions/widgets/src/api/common_types.dart';
import 'package:matrix/msc_extensions/widgets/widgets.dart';

// Empty message types are imported from common_types.dart as type aliases
// Re-export them for convenience
export 'common_types.dart'
    show
        SupportedApiVersionsRequest,
        ContentLoadedNotification,
        GetOpenIdRequest;

/// FromWidget: send_event request
class SendEventRequest {
  final String type;
  final Map<String, dynamic> content;
  final String? stateKey;

  SendEventRequest({
    required this.type,
    required this.content,
    this.stateKey,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        if (stateKey != null) 'state_key': stateKey,
      };

  static SendEventRequest fromJson(Map<String, dynamic> json) =>
      SendEventRequest(
        type: json['type'] as String,
        content: json['content'] as Map<String, dynamic>,
        stateKey: json['state_key'] as String?,
      );
}

/// FromWidget: read_events request
class ReadEventsRequest {
  final String? type;
  final String? stateKey;
  final int? limit;

  ReadEventsRequest({
    this.type,
    this.stateKey,
    this.limit,
  });

  Map<String, dynamic> toJson() => {
        if (type != null) 'type': type,
        if (stateKey != null) 'state_key': stateKey,
        if (limit != null) 'limit': limit,
      };

  static ReadEventsRequest fromJson(Map<String, dynamic> json) =>
      ReadEventsRequest(
        type: json['type'] as String?,
        stateKey: json['state_key'] as String?,
        limit: json['limit'] as int?,
      );
}

/// FromWidget: send_to_device request (MSC3819)
class SendToDeviceRequest {
  final String type;
  final bool encrypted;
  final Map<String, Map<String, Map<String, dynamic>>> messages;

  SendToDeviceRequest({
    required this.type,
    required this.encrypted,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'encrypted': encrypted,
        'messages': messages,
      };

  static SendToDeviceRequest fromJson(Map<String, dynamic> json) =>
      SendToDeviceRequest(
        type: json['type'] as String,
        encrypted: json['encrypted'] as bool,
        messages: (json['messages'] as Map<String, dynamic>).map(
          (userId, devices) => MapEntry(
            userId,
            (devices as Map<String, dynamic>).map(
              (deviceId, content) => MapEntry(
                deviceId,
                content as Map<String, dynamic>,
              ),
            ),
          ),
        ),
      );
}

/// FromWidget: update_delayed_event request (MSC4157)
class UpdateDelayedEventRequest {
  final String action;
  final String delayId;

  UpdateDelayedEventRequest({
    required this.action,
    required this.delayId,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'delay_id': delayId,
      };

  static UpdateDelayedEventRequest fromJson(Map<String, dynamic> json) =>
      UpdateDelayedEventRequest(
        action: json['action'] as String,
        delayId: json['delay_id'] as String,
      );
}

/// FromWidget: navigate request
class NavigateRequest {
  final String uri;

  NavigateRequest({required this.uri});

  Map<String, dynamic> toJson() => {'uri': uri};

  static NavigateRequest fromJson(Map<String, dynamic> json) =>
      NavigateRequest(uri: json['uri'] as String);
}

/// FromWidget: read_relations request
class ReadRelationsRequest {
  final String eventId;
  final String? relationType;
  final String? eventType;
  final int? limit;
  final String? from;
  final String? to;
  final String? direction;

  ReadRelationsRequest({
    required this.eventId,
    this.relationType,
    this.eventType,
    this.limit,
    this.from,
    this.to,
    this.direction,
  });

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        if (relationType != null) 'rel_type': relationType,
        if (eventType != null) 'event_type': eventType,
        if (limit != null) 'limit': limit,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (direction != null) 'direction': direction,
      };

  static ReadRelationsRequest fromJson(Map<String, dynamic> json) =>
      ReadRelationsRequest(
        eventId: json['event_id'] as String,
        relationType: json['rel_type'] as String?,
        eventType: json['event_type'] as String?,
        limit: json['limit'] as int?,
        from: json['from'] as String?,
        to: json['to'] as String?,
        direction: json['direction'] as String?,
      );
}

/// FromWidget: get_user_directory_search request
class GetUserDirectorySearchRequest {
  final String searchTerm;
  final int? limit;

  GetUserDirectorySearchRequest({
    required this.searchTerm,
    this.limit,
  });

  Map<String, dynamic> toJson() => {
        'search_term': searchTerm,
        if (limit != null) 'limit': limit,
      };

  static GetUserDirectorySearchRequest fromJson(Map<String, dynamic> json) =>
      GetUserDirectorySearchRequest(
        searchTerm: json['search_term'] as String,
        limit: json['limit'] as int?,
      );
}

/// FromWidget: read_state_event request
class ReadStateEventRequest {
  final String type;
  final String stateKey;

  ReadStateEventRequest({
    required this.type,
    required this.stateKey,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'state_key': stateKey,
      };

  static ReadStateEventRequest fromJson(Map<String, dynamic> json) =>
      ReadStateEventRequest(
        type: json['type'] as String,
        stateKey: json['state_key'] as String,
      );
}

/// FromWidget: send_state_event request
class SendStateEventRequest {
  final String type;
  final String stateKey;
  final Map<String, dynamic> content;

  SendStateEventRequest({
    required this.type,
    required this.stateKey,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'state_key': stateKey,
        'content': content,
      };

  static SendStateEventRequest fromJson(Map<String, dynamic> json) =>
      SendStateEventRequest(
        type: json['type'] as String,
        stateKey: json['state_key'] as String,
        content: json['content'] as Map<String, dynamic>,
      );
}

/// FromWidget: get_media_config request
class GetMediaConfigRequest {
  GetMediaConfigRequest();

  Map<String, dynamic> toJson() => {};

  static GetMediaConfigRequest fromJson(Map<String, dynamic> json) =>
      GetMediaConfigRequest();
}

/// FromWidget: upload_file request
class UploadFileRequest {
  final String file;

  UploadFileRequest({required this.file});

  Map<String, dynamic> toJson() => {'file': file};

  static UploadFileRequest fromJson(Map<String, dynamic> json) =>
      UploadFileRequest(file: json['file'] as String);
}

/// FromWidget: download_file request
class DownloadFileRequest {
  final String contentUri;

  DownloadFileRequest({required this.contentUri});

  Map<String, dynamic> toJson() => {'content_uri': contentUri};

  static DownloadFileRequest fromJson(Map<String, dynamic> json) =>
      DownloadFileRequest(contentUri: json['content_uri'] as String);
}
