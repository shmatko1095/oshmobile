import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screen_view.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';
import 'package:oshmobile/features/device_management/presentation/cubit/device_access_cubit.dart';
import 'package:oshmobile/features/device_management/presentation/widgets/remove_device_dialog.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

class DeviceAccessPage extends StatelessWidget {
  final String deviceId;
  final String deviceSerial;
  final String deviceName;
  final bool isDemoMode;

  const DeviceAccessPage({
    super.key,
    required this.deviceId,
    required this.deviceSerial,
    required this.deviceName,
    required this.isDemoMode,
  });

  static MaterialPageRoute<void> route({
    required String deviceId,
    required String deviceSerial,
    required String deviceName,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: OshAnalyticsScreens.deviceAccess),
      builder: (context) => BlocProvider<DeviceAccessCubit>(
        create: (_) => locator<DeviceAccessCubit>()..load(serial: deviceSerial),
        child: DeviceAccessPage(
          deviceId: deviceId,
          deviceSerial: deviceSerial,
          deviceName: deviceName,
          isDemoMode: context.read<GlobalAuthCubit>().isDemoMode,
        ),
      ),
    );
  }

  String _displayName(DeviceAssignedUser user) {
    final fullName = '${user.firstName} ${user.lastName}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (fullName.isNotEmpty) return fullName;
    if (user.email.trim().isNotEmpty) return user.email.trim();
    return user.uuid.trim();
  }

  String _avatarLabel(DeviceAssignedUser user) {
    final name = _displayName(user);
    if (name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  Future<void> _removeMyAccess(BuildContext context) async {
    final removed = await RemoveDeviceDialog.show(
      context,
      deviceId: deviceId,
      deviceSerial: deviceSerial,
      deviceName: deviceName,
    );

    if (removed == true && context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OshAnalyticsScreenView(
      screenName: OshAnalyticsScreens.deviceAccess,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            S.of(context).DeviceAccessTitle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<DeviceAccessCubit, DeviceAccessState>(
            builder: (context, state) {
              switch (state.status) {
                case DeviceAccessStatus.initial:
                case DeviceAccessStatus.loading:
                  return const Loader();
                case DeviceAccessStatus.failure:
                  return _FailureState(
                    message: state.errorMessage,
                    onRetry: () {
                      context.read<DeviceAccessCubit>().refresh(
                            serial: deviceSerial,
                          );
                    },
                  );
                case DeviceAccessStatus.ready:
                  return RefreshIndicator(
                    onRefresh: () => context.read<DeviceAccessCubit>().refresh(
                          serial: deviceSerial,
                        ),
                    child: state.users.isEmpty
                        ? _EmptyState(
                            isDemoMode: isDemoMode,
                          )
                        : _UsersList(
                            users: state.users,
                            currentUserUuid: state.currentUserUuid,
                            displayName: _displayName,
                            avatarLabel: _avatarLabel,
                            onRemoveCurrentUser: () => _removeMyAccess(context),
                          ),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.currentUserUuid,
    required this.displayName,
    required this.avatarLabel,
    required this.onRemoveCurrentUser,
  });

  final List<DeviceAssignedUser> users;
  final String? currentUserUuid;
  final String Function(DeviceAssignedUser user) displayName;
  final String Function(DeviceAssignedUser user) avatarLabel;
  final VoidCallback onRemoveCurrentUser;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBackground =
        isDark ? AppPalette.surfaceAlt : AppPalette.lightSurfaceMuted;
    final avatarTextColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextStrong;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.radiusXl),
          ),
          child: Column(
            children: [
              for (var i = 0; i < users.length; i++) ...[
                ListTile(
                  key: ValueKey('device_access_user_${users[i].uuid}'),
                  leading: CircleAvatar(
                    backgroundColor: avatarBackground,
                    child: Text(
                      avatarLabel(users[i]),
                      style: TextStyle(
                        color: avatarTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(displayName(users[i])),
                  subtitle:
                      users[i].email.isEmpty ? null : Text(users[i].email),
                  trailing: users[i].uuid == currentUserUuid
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.accentPrimary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                s.YouLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                            ),
                            IconButton(
                              key: ValueKey(
                                  'device_access_remove_${users[i].uuid}'),
                              tooltip: s.DeviceAccessRemoveMyAccess,
                              onPressed: onRemoveCurrentUser,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppPalette.destructiveFg,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                if (i != users.length - 1)
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isDemoMode,
  });

  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Icon(
          Icons.group_outlined,
          size: 36,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          isDemoMode
              ? S.of(context).DeviceAccessEmptyDemo
              : S.of(context).DeviceAccessEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({
    required this.message,
    required this.onRetry,
  });

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 36,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          S.of(context).DeviceAccessLoadFailed,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if ((message ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.72),
                ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(S.of(context).Retry),
          ),
        ),
      ],
    );
  }
}
