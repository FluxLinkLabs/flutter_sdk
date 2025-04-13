import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/flux_link_data.dart';

/// Exception thrown when API calls fail
class FluxLinkApiException implements Exception {
  final String message;
  final int? statusCode;

  FluxLinkApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'FluxLinkApiException: $message ${statusCode != null ? '(Status code: $statusCode)' : ''}';
}

/// Service class to handle FluxLink API communication
class FluxLinkApiService {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _httpClient;

  /// Creates a new FluxLinkApiService with the provided API key and base URL
  FluxLinkApiService({
    required String apiKey,
    String baseUrl = 'https://api.fluxlink.app/api',
    http.Client? httpClient,
  }) : _apiKey = apiKey,
       _baseUrl = baseUrl,
       _httpClient = httpClient ?? http.Client();

  /// Get the base URL of the API
  String get baseUrl => _baseUrl;

  /// Get the API key used for authentication
  String get apiKey => _apiKey;

  /// Parses API response data into a FluxLinkData object
  FluxLinkData _parseApiResponse(Map<String, dynamic> data) {
    return FluxLinkData(
      id: data['_id'] as String,
      url: data['defaultUrl'] as String, // Use the defaultUrl as the main URL
      title: data['title'] as String?,
      description: null, // Description isn't present in the sample
      metadata: {
        'shortCode': data['shortCode'],
        'analytics': data['analytics'],
        'createdAt': data['createdAt'],
        'customDomain': data['customDomain'],
        'tags': data['tags'],
      },
      androidUrl: data['androidLink'] != null ? data['androidLink']['url'] as String? : null,
      iosUrl: null, // Not present in the sample
      webUrl: data['desktopUrl'] as String?,
    );
  }

  /// Resolves a FluxLink shortcode and returns the associated data
  ///
  /// Required parameters:
  /// - [shortCode]: The FluxLink shortcode to resolve
  /// - [visitorId]: Unique identifier for the visitor
  /// - [devicePlatform]: The platform (ios/android)
  ///
  /// Optional parameters for better analytics:
  /// - [osVersion]: OS version (e.g., "16.0" for iOS or "13.0" for Android)
  /// - [deviceModel]: Device model (e.g., "iPhone 14" or "Pixel 7")
  /// - [deviceType]: Device type (mobile/tablet)
  /// - [androidVersion]: Android version as float (e.g., "13.0") - only for Android
  Future<FluxLinkData> resolveShortCode(
    String shortCode, {
    required String visitorId,
    required String devicePlatform,
    String? osVersion,
    String? deviceModel,
    String? deviceType,
    String? androidVersion,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'x-visitor-id': visitorId,
        'x-device-platform': devicePlatform.toLowerCase(),
        if (osVersion != null) 'x-os-version': osVersion,
        if (deviceModel != null) 'x-device-model': deviceModel,
        if (deviceType != null) 'x-device-type': deviceType,
        if (androidVersion != null && devicePlatform.toLowerCase() == 'android')
          'x-android-version': androidVersion,
      };

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/links/resolve/$shortCode'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Check if the response follows the expected structure with success and data fields
        if (responseBody['success'] == true && responseBody['data'] != null) {
          final data = responseBody['data'] as Map<String, dynamic>;
          return _parseApiResponse(data);
        } else {
          throw FluxLinkApiException(
            'Invalid response format for shortCode: $shortCode',
            statusCode: response.statusCode,
          );
        }
      } else {
        throw FluxLinkApiException(
          'Failed to resolve link with shortCode: $shortCode',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FluxLinkApiException) rethrow;
      throw FluxLinkApiException('Error resolving link with shortCode: $e');
    }
  }

  /// Creates a new FluxLink
  Future<FluxLinkData> createLink({
    required String originalUrl,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
    String? androidUrl,
    String? iosUrl,
    String? webUrl,
  }) async {
    try {
      final body = {
        'originalUrl': originalUrl,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (metadata != null) 'metadata': metadata,
        if (androidUrl != null) 'androidUrl': androidUrl,
        if (iosUrl != null) 'iosUrl': iosUrl,
        if (webUrl != null) 'webUrl': webUrl,
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/links'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FluxLinkData.fromJson(data);
      } else {
        throw FluxLinkApiException('Failed to create link', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is FluxLinkApiException) rethrow;
      throw FluxLinkApiException('Error creating link: $e');
    }
  }

  /// Attempts to claim a deferred deep link based on device fingerprint.
  /// Returns FluxLinkData if a link is claimed, null otherwise.
  Future<FluxLinkData?> claimDeferredLink({
    required String visitorId,
    required String devicePlatform,
    required String ipAddress,
    required String userAgent,
    required String appPackageName,
    String? osVersion,
    String? deviceModel,
    String? timezone,
    int? timezoneOffset,
    int? screenWidth,
    int? screenHeight,
  }) async {
    try {
      final body = {
        'ip': ipAddress,
        'userAgent': userAgent,
        'platform': devicePlatform.toLowerCase(),
        'appPackageName': appPackageName,
        if (osVersion != null) 'osVersion': osVersion,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (timezone != null) 'timezone': timezone,
        if (timezoneOffset != null) 'timezoneOffset': timezoneOffset,
        if (screenWidth != null) 'screenWidth': screenWidth,
        if (screenHeight != null) 'screenHeight': screenHeight,
      };

      final headers = {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'x-visitor-id': visitorId, // Include visitor ID if available/required by API
      };

      // Note: Using '/v1/links/claim-deferred' as specified in the request.
      // Adjust if the base URL already includes '/v1' or if the path is different.
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/deferred-links/claim'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Assuming the API returns { success: true, data: { ... } } structure for claimed link
        if (responseBody['success'] == true && responseBody['data'] != null) {
          final data = responseBody['data'] as Map<String, dynamic>;
          // Assuming the data returned for a claimed link has the same structure
          // as a resolved or created link, parse it using _parseApiResponse.
          // Adjust if the structure is different.
          return _parseApiResponse(data);
        } else {
          // Success false or data null likely means no link was found for this fingerprint
          return null;
        }
      } else if (response.statusCode == 404) {
        // 404 Not Found might explicitly mean no deferred link was found.
        return null;
      } else {
        // Handle other errors
        throw FluxLinkApiException(
          'Failed to claim deferred link',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FluxLinkApiException) rethrow;
      // Catch potential JSON decoding errors or other issues
      throw FluxLinkApiException('Error claiming deferred link: $e');
    }
  }

  /// Disposes the HTTP client when no longer needed
  void dispose() {
    _httpClient.close();
  }
}
