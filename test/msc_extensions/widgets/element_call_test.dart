import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/src/settings/element_call.dart';

void main() {
  group('EncryptionSystem', () {
    test('Creates from string', () {
      expect(
        EncryptionSystem.fromString('unencrypted'),
        EncryptionSystem.unencrypted,
      );
      expect(
        EncryptionSystem.fromString('perParticipantKeys'),
        EncryptionSystem.perParticipantKeys,
      );
      expect(
        EncryptionSystem.fromString('sharedSecret'),
        EncryptionSystem.sharedSecret,
      );
    });

    test('Defaults to perParticipantKeys for unknown', () {
      expect(
        EncryptionSystem.fromString('unknown'),
        EncryptionSystem.perParticipantKeys,
      );
    });

    test('Has correct values', () {
      expect(EncryptionSystem.unencrypted.value, 'unencrypted');
      expect(EncryptionSystem.perParticipantKeys.value, 'perParticipantKeys');
      expect(EncryptionSystem.sharedSecret.value, 'sharedSecret');
    });
  });

  group('CallIntent', () {
    test('Creates from string', () {
      expect(CallIntent.fromString('start_call'), CallIntent.startCall);
      expect(CallIntent.fromString('join'), CallIntent.joinExisting);
      expect(CallIntent.fromString('start_call_dm'), CallIntent.startCallDm);
      expect(CallIntent.fromString('join_dm'), CallIntent.joinExistingDm);
    });

    test('Defaults to joinExisting for unknown', () {
      expect(CallIntent.fromString('unknown'), CallIntent.joinExisting);
    });

    test('Has correct values', () {
      expect(CallIntent.startCall.value, 'start_call');
      expect(CallIntent.joinExisting.value, 'join');
      expect(CallIntent.startCallDm.value, 'start_call_dm');
      expect(CallIntent.joinExistingDm.value, 'join_dm');
    });
  });

  group('HeaderStyle', () {
    test('Creates from string', () {
      expect(HeaderStyle.fromString('standard'), HeaderStyle.standard);
      expect(HeaderStyle.fromString('appBar'), HeaderStyle.appBar);
      expect(HeaderStyle.fromString('none'), HeaderStyle.none);
    });

    test('Defaults to standard for unknown', () {
      expect(HeaderStyle.fromString('unknown'), HeaderStyle.standard);
    });

    test('Has correct values', () {
      expect(HeaderStyle.standard.value, 'standard');
      expect(HeaderStyle.appBar.value, 'appBar');
      expect(HeaderStyle.none.value, 'none');
    });
  });

  group('NotificationType', () {
    test('Creates from string', () {
      expect(NotificationType.fromString('notify'), NotificationType.notify);
      expect(NotificationType.fromString('ring'), NotificationType.ring);
    });

    test('Defaults to notify for unknown', () {
      expect(NotificationType.fromString('unknown'), NotificationType.notify);
    });

    test('Has correct values', () {
      expect(NotificationType.notify.value, 'notify');
      expect(NotificationType.ring.value, 'ring');
    });
  });

  group('ElementCallWidgetProperties', () {
    test('Creates with required fields', () {
      final props = ElementCallWidgetProperties(
        elementCallUrl: 'https://call.element.io',
        widgetId: 'call_123',
        parentUrl: 'https://app.element.io',
      );

      expect(props.elementCallUrl, 'https://call.element.io');
      expect(props.widgetId, 'call_123');
      expect(props.parentUrl, 'https://app.element.io');
      expect(props.encryption, EncryptionSystem.perParticipantKeys);
    });

    test('Creates with all fields', () {
      final props = ElementCallWidgetProperties(
        elementCallUrl: 'https://call.element.io',
        widgetId: 'call_123',
        parentUrl: 'https://app.element.io',
        encryption: EncryptionSystem.sharedSecret,
        fontScale: 1.5,
        font: 'Arial',
        analyticsId: 'analytics_123',
        sentryUrl: 'https://sentry.io/...',
        rageshakeUrl: 'https://rageshake.element.io',
      );

      expect(props.encryption, EncryptionSystem.sharedSecret);
      expect(props.fontScale, 1.5);
      expect(props.font, 'Arial');
      expect(props.analyticsId, 'analytics_123');
      expect(props.sentryUrl, 'https://sentry.io/...');
      expect(props.rageshakeUrl, 'https://rageshake.element.io');
    });
  });

  group('ElementCallWidgetConfig', () {
    test('Creates empty config', () {
      final config = ElementCallWidgetConfig();
      final params = config.toFragmentParams();
      expect(params, isEmpty);
    });

    test('Creates with all fields', () {
      final config = ElementCallWidgetConfig(
        intent: CallIntent.startCall,
        skipLobby: true,
        header: HeaderStyle.appBar,
        preload: false,
        appPrompt: true,
        confineToRoom: true,
        hideScreensharing: false,
        controlledAudioDevices: true,
        sendNotificationType: NotificationType.ring,
        password: 'secret123',
      );

      final params = config.toFragmentParams();

      expect(params['intent'], 'start_call');
      expect(params['skipLobby'], 'true');
      expect(params['header'], 'appBar');
      expect(params['preload'], 'false');
      expect(params['appPrompt'], 'true');
      expect(params['confineToRoom'], 'true');
      expect(params['hideScreensharing'], 'false');
      expect(params['controlledAudioDevices'], 'true');
      expect(params['sendNotificationType'], 'ring');
      expect(params['password'], 'secret123');
    });

    test('Only includes non-null fields in fragment params', () {
      final config = ElementCallWidgetConfig(
        intent: CallIntent.joinExisting,
        skipLobby: true,
      );

      final params = config.toFragmentParams();

      expect(params.length, 2);
      expect(params['intent'], 'join');
      expect(params['skipLobby'], 'true');
      expect(params.containsKey('header'), false);
      expect(params.containsKey('password'), false);
    });
  });

  group('ElementCallWidgetConfig intents', () {
    test('StartCall intent', () {
      final config = ElementCallWidgetConfig(
        intent: CallIntent.startCall,
      );
      expect(config.toFragmentParams()['intent'], 'start_call');
    });

    test('JoinExisting intent', () {
      final config = ElementCallWidgetConfig(
        intent: CallIntent.joinExisting,
      );
      expect(config.toFragmentParams()['intent'], 'join');
    });

    test('StartCallDm intent', () {
      final config = ElementCallWidgetConfig(
        intent: CallIntent.startCallDm,
      );
      expect(config.toFragmentParams()['intent'], 'start_call_dm');
    });

    test('JoinExistingDm intent', () {
      final config = ElementCallWidgetConfig(
        intent: CallIntent.joinExistingDm,
      );
      expect(config.toFragmentParams()['intent'], 'join_dm');
    });
  });

  group('ElementCallWidgetConfig encryption', () {
    test('Unencrypted calls', () {
      final props = ElementCallWidgetProperties(
        elementCallUrl: 'https://call.element.io',
        widgetId: 'call_123',
        parentUrl: 'https://app.element.io',
        encryption: EncryptionSystem.unencrypted,
      );

      expect(props.encryption.value, 'unencrypted');
    });

    test('Per-participant encryption (default)', () {
      final props = ElementCallWidgetProperties(
        elementCallUrl: 'https://call.element.io',
        widgetId: 'call_123',
        parentUrl: 'https://app.element.io',
      );

      expect(props.encryption, EncryptionSystem.perParticipantKeys);
      expect(props.encryption.value, 'perParticipantKeys');
    });

    test('Shared secret encryption with password', () {
      final props = ElementCallWidgetProperties(
        elementCallUrl: 'https://call.element.io',
        widgetId: 'call_123',
        parentUrl: 'https://app.element.io',
        encryption: EncryptionSystem.sharedSecret,
      );

      final config = ElementCallWidgetConfig(
        password: 'supersecret',
      );

      expect(props.encryption.value, 'sharedSecret');
      expect(config.toFragmentParams()['password'], 'supersecret');
    });
  });

  group('ElementCallWidgetConfig UI options', () {
    test('Skip lobby option', () {
      final config = ElementCallWidgetConfig(
        skipLobby: true,
      );
      expect(config.toFragmentParams()['skipLobby'], 'true');
    });

    test('Header styles', () {
      final standardConfig = ElementCallWidgetConfig(
        header: HeaderStyle.standard,
      );
      expect(standardConfig.toFragmentParams()['header'], 'standard');

      final appBarConfig = ElementCallWidgetConfig(
        header: HeaderStyle.appBar,
      );
      expect(appBarConfig.toFragmentParams()['header'], 'appBar');

      final noneConfig = ElementCallWidgetConfig(
        header: HeaderStyle.none,
      );
      expect(noneConfig.toFragmentParams()['header'], 'none');
    });

    test('Hide screensharing', () {
      final config = ElementCallWidgetConfig(
        hideScreensharing: true,
      );
      expect(config.toFragmentParams()['hideScreensharing'], 'true');
    });

    test('Controlled audio devices', () {
      final config = ElementCallWidgetConfig(
        controlledAudioDevices: true,
      );
      expect(config.toFragmentParams()['controlledAudioDevices'], 'true');
    });
  });

  group('ElementCallWidgetConfig behavior', () {
    test('Preload option', () {
      final config = ElementCallWidgetConfig(
        preload: true,
      );
      expect(config.toFragmentParams()['preload'], 'true');
    });

    test('App prompt option', () {
      final config = ElementCallWidgetConfig(
        appPrompt: true,
      );
      expect(config.toFragmentParams()['appPrompt'], 'true');
    });

    test('Confine to room', () {
      final config = ElementCallWidgetConfig(
        confineToRoom: true,
      );
      expect(config.toFragmentParams()['confineToRoom'], 'true');
    });

    test('Notification types', () {
      final notifyConfig = ElementCallWidgetConfig(
        sendNotificationType: NotificationType.notify,
      );
      expect(notifyConfig.toFragmentParams()['sendNotificationType'], 'notify');

      final ringConfig = ElementCallWidgetConfig(
        sendNotificationType: NotificationType.ring,
      );
      expect(ringConfig.toFragmentParams()['sendNotificationType'], 'ring');
    });
  });

  // Note: Full integration tests for buildElementCallWidgetUrl and
  // createElementCallWidgetSettings would require actual Client/Room instances,
  // which should be done in separate integration tests.
}