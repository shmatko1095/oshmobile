import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/core/configuration/power_meter_series_keys.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_state.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';

class DailyEnergyUsageCubit extends Cubit<DailyEnergyUsageState> {
  DailyEnergyUsageCubit({
    required DeviceTelemetryHistoryApi telemetryHistory,
    DailyEnergyUsageCache? persistentCache,
    String? persistentCacheNamespace,
    Duration cacheTtl = const Duration(minutes: 2),
    Duration persistentCacheMaxAge = const Duration(hours: 24),
    DateTime Function()? nowUtc,
  })  : _telemetryHistory = telemetryHistory,
        _persistentCache = persistentCache,
        _persistentCacheNamespace = persistentCacheNamespace?.trim(),
        _cacheTtl = cacheTtl,
        _persistentCacheMaxAge = persistentCacheMaxAge,
        _nowUtc = nowUtc ?? _defaultNowUtc,
        super(const DailyEnergyUsageState.initial());

  static const Duration _historyWindow = Duration(hours: 24);
  static const String seriesKey = PowerMeterSeriesKeys.energyWhDelta;

  final DeviceTelemetryHistoryApi _telemetryHistory;
  final DailyEnergyUsageCache? _persistentCache;
  final String? _persistentCacheNamespace;
  final Duration _cacheTtl;
  final Duration _persistentCacheMaxAge;
  final DateTime Function() _nowUtc;
  int _requestVersion = 0;

  static DateTime _defaultNowUtc() => DateTime.now().toUtc();

  Future<void> ensureLoaded() async {
    final now = _nowUtc();
    if (_isFresh(state, now)) {
      return;
    }

    if (state.energyWh == null) {
      final cached = await _readPersistentCache(now);
      if (isClosed) return;

      if (_isFresh(state, _nowUtc())) {
        return;
      }

      if (state.energyWh == null && cached != null) {
        emit(_stateFromCache(cached));
      }
    }

    if (state.status == DailyEnergyUsageStatus.loading) {
      return;
    }

    final requestVersion = ++_requestVersion;
    emit(
      state.copyWith(
        status: DailyEnergyUsageStatus.loading,
        clearErrorMessage: true,
      ),
    );

    final to = _nowUtc();
    final from = to.subtract(_historyWindow);

    try {
      final aggregate = await _telemetryHistory.getAggregate(
        query: TelemetryAggregateQuery(
          seriesKeys: const <String>[seriesKey],
          from: from,
          to: to,
          preferredResolution: 'auto',
        ),
      );
      if (_isStaleResponse(requestVersion)) return;

      final energyWh = _energyWhFromAggregate(aggregate);
      final updatedAt = _nowUtc();
      final nextState = DailyEnergyUsageState(
        status: DailyEnergyUsageStatus.ready,
        energyWh: energyWh,
        updatedAt: updatedAt,
        windowStart: aggregate.from,
        windowEnd: aggregate.to,
      );
      if (energyWh == null) {
        await _removePersistentCache();
      } else {
        await _writePersistentCache(nextState);
      }
      if (!isClosed) {
        emit(nextState);
      }
    } catch (error) {
      if (_isStaleResponse(requestVersion)) return;
      emit(
        state.copyWith(
          status: DailyEnergyUsageStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  bool shouldLoad() => !_isFresh(state, _nowUtc());

  bool _isFresh(DailyEnergyUsageState state, DateTime now) {
    if (state.status == DailyEnergyUsageStatus.loading) return true;
    if (state.status != DailyEnergyUsageStatus.ready) return false;
    if (state.isFromPersistentCache) return false;
    final updatedAt = state.updatedAt;
    if (updatedAt == null) return false;
    return now.difference(updatedAt) <= _cacheTtl;
  }

  double? _energyWhFromAggregate(TelemetryAggregate aggregate) {
    for (final item in aggregate.series) {
      if (item.seriesKey == seriesKey) {
        return item.sumValue;
      }
    }
    return null;
  }

  Future<DailyEnergyUsageCacheRecord?> _readPersistentCache(
    DateTime now,
  ) async {
    final cache = _persistentCache;
    final namespace = _persistentCacheNamespace;
    if (cache == null || namespace == null || namespace.isEmpty) {
      return null;
    }

    try {
      return await cache.read(
        namespace: namespace,
        seriesKey: seriesKey,
        nowUtc: now,
        maxAge: _persistentCacheMaxAge,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePersistentCache(DailyEnergyUsageState state) async {
    final cache = _persistentCache;
    final namespace = _persistentCacheNamespace;
    final energyWh = state.energyWh;
    final windowStart = state.windowStart;
    final windowEnd = state.windowEnd;
    if (cache == null ||
        namespace == null ||
        namespace.isEmpty ||
        energyWh == null ||
        windowStart == null ||
        windowEnd == null) {
      return;
    }

    try {
      await cache.write(
        namespace: namespace,
        seriesKey: seriesKey,
        record: DailyEnergyUsageCacheRecord(
          energyWh: energyWh,
          savedAt: state.updatedAt ?? _nowUtc(),
          windowStart: windowStart,
          windowEnd: windowEnd,
        ),
      );
    } catch (_) {
      // Dashboard cache is best-effort. Storage failures should not hide data.
    }
  }

  Future<void> _removePersistentCache() async {
    final cache = _persistentCache;
    final namespace = _persistentCacheNamespace;
    if (cache == null || namespace == null || namespace.isEmpty) return;

    try {
      await cache.remove(namespace: namespace, seriesKey: seriesKey);
    } catch (_) {
      // Cache eviction is best-effort.
    }
  }

  DailyEnergyUsageState _stateFromCache(DailyEnergyUsageCacheRecord record) {
    return DailyEnergyUsageState(
      status: DailyEnergyUsageStatus.ready,
      energyWh: record.energyWh,
      updatedAt: record.savedAt,
      windowStart: record.windowStart,
      windowEnd: record.windowEnd,
      isFromPersistentCache: true,
    );
  }

  bool _isStaleResponse(int requestVersion) {
    if (isClosed) return true;
    return _requestVersion != requestVersion;
  }
}
