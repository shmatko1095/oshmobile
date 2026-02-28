import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/di/device_context.dart';
import 'package:oshmobile/app/device_session/di/device_di.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_page_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/pages/device_host_body.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_presenter.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';

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
  late final DeviceFacade _facade;
  late final DeviceSnapshotCubit _snapshot;
  bool _snapshotInitialized = false;

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

  Future<void> _retry() async {
    if (_snapshotInitialized) {
      await _snapshot.close();
      _snapshotInitialized = false;
    }

    final gen = _deviceGen;
    _deviceGen = null;
    if (gen != null) {
      await DeviceDi.leave(gen: gen);
    }

    if (!mounted) return;
    setState(() {
      _error = null;
      _ready = false;
    });

    await _enterAndStart();
  }

  Future<void> _enterAndStart() async {
    _error = null;
    try {
      // 1) Enter device DI (creates `device:<deviceId>` scope).
      final gen = await DeviceDi.enter(widget.device);
      _deviceGen = gen;

      final sl = GetIt.instance;

      // 2) Resolve device singletons.
      _ctx = sl<DeviceContext>();
      _host = sl<DeviceHostCubit>();
      _page = sl<DevicePageCubit>();
      _facade = sl<DeviceFacade>();
      _snapshot = DeviceSnapshotCubit(facade: _facade);
      _snapshotInitialized = true;
      _presenters = sl<DevicePresenterRegistry>();

      await _page.load(_ctx.deviceId);

      // Start reactive stream only after negotiation/profile bootstrap completes.
      _snapshot.start();

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
    if (_snapshotInitialized) {
      unawaited(_snapshot.close());
    }
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

    final err = _error;
    if (err != null) {
      return _DeviceScopeError(
        message: err.toString(),
        onRetry: () => unawaited(_retry()),
      );
    }

    return RepositoryProvider<DeviceFacade>.value(
      value: _facade,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _host),
          BlocProvider.value(value: _page),
          BlocProvider.value(value: _snapshot),
        ],
        child: DeviceHostBody(
          deviceId: _ctx.deviceId,
          presenters: _presenters,
          onTitleChanged: widget.onTitleChanged,
          onSettingsActionChanged: widget.onSettingsActionChanged,
        ),
      ),
    );
  }
}

class _DeviceScopeError extends StatelessWidget {
  const _DeviceScopeError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Failed to open device session',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
