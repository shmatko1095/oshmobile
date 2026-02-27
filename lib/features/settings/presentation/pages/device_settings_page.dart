import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/device_about/presentation/pages/device_about_page.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_slider_tile.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceSettingsPage extends StatelessWidget {
  final Device device;
  final SettingsUiSchema schema;

  const DeviceSettingsPage({
    super.key,
    required this.device,
    required this.schema,
  });

  DeviceSlice<SettingsSnapshot> _settingsSlice(BuildContext context) =>
      context.read<DeviceSnapshotCubit>().state.settings;

  Future<bool> _onWillPop(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final facade = context.read<DeviceFacade>();

    return PopScope(
      canPop: false,
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
            S.of(context).Settings,
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
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                  );
                }

                final canSave = slice.dirty;
                return TextButton(
                  onPressed: canSave
                      ? () async {
                          await facade.settings.save();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      : null,
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
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (schema.fieldsByPath.isEmpty) {
      return Center(
        child: Text(S.of(context).DeviceNoSettingsYet),
      );
    }

    return BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
      buildWhen: (prev, next) => prev.settings != next.settings,
      builder: (context, snap) {
        final slice = snap.settings;

        switch (slice.status) {
          case DeviceSliceStatus.idle:
          case DeviceSliceStatus.loading:
            return const Loader();
          case DeviceSliceStatus.error:
            if (slice.data == null) {
              return _buildError(context, slice.error ?? 'Unknown error');
            }
            return _buildSettingsList(
              context,
              schema,
              slice.data!,
              device,
            );
          case DeviceSliceStatus.ready:
          case DeviceSliceStatus.saving:
            final data = slice.data;
            if (data == null) {
              return _buildError(context, 'Settings state is empty');
            }
            return _buildSettingsList(context, schema, data, device);
        }
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);

    final isTimeout = message.toLowerCase().contains('timeout');
    final friendly = isTimeout
        ? S.of(context).DeviceOfflineOrNotResponding
        : S.of(context).FailedToLoadSettings;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              friendly,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<DeviceFacade>().settings.get(force: true),
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).Retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    SettingsUiSchema schema,
    SettingsSnapshot snapshot,
    Device device,
  ) {
    final theme = Theme.of(context);
    final groups = schema.groups.toList(growable: false);
    final itemCount = groups.length + 1;

    return RefreshIndicator(
      onRefresh: () => context.read<DeviceFacade>().settings.get(force: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: itemCount,
        itemBuilder: (ctx, index) {
          if (index == groups.length) {
            return _buildAboutCard(context, theme, device);
          }

          final group = groups[index];
          final fields = schema.fieldsInGroup(group.id).toList(growable: false);
          if (fields.isEmpty) return const SizedBox.shrink();

          return Card(
            margin: EdgeInsets.only(top: index == 0 ? 4 : 12, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppPalette.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    group.titleKey ?? group.id,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                for (var i = 0; i < fields.length; i++)
                  _buildFieldTile(
                    context,
                    fields[i],
                    snapshot,
                    showDivider: i != fields.length - 1,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, ThemeData theme, Device device) {
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusXl),
      ),
      child: ListTile(
        title: Text(S.of(context).About),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeviceRouteScope.provide(
                facade: facade,
                snapshotCubit: snapshotCubit,
                child: DeviceAboutPage(deviceSn: device.sn),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldTile(
    BuildContext context,
    SettingsUiField field,
    SettingsSnapshot snapshot, {
    required bool showDivider,
  }) {
    final facade = context.read<DeviceFacade>();
    final title = (field.titleKey == null || field.titleKey!.trim().isEmpty)
        ? field.path
        : field.titleKey!.trim();

    switch (field.widget) {
      case SettingsUiWidget.toggle:
        final value = snapshot.getValue<bool>(field.path) ?? false;
        return SettingsSwitchTile(
          title: title,
          value: value,
          onChanged: field.writable
              ? (v) => facade.settings.patch(field.path, v)
              : (_) {},
          showDivider: showDivider,
        );

      case SettingsUiWidget.slider:
        final raw = snapshot.getValue<num>(field.path) ?? field.min ?? 0;
        final value = raw.toDouble();
        final min = (field.min ?? 0).toDouble();
        final max = (field.max ?? (min + 100)).toDouble();
        final step = (field.step ?? 1).toDouble().abs();

        return SettingsSliderTile(
          title: title,
          value: value,
          min: min,
          max: max > min ? max : min + 1,
          step: step > 0 ? step : 1,
          unit: field.unit,
          onChanged: field.writable
              ? (newVal) {
                  final snapped = _snapToStep(min, max, step, newVal);
                  if (field.type == SettingsUiFieldType.integer) {
                    facade.settings.patch(field.path, snapped.round());
                  } else {
                    facade.settings.patch(field.path, snapped);
                  }
                }
              : (_) {},
          showDivider: showDivider,
        );

      case SettingsUiWidget.select:
        final options = field.enumValues ?? const <String>[];
        return _buildSelectTile(
          context,
          title: title,
          options: options,
          value: snapshot.getValue<Object?>(field.path)?.toString(),
          showDivider: showDivider,
          onChanged: field.writable
              ? (v) => facade.settings.patch(field.path, v)
              : null,
        );

      case SettingsUiWidget.text:
        final value = snapshot.getValue<Object?>(field.path);
        return _buildReadonlyTile(
          title: title,
          value: value?.toString(),
          showDivider: showDivider,
        );

      case SettingsUiWidget.unsupported:
        return _buildReadonlyTile(
          title: title,
          value: 'Unsupported',
          showDivider: showDivider,
        );
    }
  }

  Widget _buildSelectTile(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String? value,
    required bool showDivider,
    required ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    final safeOptions = options.isEmpty ? const <String>['-'] : options;
    final safeValue = safeOptions.contains(value) ? value : safeOptions.first;

    return Column(
      children: [
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          minVerticalPadding: 2,
          title: Text(title, style: theme.textTheme.bodyLarge),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              items: safeOptions
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (v) {
                if (v == null ||
                    onChanged == null ||
                    safeOptions.first == '-') {
                  return;
                }
                onChanged(v);
              },
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  Widget _buildReadonlyTile({
    required String title,
    required String? value,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          minVerticalPadding: 2,
          title: Text(title),
          subtitle: value == null ? null : Text(value),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  double _snapToStep(double min, double max, double step, double value) {
    final safeStep = step <= 0 ? 1.0 : step;
    final clamped = value.clamp(min, max);
    final n = ((clamped - min) / safeStep).round();
    return (min + n * safeStep).clamp(min, max);
  }
}

enum _DiscardDialogResult { discard, cancel }
