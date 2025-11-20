import 'package:collection/collection.dart';

/// Configuration limits for pending requests.
class RequestLimits {
  /// Maximum number of concurrent pending requests.
  ///
  /// This prevents memory exhaustion from malicious or buggy widgets.
  final int maxPending;

  /// Maximum time a request can remain pending before expiring.
  final Duration timeout;

  const RequestLimits({
    this.maxPending = 128,
    this.timeout = const Duration(seconds: 30),
  });
}

/// A request with an expiration time.
class _ExpirableRequest<T> {
  final T data;
  final DateTime expiresAt;

  _ExpirableRequest(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool isExpiredAt(DateTime now) => now.isAfter(expiresAt);
}

/// Exception thrown when too many requests are pending.
class TooManyPendingRequestsException implements Exception {
  final int maxPending;

  TooManyPendingRequestsException(this.maxPending);

  @override
  String toString() =>
      'Too many pending requests (max: $maxPending). Widget may be unresponsive.';
}

/// Manages pending widget API requests with timeout tracking.
///
/// Tracks requests by UUID and automatically expires them after a timeout period.
/// This prevents memory leaks from unresponsive widgets and provides DoS protection.
class PendingRequests<T> {
  final RequestLimits limits;
  final Map<String, _ExpirableRequest<T>> _requests = {};

  /// Callback invoked when a request expires.
  ///
  /// This is called during cleanup operations when expired requests are removed.
  final void Function(String requestId, T data)? onExpired;

  PendingRequests({
    this.limits = const RequestLimits(),
    this.onExpired,
  });

  /// Insert a new pending request.
  ///
  /// Throws [TooManyPendingRequestsException] if the maximum number of
  /// pending requests has been reached.
  ///
  /// The request will expire after [limits.timeout] duration.
  void insert(String requestId, T data) {
    if (_requests.length >= limits.maxPending) {
      throw TooManyPendingRequestsException(limits.maxPending);
    }

    final expiresAt = DateTime.now().add(limits.timeout);
    _requests[requestId] = _ExpirableRequest(data, expiresAt);
  }

  /// Extract and remove a pending request by ID.
  ///
  /// Returns null if:
  /// - The request ID doesn't exist
  /// - The request has expired
  ///
  /// Automatically removes expired requests during lookup.
  T? extract(String requestId) {
    final now = DateTime.now();

    // Clean up expired requests
    removeExpired(now);

    final request = _requests.remove(requestId);
    if (request == null) return null;

    if (request.isExpiredAt(now)) {
      onExpired?.call(requestId, request.data);
      return null;
    }

    return request.data;
  }

  /// Check if a request is pending (and not expired).
  bool contains(String requestId) {
    final request = _requests[requestId];
    if (request == null) return false;

    final now = DateTime.now();
    if (request.isExpiredAt(now)) {
      _requests.remove(requestId);
      onExpired?.call(requestId, request.data);
      return false;
    }
    return true;
  }

  /// Remove all expired requests.
  ///
  /// Returns the number of requests that were removed.
  int removeExpired([DateTime? now]) {
    now ??= DateTime.now();

    // Collect expired keys to avoid modifying map during iteration
    final expiredKeys = <String>[];
    final expiredData = <T>[];

    for (final entry in _requests.entries) {
      if (entry.value.isExpiredAt(now)) {
        expiredKeys.add(entry.key);
        expiredData.add(entry.value.data);
      }
    }

    // Remove expired entries and call callbacks
    for (var i = 0; i < expiredKeys.length; i++) {
      _requests.remove(expiredKeys[i]);
      onExpired?.call(expiredKeys[i], expiredData[i]);
    }

    return expiredKeys.length;
  }

  /// Get all pending request IDs.
  List<String> get pendingIds => _requests.keys.toList();

  /// Get the number of pending requests.
  int get count => _requests.length;

  /// Clear all pending requests.
  ///
  /// This should be called during cleanup/disposal.
  void clear() {
    _requests.clear();
  }
}
