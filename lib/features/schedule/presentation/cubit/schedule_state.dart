part of 'schedule_cubit.dart';

/// A single outgoing operation awaiting device ACK.
/// We snapshot UI *before* sending and keep a timer per op.
class PendingTxn {
  final String reqId;
  final CalendarSnapshot beforeSnap; // state BEFORE we sent the command
  final CalendarSnapshot? desiredSnap; // full state we WANT (optimistic), if known
  final DateTime deadline;
  final String kind; // 'mode' | 'saveAll' | 'other'
  final CalendarMode? desiredMode; // convenience for 'mode' ops

  const PendingTxn({
    required this.reqId,
    required this.beforeSnap,
    required this.deadline,
    required this.kind,
    this.desiredSnap,
    this.desiredMode,
  });

  PendingTxn copyWith({
    String? reqId,
    CalendarSnapshot? beforeSnap,
    CalendarSnapshot? desiredSnap,
    DateTime? deadline,
    String? kind,
    CalendarMode? desiredMode,
  }) =>
      PendingTxn(
        reqId: reqId ?? this.reqId,
        beforeSnap: beforeSnap ?? this.beforeSnap,
        desiredSnap: desiredSnap ?? this.desiredSnap,
        deadline: deadline ?? this.deadline,
        kind: kind ?? this.kind,
        desiredMode: desiredMode ?? this.desiredMode,
      );
}

sealed class DeviceScheduleState {
  const DeviceScheduleState();

  /// Current mode for UI (already optimistic if pending exists).
  CalendarMode get mode;

  /// Points for the current active mode (already optimistic if pending exists).
  List<SchedulePoint> get points;
}

class DeviceScheduleLoading extends DeviceScheduleState {
  final CalendarMode modeHint;
  const DeviceScheduleLoading({this.modeHint = CalendarMode.off});

  @override
  CalendarMode get mode => modeHint;

  @override
  List<SchedulePoint> get points => const <SchedulePoint>[];
}

class DeviceScheduleError extends DeviceScheduleState {
  final String message;
  const DeviceScheduleError(this.message);

  @override
  CalendarMode get mode => CalendarMode.off;

  @override
  List<SchedulePoint> get points => const <SchedulePoint>[];
}

class DeviceScheduleReady extends DeviceScheduleState {
  final CalendarSnapshot snap; // last confirmed (or latest we stored)
  final bool dirty;
  final bool saving;
  final String? flash;

  /// Queue of pending ops waiting for ACK via reported.appliedReqId key.
  final List<PendingTxn> pendingQueue;

  const DeviceScheduleReady({
    required this.snap,
    this.dirty = false,
    this.saving = false,
    this.flash,
    this.pendingQueue = const <PendingTxn>[],
  });

  /// Optimistic view for UI:
  /// - If there are pending ops, prefer the last txn.desiredSnap;
  /// - Else, if last txn is 'mode' and has desiredMode, overlay it on current snap;
  /// - Else, fall back to confirmed snap.
  CalendarSnapshot get viewSnap {
    if (pendingQueue.isNotEmpty) {
      for (int i = pendingQueue.length - 1; i >= 0; --i) {
        final t = pendingQueue[i];
        if (t.desiredSnap != null) return t.desiredSnap!;
        if (t.kind == 'mode' && t.desiredMode != null) {
          return snap.copyWith(mode: t.desiredMode);
        }
      }
    }
    return snap;
  }

  /// Latest desired mode from the queue (handy for UI badges/spinners).
  CalendarMode? get desiredModeHint {
    for (int i = pendingQueue.length - 1; i >= 0; --i) {
      final t = pendingQueue[i];
      if (t.kind == 'mode' && t.desiredMode != null) return t.desiredMode;
    }
    return null;
  }

  @override
  CalendarMode get mode => viewSnap.mode;

  @override
  List<SchedulePoint> get points => viewSnap.pointsFor(viewSnap.mode);

  DeviceScheduleReady copyWith({
    CalendarSnapshot? snap,
    bool? dirty,
    bool? saving,
    String? flash, // pass null to clear
    List<PendingTxn>? pendingQueue,
  }) =>
      DeviceScheduleReady(
        snap: snap ?? this.snap,
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
        flash: flash,
        pendingQueue: pendingQueue ?? this.pendingQueue,
      );
}
