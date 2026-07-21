import 'package:flutter_test/flutter_test.dart';
import 'package:dantn_app_cookbook/core/utils/auth_utils.dart';

void main() {
  group('admin credential detection', () {
    test('recognizes the default admin credentials', () {
      expect(
        isAdminCredentials(
          'adminCookBook@cookbook.com',
          'admin050903',
        ),
        isTrue,
      );
    });

    test('does not treat regular user credentials as admin', () {
      expect(
        isAdminCredentials(
          'user@example.com',
          'password123',
        ),
        isFalse,
      );
    });
  });
}
