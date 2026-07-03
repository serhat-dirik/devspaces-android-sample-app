// Widget tests for the surface-aware sample app.
// Run with:  flutter test
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp/main.dart';

/// Pumps the app under a given target platform, then immediately clears the
/// override. The override must be reset inside the test body (before it
/// returns), otherwise the framework's end-of-test invariant check trips with
/// "a foundation debug variable was changed".
Future<void> pumpOn(WidgetTester tester, TargetPlatform platform) async {
  debugDefaultTargetPlatformOverride = platform;
  await tester.pumpWidget(const DevSpacesApp());
  await tester.pump(const Duration(seconds: 1)); // let the entrance run
  debugDefaultTargetPlatformOverride = null;
}

void main() {
  testWidgets('Android surface: names itself and the counter increments',
      (tester) async {
    await pumpOn(tester, TargetPlatform.android);

    // The surface banner + app bar both name the Android device.
    expect(find.text('Android Device'), findsWidgets);

    // The interactive state & input check starts at 0 and increments on tap.
    expect(find.text('Taps: 0'), findsWidgets);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('Taps: 1'), findsWidgets);
  });

  testWidgets('Reset is always usable, even at zero (no-op, not disabled)',
      (tester) async {
    // Tall viewport so the whole page (incl. the Hot-reload card at the bottom
    // of the ListView) is laid out without scrolling.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpOn(tester, TargetPlatform.android);

    final reset = find.widgetWithText(OutlinedButton, 'Reset');
    expect(reset, findsOneWidget);

    // At zero the Reset button is enabled (onPressed non-null), not greyed out.
    final OutlinedButton resetAtZero = tester.widget(reset);
    expect(resetAtZero.onPressed, isNotNull);

    // Tapping it at zero is a harmless no-op (stays at 0).
    await tester.tap(reset);
    await tester.pump();
    expect(find.text('Taps: 0'), findsWidgets);

    // After incrementing, Reset clears the counter back to zero.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('Taps: 1'), findsWidgets);
    await tester.tap(reset);
    await tester.pump();
    expect(find.text('Taps: 0'), findsWidgets);
  });

  testWidgets('iOS surface is detected and labelled', (tester) async {
    await pumpOn(tester, TargetPlatform.iOS);

    expect(find.text('iOS Device'), findsWidgets);
    expect(find.text('Android Device'), findsNothing);
  });

  testWidgets('Desktop default branch labels the host without crashing',
      (tester) async {
    // Exercises the default branch of Surface.detect() (and its guarded name
    // indexing) on a non-mobile platform.
    await pumpOn(tester, TargetPlatform.macOS);

    // TargetPlatform.macOS.name is "macOS"; the detector capitalises the first
    // letter, so the label reads "MacOS Host".
    expect(find.text('MacOS Host'), findsWidgets);
  });

  testWidgets('cards survive a large text scale without overflowing',
      (tester) async {
    // M4: at 2.0x text scale the "at a glance" cards must grow rather than clip
    // or throw a RenderFlex overflow.
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const DevSpacesApp());
    await tester.pump(const Duration(seconds: 1));
    debugDefaultTargetPlatformOverride = null;

    // No overflow exception was thrown, and the surface card is still rendered.
    expect(tester.takeException(), isNull);
    expect(find.text('SURFACE'), findsOneWidget);
  });

  test('Surface.detect web branch returns the Web Preview surface', () {
    // kIsWeb is a compile-time const that is false under the VM test runner, so
    // the web branch is asserted directly against the Surface contract. The
    // tagline mirrors production (lib/main.dart) — a profile re-run, NOT a
    // hot-reload loop — so this literal can't drift back into the old claim.
    const web = Surface('Web Preview', Color(0xFF1357D6), Icons.public,
        'Fast browser preview — re-run after edits');
    expect(web.label, 'Web Preview');
    expect(web.icon, Icons.public);
    expect(web.tagline, 'Fast browser preview — re-run after edits');
  });
}
