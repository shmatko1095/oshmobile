import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:oshmobile/app/device_session/presentation/cubit/selected_device_session_cubit.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_host_state.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_compatibility_state_page.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_offline_page.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';

import '../cubit/device_host_cubit.dart';
import '../cubit/device_page_cubit.dart';
import '../presenters/device_presenter.dart';

class DeviceHostBody extends StatelessWidget {
  final String deviceId;
  final DevicePresenterRegistry presenters;
  final ValueChanged<String?>? onTitleChanged;

  const DeviceHostBody({
    super.key,
    required this.deviceId,
    required this.presenters,
    required this.onTitleChanged,
  });

  String? _titleFrom(DevicePageState s) {
    if (s is DevicePageReady) {
      String take(String v) => v.trim();
      final alias = take(s.device.userData.alias);
      if (alias.isNotEmpty) return alias;

      final sn = take(s.device.sn);
      if (sn.isNotEmpty) return sn;

      final model = take(s.device.modelId);
      if (model.isNotEmpty) return model;

      final id = take(s.device.id);
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  Future<void> _refreshAll(BuildContext context) async {
    try {
      await context.read<DeviceFacade>().refreshAll(forceGet: true);
    } catch (_) {}
  }

  void _setAvailability(
    BuildContext context, {
    required bool canOpenInternalSettings,
    required bool canOpenAbout,
  }) {
    context.read<SelectedDeviceSessionCubit>().updateAvailability(
          deviceId: deviceId,
          canOpenInternalSettings: canOpenInternalSettings,
          canOpenAbout: canOpenAbout,
        );
  }

  @override
  Widget build(BuildContext context) {
    final liveDevice = context.select<DeviceCatalogCubit, Device?>(
      (cubit) => cubit.getById(deviceId),
    );

    if (liveDevice == null) {
      _setAvailability(
        context,
        canOpenInternalSettings: false,
        canOpenAbout: false,
      );
      return const Loader();
    }

    return BlocBuilder<DeviceHostCubit, DeviceHostState>(
      builder: (context, hostState) {
        if (hostState.isWaitingOnline) {
          _setAvailability(
            context,
            canOpenInternalSettings: false,
            canOpenAbout: false,
          );
          return const Loader();
        }

        // For offline devices show offline screen immediately.
        if (!liveDevice.connectionInfo.online) {
          _setAvailability(
            context,
            canOpenInternalSettings: false,
            canOpenAbout: false,
          );
          return DeviceOfflinePage(
            device: liveDevice,
            onWifiProvisioningSuccess: () {
              context.read<DeviceHostCubit>().onWifiProvisioningSuccess();
            },
          );
        }

        return BlocConsumer<DevicePageCubit, DevicePageState>(
          listenWhen: (prev, next) => _titleFrom(prev) != _titleFrom(next),
          listener: (context, state) {
            final t = _titleFrom(state);
            onTitleChanged?.call(t);
          },
          builder: (context, st) {
            switch (st) {
              case DevicePageLoading():
                _setAvailability(
                  context,
                  canOpenInternalSettings: false,
                  canOpenAbout: true,
                );
                return const Loader();

              case DevicePageError(:final message):
                _setAvailability(
                  context,
                  canOpenInternalSettings: false,
                  canOpenAbout: true,
                );
                return Center(child: Text(message));

              case DevicePageUpdateRequired(:final message):
                _setAvailability(
                  context,
                  canOpenInternalSettings: false,
                  canOpenAbout: true,
                );
                return DeviceCompatibilityStatePage(
                  device: liveDevice,
                  variant: DeviceCompatibilityVariant.updateRequired,
                  details: message,
                  onRetry: () =>
                      context.read<DevicePageCubit>().load(liveDevice.sn),
                );

              case DevicePageCompatibilityError(:final message):
                _setAvailability(
                  context,
                  canOpenInternalSettings: false,
                  canOpenAbout: true,
                );
                return DeviceCompatibilityStatePage(
                  device: liveDevice,
                  variant: DeviceCompatibilityVariant.compatibilityError,
                  details: message,
                  onRetry: () =>
                      context.read<DevicePageCubit>().load(liveDevice.sn),
                );

              case DevicePageReady(:final bundle):
                final uiSchema = context.read<DeviceFacade>().settingsUiSchema;
                _setAvailability(
                  context,
                  canOpenInternalSettings:
                      uiSchema != null && uiSchema.fieldsByPath.isNotEmpty,
                  canOpenAbout: true,
                );
                final presenter = presenters.resolve(bundle.layout);
                return OshAnalyticsScreenView(
                  screenName: OshAnalyticsScreens.deviceDashboard,
                  child: RefreshIndicator(
                    onRefresh: () => _refreshAll(context),
                    child: presenter.build(context, liveDevice, bundle),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
