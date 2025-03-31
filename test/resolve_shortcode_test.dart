import 'package:flutter_test/flutter_test.dart';
import 'package:fluxlink_sdk/fluxlink_sdk.dart';

void main() {
  group('FluxLinkApiService', () {
    test('resolveShortCode parses API response correctly', () async {
      final fluxlink = await FluxLink.initialize(
        apiKey: 'flx_xxHHnwZKVJm5L6lWNl0eFN4swUhpZuIg',
        baseUrl: 'http://localhost:4000/api',
      );
      final data = await fluxlink.resolve('1se1KMmu');
      print('FluxLinkData: ${data.toJson()}');
      expect(data, isA<FluxLinkData>());
    });
  });
}
