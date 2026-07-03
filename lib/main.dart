// OpenShift Dev Spaces — mobile sample app.
//
// The whole point of this screen: make it OBVIOUS at a glance whether you are
// looking at the WEB PREVIEW tab or the ANDROID DEVICE tab, so the two browser
// tabs are never confused. Each surface gets a loud, distinct accent color +
// icon, used for the AppBar, the gradient hero banner, and the ColorScheme seed.
//
// Surface detection uses ONLY package:flutter/foundation.dart (kIsWeb /
// defaultTargetPlatform). It never imports dart:io, which does not compile on
// Flutter web.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DevSpacesApp());

/// Immutable description of the surface the app is currently running on.
class Surface {
  const Surface(this.label, this.color, this.icon, this.tagline);

  final String label;
  final Color color;
  final IconData icon;
  final String tagline;

  static Surface detect() {
    // Every surface accent below clears WCAG 2.1 AA (>=4.5:1) for white-on-accent
    // (AppBar title, hero text, FAB label). As an accent-on-light value on the
    // light surfaceContainerHighest card the accent is only ever an icon /
    // graphical color (3:1 bar, all clear it) — the accent is NOT used for body
    // text (card text uses scheme.onSurface), so the per-surface accent-on-light
    // ratios noted below are FYI, not a text-contrast guarantee (Android in
    // particular is ~4.21:1, just under the 4.5:1 text bar). Ratios were verified
    // with a contrast checker.
    if (kIsWeb) {
      // Darkened Web blue (was 0xFF1E6FFF, white-on-accent only ~4.40:1 — under
      // AA). 0xFF1357D6 is white-on-accent ~6.25:1 and accent-on-light ~5.17:1.
      return const Surface('Web Preview', Color(0xFF1357D6), Icons.public,
          'Fast browser preview — re-run after edits');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Darkened Android green (was 0xFF14A44D, ~3.3:1 on white — fails AA).
        // 0xFF0B7A37 is white-on-accent ~5.45:1, so the AppBar title and hero
        // tagline (white-on-accent) clear AA. As an accent-on-light value on the
        // M3 light card surface (~#E6E0E9) it is ~4.21:1 — that clears the 3:1
        // bar for icons/graphical elements (its only use here) but is just under
        // the 4.5:1 text bar, so it is NOT used for accent body text (card text
        // uses scheme.onSurface). It stays recognisably "Android green".
        return const Surface('Android Device', Color(0xFF0B7A37), Icons.android,
            'Live on the on-cluster device');
      case TargetPlatform.iOS:
        // iOS gets a loud, distinct indigo/purple (was a flat slate grey,
        // 0xFF4A4E57 — high contrast but off-palette and dull). 0xFF5B33C0 is
        // white-on-accent ~7.84:1 and accent-on-light ~6.49:1, and reads as
        // unmistakably different from Web blue and Android green.
        return const Surface('iOS Device', Color(0xFF5B33C0),
            Icons.phone_iphone, 'Running on an Apple device');
      default:
        final name = defaultTargetPlatform.name;
        // Guard the empty-name case (no enum value is empty today, but indexing
        // name[0] unguarded is the one un-defensive spot — keep it safe).
        final label = name.isEmpty
            ? 'Native Host'
            : '${name[0].toUpperCase()}${name.substring(1)} Host';
        // Desktop violet: white-on-accent ~6.44:1, accent-on-light ~5.33:1.
        return Surface(label, const Color(0xFF6750A4), Icons.devices_other,
            'Native desktop host');
    }
  }
}

