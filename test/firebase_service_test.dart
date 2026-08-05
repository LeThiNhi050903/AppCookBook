import 'package:flutter_test/flutter_test.dart';
import 'package:dantn_app_cookbook/core/services/firebase_service.dart';
import 'package:dantn_app_cookbook/core/utils/auth_utils.dart';

void main() {
  group('FirebaseService creation mode', () {
    test('admin email uses admin creation mode', () {
      expect(
        FirebaseService.resolveCreationMode(kAdminEmail),
        RecipeCreationMode.admin,
      );
    });

    test('regular email uses user creation mode', () {
      expect(
        FirebaseService.resolveCreationMode('user@example.com'),
        RecipeCreationMode.user,
      );
    });
  });
}
