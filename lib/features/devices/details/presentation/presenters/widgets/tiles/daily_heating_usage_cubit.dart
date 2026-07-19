import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/configuration/app_polling_intervals.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_state.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/heating_usage_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

class DailyHeatingUsageCubit extends Cubit<DailyHeatingUsageState> {
  DailyHeatingUsageCubit({
    required HeatingUsageReader heatingUsageReader,
    Duration cacheTtl = const Duration(minutes: 2),
    Duration pollInterval = AppPollingIntervals.deviceData,
    DateTime Function()? nowUtc,
  })  : _heatingUsageReader = heatingUsageReader,
        _cacheTtl = cacheTtl,
        _pollInterval = pollInterval,
        _nowUtc = nowUtc ?? _defaultNowUtc,
        super(const DailyHeatingUsageState.initial());

  static const Duration _historyWindow = Duration(hours: 24);

  final HeatingUsageReader _heatingUsageReader;
  final Duration _cacheTtl;
  final Duration _pollInterval;
  final DateTime Function() _nowUtc;
  Timer? _pollTimer;
  int _requestVersion = 0;

  static DateTime _defaultNowUtc() => DateTime.now().toUtc();

  void startPolling() {
    if (_pollTimer != null) return;
    unawaited(ensureLoaded());
    if (_pollInterval <= Duration.zero) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(refresh()));
  }

  Future<void> ensureLoaded() => _load(force: false);

  Future<void> refresh() => _load(force: true);

  Future<void> _load({required bool force}) async {
    final now = _nowUtc();
    if (state.status == DailyHeatingUsageStatus.loading) return;
    if (!force && _isFresh(now)) return;

    final requestVersion = ++_requestVersion;
    emit(
      state.copyWith(
        status: DailyHeatingUsageStatus.loading,
        clearErrorMessage: true,
      ),
    );
    final to = _nowUtc();
    final from = to.subtract(_historyWindow);
    try {
      final usage = await _heatingUsageReader.getHeatingUsage(
        query: TelemetryUsageQuery.summary(from: from, to: to),
      );
      if (_isStale(requestVersion)) return;
      emit(
        DailyHeatingUsageState(
          status: DailyHeatingUsageStatus.ready,
          loadFactorPercent: usage.loadFactorPercent,
          coverageRatio: usage.coverageRatio,
          updatedAt: _nowUtc(),
          windowStart: usage.from,
          windowEnd: usage.to,
        ),
      );
    } catch (error) {
      if (_isStale(requestVersion)) return;
      emit(
        state.copyWith(
          status: DailyHeatingUsageStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  bool _isFresh(DateTime now) {
    if (state.status != DailyHeatingUsageStatus.ready) return false;
    final updatedAt = state.updatedAt;
    return updatedAt != null && now.difference(updatedAt) <= _cacheTtl;
  }

  bool _isStale(int requestVersion) {
    return isClosed || _requestVersion != requestVersion;
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }
}
