import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/presentation/utils/settings_text_localizer.dart';
import 'package:oshmobile/features/settings/presentation/widgets/device_settings_content.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceSettingsPage extends StatelessWidget {
  final SettingsUiSchema schema;
  final String? groupId;

  static const SettingsTextLocalizer _textLocalizer = SettingsTextLocalizer();

  const DeviceSettingsPage({
    super.key,
    required this.schema,
    this.groupId,
  });

  bool get _isRoot => groupId == null;

  DeviceSlice<SettingsSnapshot> _settingsSlice(BuildContext context) =>
      context.read<DeviceSnapshotCubit>().state.settings;

  SettingsUiGroup? _currentGroup() =>
      groupId == null ? null : schema.group(groupId!);

  List<SettingsUiGroup> _groupsForPage() {
    final groups = _isRoot ? schema.rootGroups : schema.childGroupsOf(groupId!);
    return groups.toList(growable: false);
  }

  List<SettingsUiField> _fieldsForPage() {
    if (_isRoot) {
      return const <SettingsUiField>[];
    }
    return schema.fieldsInGroup(groupId!).toList(growable: false);
  }

  Future<bool> _onWillPop(BuildContext context) async {
    if (!_isRoot) {
      return true;
    }

    final slice = _settingsSlice(context);
    if (!slice.dirty || slice.status == DeviceSliceStatus.saving) {
      return true;
    }

    final result = await showDialog<_DiscardDialogResult>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.of(context).UnsavedChanges),
          content: Text(S.of(context).UnsavedChangesDiscardPrompt),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_DiscardDialogResult.cancel),
              child: Text(S.of(context).Cancel),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_DiscardDialogResult.discard),
              child: Text(S.of(context).Discard),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return false;

    if (result == _DiscardDialogResult.discard) {
      context.read<DeviceFacade>().settings.discardLocalChanges();
      return true;
    }

    return false;
  }

  Future<void> _saveAndClose(BuildContext context) async {
    await context.read<DeviceFacade>().settings.save();
    if (!context.mounted) return;

    final slice = _settingsSlice(context);
    if (slice.dirty || slice.status == DeviceSliceStatus.saving) {
      return;
    }

    _closeSettingsFlow(context);
  }

  void _closeSettingsFlow(BuildContext context) {
    final navigator = Navigator.of(context);
    if (ModalRoute.of(context)?.settings.name !=
        OshAnalyticsScreens.deviceSettings) {
      navigator.pop();
      return;
    }

    navigator.popUntil(
      (route) => route.settings.name != OshAnalyticsScreens.deviceSettings,
    );
  }

  Future<void> _openGroup(
    BuildContext context,
    SettingsUiGroup group,
  ) async {
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    final deviceLayout = snapshotCubit.state.details.data?.layout;

    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.deviceSettingsOpened,
        parameters: {
          'device_layout': deviceLayout,
          'group_id': group.id,
        },
      ),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: OshAnalyticsScreens.deviceSettings),
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: DeviceSettingsPage(
            schema: schema,
            groupId: group.id,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentGroup = _currentGroup();
    final groups = _groupsForPage();
    final fields = _fieldsForPage();

    return PopScope(
      canPop: !_isRoot,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: BackButton(
            onPressed: () async {
              final shouldPop = await _onWillPop(context);
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            currentGroup == null
                ? S.of(context).Settings
                : _textLocalizer.groupTitle(context, currentGroup),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
              buildWhen: (prev, next) {
                return prev.settings.status != next.settings.status ||
                    prev.settings.dirty != next.settings.dirty;
              },
              builder: (context, snap) {
                final slice = snap.settings;
                if (slice.status == DeviceSliceStatus.loading ||
                    slice.status == DeviceSliceStatus.idle) {
                  return const SizedBox.shrink();
                }

                if (slice.status == DeviceSliceStatus.saving) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final canSave = slice.dirty;
                return TextButton(
                  onPressed: canSave ? () => _saveAndClose(context) : null,
                  child: Text(
                    S.of(context).Save,
                    style: TextStyle(
                      color: canSave
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocListener<DeviceSnapshotCubit, DeviceSnapshot>(
          listenWhen: (prev, next) {
            return prev.settings.error != next.settings.error &&
                next.settings.error != null;
          },
          listener: (context, snap) {
            final msg = snap.settings.error;
            if (msg != null) {
              SnackBarUtils.showFail(context: context, content: msg);
            }
          },
          child: SafeArea(
            child: DeviceSettingsContent(
              schema: schema,
              isRoot: _isRoot,
              groups: groups,
              fields: fields,
              onOpenGroup: (group) => _openGroup(context, group),
            ),
          ),
        ),
      ),
    );
  }
}

enum _DiscardDialogResult { discard, cancel }
