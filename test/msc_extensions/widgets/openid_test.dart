import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('OpenIdCredentials', () {
    test('Create OpenIdCredentials', () {
      final creds = OpenIdCredentials(
        accessToken: 'test_token_123',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
        tokenType: 'Bearer',
      );

      expect(creds.accessToken, 'test_token_123');
      expect(creds.expiresIn, const Duration(seconds: 3600));
      expect(creds.matrixServerName, 'matrix.example.com');
      expect(creds.tokenType, 'Bearer');
    });

    test('Default tokenType is Bearer', () {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      expect(creds.tokenType, 'Bearer');
    });

    test('JSON serialization', () {
      final creds = OpenIdCredentials(
        accessToken: 'test_token',
        expiresIn: const Duration(seconds: 7200),
        matrixServerName: 'matrix.example.com',
        tokenType: 'Bearer',
      );

      final json = creds.toJson();
      expect(json['access_token'], 'test_token');
      expect(json['expires_in'], 7200);
      expect(json['matrix_server_name'], 'matrix.example.com');
      expect(json['token_type'], 'Bearer');

      final restored = OpenIdCredentials.fromJson(json);
      expect(restored.accessToken, creds.accessToken);
      expect(restored.expiresIn, creds.expiresIn);
      expect(restored.matrixServerName, creds.matrixServerName);
      expect(restored.tokenType, creds.tokenType);
    });
  });

  group('OpenIdState', () {
    test('Create OpenIdState', () {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      final now = DateTime.now();
      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
        acquiredAt: now,
      );

      expect(state.originalRequestId, 'req_123');
      expect(state.credentials, creds);
      expect(state.acquiredAt, now);
    });

    test('Default acquiredAt is current time', () {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      final before = DateTime.now();
      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
      );
      final after = DateTime.now();

      expect(
        state.acquiredAt.isAfter(before) || state.acquiredAt.isAtSameMomentAs(before),
        true,
      );
      expect(
        state.acquiredAt.isBefore(after) || state.acquiredAt.isAtSameMomentAs(after),
        true,
      );
    });

    test('expiresAt is calculated correctly', () {
      final now = DateTime.now();
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
        acquiredAt: now,
      );

      final expectedExpiry = now.add(const Duration(seconds: 3600));
      expect(state.expiresAt, expectedExpiry);
    });

    test('isExpired returns false for valid token', () {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
      );

      expect(state.isExpired, false);
    });

    test('isExpired returns true for expired token', () async {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(milliseconds: 50),
        matrixServerName: 'matrix.example.com',
      );

      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
      );

      expect(state.isExpired, false);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      expect(state.isExpired, true);
    });

    test('timeUntilExpiry is calculated correctly', () {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
      );

      final remaining = state.timeUntilExpiry;
      expect(remaining.inSeconds, greaterThan(3590)); // Allow some tolerance
      expect(remaining.inSeconds, lessThanOrEqualTo(3600));
    });

    test('timeUntilExpiry is zero for expired token', () async {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(milliseconds: 50),
        matrixServerName: 'matrix.example.com',
      );

      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
      );

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      expect(state.timeUntilExpiry, Duration.zero);
    });
  });

  group('OpenIdResponse', () {
    test('OpenIdAllowed contains state', () {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
      );

      final response = OpenIdAllowed(state);
      expect(response.state, state);
    });

    test('OpenIdBlocked is created correctly', () {
      const response = OpenIdBlocked();
      expect(response, isA<OpenIdBlocked>());
      expect(response, isA<OpenIdResponse>());
    });

    test('OpenIdPending is created correctly', () {
      const response = OpenIdPending();
      expect(response, isA<OpenIdPending>());
      expect(response, isA<OpenIdResponse>());
    });

    test('OpenIdResponse types are distinct', () {
      final creds = OpenIdCredentials(
        accessToken: 'token',
        expiresIn: const Duration(seconds: 3600),
        matrixServerName: 'matrix.example.com',
      );

      final state = OpenIdState(
        originalRequestId: 'req_123',
        credentials: creds,
      );

      final allowed = OpenIdAllowed(state);
      const blocked = OpenIdBlocked();
      const pending = OpenIdPending();

      expect(allowed is OpenIdAllowed, true);
      expect(allowed is OpenIdBlocked, false);
      expect(allowed is OpenIdPending, false);

      expect(blocked is OpenIdBlocked, true);
      expect(blocked is OpenIdAllowed, false);
      expect(blocked is OpenIdPending, false);

      expect(pending is OpenIdPending, true);
      expect(pending is OpenIdAllowed, false);
      expect(pending is OpenIdBlocked, false);
    });
  });
}
