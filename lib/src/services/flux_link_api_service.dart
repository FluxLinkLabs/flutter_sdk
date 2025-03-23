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

  /// Resolves a FluxLink shortcode and returns the associated data
  Future<FluxLinkData> resolveShortCode(String shortCode) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/links/resolve/$shortCode'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        // Check if the response follows the expected structure with success and data fields
        if (responseBody['success'] == true && responseBody['data'] != null) {
          final data = responseBody['data'] as Map<String, dynamic>;

          // Extract the relevant fields from the API response
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
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
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

  /// Disposes the HTTP client when no longer needed
  void dispose() {
    _httpClient.close();
  }
}
