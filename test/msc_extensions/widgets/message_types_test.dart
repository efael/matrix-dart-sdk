import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('Supported API Versions', () {
    test('Contains expected versions', () {
      expect(supportedApiVersions, contains('0.0.1'));
      expect(supportedApiVersions, contains('0.0.2'));
      expect(supportedApiVersions, contains('MSC2762'));
      expect(supportedApiVersions, contains('MSC2871'));
      expect(supportedApiVersions, contains('MSC3819'));
      expect(supportedApiVersions, contains('MSC4157'));
    });

    test('Has correct number of versions', () {
      expect(supportedApiVersions.length, 6);
    });
  });

  group('MessageDirection', () {
    test('FromWidget has correct value', () {
      expect(MessageDirection.fromWidget.value, 'FromWidget');
    });

    test('ToWidget has correct value', () {
      expect(MessageDirection.toWidget.value, 'ToWidget');
    });

    test('Parse FromWidget from string', () {
      final direction = MessageDirection.fromString('FromWidget');
      expect(direction, MessageDirection.fromWidget);
    });

    test('Parse ToWidget from string', () {
      final direction = MessageDirection.fromString('ToWidget');
      expect(direction, MessageDirection.toWidget);
    });

    test('Throw on invalid direction', () {
      expect(
        () => MessageDirection.fromString('Invalid'),
        throwsArgumentError,
      );
    });
  });

  group('WidgetMessage', () {
    test('Create basic message', () {
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_123',
        widgetId: 'widget_1',
        action: 'test_action',
        data: {'key': 'value'},
      );

      expect(message.api, MessageDirection.fromWidget);
      expect(message.requestId, 'req_123');
      expect(message.widgetId, 'widget_1');
      expect(message.action, 'test_action');
      expect(message.data, {'key': 'value'});
    });

    test('Message without requestId', () {
      final message = WidgetMessage(
        api: MessageDirection.toWidget,
        widgetId: 'widget_1',
        action: 'notify',
      );

      expect(message.requestId, isNull);
      expect(message.data, isEmpty);
    });

    test('JSON serialization with requestId', () {
      final message = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_123',
        widgetId: 'widget_1',
        action: 'test_action',
        data: {'key': 'value'},
      );

      final json = message.toJson();
      expect(json['api'], 'FromWidget');
      expect(json['requestId'], 'req_123');
      expect(json['widgetId'], 'widget_1');
      expect(json['action'], 'test_action');
      expect(json['data'], {'key': 'value'});
    });

    test('JSON serialization without requestId', () {
      final message = WidgetMessage(
        api: MessageDirection.toWidget,
        widgetId: 'widget_1',
        action: 'notify',
      );

      final json = message.toJson();
      expect(json.containsKey('requestId'), false);
      expect(json['api'], 'ToWidget');
      expect(json['widgetId'], 'widget_1');
      expect(json['action'], 'notify');
      expect(json['data'], isEmpty);
    });

    test('JSON deserialization', () {
      final json = {
        'api': 'FromWidget',
        'requestId': 'req_123',
        'widgetId': 'widget_1',
        'action': 'test_action',
        'data': {'key': 'value'},
      };

      final message = WidgetMessage.fromJson(json);
      expect(message.api, MessageDirection.fromWidget);
      expect(message.requestId, 'req_123');
      expect(message.widgetId, 'widget_1');
      expect(message.action, 'test_action');
      expect(message.data, {'key': 'value'});
    });

    test('JSON deserialization without requestId', () {
      final json = {
        'api': 'ToWidget',
        'widgetId': 'widget_1',
        'action': 'notify',
      };

      final message = WidgetMessage.fromJson(json);
      expect(message.requestId, isNull);
      expect(message.data, isEmpty);
    });

    test('Round-trip serialization', () {
      final original = WidgetMessage(
        api: MessageDirection.fromWidget,
        requestId: 'req_123',
        widgetId: 'widget_1',
        action: 'test_action',
        data: {'key': 'value', 'nested': {'data': 123}},
      );

      final json = original.toJson();
      final restored = WidgetMessage.fromJson(json);

      expect(restored.api, original.api);
      expect(restored.requestId, original.requestId);
      expect(restored.widgetId, original.widgetId);
      expect(restored.action, original.action);
      expect(restored.data, original.data);
    });
  });

  group('WidgetError', () {
    test('Create basic error', () {
      final error = WidgetError(
        code: 'TEST_ERROR',
        message: 'Test error message',
      );

      expect(error.code, 'TEST_ERROR');
      expect(error.message, 'Test error message');
      expect(error.matrixError, isNull);
    });

    test('Create error with Matrix error', () {
      final error = WidgetError(
        code: 'MATRIX_ERROR',
        message: 'Matrix API failed',
        matrixError: {
          'errcode': 'M_FORBIDDEN',
          'error': 'Access denied',
        },
      );

      expect(error.matrixError, isNotNull);
      expect(error.matrixError!['errcode'], 'M_FORBIDDEN');
    });

    test('JSON serialization without Matrix error', () {
      final error = WidgetError(
        code: 'TEST_ERROR',
        message: 'Test error message',
      );

      final json = error.toJson();
      expect(json['code'], 'TEST_ERROR');
      expect(json['message'], 'Test error message');
      expect(json.containsKey('matrix_error'), false);
    });

    test('JSON serialization with Matrix error', () {
      final error = WidgetError(
        code: 'MATRIX_ERROR',
        message: 'Matrix API failed',
        matrixError: {
          'errcode': 'M_FORBIDDEN',
          'error': 'Access denied',
        },
      );

      final json = error.toJson();
      expect(json['code'], 'MATRIX_ERROR');
      expect(json['message'], 'Matrix API failed');
      expect(json['matrix_error'], {
        'errcode': 'M_FORBIDDEN',
        'error': 'Access denied',
      });
    });

    test('JSON deserialization', () {
      final json = {
        'code': 'TEST_ERROR',
        'message': 'Test error message',
        'matrix_error': {
          'errcode': 'M_FORBIDDEN',
          'error': 'Access denied',
        },
      };

      final error = WidgetError.fromJson(json);
      expect(error.code, 'TEST_ERROR');
      expect(error.message, 'Test error message');
      expect(error.matrixError, isNotNull);
      expect(error.matrixError!['errcode'], 'M_FORBIDDEN');
    });

    test('Round-trip serialization', () {
      final original = WidgetError(
        code: 'MATRIX_ERROR',
        message: 'Matrix API failed',
        matrixError: {
          'errcode': 'M_FORBIDDEN',
          'error': 'Access denied',
        },
      );

      final json = original.toJson();
      final restored = WidgetError.fromJson(json);

      expect(restored.code, original.code);
      expect(restored.message, original.message);
      expect(restored.matrixError, original.matrixError);
    });
  });

  group('WidgetErrorCode', () {
    test('Standard error codes are defined', () {
      expect(WidgetErrorCode.notAllowed, 'NOT_ALLOWED');
      expect(WidgetErrorCode.invalidRequest, 'INVALID_REQUEST');
      expect(WidgetErrorCode.timeout, 'TIMEOUT');
      expect(WidgetErrorCode.transportError, 'TRANSPORT_ERROR');
      expect(WidgetErrorCode.matrixError, 'MATRIX_ERROR');
      expect(WidgetErrorCode.unknown, 'UNKNOWN');
    });
  });
}
