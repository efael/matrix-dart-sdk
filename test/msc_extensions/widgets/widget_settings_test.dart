import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('WidgetSettings', () {
    test('Create widget settings', () {
      final settings = WidgetSettings(
        widgetId: 'test_widget',
        url: 'https://example.com/widget',
        initOnContentLoad: true,
      );

      expect(settings.widgetId, 'test_widget');
      expect(settings.url, 'https://example.com/widget');
      expect(settings.initOnContentLoad, true);
    });

    test('Default initOnContentLoad is true', () {
      final settings = WidgetSettings(
        widgetId: 'test_widget',
        url: 'https://example.com/widget',
      );

      expect(settings.initOnContentLoad, true);
    });

    test('JSON serialization', () {
      final settings = WidgetSettings(
        widgetId: 'test_widget',
        url: 'https://example.com/widget',
        initOnContentLoad: false,
      );

      final json = settings.toJson();
      expect(json['widget_id'], 'test_widget');
      expect(json['url'], 'https://example.com/widget');
      expect(json['init_on_content_load'], false);

      final restored = WidgetSettings.fromJson(json);
      expect(restored.widgetId, settings.widgetId);
      expect(restored.url, settings.url);
      expect(restored.initOnContentLoad, settings.initOnContentLoad);
    });

    // TODO: Add integration tests for buildUrl with real Client/Room objects
    // These tests require database setup and should be run separately
  });
}
