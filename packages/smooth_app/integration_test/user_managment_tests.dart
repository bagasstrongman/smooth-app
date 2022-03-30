import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UserManagment Tests', () {
    testWidgets('Login', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        // Configured by test
        'init': 'true',
        'themeColorTag': 'blue',
        //TODO(M123): To be switched after https://github.com/openfoodfacts/smooth-app/issues/1400
        //'themeDark': 'false',

        // Very important by default
        'IMPORTANCE_AS_STRINGnutriscore': 'very_important',

        // Important by default
        'IMPORTANCE_AS_STRINGecoscore': 'important',
        'IMPORTANCE_AS_STRINGnova': 'important',

        // Not important by default
        'IMPORTANCE_AS_STRINGadditives': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_celery': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_crustaceans': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_eggs': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_fish': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_gluten': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_lupin': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_milk': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_molluscs': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_mustard': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_nuts': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_peanuts': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_sesame_seeds': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_soybeans': 'not_important',
        'IMPORTANCE_AS_STRINGallergens_no_sulphur_dioxide_and_sulphites':
            'not_important',
        'IMPORTANCE_AS_STRINGforest_footprint': 'not_important',
        'IMPORTANCE_AS_STRINGlabels_fair_trade': 'not_important',
        'IMPORTANCE_AS_STRINGlabels_organic': 'not_important',
        'IMPORTANCE_AS_STRINGlow_fat': 'not_important',
        'IMPORTANCE_AS_STRINGlow_salt': 'not_important',
        'IMPORTANCE_AS_STRINGlow_saturated_fat': 'not_important',
        'IMPORTANCE_AS_STRINGlow_sugars': 'not_important',
        'IMPORTANCE_AS_STRINGpalm_oil_free': 'not_important',
        'IMPORTANCE_AS_STRINGvegan': 'not_important',
        'IMPORTANCE_AS_STRINGvegetarian': 'not_important',
      });

      app.main();
      await tester.pumpAndSettle();

      final Finder profileTab =
          find.byKey(const ValueKey<String>('Profile Tab'));
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      final Finder gotoLoginPageButton =
          find.byKey(const ValueKey<String>('Goto: LoginPage'));
      await tester.tap(gotoLoginPageButton);
      await tester.pumpAndSettle();

      final Finder userIDTextField =
          find.byKey(const ValueKey<String>('UserID-TextField'));
      await tester.enterText(userIDTextField, 'smoothie-app');

      final Finder passwordTextField =
          find.byKey(const ValueKey<String>('Password-TextField'));
      await tester.enterText(passwordTextField, 'strawberrybanana');

      final Finder loginButton =
          find.byKey(const ValueKey<String>('Login-Button'));
      await tester.tap(loginButton);

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
