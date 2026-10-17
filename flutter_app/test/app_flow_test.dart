import 'package:alcohol_tracker/app.dart';
import 'package:alcohol_tracker/screens/splash_screen.dart';
import 'package:alcohol_tracker/services/demo_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'splash animation runs, then first launch lands on the setup screen',
    (tester) async {
      tester.view.physicalSize = const Size(430 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(AlcoholTrackerApp(api: DemoApi()));
      await tester.pump();

      // Waehrend der Animation: Splash sichtbar, Setup noch nicht.
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Dein Name'), findsNothing);

      // Nach Intro (3 s) + Outro (0,45 s) + Seitenuebergang -> Setup.
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('DEIN NAME'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a profile leads to the home screen with running parties',
    (tester) async {
      tester.view.physicalSize = const Size(430 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(AlcoholTrackerApp(api: DemoApi()));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.text('DEIN NAME'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Julius');
      await tester.pump();
      await tester.tap(find.textContaining("Los geht's"));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }

      expect(find.text('Neue Party starten'), findsOneWidget);
      expect(find.text('WG-Abend'), findsOneWidget);
      expect(find.text('Geburtstagsfeier'), findsOneWidget);
      expect(find.text('Laufende Partys (2)'), findsOneWidget);
    },
  );

  testWidgets('a stored profile skips the setup screen', (tester) async {
    tester.view.physicalSize = const Size(430 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'alcohol_tracker_profile_id_v2': 'demo-lukas',
    });
    await tester.pumpWidget(AlcoholTrackerApp(api: DemoApi()));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('DEIN NAME'), findsNothing);
    expect(find.text('Neue Party starten'), findsOneWidget);
    expect(find.text('Lukas'), findsOneWidget); // Profil-Button im Header
  });
}
