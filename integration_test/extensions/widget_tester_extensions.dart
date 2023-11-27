import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiori/presentation/desktop_tablet_scaffold.dart';
import 'package:shiori/presentation/mobile_scaffold.dart';

extension PumpUntilFound on WidgetTester {
  bool get isUsingDesktopLayout {
    final Finder desktopFinder = find.byType(DesktopTabletScaffold, skipOffstage: false);
    final Finder mobileFinder = find.byType(MobileScaffold, skipOffstage: false);
    final bool usesDesktopLayout = any(desktopFinder);
    final bool usesMobileLayout = any(mobileFinder);
    assert(usesDesktopLayout || usesMobileLayout);

    return usesDesktopLayout;
  }

  bool get isLandscape {
    final size = view.display.size;
    return size.width > size.height;
  }

  Future<void> _pumpUntil(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    bool untilFound = true,
  }) async {
    bool timerDone = false;
    final timer = Timer(timeout, () => timerDone = true);
    while (!timerDone) {
      await pump(const Duration(milliseconds: 100));

      if (untilFound && any(finder)) {
        timerDone = true;
        break;
      }

      if (!untilFound && !any(finder)) {
        timerDone = true;
        break;
      }
    }

    timer.cancel();
  }

  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _pumpUntil(finder, timeout: timeout);
  }

  Future<void> pumpUntilNotFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _pumpUntil(finder, timeout: timeout, untilFound: false);
  }
}
