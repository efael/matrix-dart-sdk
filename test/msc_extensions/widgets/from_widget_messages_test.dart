import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('SupportedApiVersionsRequest', () {
    test('Serialization', () {
      final request = SupportedApiVersionsRequest();
      final json = request.toJson();
      expect(json, isEmpty);

      final restored = SupportedApiVersionsRequest.fromJson(json);
      expect(restored, isA<SupportedApiVersionsRequest>());
    });
  });

  group('ContentLoadedNotification', () {
    test('Serialization', () {
      final notification = ContentLoadedNotification();
      final json = notification.toJson();
      expect(json, isEmpty);

      final restored = ContentLoadedNotification.fromJson(json);
      expect(restored, isA<ContentLoadedNotification>());
    });
  });

  group('GetOpenIdRequest', () {
    test('Serialization', () {
      final request = GetOpenIdRequest();
      final json = request.toJson();
      expect(json, isEmpty);

      final restored = GetOpenIdRequest.fromJson(json);
      expect(restored, isA<GetOpenIdRequest>());
    });
  });

  group('SendEventRequest', () {
    test('Message-like event serialization', () {
      final request = SendEventRequest(
        type: 'm.room.message',
        content: {'msgtype': 'm.text', 'body': 'Hello'},
      );

      final json = request.toJson();
      expect(json['type'], 'm.room.message');
      expect(json['content'], {'msgtype': 'm.text', 'body': 'Hello'});
      expect(json['state_key'], isNull);

      final restored = SendEventRequest.fromJson(json);
      expect(restored.type, 'm.room.message');
      expect(restored.content, {'msgtype': 'm.text', 'body': 'Hello'});
      expect(restored.stateKey, isNull);
    });

    test('State event serialization', () {
      final request = SendEventRequest(
        type: 'm.room.topic',
        content: {'topic': 'Test'},
        stateKey: '',
      );

      final json = request.toJson();
      expect(json['type'], 'm.room.topic');
      expect(json['content'], {'topic': 'Test'});
      expect(json['state_key'], '');

      final restored = SendEventRequest.fromJson(json);
      expect(restored.type, 'm.room.topic');
      expect(restored.content, {'topic': 'Test'});
      expect(restored.stateKey, '');
    });
  });

  group('ReadEventsRequest', () {
    test('Empty filter serialization', () {
      final request = ReadEventsRequest();

      final json = request.toJson();
      expect(json, isEmpty);

      final restored = ReadEventsRequest.fromJson(json);
      expect(restored.type, isNull);
      expect(restored.stateKey, isNull);
      expect(restored.limit, isNull);
    });

    test('Full filter serialization', () {
      final request = ReadEventsRequest(
        type: 'm.room.message',
        stateKey: '',
        limit: 50,
      );

      final json = request.toJson();
      expect(json['type'], 'm.room.message');
      expect(json['state_key'], '');
      expect(json['limit'], 50);

      final restored = ReadEventsRequest.fromJson(json);
      expect(restored.type, 'm.room.message');
      expect(restored.stateKey, '');
      expect(restored.limit, 50);
    });
  });

  group('SendToDeviceRequest', () {
    test('Serialization', () {
      final request = SendToDeviceRequest(
        type: 'm.room_key',
        encrypted: true,
        messages: {
          '@alice:example.com': {
            'DEVICE1': {'foo': 'bar'},
          },
        },
      );

      final json = request.toJson();
      expect(json['type'], 'm.room_key');
      expect(json['encrypted'], true);
      expect(json['messages']['@alice:example.com']['DEVICE1'], {'foo': 'bar'});

      final restored = SendToDeviceRequest.fromJson(json);
      expect(restored.type, 'm.room_key');
      expect(restored.encrypted, true);
      expect(restored.messages['@alice:example.com']!['DEVICE1'], {'foo': 'bar'});
    });
  });

  group('UpdateDelayedEventRequest', () {
    test('Serialization', () {
      final request = UpdateDelayedEventRequest(
        action: 'cancel',
        delayId: 'delay_123',
      );

      final json = request.toJson();
      expect(json['action'], 'cancel');
      expect(json['delay_id'], 'delay_123');

      final restored = UpdateDelayedEventRequest.fromJson(json);
      expect(restored.action, 'cancel');
      expect(restored.delayId, 'delay_123');
    });
  });

  group('NavigateRequest', () {
    test('Serialization', () {
      final request = NavigateRequest(uri: 'https://example.com');

      final json = request.toJson();
      expect(json['uri'], 'https://example.com');

      final restored = NavigateRequest.fromJson(json);
      expect(restored.uri, 'https://example.com');
    });
  });

  group('ReadRelationsRequest', () {
    test('Minimal serialization', () {
      final request = ReadRelationsRequest(eventId: '\$event123');

      final json = request.toJson();
      expect(json['event_id'], '\$event123');
      expect(json['rel_type'], isNull);
      expect(json['event_type'], isNull);

      final restored = ReadRelationsRequest.fromJson(json);
      expect(restored.eventId, '\$event123');
      expect(restored.relationType, isNull);
    });

    test('Full serialization', () {
      final request = ReadRelationsRequest(
        eventId: '\$event123',
        relationType: 'm.annotation',
        eventType: 'm.reaction',
        limit: 100,
        from: 'token1',
        to: 'token2',
        direction: 'b',
      );

      final json = request.toJson();
      expect(json['event_id'], '\$event123');
      expect(json['rel_type'], 'm.annotation');
      expect(json['event_type'], 'm.reaction');
      expect(json['limit'], 100);
      expect(json['from'], 'token1');
      expect(json['to'], 'token2');
      expect(json['direction'], 'b');

      final restored = ReadRelationsRequest.fromJson(json);
      expect(restored.eventId, '\$event123');
      expect(restored.relationType, 'm.annotation');
      expect(restored.eventType, 'm.reaction');
      expect(restored.limit, 100);
      expect(restored.from, 'token1');
      expect(restored.to, 'token2');
      expect(restored.direction, 'b');
    });
  });

  group('GetUserDirectorySearchRequest', () {
    test('Minimal serialization', () {
      final request = GetUserDirectorySearchRequest(searchTerm: 'alice');

      final json = request.toJson();
      expect(json['search_term'], 'alice');
      expect(json['limit'], isNull);

      final restored = GetUserDirectorySearchRequest.fromJson(json);
      expect(restored.searchTerm, 'alice');
      expect(restored.limit, isNull);
    });

    test('Full serialization', () {
      final request = GetUserDirectorySearchRequest(
        searchTerm: 'alice',
        limit: 10,
      );

      final json = request.toJson();
      expect(json['search_term'], 'alice');
      expect(json['limit'], 10);

      final restored = GetUserDirectorySearchRequest.fromJson(json);
      expect(restored.searchTerm, 'alice');
      expect(restored.limit, 10);
    });
  });

  group('ReadStateEventRequest', () {
    test('Serialization', () {
      final request = ReadStateEventRequest(
        type: 'm.room.topic',
        stateKey: '',
      );

      final json = request.toJson();
      expect(json['type'], 'm.room.topic');
      expect(json['state_key'], '');

      final restored = ReadStateEventRequest.fromJson(json);
      expect(restored.type, 'm.room.topic');
      expect(restored.stateKey, '');
    });
  });

  group('SendStateEventRequest', () {
    test('Serialization', () {
      final request = SendStateEventRequest(
        type: 'm.room.topic',
        stateKey: '',
        content: {'topic': 'New Topic'},
      );

      final json = request.toJson();
      expect(json['type'], 'm.room.topic');
      expect(json['state_key'], '');
      expect(json['content'], {'topic': 'New Topic'});

      final restored = SendStateEventRequest.fromJson(json);
      expect(restored.type, 'm.room.topic');
      expect(restored.stateKey, '');
      expect(restored.content, {'topic': 'New Topic'});
    });
  });

  group('GetMediaConfigRequest', () {
    test('Serialization', () {
      final request = GetMediaConfigRequest();
      final json = request.toJson();
      expect(json, isEmpty);

      final restored = GetMediaConfigRequest.fromJson(json);
      expect(restored, isA<GetMediaConfigRequest>());
    });
  });

  group('UploadFileRequest', () {
    test('Serialization', () {
      final request = UploadFileRequest(file: 'data:image/png;base64,...');

      final json = request.toJson();
      expect(json['file'], 'data:image/png;base64,...');

      final restored = UploadFileRequest.fromJson(json);
      expect(restored.file, 'data:image/png;base64,...');
    });
  });

  group('DownloadFileRequest', () {
    test('Serialization', () {
      final request = DownloadFileRequest(contentUri: 'mxc://example.com/abc');

      final json = request.toJson();
      expect(json['content_uri'], 'mxc://example.com/abc');

      final restored = DownloadFileRequest.fromJson(json);
      expect(restored.contentUri, 'mxc://example.com/abc');
    });
  });
}
