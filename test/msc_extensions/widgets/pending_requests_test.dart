import 'package:test/test.dart';

import 'package:matrix/msc_extensions/widgets/widgets.dart';

void main() {
  group('PendingRequests', () {
    test('Insert and extract request', () {
      final pending = PendingRequests<String>();

      pending.insert('req1', 'test data');
      expect(pending.count, 1);
      expect(pending.contains('req1'), true);

      final data = pending.extract('req1');
      expect(data, 'test data');
      expect(pending.count, 0);
      expect(pending.contains('req1'), false);
    });

    test('Extract non-existent request returns null', () {
      final pending = PendingRequests<String>();

      expect(pending.extract('nonexistent'), isNull);
    });

    test('Contains checks for pending request', () {
      final pending = PendingRequests<String>();

      expect(pending.contains('req1'), false);

      pending.insert('req1', 'data');
      expect(pending.contains('req1'), true);

      pending.extract('req1');
      expect(pending.contains('req1'), false);
    });

    test('Respect max pending limit', () {
      final pending = PendingRequests<String>(
        limits: const RequestLimits(maxPending: 3),
      );

      pending.insert('req1', 'data1');
      pending.insert('req2', 'data2');
      pending.insert('req3', 'data3');

      expect(pending.count, 3);

      expect(
        () => pending.insert('req4', 'data4'),
        throwsA(isA<TooManyPendingRequestsException>()),
      );
    });

    test('TooManyPendingRequestsException message', () {
      final exception = TooManyPendingRequestsException(128);
      expect(
        exception.toString(),
        contains('Too many pending requests'),
      );
      expect(exception.toString(), contains('128'));
    });

    test('Expired requests are removed on extract', () async {
      final pending = PendingRequests<String>(
        limits: const RequestLimits(timeout: Duration(milliseconds: 50)),
      );

      pending.insert('req1', 'data1');
      expect(pending.count, 1);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      final data = pending.extract('req1');
      expect(data, isNull);
      expect(pending.count, 0);
    });

    test('Expired requests return false on contains', () async {
      final pending = PendingRequests<String>(
        limits: const RequestLimits(timeout: Duration(milliseconds: 50)),
      );

      pending.insert('req1', 'data1');
      expect(pending.contains('req1'), true);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      expect(pending.contains('req1'), false);
      expect(pending.count, 0);
    });

    test('removeExpired removes all expired requests', () async {
      final pending = PendingRequests<String>(
        limits: const RequestLimits(timeout: Duration(milliseconds: 50)),
      );

      pending.insert('req1', 'data1');
      pending.insert('req2', 'data2');
      pending.insert('req3', 'data3');
      expect(pending.count, 3);

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      final removed = pending.removeExpired();
      expect(removed, 3);
      expect(pending.count, 0);
    });

    test('removeExpired only removes expired requests', () async {
      final pending = PendingRequests<String>(
        limits: const RequestLimits(timeout: Duration(milliseconds: 100)),
      );

      pending.insert('req1', 'data1');

      // Wait a bit but not long enough to expire
      await Future.delayed(const Duration(milliseconds: 30));

      pending.insert('req2', 'data2');
      pending.insert('req3', 'data3');

      // Wait for req1 to expire but not req2/req3
      await Future.delayed(const Duration(milliseconds: 80));

      final removed = pending.removeExpired();
      expect(removed, 1);
      expect(pending.count, 2);
      expect(pending.contains('req1'), false);
      expect(pending.contains('req2'), true);
      expect(pending.contains('req3'), true);
    });

    test('onExpired callback is called for expired requests', () async {
      final expired = <String, String>{};
      final pending = PendingRequests<String>(
        limits: const RequestLimits(timeout: Duration(milliseconds: 50)),
        onExpired: (id, data) {
          expired[id] = data;
        },
      );

      pending.insert('req1', 'data1');
      pending.insert('req2', 'data2');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      pending.removeExpired();

      expect(expired.length, 2);
      expect(expired['req1'], 'data1');
      expect(expired['req2'], 'data2');
    });

    test('onExpired is called on extract of expired request', () async {
      final expired = <String, String>{};
      final pending = PendingRequests<String>(
        limits: const RequestLimits(timeout: Duration(milliseconds: 50)),
        onExpired: (id, data) {
          expired[id] = data;
        },
      );

      pending.insert('req1', 'data1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      final data = pending.extract('req1');

      expect(data, isNull);
      expect(expired['req1'], 'data1');
    });

    test('onExpired is called on contains of expired request', () async {
      final expired = <String, String>{};
      final pending = PendingRequests<String>(
        limits: const RequestLimits(timeout: Duration(milliseconds: 50)),
        onExpired: (id, data) {
          expired[id] = data;
        },
      );

      pending.insert('req1', 'data1');

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 100));

      final exists = pending.contains('req1');

      expect(exists, false);
      expect(expired['req1'], 'data1');
    });

    test('pendingIds returns all pending request IDs', () {
      final pending = PendingRequests<String>();

      pending.insert('req1', 'data1');
      pending.insert('req2', 'data2');
      pending.insert('req3', 'data3');

      final ids = pending.pendingIds;
      expect(ids.length, 3);
      expect(ids, contains('req1'));
      expect(ids, contains('req2'));
      expect(ids, contains('req3'));
    });

    test('clear removes all requests', () {
      final pending = PendingRequests<String>();

      pending.insert('req1', 'data1');
      pending.insert('req2', 'data2');
      expect(pending.count, 2);

      pending.clear();
      expect(pending.count, 0);
      expect(pending.pendingIds, isEmpty);
    });

    test('Custom RequestLimits configuration', () {
      final pending = PendingRequests<String>(
        limits: const RequestLimits(
          maxPending: 5,
          timeout: Duration(seconds: 60),
        ),
      );

      expect(pending.limits.maxPending, 5);
      expect(pending.limits.timeout, const Duration(seconds: 60));
    });

    test('Different data types work correctly', () {
      final pendingInt = PendingRequests<int>();
      pendingInt.insert('req1', 42);
      expect(pendingInt.extract('req1'), 42);

      final pendingMap = PendingRequests<Map<String, dynamic>>();
      pendingMap.insert('req1', {'key': 'value'});
      expect(pendingMap.extract('req1'), {'key': 'value'});

      final pendingList = PendingRequests<List<String>>();
      pendingList.insert('req1', ['a', 'b', 'c']);
      expect(pendingList.extract('req1'), ['a', 'b', 'c']);
    });
  });
}
