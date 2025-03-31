/// FluxLink SDK for Flutter
///
/// A package that enables easy integration with the FluxLink API
/// for handling dynamic links in mobile applications.
library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'src/models/flux_link_data.dart';
import 'src/services/flux_link_api_service.dart';

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
    String baseUrl = 'https://api.fluxlink.app/api',
  }) async {
    final instance = FluxLink._(apiKey: apiKey, baseUrl: baseUrl);
    await instance._initialize();
    return instance;
  }

  FluxLink._({required String apiKey, required String baseUrl})
    : _apiService = FluxLinkApiService(apiKey: apiKey, baseUrl: baseUrl),
      _deviceInfo = DeviceInfoPlugin(),
      _uuid = const Uuid();

  final FluxLinkApiService _apiService;
  final DeviceInfoPlugin _deviceInfo;
  final Uuid _uuid;
  String? _visitorId;

  Future<void> _initialize() async {
    _visitorId = await _generateVisitorId();
  }

  /// Generates a deterministic visitor ID based on device identifiers
  Future<String> _generateVisitorId() async {
    try {
      String? deviceIdentifier;

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor which is unique per vendor per device
        deviceIdentifier = iosInfo.identifierForVendor;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use a combination of androidId and fingerprint for uniqueness
        deviceIdentifier = '${androidInfo.id}_${androidInfo.fingerprint}';
      }

      // If we couldn't get a device identifier, generate a random UUID
      // This UUID will be different for each app installation
      if (deviceIdentifier == null || deviceIdentifier.isEmpty) {
        deviceIdentifier = _uuid.v4();
      }

      // Generate a deterministic UUID using name-based UUID (v5)
      // We use the DNS namespace and combine it with our device identifier
      return _uuid.v5(Uuid.NAMESPACE_DNS, 'fluxlink.app:$deviceIdentifier');
    } catch (e) {
      // If anything fails, fallback to a random UUID
      return _uuid.v4();
    }
  }

  /// Get device platform (ios/android)
  String get _devicePlatform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Get device information based on the platform
  Future<Map<String, String?>> _getDeviceInfo() async {
    final info = <String, String?>{};

    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info['osVersion'] = iosInfo.systemVersion;
        info['deviceModel'] = iosInfo.model;
        info['deviceType'] = iosInfo.model.toLowerCase().contains('ipad') ? 'tablet' : 'mobile';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info['osVersion'] = androidInfo.version.release;
        info['deviceModel'] = androidInfo.model;
        info['deviceType'] = 'mobile'; // Default to mobile as tablet detection requires UI context
        info['androidVersion'] = androidInfo.version.release;
      }
    } catch (e) {
      // If we fail to get device info, we'll just return empty map
      // The API will work with minimal required information
    }

    return info;
  }

  /// Resolves a FluxLink shortcode and returns the associated data.
  ///
  /// This makes a GET request to `/links/resolve/{shortCode}` and returns
  /// the resolved link data.
  Future<FluxLinkData> resolve(String shortCode) async {
    if (_visitorId == null) {
      throw StateError('FluxLink not initialized. Call FluxLink.initialize() first.');
    }

    final deviceInfo = await _getDeviceInfo();

    return _apiService.resolveShortCode(
      shortCode,
      visitorId: _visitorId!,
      devicePlatform: _devicePlatform,
      osVersion: deviceInfo['osVersion'],
      deviceModel: deviceInfo['deviceModel'],
      deviceType: deviceInfo['deviceType'],
      androidVersion: deviceInfo['androidVersion'],
    );
  }

  /// Resolves a FluxLink shortcode and returns the appropriate URL for the current platform.
  ///
  /// This is a convenience method that resolves the shortcode and returns the platform-specific URL.
  Future<String> resolveForCurrentPlatform(String shortCode) async {
    final linkData = await resolve(shortCode);
    return linkData.getPlatformUrl();
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
    _apiService.dispose();
  }
}
