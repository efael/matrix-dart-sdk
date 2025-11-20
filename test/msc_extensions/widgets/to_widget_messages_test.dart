import 'package:test/test.dart';

import 'package:matrix/matrix.dart';
import 'package:matrix/msc_extensions/widgets/widgets.dart';
import 'package:matrix/msc_extensions/widgets/src/models/openid.dart'
    as widget_openid;

void main() {
  group('SupportedApiVersionsResponse', () {
    test('Serialization', () {
      final response = SupportedApiVersionsResponse(
        supportedVersions: ['0.0.1', '0.0.2', 'MSC2762'],
      );

      final json = response.toJson();
      expect(json['supported_versions'], ['0.0.1', '0.0.2', 'MSC2762']);

      final restored = SupportedApiVersionsResponse.fromJson(json);
      expect(restored.supportedVersions, ['0.0.1', '0.0.2', 'MSC2762']);
    });
  });

  group('CapabilitiesResponse', () {
    test('Serialization', () {
      const caps = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
        send: [StateWithType('m.room.topic')],
        requiresClient: true,
      );

      final response = CapabilitiesResponse(capabilities: caps);

      final json = response.toJson();
      expect(json['capabilities'], isA<Map<String, dynamic>>());
      expect(json['capabilities']['read'], ['m.room.message']);
      expect(json['capabilities']['send'], ['m.room.topic']);
      expect(json['capabilities']['requires_client'], true);

      final restored = CapabilitiesResponse.fromJson(json);
      expect(restored.capabilities.read.length, 1);
      expect(restored.capabilities.send.length, 1);
      expect(restored.capabilities.requiresClient, true);
    });
  });

  group('NotifyCapabilitiesNotification', () {
    test('Serialization', () {
      const requested = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
      );
      const approved = WidgetCapabilities(
        read: [MessageLikeWithType('m.room.message')],
      );

      final notification = NotifyCapabilitiesNotification(
        requested: requested,
        approved: approved,
      );

      final json = notification.toJson();
      expect(json['requested'], isA<Map<String, dynamic>>());
      expect(json['approved'], isA<Map<String, dynamic>>());

      final restored = NotifyCapabilitiesNotification.fromJson(json);
      expect(restored.requested.read.length, 1);
      expect(restored.approved.read.length, 1);
    });
  });

  group('OpenIdCredentialsResponse', () {
    test('Allowed state serialization', () {
      final credentials = widget_openid.OpenIdCredentials(
        accessToken: 'token123',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );
      final state = widget_openid.OpenIdState(
        originalRequestId: 'req_123',
        credentials: credentials,
      );

      final response =
          OpenIdCredentialsResponse(state: widget_openid.OpenIdAllowed(state));

      final json = response.toJson();
      expect(json['state'], 'allowed');
      expect(json['access_token'], 'token123');
      expect(json['expires_in'], 3600);
      expect(json['matrix_server_name'], 'matrix.example.com');
    });

    test('Blocked state serialization', () {
      final response = OpenIdCredentialsResponse(
          state: const widget_openid.OpenIdBlocked());

      final json = response.toJson();
      expect(json['state'], 'blocked');
    });

    test('Pending state serialization', () {
      final response = OpenIdCredentialsResponse(
          state: const widget_openid.OpenIdPending());

      final json = response.toJson();
      expect(json['state'], 'request');
    });

    test('Allowed state deserialization', () {
      final json = {
        'state': 'allowed',
        'access_token': 'token123',
        'expires_in': 3600,
        'matrix_server_name': 'matrix.example.com',
        'token_type': 'Bearer',
        'request_id': 'req_123',
      };

      final restored = OpenIdCredentialsResponse.fromJson(json);
      expect(restored.state, isA<widget_openid.OpenIdAllowed>());
      final allowed = restored.state as widget_openid.OpenIdAllowed;
      expect(allowed.state.credentials.accessToken, 'token123');
      expect(
          allowed.state.credentials.expiresIn, const Duration(seconds: 3600));
      expect(allowed.state.credentials.matrixServerName, 'matrix.example.com');
    });

    test('Blocked state deserialization', () {
      final json = {'state': 'blocked'};

      final restored = OpenIdCredentialsResponse.fromJson(json);
      expect(restored.state, isA<widget_openid.OpenIdBlocked>());
    });

    test('Pending state deserialization', () {
      final json = {'state': 'request'};

      final restored = OpenIdCredentialsResponse.fromJson(json);
      expect(restored.state, isA<widget_openid.OpenIdPending>());
    });
  });

  group('SendEventResponse', () {
    test('Serialization without roomId', () {
      final response = SendEventResponse(eventId: '\$event123');

      final json = response.toJson();
      expect(json['event_id'], '\$event123');
      expect(json['room_id'], isNull);

      final restored = SendEventResponse.fromJson(json);
      expect(restored.eventId, '\$event123');
      expect(restored.roomId, isNull);
    });

    test('Serialization with roomId', () {
      final response = SendEventResponse(
        eventId: '\$event123',
        roomId: '!room:example.com',
      );

      final json = response.toJson();
      expect(json['event_id'], '\$event123');
      expect(json['room_id'], '!room:example.com');

      final restored = SendEventResponse.fromJson(json);
      expect(restored.eventId, '\$event123');
      expect(restored.roomId, '!room:example.com');
    });
  });

  group('ReadEventsResponse', () {
    test('Serialization', () {
      final events = [
        MatrixEvent(
          type: 'm.room.message',
          content: {'body': 'Hello'},
          senderId: '@user:example.com',
          eventId: '\$event1',
          originServerTs: DateTime(2024, 1, 1),
        ),
      ];

      final response = ReadEventsResponse(events: events);

      final json = response.toJson();
      expect(json['events'], isA<List>());
      expect(json['events'].length, 1);

      final restored = ReadEventsResponse.fromJson(json);
      expect(restored.events.length, 1);
      expect(restored.events[0].type, 'm.room.message');
      expect(restored.events[0].content['body'], 'Hello');
    });
  });

  group('NotifyNewEventNotification', () {
    test('Serialization', () {
      final event = MatrixEvent(
        type: 'm.room.message',
        content: {'body': 'Hello'},
        senderId: '@user:example.com',
        eventId: '\$event1',
        originServerTs: DateTime(2024, 1, 1),
      );

      final notification = NotifyNewEventNotification(event: event);

      final json = notification.toJson();
      expect(json['type'], 'm.room.message');
      expect(json['content']['body'], 'Hello');

      final restored = NotifyNewEventNotification.fromJson(json);
      expect(restored.event.type, 'm.room.message');
      expect(restored.event.content['body'], 'Hello');
    });
  });

  group('NotifyStateUpdateNotification', () {
    test('Serialization', () {
      final event = MatrixEvent(
        type: 'm.room.topic',
        content: {'topic': 'New Topic'},
        senderId: '@user:example.com',
        stateKey: '',
        eventId: '\$event1',
        originServerTs: DateTime(2024, 1, 1),
      );

      final notification = NotifyStateUpdateNotification(event: event);

      final json = notification.toJson();
      expect(json['type'], 'm.room.topic');
      expect(json['content']['topic'], 'New Topic');

      final restored = NotifyStateUpdateNotification.fromJson(json);
      expect(restored.event.type, 'm.room.topic');
      expect(restored.event.content['topic'], 'New Topic');
    });
  });

  group('SendToDeviceResponse', () {
    test('Serialization', () {
      final response = SendToDeviceResponse();
      final json = response.toJson();
      expect(json, isEmpty);

      final restored = SendToDeviceResponse.fromJson(json);
      expect(restored, isA<SendToDeviceResponse>());
    });
  });

  group('UpdateDelayedEventResponse', () {
    test('Serialization', () {
      final response = UpdateDelayedEventResponse();
      final json = response.toJson();
      expect(json, isEmpty);

      final restored = UpdateDelayedEventResponse.fromJson(json);
      expect(restored, isA<UpdateDelayedEventResponse>());
    });
  });

  group('NavigateResponse', () {
    test('Serialization', () {
      final response = NavigateResponse();
      final json = response.toJson();
      expect(json, isEmpty);

      final restored = NavigateResponse.fromJson(json);
      expect(restored, isA<NavigateResponse>());
    });
  });

  group('ReadRelationsResponse', () {
    test('Serialization with chunks', () {
      final events = [
        MatrixEvent(
          type: 'm.reaction',
          content: {},
          senderId: '@user:example.com',
          eventId: '\$event1',
          originServerTs: DateTime(2024, 1, 1),
        ),
      ];

      final response = ReadRelationsResponse(
        chunk: events,
        nextBatch: 'next_token',
        prevBatch: 'prev_token',
      );

      final json = response.toJson();
      expect(json['chunk'], isA<List>());
      expect(json['chunk'].length, 1);
      expect(json['next_batch'], 'next_token');
      expect(json['prev_batch'], 'prev_token');

      final restored = ReadRelationsResponse.fromJson(json);
      expect(restored.chunk.length, 1);
      expect(restored.nextBatch, 'next_token');
      expect(restored.prevBatch, 'prev_token');
    });
  });

  group('GetUserDirectorySearchResponse', () {
    test('Serialization', () {
      final response = GetUserDirectorySearchResponse(
        results: [
          {'user_id': '@alice:example.com', 'display_name': 'Alice'},
        ],
        limited: false,
      );

      final json = response.toJson();
      expect(json['results'], isA<List>());
      expect(json['results'].length, 1);
      expect(json['limited'], false);

      final restored = GetUserDirectorySearchResponse.fromJson(json);
      expect(restored.results.length, 1);
      expect(restored.results[0]['user_id'], '@alice:example.com');
      expect(restored.limited, false);
    });
  });

  group('ReadStateEventResponse', () {
    test('Serialization', () {
      final response = ReadStateEventResponse(
        content: {'topic': 'Room Topic'},
      );

      final json = response.toJson();
      expect(json['topic'], 'Room Topic');

      final restored = ReadStateEventResponse.fromJson(json);
      expect(restored.content['topic'], 'Room Topic');
    });
  });

  group('SendStateEventResponse', () {
    test('Serialization without roomId', () {
      final response = SendStateEventResponse(eventId: '\$event123');

      final json = response.toJson();
      expect(json['event_id'], '\$event123');
      expect(json['room_id'], isNull);

      final restored = SendStateEventResponse.fromJson(json);
      expect(restored.eventId, '\$event123');
      expect(restored.roomId, isNull);
    });

    test('Serialization with roomId', () {
      final response = SendStateEventResponse(
        eventId: '\$event123',
        roomId: '!room:example.com',
      );

      final json = response.toJson();
      expect(json['event_id'], '\$event123');
      expect(json['room_id'], '!room:example.com');

      final restored = SendStateEventResponse.fromJson(json);
      expect(restored.eventId, '\$event123');
      expect(restored.roomId, '!room:example.com');
    });
  });

  group('GetMediaConfigResponse', () {
    test('Serialization', () {
      final response = GetMediaConfigResponse(uploadSize: 52428800);

      final json = response.toJson();
      expect(json['m.upload.size'], 52428800);

      final restored = GetMediaConfigResponse.fromJson(json);
      expect(restored.uploadSize, 52428800);
    });
  });

  group('UploadFileResponse', () {
    test('Serialization', () {
      final response = UploadFileResponse(contentUri: 'mxc://example.com/abc');

      final json = response.toJson();
      expect(json['content_uri'], 'mxc://example.com/abc');

      final restored = UploadFileResponse.fromJson(json);
      expect(restored.contentUri, 'mxc://example.com/abc');
    });
  });

  group('DownloadFileResponse', () {
    test('Serialization', () {
      final response = DownloadFileResponse(file: 'data:image/png;base64,...');

      final json = response.toJson();
      expect(json['file'], 'data:image/png;base64,...');

      final restored = DownloadFileResponse.fromJson(json);
      expect(restored.file, 'data:image/png;base64,...');
    });
  });
}
