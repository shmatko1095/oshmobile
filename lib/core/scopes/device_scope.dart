import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/di/device_context.dart';
import 'package:oshmobile/core/di/device_di.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_actions_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/pages/device_host_body.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_presenter.dart';
import 'package:oshmobile/features/device_about/presentation/cubit/device_about_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';

/// DeviceScope:
/// - Enters GetIt device scope for the selected device.
/// - Provides device-scoped cubits.
/// - Leaves device scope on dispose.
///
/// NOTE:
/// We use a generation token in DeviceDi to protect against Flutter rebuild races
/// when switching devices fast (new widget can mount before the old one disposes).
class DeviceScope extends StatefulWidget {
  final Device device;
  final ValueChanged<String?>? onTitleChanged;
  final ValueChanged<VoidCallback?>? onSettingsActionChanged;

  const DeviceScope({
    super.key,
    required this.device,
    required this.onTitleChanged,
    required this.onSettingsActionChanged,
  });

  @override
  State<DeviceScope> createState() => _DeviceScopeState();
}

class _DeviceScopeState extends State<DeviceScope> {
  bool _ready = false;
  Object? _error;

  int? _deviceGen;

  late final DeviceContext _ctx;

  late final DeviceHostCubit _host;
  late final DevicePageCubit _page;
  late final DeviceStateCubit _state;
  late final DeviceActionsCubit _actions;
  late final DeviceScheduleCubit _schedule;
  late final DeviceSettingsCubit _settings;
  late final DeviceAboutCubit _about;

  late final DevicePresenterRegistry _presenters;

  @override
  void initState() {
    super.initState();

    // IMPORTANT:
    // When user switches device, Flutter may create the new DeviceScope
    // before disposing the previous one. Enter on the next frame to reduce
    // contention and rely on DeviceDi generation token for correctness.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_enterAndStart());
    });
  }

  Future<void> _enterAndStart() async {
    try {
      // 1) Enter device DI (creates `device:<deviceId>` scope).
      final gen = await DeviceDi.enter(widget.device);
      _deviceGen = gen;

      final sl = GetIt.instance;

      // 2) Resolve device singletons.
      _ctx = sl<DeviceContext>();
      _host = sl<DeviceHostCubit>();
      _page = sl<DevicePageCubit>();
      _state = sl<DeviceStateCubit>();
      _actions = sl<DeviceActionsCubit>();
      _schedule = sl<DeviceScheduleCubit>();
      _settings = sl<DeviceSettingsCubit>();
      _about = sl<DeviceAboutCubit>();
      _presenters = sl<DevicePresenterRegistry>();

      // 3) Start background flows.
      await _page.load(_ctx.deviceId);
      unawaited(_state.start());

      _schedule.start();
      unawaited(_schedule.refresh());

      _settings.start();
      unawaited(_settings.refresh());

      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ready = true;
      });
    }
  }

  @override
  void dispose() {
    final gen = _deviceGen;
    if (gen != null) {
      unawaited(DeviceDi.leave(gen: gen));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    // ignore: unused_local_variable
    final err = _error;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _host),
        BlocProvider.value(value: _page),
        BlocProvider.value(value: _state),
        BlocProvider.value(value: _actions),
        BlocProvider.value(value: _schedule),
        BlocProvider.value(value: _settings),
        BlocProvider.value(value: _about),
      ],
      child: DeviceHostBody(
        deviceId: _ctx.deviceId,
        presenters: _presenters,
        onTitleChanged: widget.onTitleChanged,
        onSettingsActionChanged: widget.onSettingsActionChanged,
      ),
    );
  }
}
