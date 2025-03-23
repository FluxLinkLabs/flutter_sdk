<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# FluxLink SDK for Flutter

A Flutter package for integrating with the FluxLink API to handle dynamic links in mobile applications.

## Features

- Resolve FluxLink URLs to retrieve associated data
- Resolve FluxLink shortcodes directly
- Create new FluxLinks with custom metadata
- Platform-specific URL handling
- Automatic deep link detection

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  fluxlink_sdk: ^0.0.1
```

## Usage

### Initialize the SDK

```dart
import 'package:fluxlink_sdk/fluxlink_sdk.dart';

void main() async {
  // Initialize the SDK with your API key
  // If you need shortcode resolution, also provide a clientToken
  final fluxLink = await FluxLink.initialize(
    apiKey: 'your-api-key',
    clientToken: 'your-client-token', // Optional: for shortcode resolution
    // Optional: custom API URL
    // baseUrl: 'https://your-custom-api.com/v1',
  );

  // Your app initialization
  runApp(MyApp(fluxLink: fluxLink));
}
```

### Listen for Dynamic Links

```dart
class MyApp extends StatefulWidget {
  final FluxLink fluxLink;

  const MyApp({Key? key, required this.fluxLink}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<FluxLinkData> _linkSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for dynamic links
    _linkSubscription = widget.fluxLink.onLinkResolved.listen(_handleLink);
  }

  void _handleLink(FluxLinkData data) {
    // Handle the link data
    print('Received link with ID: ${data.id}');
    print('URL: ${data.url}');

    // Access optional fields
    if (data.title != null) {
      print('Title: ${data.title}');
    }

    // Navigate to appropriate screen based on link data
    // ...
  }

  @override
  void dispose() {
    _linkSubscription.cancel();
    widget.fluxLink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your app UI
  }
}
```

### Manually Handle a Link

```dart
Future<void> handleManualLink(String url) async {
  try {
    final data = await fluxLink.handleLink(url);
    // Process the link data
  } catch (e) {
    // Handle error
    print('Error handling link: $e');
  }
}
```

### Resolve a ShortCode

```dart
Future<void> resolveShortCode(String shortCode) async {
  try {
    // Note: You must initialize FluxLink with a clientToken to use this
    final data = await fluxLink.resolveShortCode(shortCode);
    print('Resolved shortcode to URL: ${data.url}');
    // Process the link data
  } catch (e) {
    // Handle error
    print('Error resolving shortcode: $e');
  }
}
```

### Create a New Link

```dart
Future<void> createNewLink() async {
  try {
    final linkData = await fluxLink.createLink(
      originalUrl: 'https://example.com/product/123',
      title: 'Awesome Product',
      description: 'Check out this awesome product!',
      metadata: {
        'productId': '123',
        'category': 'electronics',
      },
      // Optional platform-specific URLs
      androidUrl: 'myapp://product/123',
      iosUrl: 'myapp://product/123',
      webUrl: 'https://mywebsite.com/product/123',
    );

    print('Created new link: ${linkData.url}');
  } catch (e) {
    print('Error creating link: $e');
  }
}
```

## Additional Information

For more detailed documentation, please visit [fluxlink.com/docs](https://fluxlink.com/docs).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
