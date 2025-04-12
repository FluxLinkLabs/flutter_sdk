/// FluxLink SDK for Flutter
///
/// A package that enables easy integration with the FluxLink API
/// for handling dynamic links in mobile applications.
library;

import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  http.Client? _internalHttpClient; // For IP fetching if needed
  bool _isInternalHttpClient = false; // Track if we created the client

  // Key for SharedPreferences
  static const String _firstLaunchCheckKey = 'fluxlink_first_launch_checked';

  Future<void> _initialize() async {
    _visitorId = await _generateVisitorId();
    // Use the API service's client if possible, otherwise create a new one
    // Note: Accessing _httpClient directly is not ideal. Consider passing Client in constructor.
    // For now, let's create one if needed, assuming apiService might have its own.
    // A better approach might be to require an http.Client to be passed to initialize().
    _internalHttpClient = http.Client();
    _isInternalHttpClient = true;
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

  /// Fetches the public IP address of the device.
  Future<String?> _getPublicIpAddress() async {
    if (_internalHttpClient == null) return null; // Should not happen if initialized
    try {
      final response = await _internalHttpClient!.get(
        Uri.parse('https://api.ipify.org?format=json'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['ip'] as String?;
      }
      return null;
    } catch (e) {
      // Handle network errors or JSON parsing errors gracefully
      print('FluxLink SDK: Error fetching public IP address: $e');
      return null;
    }
  }

  /// Constructs a basic User Agent string for the API call.
  String _constructUserAgent(Map<String, String?> deviceInfo) {
    final platform = _devicePlatform;
    final osVersion = deviceInfo['osVersion'] ?? 'UnknownOS';
    final deviceModel = deviceInfo['deviceModel'] ?? 'UnknownDevice';
    // Example: FluxLinkSDK/Dart (iOS; 16.0; iPhone14,6)
    return 'FluxLinkSDK/Dart ($platform; $osVersion; $deviceModel)';
  }

  /// Checks for a deferred deep link on the first launch after installation.
  ///
  /// This method should be called once, shortly after app initialization.
  /// It checks if this is the first time the app has run since installation
  /// (using `shared_preferences`). If it is, it attempts to claim a deferred
  /// link by sending device fingerprint data to the FluxLink API.
  ///
  /// Returns the `FluxLinkData` if a deferred link is successfully claimed,
  /// otherwise returns `null`. It also returns `null` on subsequent launches
  /// or if the check fails.
  Future<FluxLinkData?> checkForDeferredLinkOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunchChecked = prefs.getBool(_firstLaunchCheckKey) ?? false;

    if (isFirstLaunchChecked) {
      print('FluxLink SDK: Deferred link check already performed.');
      return null; // Already checked, don't check again
    }

    // Mark as checked immediately to prevent race conditions/multiple checks
    await prefs.setBool(_firstLaunchCheckKey, true);
    print('FluxLink SDK: Performing first launch deferred link check...');

    if (_visitorId == null) {
      print('FluxLink SDK: Cannot check for deferred link, SDK not initialized.');
      // Potentially revert the flag if initialization state is critical,
      // but generally, we mark it checked to avoid repeated attempts on failed init.
      // await prefs.setBool(_firstLaunchCheckKey, false);
      return null;
    }

    try {
      final deviceInfo = await _getDeviceInfo();
      final ipAddress = await _getPublicIpAddress();
      final userAgent = _constructUserAgent(deviceInfo);
      final platform = _devicePlatform;
      final osVersion = deviceInfo['osVersion'];
      final deviceModel = deviceInfo['deviceModel'];

      if (ipAddress == null) {
        print('FluxLink SDK: Could not retrieve IP address for deferred link check.');
        // No IP, claim attempt is unlikely to succeed.
        // Consider if you still want to call the API endpoint without IP.
        // Depending on API requirements, it might be mandatory.
        return null;
      }

      print(
        'FluxLink SDK: Claiming deferred link with IP: $ipAddress, UA: $userAgent, Platform: $platform',
      );

      final claimedLinkData = await _apiService.claimDeferredLink(
        visitorId: _visitorId!,
        devicePlatform: platform,
        ipAddress: ipAddress,
        userAgent: userAgent,
        osVersion: osVersion,
        deviceModel: deviceModel,
      );

      if (claimedLinkData != null) {
        final shortCode = claimedLinkData.metadata?['shortCode'] ?? 'N/A';
        print('FluxLink SDK: Successfully claimed deferred link: $shortCode');
      } else {
        print('FluxLink SDK: No deferred link found for this device.');
      }
      return claimedLinkData;
    } catch (e) {
      print('FluxLink SDK: Error during deferred link check: $e');
      // Log error but don't throw, return null as no link was claimed.
      return null;
    }
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
    // Close the internal client only if we created it
    if (_isInternalHttpClient) {
      _internalHttpClient?.close();
    }
  }
}
