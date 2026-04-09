import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';

/// Manual screen tracking for root or in-place views that are not surfaced
/// as Navigator route transitions.
class OshAnalyticsScreenView extends StatefulWidget {
  const OshAnalyticsScreenView({
    super.key,
    required this.screenName,
    required this.child,
  });

  final String screenName;
  final Widget child;

  @override
  State<OshAnalyticsScreenView> createState() => _OshAnalyticsScreenViewState();
}

class _OshAnalyticsScreenViewState extends State<OshAnalyticsScreenView> {
  String? _lastTrackedScreen;

  @override
  void initState() {
    super.initState();
    _trackCurrentScreen();
  }

  @override
  void didUpdateWidget(covariant OshAnalyticsScreenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName != widget.screenName) {
      _trackCurrentScreen();
    }
  }

  void _trackCurrentScreen() {
    final next = widget.screenName.trim();
    if (next.isEmpty || next == _lastTrackedScreen) return;
    _lastTrackedScreen = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        OshAnalytics.logScreenView(
          screenName: next,
          screenClass: widget.runtimeType.toString(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
