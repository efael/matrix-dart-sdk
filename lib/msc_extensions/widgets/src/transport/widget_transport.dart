/// Abstract interface for widget communication transport.
///
/// This interface provides a platform-agnostic way to communicate with widgets.
/// Implementations should handle the platform-specific details (e.g., postMessage
/// for web, JavaScriptChannel for mobile WebViews).
///
/// Example implementations:
/// - Web: Use `window.postMessage()` and `window.addEventListener('message')`
/// - Mobile: Use WebView's JavaScriptChannel or similar mechanism
/// - Testing: Use StreamController for mock implementation
abstract class WidgetTransport {
  /// Stream of incoming JSON message strings from the widget.
  ///
  /// Each message should be a complete JSON string that can be parsed
  /// into a WidgetMessage.
  Stream<String> get incoming;

  /// Send a JSON message string to the widget.
  ///
  /// The [message] should be a valid JSON string representing a
  /// widget API message.
  void send(String message);

  /// Dispose of resources used by this transport.
  ///
  /// This should clean up any listeners, close streams, and release
  /// any platform-specific resources.
  void dispose();
}
