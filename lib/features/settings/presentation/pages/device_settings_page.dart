import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/device_about/presentation/cubit/device_about_cubit.dart';
import 'package:oshmobile/features/device_about/presentation/pages/device_about_page.dart';
import 'package:oshmobile/features/devices/details/presentation/models/osh_config.dart';
import 'package:oshmobile/features/devices/details/presentation/models/settings_schema.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_slider_tile.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:oshmobile/generated/l10n.dart';

/// Page that renders editable device settings based on DeviceConfig.settings.
///
/// Assumptions:
/// - DeviceSettingsCubit is already provided above this widget.
/// - [config.settings] describes how to render each field.
/// - Actual values come from SettingsSnapshot inside the cubit.
class DeviceSettingsPage extends StatelessWidget {
  final Device device;
  final DeviceConfig config;

  const DeviceSettingsPage({
    super.key,
    required this.device,
    required this.config,
  });

  /// Handle system back / app bar back with "unsaved changes" dialog.
  Future<bool> _onWillPop(BuildContext context) async {
    final cubit = context.read<DeviceSettingsCubit>();
    final state = cubit.state;

    if (state is! DeviceSettingsReady) {
      // Loading / error states – просто уходим.
      return true;
    }

    if (!state.dirty || state.saving) {
      // Нет локальных изменений или как раз сохраняем – уходим без вопросов.
      // (Сохранение всё равно завершится в фоне, кубит живёт в DeviceHostBody.)
      return true;
    }

    // Есть несохранённые изменения – спрашиваем пользователя.
    final result = await showDialog<_DiscardDialogResult>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.of(context).UnsavedChanges),
          content: Text(
            S.of(context).UnsavedChangesDiscardPrompt,
          ),
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

    if (result == _DiscardDialogResult.discard) {
      cubit.discardLocalChanges();
      return true;
    }

    // Cancel or null (backdrop tap) – остаёмся на странице.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final schema = config.settings;

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
            BlocBuilder<DeviceSettingsCubit, DeviceSettingsState>(
              buildWhen: (prev, next) {
                if (prev is! DeviceSettingsReady ||
                    next is! DeviceSettingsReady) {
                  return prev.runtimeType != next.runtimeType;
                }
                return prev.dirty != next.dirty || prev.saving != next.saving;
              },
              builder: (context, state) {
                if (state is! DeviceSettingsReady) {
                  return const SizedBox.shrink();
                }

                if (state.saving) {
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

                final canSave = state.dirty && !state.saving;
                return TextButton(
                  onPressed: canSave
                      ? () {
                          context.read<DeviceSettingsCubit>().saveAll();
                          Navigator.of(context).pop();
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
        body: BlocListener<DeviceSettingsCubit, DeviceSettingsState>(
          listenWhen: (_, s) => s is DeviceSettingsReady && s.flash != null,
          listener: (context, s) {
            final msg = (s as DeviceSettingsReady).flash!;
            // Сейчас flash используется только для ошибок (таймаут/ошибка сохранения),
            // поэтому показываем через showFail.
            SnackBarUtils.showFail(context: context, content: msg);
          },
          child: SafeArea(
            child: _buildBody(context, schema),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SettingsSchema? schema) {
    if (schema == null) {
      return Center(
        child: Text(S.of(context).DeviceNoSettingsYet),
      );
    }

    return BlocBuilder<DeviceSettingsCubit, DeviceSettingsState>(
      builder: (context, state) {
        switch (state) {
          case DeviceSettingsLoading():
            return const Loader();
          case DeviceSettingsError(:final message):
            return _buildError(context, message);
          case DeviceSettingsReady(:final snapshot):
            return _buildSettingsList(context, schema, snapshot, device);
        }
      },
    );
  }

  /// Friendly error UI with "Retry" button.
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
              onPressed: () => context.read<DeviceSettingsCubit>().refresh(),
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
    SettingsSchema schema,
    SettingsSnapshot snapshot,
    Device device,
  ) {
    final theme = Theme.of(context);
    final groups = schema.groups.toList();
    final itemCount = groups.length + 1; // extra About card

    return RefreshIndicator(
      onRefresh: () =>
          context.read<DeviceSettingsCubit>().refresh(forceGet: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: itemCount,
        itemBuilder: (ctx, index) {
          if (index == groups.length) {
            return _buildAboutCard(context, theme, device);
          }

          final group = groups[index];
          final fields = schema.fieldsInGroup(group.id).toList();
          if (fields.isEmpty) return const SizedBox.shrink();

          return Card(
            margin: EdgeInsets.only(top: index == 0 ? 4 : 12, bottom: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppPalette.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group header
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
    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppPalette.radiusXl),
      ),
      child: ListTile(
        title: Text(S.of(context).About),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final aboutCubit = context.read<DeviceAboutCubit>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: aboutCubit,
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
    SettingsFieldMeta meta,
    SettingsSnapshot snapshot, {
    required bool showDivider,
  }) {
    final cubit = context.read<DeviceSettingsCubit>();

    switch (meta.type) {
      case 'bool':
        final value = snapshot.getValue<bool>(meta.id) ??
            (meta.defaultValue is bool ? meta.defaultValue as bool : false);

        return SettingsSwitchTile(
          title: meta.titleKey ?? meta.id,
          value: value,
          onChanged: (v) => cubit.changeValue(meta.id, v),
          showDivider: showDivider,
        );

      case 'int':
      case 'double':
        final min = (meta.min ?? 0).toDouble();
        final max = (meta.max ?? 100).toDouble();
        final step = (meta.step ?? 1).toDouble().abs();

        final raw = snapshot.getValue<num>(meta.id) ??
            (meta.defaultValue is num ? meta.defaultValue as num : min);
        final value = raw.toDouble();

        return SettingsSliderTile(
          title: meta.titleKey ?? meta.id,
          value: value,
          min: min,
          max: max > min ? max : min + 1,
          step: step > 0 ? step : 1,
          unit: meta.unit,
          onChanged: (newVal) {
            // Snap to step
            final snapped = _snapToStep(min, max, step, newVal);
            if (meta.type == 'int') {
              cubit.changeValue(meta.id, snapped.round());
            } else {
              cubit.changeValue(meta.id, snapped);
            }
          },
          showDivider: showDivider,
        );

      default:
        // Fallback для пока не поддерживаемых типов (string, enum etc.).
        // Можно потом заменить на нормальные контролы.
        return SettingsSwitchTile(
          title: '${meta.titleKey ?? meta.id} (unsupported type: ${meta.type})',
          value: false,
          onChanged: (_) {},
          showDivider: showDivider,
        );
    }
  }

  double _snapToStep(double min, double max, double step, double value) {
    final safeStep = step <= 0 ? 1.0 : step;
    final clamped = value.clamp(min, max);
    final n = ((clamped - min) / safeStep).round();
    return (min + n * safeStep).clamp(min, max);
  }
}

enum _DiscardDialogResult { discard, cancel }
