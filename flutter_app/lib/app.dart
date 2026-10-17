import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/connection_error_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/home_screen.dart';
import 'screens/me_screen.dart';
import 'screens/party_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wrapped_screen.dart';
import 'services/api.dart';
import 'state/body_profile_controller.dart';
import 'state/profile_controller.dart';
import 'state/startup_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

/// Wurzel der App: Provider, Router und Theme.
class AlcoholTrackerApp extends StatefulWidget {
  const AlcoholTrackerApp({super.key, required this.api});

  final Api api;

  @override
  State<AlcoholTrackerApp> createState() => _AlcoholTrackerAppState();
}

class _AlcoholTrackerAppState extends State<AlcoholTrackerApp> {
  late final ProfileController _profile = ProfileController(widget.api);
  late final BodyProfileController _body = BodyProfileController();
  late final StartupController _startup = StartupController();
  late final GoRouter _router = _buildRouter();

  @override
  void initState() {
    super.initState();
    // Laeuft waehrend der Start-Animation im Hintergrund.
    _profile.init();
    _body.load();
  }

  @override
  void dispose() {
    _router.dispose();
    _profile.dispose();
    _body.dispose();
    _startup.dispose();
    super.dispose();
  }

  CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
      );

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: Listenable.merge([_startup, _profile]),
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (!_startup.splashDone) return loc == '/splash' ? null : '/splash';
        if (_profile.needsRetry) return loc == '/offline' ? null : '/offline';
        if (_profile.profile == null) return loc == '/setup' ? null : '/setup';
        if (loc == '/splash' || loc == '/setup' || loc == '/offline') {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => Consumer<ProfileController>(
            builder: (context, profile, _) => SplashScreen(
              ready: !profile.loading,
              onFinished: _startup.markSplashDone,
            ),
          ),
        ),
        GoRoute(
          path: '/offline',
          pageBuilder: (context, state) =>
              _fade(state, const ConnectionErrorScreen()),
        ),
        GoRoute(
          path: '/setup',
          pageBuilder: (context, state) => _fade(state, const SetupScreen()),
        ),
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _fade(state, const HomeScreen()),
        ),
        GoRoute(
          path: '/p/:id',
          builder: (context, state) =>
              PartyScreen(partyId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'wrapped',
              builder: (context, state) => WrappedScreen(
                partyId: state.pathParameters['id']!,
                fromParty: state.extra == 'party',
              ),
            ),
          ],
        ),
        GoRoute(path: '/me', builder: (context, state) => const MeScreen()),
        GoRoute(
          path: '/guide',
          builder: (context, state) => const GuideScreen(),
        ),
      ],
      errorBuilder: (context, state) => const HomeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Api>.value(value: widget.api),
        ChangeNotifierProvider<ProfileController>.value(value: _profile),
        ChangeNotifierProvider<BodyProfileController>.value(value: _body),
        ChangeNotifierProvider<StartupController>.value(value: _startup),
      ],
      child: MaterialApp.router(
        title: 'AlcoholTracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
        locale: const Locale('de'),
        supportedLocales: const [Locale('de'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => AppFrame(child: child ?? const SizedBox()),
      ),
    );
  }
}
