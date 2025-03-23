import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../models/flux_link_data.dart';
import 'flux_link_api_service.dart';

/// Service to handle deep link detection and resolution on different platforms
class FluxLinkDetector {
  final FluxLinkApiService _apiService;
  final StreamController<FluxLinkData> _linkStreamController =
      StreamController<FluxLinkData>.broadcast();

  /// Stream of resolved FluxLink data
  Stream<FluxLinkData> get onLinkResolved => _linkStreamController.stream;

  /// Creates a new FluxLinkDetector with the provided API service
  FluxLinkDetector({required FluxLinkApiService apiService}) : _apiService = apiService;

  /// Initializes the link detector to listen for incoming links
  Future<void> initialize() async {
    // Platform-specific initialization would go here
    // This would typically involve setting up listeners for deep links
    // using platform-specific plugins like uni_links

    // For demonstration purposes, we're just showing the structure
    if (kIsWeb) {
      _initializeForWeb();
    } else if (Platform.isAndroid) {
      _initializeForAndroid();
    } else if (Platform.isIOS) {
      _initializeForIOS();
    }
  }

  void _initializeForWeb() {
    // Web-specific initialization
    // Could use window.location.href and history API
  }

  void _initializeForAndroid() {
    // Android-specific initialization
    // Could use the uni_links package to listen for incoming links
  }

  void _initializeForIOS() {
    // iOS-specific initialization
    // Could use the uni_links package to listen for incoming links
  }

  /// Handles an incoming link and resolves it
  ///
  /// This is used to handle full FluxLink URLs in the app
  Future<FluxLinkData> handleLink(String url) async {
    try {
      // Check if the URL contains a shortcode pattern
      final shortCodePattern = RegExp(r'\/([a-zA-Z0-9]{8})$');
      final match = shortCodePattern.firstMatch(url);

      if (match != null) {
        // Extract shortcode from URL and resolve it
        final shortCode = match.group(1);
        if (shortCode != null) {
          // Reuse the resolveShortCode method from the API service
          final linkData = await _apiService.resolveShortCode(shortCode);
          _linkStreamController.add(linkData);
          return linkData;
        }
      }
      // else throw an error
      throw FluxLinkApiException('Invalid FluxLink URL: $url');
    } catch (e) {
      if (e is FluxLinkApiException) rethrow;
      throw FluxLinkApiException('Error resolving link: $e');
    }
  }

  /// Cleans up resources when no longer needed
  void dispose() {
    _linkStreamController.close();
  }
}
