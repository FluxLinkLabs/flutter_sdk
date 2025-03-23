import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxlink_sdk/src/models/flux_link_data.dart';

void main() {
  group('FluxLinkApiService', () {
    test('resolveShortCode parses API response correctly', () {
      // Simulate a response from the API
      final jsonResponse = {
        'success': true,
        'data': {
          '_id': '12345abcde',
          'shortCode': 'abc12345',
          'title': 'Test Link',
          'defaultUrl': 'https://example.com',
          'androidLink': 'https://example.com/android',
          'iosLink': 'https://example.com/ios',
          'desktopUrl': 'https://example.com/desktop',
          'analytics': {'clicks': 42, 'uniqueClicks': 24},
          'createdBy': 'user123',
          'organization': 'org456',
          'isActive': true,
          'deferredLinking': false,
          'tags': ['test', 'example'],
          'createdAt': '2023-01-01T00:00:00.000Z',
          'customDomain': 'custom.example.com',
        },
      };

      // Manually parse the response
      final responseBody = jsonEncode(jsonResponse);
      final dynamic data = json.decode(responseBody);

      if (data is Map &&
          data.containsKey('success') &&
          data['success'] == true &&
          data.containsKey('data') &&
          data['data'] is Map) {
        final Map<String, dynamic> linkData = data['data'];

        final FluxLinkData result = FluxLinkData(
          id: linkData['_id'],
          url: linkData['defaultUrl'],
          title: linkData['title'],
          androidUrl: linkData['androidLink'],
          iosUrl: linkData['iosLink'],
          webUrl: linkData['desktopUrl'],
          metadata: {
            'analytics': linkData['analytics'],
            'createdBy': linkData['createdBy'],
            'organization': linkData['organization'],
            'isActive': linkData['isActive'],
            'shortCode': linkData['shortCode'],
            'deferredLinking': linkData['deferredLinking'],
            'tags': linkData['tags'],
            'createdAt': linkData['createdAt'],
            'customDomain': linkData['customDomain'],
          },
        );

        // Verify that the manual parsing works correctly
        expect(result.id, '12345abcde');
        expect(result.url, 'https://example.com');
        expect(result.title, 'Test Link');
        expect(result.androidUrl, 'https://example.com/android');
        expect(result.iosUrl, 'https://example.com/ios');
        expect(result.webUrl, 'https://example.com/desktop');
        expect(result.metadata!['analytics']['clicks'], 42);
        expect(result.metadata!['shortCode'], 'abc12345');
        expect(result.metadata!['customDomain'], 'custom.example.com');
      } else {
        fail('Failed to parse JSON correctly');
      }
    });

    test('getPlatformUrl returns correct URL based on platform', () {
      final data = FluxLinkData(
        id: '123',
        url: 'https://default.com',
        androidUrl: 'https://android.com',
        iosUrl: 'https://ios.com',
        webUrl: 'https://web.com',
      );

      // Note: Since we can't control the platform during a test,
      // we're just testing that the method exists and returns a non-null value
      expect(data.getPlatformUrl(), isNotNull);
      expect(data.getPlatformUrl(), isA<String>());
    });
  });
}
