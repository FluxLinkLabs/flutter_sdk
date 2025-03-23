/// FluxLink SDK for Flutter
///
/// A package that enables easy integration with the FluxLink API
/// for handling dynamic links in mobile applications.
library;

import 'src/models/flux_link_data.dart';
import 'src/services/flux_link_api_service.dart';
import 'src/services/flux_link_detector.dart';

export 'src/models/models.dart';
export 'src/services/services.dart';

/// Main class for interacting with the FluxLink SDK.
///
/// This class provides methods for creating links, handling incoming deep links,
/// resolving shortcodes, and listening for dynamic link events across different platforms.
class FluxLink {
  /// Creates a new instance of the FluxLink SDK.
  ///
  /// This initializes the SDK with your API key and prepares it for
  /// handling dynamic links.
  static Future<FluxLink> initialize({
    required String apiKey,
    String baseUrl = 'https://api.fluxlink.com',
  }) async {
    final instance = FluxLink._(apiKey: apiKey, baseUrl: baseUrl);
    await instance._initialize();
    return instance;
  }

  FluxLink._({required String apiKey, required String baseUrl})
    : _apiService = FluxLinkApiService(apiKey: apiKey, baseUrl: baseUrl),
      _apiClient = FluxLinkApiClient(apiKey: apiKey, baseUrl: baseUrl),
      _detector = null;

  final FluxLinkApiService _apiService;
  final FluxLinkApiClient _apiClient;
  FluxLinkDetector? _detector;

  Future<void> _initialize() async {
    _detector = FluxLinkDetector(apiService: _apiService);
    await _detector!.initialize();
  }

  /// Stream of resolved FluxLink data from automatic link detection.
  ///
  /// Listen to this stream to receive notifications when deep links are detected.
  Stream<FluxLinkData> get onLinkResolved =>
      _detector?.onLinkResolved ?? Stream<FluxLinkData>.empty();

  /// Manually handle a FluxLink URL.
  ///
  /// This resolves a full FluxLink URL (not a shortcode) and returns the associated data.
  Future<FluxLinkData> handleLink(String url) async {
    if (_detector == null) {
      throw StateError('FluxLink not initialized. Call FluxLink.initialize() first.');
    }
    return _detector!.handleLink(url);
  }

  /// Resolves a FluxLink shortcode and returns the associated data.
  ///
  /// This makes a GET request to `/links/resolve/{shortCode}` and returns
  /// the resolved link data.
  Future<FluxLinkData> resolveShortCode(String shortCode) {
    return _apiClient.resolveLink(shortCode);
  }

  /// Create a new FluxLink.
  ///
  /// This creates a new dynamic link with the provided parameters and returns
  /// the created link data.
  Future<FluxLinkData> createLink({
    required String originalUrl,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
    String? androidUrl,
    String? iosUrl,
    String? webUrl,
  }) {
    return _apiService.createLink(
      originalUrl: originalUrl,
      title: title,
      description: description,
      metadata: metadata,
      androidUrl: androidUrl,
      iosUrl: iosUrl,
      webUrl: webUrl,
    );
  }

  /// Disposes the FluxLink instance when no longer needed.
  void dispose() {
    _detector?.dispose();
    _apiService.dispose();
    _apiClient.dispose();
  }
}
