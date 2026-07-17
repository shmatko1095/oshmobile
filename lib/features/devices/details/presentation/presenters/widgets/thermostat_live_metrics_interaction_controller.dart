import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThermostatLiveMetricsInteractionController extends ChangeNotifier {
  ThermostatLiveMetricsInteractionController({
    VoidCallback? onThresholdFeedback,
  }) : _onThresholdFeedback =
            onThresholdFeedback ?? _performDefaultThresholdFeedback {
    sheetController.addListener(_handleSheetChanged);
  }

  static const double openThreshold = 56;
  static const double flingVelocity = -700;
  static const double _axisLockDistance = 10;
  static const double _verticalDominanceRatio = 1.2;
  static const Duration _maximumSettleDuration = Duration(milliseconds: 240);
  static const Curve _settleCurve = Cubic(0.22, 0.25, 0, 1);

  final DraggableScrollableController sheetController =
      DraggableScrollableController();
  final VoidCallback _onThresholdFeedback;

  double _progress = 0;
  bool _thresholdReached = false;
  bool _enabled = true;
  bool _disableAnimations = false;
  bool _dragActive = false;
  bool _axisLockedVertically = false;
  bool _gestureRejected = false;
  bool _thresholdFeedbackSent = false;
  Offset _dragOffset = Offset.zero;
  double _dragStartPixels = 0;

  double get progress => _progress;
  bool get thresholdReached => _thresholdReached;
  bool get isDragging => _dragActive;
  bool get isOpen => _progress > 0.001;

  void configure({
    required bool enabled,
    required bool disableAnimations,
  }) {
    _enabled = enabled;
    _disableAnimations = disableAnimations;
  }

  void startDrag() {
    if (!_enabled || !sheetController.isAttached) return;
    _dragActive = true;
    _axisLockedVertically = false;
    _gestureRejected = false;
    _thresholdFeedbackSent = false;
    _dragOffset = Offset.zero;
    _dragStartPixels = sheetController.pixels;
    _setThresholdReached(false);
  }

  void updateDrag(Offset delta) {
    if (!_dragActive || _gestureRejected || !sheetController.isAttached) {
      return;
    }

    _dragOffset += delta;
    if (!_axisLockedVertically) {
      final horizontalDistance = _dragOffset.dx.abs();
      final verticalDistance = _dragOffset.dy.abs();
      if (_dragOffset.distance < _axisLockDistance) return;

      final isUpward = _dragOffset.dy < 0;
      final isVerticallyDominant =
          verticalDistance > horizontalDistance * _verticalDominanceRatio;
      if (!isUpward || !isVerticallyDominant) {
        _gestureRejected = true;
        return;
      }
      _axisLockedVertically = true;
    }

    final upwardDistance = (-_dragOffset.dy).clamp(0.0, double.infinity);
    _setSheetPixels(_dragStartPixels + upwardDistance);
    final reachedThreshold = upwardDistance >= openThreshold;
    _setThresholdReached(reachedThreshold);
    if (reachedThreshold && !_thresholdFeedbackSent) {
      _thresholdFeedbackSent = true;
      _onThresholdFeedback();
    }
  }

  Future<bool> endDrag(Offset velocity) async {
    if (!_dragActive) return _progress >= 0.999;

    final upwardDistance = (-_dragOffset.dy).clamp(0.0, double.infinity);
    final verticallyDominantVelocity = velocity.dy < 0 &&
        velocity.dy.abs() > velocity.dx.abs() * _verticalDominanceRatio;
    final shouldOpen = !_gestureRejected &&
        (_axisLockedVertically || verticallyDominantVelocity) &&
        (upwardDistance >= openThreshold ||
            (verticallyDominantVelocity && velocity.dy <= flingVelocity));

    _resetDragState();
    if (shouldOpen) return open();
    await close();
    return false;
  }

  Future<void> cancelDrag() async {
    if (!_dragActive) return;
    _resetDragState();
    await close();
  }

  Future<bool> open() async {
    if (!_enabled || !sheetController.isAttached) return false;
    if (_dragActive) _resetDragState();
    await _settleTo(1);
    return _progress >= 0.999;
  }

  Future<void> close() async {
    if (!sheetController.isAttached) return;
    if (_dragActive) _resetDragState();
    await _settleTo(0);
  }

  void _resetDragState() {
    _dragActive = false;
    _axisLockedVertically = false;
    _gestureRejected = false;
    _dragOffset = Offset.zero;
    _dragStartPixels = 0;
    _setThresholdReached(false);
  }

  void _setThresholdReached(bool value) {
    if (_thresholdReached == value) return;
    _thresholdReached = value;
    notifyListeners();
  }

  void _setSheetPixels(double pixels) {
    if (!sheetController.isAttached) return;
    final extent =
        sheetController.pixelsToSize(pixels).clamp(0.0, 1.0).toDouble();
    sheetController.jumpTo(extent);
  }

  Future<void> _settleTo(double target) async {
    if (!sheetController.isAttached) return;
    final distance = (target - sheetController.size).abs();
    if (distance <= 0.001) {
      sheetController.jumpTo(target);
      return;
    }
    if (_disableAnimations) {
      sheetController.jumpTo(target);
      return;
    }

    final durationMs = (_maximumSettleDuration.inMilliseconds * distance)
        .round()
        .clamp(80, _maximumSettleDuration.inMilliseconds);
    await sheetController.animateTo(
      target,
      duration: Duration(milliseconds: durationMs),
      curve: _settleCurve,
    );
  }

  void _handleSheetChanged() {
    if (!sheetController.isAttached) return;
    final nextProgress = sheetController.size.clamp(0.0, 1.0).toDouble();
    if ((_progress - nextProgress).abs() <= 0.0001) return;
    _progress = nextProgress;
    notifyListeners();
  }

  static void _performDefaultThresholdFeedback() {
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  void dispose() {
    sheetController
      ..removeListener(_handleSheetChanged)
      ..dispose();
    super.dispose();
  }
}
