import 'package:go_router/go_router.dart';
import 'package:rairepo/home_page.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(title: 'Rairepo Home'),
    ),
  ],
);
