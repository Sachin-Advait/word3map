import 'package:flutter/material.dart';
import 'package:word3map/modules/home_page.dart';
import 'package:word3map/modules/login_page.dart';
import 'package:word3map/modules/notification_page.dart';
import 'package:word3map/modules/splash_page.dart';
import 'package:word3map/routes/deflaut_route.dart';
import 'package:word3map/routes/routes.dart';

PageRouteBuilder buildRoutes(Widget child) {
  return PageRouteBuilder(
    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    pageBuilder: (_, __, ___) => child,
  );
}

class AppPages {
  static String getInitialRoute() => AppRoutes.INITIAL;

  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.INITIAL:
        return buildRoutes(SplashPage());

      case AppRoutes.HOME:
        final arg = settings.arguments as String? ?? "";
        return buildRoutes(HomePage(notificationThreeWord: arg));

      case AppRoutes.LOGIN:
        return buildRoutes(LoginPage());

      case AppRoutes.NOTIFICATION:
        return buildRoutes(NotificationsPage());

      default:
        return buildRoutes(const DeflautView());
    }
  }
}
