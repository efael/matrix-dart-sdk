/// OpenID credentials for widget authentication.
///
/// Contains the access token and metadata required for a widget to make
/// Matrix API calls on behalf of the user.
class OpenIdCredentials {
  /// The OpenID access token.
  final String accessToken;

  /// Duration until the token expires.
  final Duration expiresIn;

  /// The Matrix homeserver name.
  final String matrixServerName;

  /// The token type (typically 'Bearer').
  final String tokenType;

  OpenIdCredentials({
    required this.accessToken,
    required this.expiresIn,
    required this.matrixServerName,
    this.tokenType = 'Bearer',
  });

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'expires_in': expiresIn.inSeconds,
        'matrix_server_name': matrixServerName,
        'token_type': tokenType,
      };

  factory OpenIdCredentials.fromJson(Map<String, dynamic> json) =>
      OpenIdCredentials(
        accessToken: json['access_token'] as String,
        expiresIn: Duration(seconds: json['expires_in'] as int),
        matrixServerName: json['matrix_server_name'] as String,
        tokenType: json['token_type'] as String? ?? 'Bearer',
      );
}

/// State of an OpenID token, including expiration tracking.
///
/// This extends OpenIdCredentials with additional state needed for
/// token lifecycle management.
class OpenIdState {
  /// The original widget request ID that triggered this token request.
  final String originalRequestId;

  /// The OpenID credentials.
  final OpenIdCredentials credentials;

  /// When the token was acquired.
  final DateTime acquiredAt;

  OpenIdState({
    required this.originalRequestId,
    required this.credentials,
    DateTime? acquiredAt,
  }) : acquiredAt = acquiredAt ?? DateTime.now();

  /// When the token will expire.
  DateTime get expiresAt => acquiredAt.add(credentials.expiresIn);

  /// Whether the token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Time remaining until expiration.
  Duration get timeUntilExpiry {
    final now = DateTime.now();
    return expiresAt.isAfter(now)
        ? expiresAt.difference(now)
        : Duration.zero;
  }
}

/// Response to an OpenID request.
///
/// Represents the three possible states:
/// - Allowed: User approved, token provided
/// - Blocked: User denied the request
/// - Pending: Request is still being processed
sealed class OpenIdResponse {
  const OpenIdResponse();
}

/// OpenID request was approved and token is available.
class OpenIdAllowed extends OpenIdResponse {
  final OpenIdState state;

  const OpenIdAllowed(this.state);
}

/// OpenID request was blocked/denied by the user.
class OpenIdBlocked extends OpenIdResponse {
  const OpenIdBlocked();
}

/// OpenID request is still pending user approval.
class OpenIdPending extends OpenIdResponse {
  const OpenIdPending();
}
