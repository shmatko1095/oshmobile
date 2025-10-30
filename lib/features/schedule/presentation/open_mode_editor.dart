import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_actions_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

import '../../schedule/data/schedule_repository.dart'; // InMemoryScheduleRepository / DeviceActionsScheduleRepository
import '../../schedule/presentation/cubit/schedule_cubit.dart';
import 'pages/antifreeze_range_page.dart';
import 'pages/manual_temperature_page.dart';
import 'pages/schedule_editor_page.dart';

String _modeRaw(BuildContext context) {
  final v = context.read<DeviceStateCubit>().state.get(Signal('climate.mode'));
  return v?.toString().toLowerCase() ?? 'off';
}

Future<void> openThermostatModeEditor(
  BuildContext context, {
  required String deviceId,

  // Binds: можно подправить под свой бекенд/стейт
  String manualTargetBind = 'setting.target_temperature',
  String antifreezeMinBind = 'antifreeze.min_temperature',
  String antifreezeMaxBind = 'antifreeze.max_temperature',

  // Команды: подправь, если у тебя другие
  String manualCommand = 'climate.set_target_temperature',
  String antifreezeCommand = 'climate.set_antifreeze_range',
  ScheduleRepository? scheduleRepository, // если не передать — InMemory для dev
}) async {
  final mode = _modeRaw(context);

  if (mode == 'off') return;

  final deviceState = context.read<DeviceStateCubit>();
  final deviceActions = context.read<DeviceActionsCubit>();

  if (mode == 'manual') {
    final current = deviceState.state.get(Signal(manualTargetBind));
    final double initial = (current is num) ? current.toDouble() : double.tryParse(current?.toString() ?? '') ?? 21.0;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: deviceState),
            BlocProvider.value(value: deviceActions),
          ],
          child: ManualTemperaturePage(
              deviceId: deviceId,
              initial: initial,
              onSave: (v) => deviceActions.send(Command(manualCommand), {'value': v}),
              title: S.of(context).ManualTemperature),
        ),
      ),
    );
    return;
  }

  if (mode == 'antifreeze') {
    final rawMin = deviceState.state.get(Signal(antifreezeMinBind));
    final rawMax = deviceState.state.get(Signal(antifreezeMaxBind));
    final double minInit = (rawMin is num) ? rawMin.toDouble() : double.tryParse(rawMin?.toString() ?? '') ?? 5.0;
    final double maxInit = (rawMax is num) ? rawMax.toDouble() : double.tryParse(rawMax?.toString() ?? '') ?? 10.0;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: deviceState),
            BlocProvider.value(value: deviceActions),
          ],
          child: AntifreezeRangePage(
              deviceId: deviceId,
              initialMin: minInit,
              initialMax: maxInit,
              // Todo: No commands here. every action via schedule as mode
              onSave: (minV, maxV) => deviceActions.send(Command(antifreezeCommand), {'min': minV, 'max': maxV}),
              title: S.of(context).ModeAntifreeze),
        ),
      ),
    );
    return;
  }

  String label = mode == 'weekly' ? S.of(context).ModeWeekly : S.of(context).ModeDaily;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: deviceState),
          BlocProvider.value(value: deviceActions),
          BlocProvider(
              create: (_) => ScheduleCubit(
                    deviceId: deviceId,
                    fetch: locator<FetchSchedule>(),
                    save: locator<SaveSchedule>(),
                  )),
        ],
        child: ScheduleEditorPage(deviceId: deviceId, title: label),
      ),
    ),
  );
}
