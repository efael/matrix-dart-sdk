import 'package:matrix/msc_extensions/widgets/widgets.dart';

/// Request from a widget to acquire capabilities.
///
/// Contains the list of capabilities the widget is requesting and
/// metadata about the widget making the request.
class CapabilityRequest {
  /// Raw capability strings requested by the widget.
  ///
  /// Format examples:
  /// - "org.matrix.msc2762.send.event:m.room.message"
  /// - "org.matrix.msc2762.read.event:m.room.message#m.text"
  /// - "org.matrix.msc2762.send.state_event:m.room.topic"
  final List<String> requested;

  /// The widget ID making the request.
  final String widgetId;

  /// Optional widget name for display purposes.
  final String? widgetName;

  /// Whether the widget requested OpenID credentials.
  final bool requestsOpenId;

  CapabilityRequest({
    required this.requested,
    required this.widgetId,
    this.widgetName,
    this.requestsOpenId = false,
  });
}

/// Response to a capability request.
///
/// Contains the approved capabilities (which may be a subset of requested)
/// and optionally the OpenID response if requested.
class CapabilityResponse {
  /// The approved capabilities.
  ///
  /// This may be:
  /// - A subset of what was requested (partial approval)
  /// - Exactly what was requested (full approval)
  /// - Empty (full denial)
  final WidgetCapabilities approved;

  /// OpenID response if the widget requested it.
  ///
  /// - [OpenIdAllowed] - User approved, token provided
  /// - [OpenIdBlocked] - User denied
  /// - [OpenIdPending] - Still being processed
  /// - null - Not requested
  final OpenIdResponse? openId;

  CapabilityResponse({
    required this.approved,
    this.openId,
  });
}

/// Provider interface for acquiring widget capabilities.
///
/// Implementations of this class handle the authorization flow for
/// widget capability requests. This typically involves showing a UI
/// to the user asking them to approve or deny the requested permissions.
///
/// The provider is called during widget initialization when the widget
/// requests capabilities.
abstract class CapabilityProvider {
  /// Acquire capabilities for a widget.
  ///
  /// This method is called when a widget requests capabilities. The
  /// implementation should:
  /// 1. Present the requested capabilities to the user
  /// 2. Get user approval/denial
  /// 3. Return the approved subset
  ///
  /// The returned [CapabilityResponse] contains:
  /// - [approved] - Capabilities that were approved (may be subset)
  /// - [openId] - OpenID response if requested
  ///
  /// Example implementation:
  /// ```dart
  /// @override
  /// Future<CapabilityResponse> acquireCapabilities(
  ///   CapabilityRequest request,
  /// ) async {
  ///   // Show UI dialog to user
  ///   final userApproved = await showApprovalDialog(request);
  ///
  ///   if (userApproved) {
  ///     // Parse and return approved capabilities
  ///     final caps = parseCapabilityStrings(request.requested);
  ///     return CapabilityResponse(approved: caps);
  ///   } else {
  ///     // Deny all capabilities
  ///     return CapabilityResponse(approved: WidgetCapabilities.empty());
  ///   }
  /// }
  /// ```
  Future<CapabilityResponse> acquireCapabilities(CapabilityRequest request);
}
