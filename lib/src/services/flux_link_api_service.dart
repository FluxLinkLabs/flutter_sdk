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

/// Client class to handle FluxLink API communication using shortcodes
class FluxLinkApiClient {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _httpClient;

  /// Creates a new FluxLinkApiClient with the provided base URL and API key
  FluxLinkApiClient({
    required String apiKey,
    String baseUrl = 'https://api.fluxlink.com/v1',
    http.Client? httpClient,
  }) : _apiKey = apiKey,
       _baseUrl = baseUrl,
       _httpClient = httpClient ?? http.Client();

  /// Resolves a FluxLink shortcode and returns the associated data
  Future<FluxLinkData> resolveLink(String shortCode) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/links/resolve/$shortCode'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FluxLinkData.fromJson(data);
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

  /// Disposes the HTTP client when no longer needed
  void dispose() {
    _httpClient.close();
  }
}

/// Service class to handle FluxLink API communication
class FluxLinkApiService {
  final String _baseUrl;
  final String _apiKey;
  final http.Client _httpClient;

  /// Creates a new FluxLinkApiService with the provided API key and base URL
  FluxLinkApiService({
    required String apiKey,
    String baseUrl = 'https://api.fluxlink.com/v1',
    http.Client? httpClient,
  }) : _apiKey = apiKey,
       _baseUrl = baseUrl,
       _httpClient = httpClient ?? http.Client();

  /// Resolves a FluxLink URL and returns the associated data
  Future<FluxLinkData> resolveLink(String url) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/resolve'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return FluxLinkData.fromJson(data);
      } else {
        throw FluxLinkApiException('Failed to resolve link', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is FluxLinkApiException) rethrow;
      throw FluxLinkApiException('Error resolving link: $e');
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
