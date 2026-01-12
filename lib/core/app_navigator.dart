import 'package:flutter/widgets.dart';

/// Global navigator key reused across services that need access to the app
/// navigator without introducing circular dependencies.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
