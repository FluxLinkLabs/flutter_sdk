/// Model class representing resolved FluxLink data.
class FluxLinkData {
  /// Unique identifier for the link
  final String id;

  /// The original URL that was resolved
  final String url;

  /// Optional title associated with the link
  final String? title;

  /// Optional description associated with the link
  final String? description;

  /// Optional metadata as key-value pairs
  final Map<String, dynamic>? metadata;

  /// Platform-specific URL for Android
  final String? androidUrl;

  /// Platform-specific URL for iOS
  final String? iosUrl;

  /// Platform-specific URL for Web
  final String? webUrl;

  /// Constructs a FluxLinkData instance with required and optional parameters
  FluxLinkData({
    required this.id,
    required this.url,
    this.title,
    this.description,
    this.metadata,
    this.androidUrl,
    this.iosUrl,
    this.webUrl,
  });

  /// Creates a FluxLinkData instance from a JSON map
  factory FluxLinkData.fromJson(Map<String, dynamic> json) {
    return FluxLinkData(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      androidUrl: json['androidUrl'] as String?,
      iosUrl: json['iosUrl'] as String?,
      webUrl: json['webUrl'] as String?,
    );
  }

  /// Converts the FluxLinkData instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
      if (androidUrl != null) 'androidUrl': androidUrl,
      if (iosUrl != null) 'iosUrl': iosUrl,
      if (webUrl != null) 'webUrl': webUrl,
    };
  }
}