class DevSpacesApp extends StatelessWidget {
  const DevSpacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Surface.detect();
    return MaterialApp(
      title: 'Dev Spaces — ${surface.label}',
      debugShowCheckedModeBanner: false,
      // L2: follow the system brightness. The counter readout and card text all
      // draw in scheme.onSurface / onSurfaceVariant, which the dark scheme
      // re-derives to keep contrast — so a dark-mode user no longer gets a
      // forced bright-white diagnostics screen.
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: surface.color),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: surface.color,
          brightness: Brightness.dark,
        ),
      ),
      home: DiagnosticsPage(surface: surface),
    );
  }
}

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key, required this.surface});

  final Surface surface;

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();
  int _taps = 0;

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.surface;
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final size = media.size;
    final mode = kDebugMode ? 'Debug' : (kProfileMode ? 'Profile' : 'Release');

    // At-a-glance hero metrics shown as a small grid of accent cards.
    final cards = <Widget>[
      _InfoCard(Icons.devices, 'Surface', surface.label, surface.color),
      _InfoCard(kDebugMode ? Icons.bug_report : Icons.rocket_launch,
          'Build Mode', mode, scheme.primary),
      _InfoCard(Icons.aspect_ratio, 'Screen Size',
          '${size.width.toStringAsFixed(0)} x ${size.height.toStringAsFixed(0)} dp',
          scheme.primary),
    ];

    // Longer textual facts read cleaner as label:value rows than as a grid.
    final facts = <_Fact>[
      _Fact(Icons.memory, 'TargetPlatform', defaultTargetPlatform.name),
      _Fact(Icons.grain, 'Device pixel ratio',
          '${media.devicePixelRatio.toStringAsFixed(2)}x'),
      _Fact(Icons.text_fields, 'Text scale',
          '${media.textScaler.scale(1.0).toStringAsFixed(2)}x'),
      _Fact(
          media.platformBrightness == Brightness.dark
              ? Icons.dark_mode
              : Icons.light_mode,
          'Platform brightness',
          media.platformBrightness.name),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: surface.color,
        foregroundColor: Colors.white,
        title: Row(children: [
          Icon(surface.icon),
          const SizedBox(width: 10),
          Text(surface.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _Hero(surface: surface, entrance: _entrance),
          const SizedBox(height: 20),
          _SectionLabel('At a glance', scheme),
          const SizedBox(height: 12),
          // A flowing grid whose cells grow to fit their content. Using Wrap
          // (instead of a fixed childAspectRatio GridView) means card height
          // follows the text — so values no longer clip at large text scale.
          LayoutBuilder(builder: (context, constraints) {
            const spacing = 12.0;
            final columns = constraints.maxWidth >= 600 ? 3 : 2;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          }),
          const SizedBox(height: 20),
          _SectionLabel('Runtime', scheme),
          const SizedBox(height: 8),
          _RuntimeList(facts: facts, scheme: scheme),
          const SizedBox(height: 20),
          _SectionLabel('State & input check', scheme),
          const SizedBox(height: 8),
          _HotReloadCard(
            taps: _taps,
            color: surface.color,
            // L1: keep Reset usable (a no-op at zero) instead of disabling it,
            // so it never reads as a broken/greyed-out control.
            onReset: () => setState(() => _taps = 0),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: surface.color,
        foregroundColor: Colors.white,
        onPressed: () => setState(() => _taps++),
        // This is the SINGLE increment control; the card just shows the live
        // value and offers Reset. The tooltip is the ONE accessible-name source
        // (it spells out the action + live count for screen readers / hover);
        // the visible "Taps: N" label is left to be read as the button's text,
        // so the count is not announced two or three times over.
        tooltip: 'Increment the tap counter (now $_taps)',
        icon: const Icon(Icons.touch_app),
        label: Text('Taps: $_taps'),
      ),
    );
  }
}

/// Small uppercase heading that breaks the page into clear groups.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.scheme);

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ));
  }
}

/// Big gradient banner that names the surface unmistakably, with a fade + slide
/// entrance so a fresh hot-reload is visually confirmed.
class _Hero extends StatelessWidget {
  const _Hero({required this.surface, required this.entrance});

  final Surface surface;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: entrance, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -0.08), end: Offset.zero)
            .animate(curved),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surface.color,
                Color.lerp(surface.color, Colors.black, 0.28)!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(surface.icon, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 14),
                Text('RUNNING ON',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    )),
              ]),
              const SizedBox(height: 16),
              Text(surface.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  )),
              const SizedBox(height: 6),
              Text(surface.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single label:value runtime fact.
class _Fact {
  const _Fact(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

/// Clean label:value list of runtime facts, separated by hairline dividers.
class _RuntimeList extends StatelessWidget {
  const _RuntimeList({required this.facts, required this.scheme});

  final List<_Fact> facts;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            ListTile(
              leading: Icon(facts[i].icon, color: scheme.primary),
              title: Text(facts[i].label),
              trailing: Text(facts[i].value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dedicated interactive panel: a large live counter readout plus a Reset
/// button, so the developer can confirm input handling and live state on every
/// surface. (On the device / IDE debug session the value also survives hot
/// reload; the default web preview is a re-run, so it resets — see the card
/// copy.) There is ONE increment control — the extended FAB ("Taps: N"); this
/// card just shows the live value and lets you reset it. (Previously a duplicate
/// in-card "Tap" button drove the same counter, which read as ambiguous.)
class _HotReloadCard extends StatelessWidget {
  const _HotReloadCard({
    required this.taps,
    required this.color,
    required this.onReset,
  });

  final int taps;
  final Color color;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // L2: 48dp minimum touch target on the device under test.
    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(72, 48)),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(children: [
        // The accent only tints the chip BACKGROUND; the number itself is drawn
        // in onSurface, which Material 3 guarantees clears AA on this surface
        // (drawing the digits in the raw accent could dip under 4.5:1).
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text('$taps',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Counter is live',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: scheme.onSurface)),
              const SizedBox(height: 2),
              Text('Tap to increment. On the device (and the IDE debug '
                  'session) it survives hot reload; the default web preview '
                  'is a re-run, so it resets.',
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // L2: 48dp target; L1: Reset always enabled (no-op at zero).
        OutlinedButton(
            onPressed: onReset, style: buttonStyle, child: const Text('Reset')),
      ]),
    );
  }
}

/// Accent card for an at-a-glance metric: icon on top, label + value below.
class _InfoCard extends StatelessWidget {
  const _InfoCard(this.icon, this.label, this.value, this.color);

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 12),
          Text(label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 0.6,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 2),
          // Allow the value to wrap instead of clipping — keeps the metric
          // readable at large text scale (the card grows to fit).
          Text(value,
              softWrap: true,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              )),
        ],
      ),
    );
  }
}
