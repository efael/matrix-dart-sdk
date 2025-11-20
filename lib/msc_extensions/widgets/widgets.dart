/// Matrix Widget API implementation.
///
/// Provides a driver for secure communication between Matrix clients and
/// embedded widgets via the postMessage API.
///
/// Based on:
/// - MSC2762: Widget API v1
/// - MSC2871: Widget API event sending/reading
/// - MSC2873: Client metadata in widget URLs
/// - MSC3819: To-device messaging
/// - MSC4039: Homeserver URL in widget URLs
/// - MSC4157: Delayed events
library;

// Export public API
export 'src/api/from_widget_messages.dart';
export 'src/api/message_types.dart';
export 'src/api/to_widget_messages.dart';
export 'src/capabilities/capabilities.dart';
export 'src/capabilities/capability_parser.dart';
export 'src/capabilities/capability_provider.dart';
export 'src/capabilities/element_call_permissions.dart';
export 'src/capabilities/filters.dart';
export 'src/driver/matrix_driver.dart';
export 'src/driver/widget_driver.dart';
export 'src/machine/widget_machine.dart';
export 'src/models/openid.dart';
export 'src/models/pending_requests.dart';
export 'src/models/widget_settings.dart';
export 'src/settings/element_call.dart';
export 'src/transport/widget_transport.dart';
