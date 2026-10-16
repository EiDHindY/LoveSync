import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/services/update_service.dart';

void main() {
  group('UpdateService.isVersionGreater', () {
    test('correctly identifies higher patch version', () {
      expect(UpdateService.isVersionGreater('1.0.2', '1.0.1'), isTrue);
      expect(UpdateService.isVersionGreater('1.0.1', '1.0.2'), isFalse);
    });

    test('correctly identifies higher minor version', () {
      expect(UpdateService.isVersionGreater('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isVersionGreater('1.0.9', '1.1.0'), isFalse);
    });

    test('correctly identifies higher major version', () {
      expect(UpdateService.isVersionGreater('2.0.0', '1.9.9'), isTrue);
      expect(UpdateService.isVersionGreater('1.9.9', '2.0.0'), isFalse);
    });

    test('returns false when versions are identical', () {
      expect(UpdateService.isVersionGreater('1.0.1', '1.0.1'), isFalse);
    });

    test('handles versions with different segment counts', () {
      expect(UpdateService.isVersionGreater('1.0.1.1', '1.0.1'), isTrue);
      expect(UpdateService.isVersionGreater('1.0', '1.0.0'), isFalse);
      expect(UpdateService.isVersionGreater('1.0.1', '1.0'), isTrue);
    });

    test('handles empty strings safely', () {
      expect(UpdateService.isVersionGreater('', '1.0.0'), isFalse);
      expect(UpdateService.isVersionGreater('1.0.0', ''), isFalse);
    });
  });
}
