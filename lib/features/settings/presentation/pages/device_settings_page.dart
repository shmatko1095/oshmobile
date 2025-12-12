import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/devices/details/presentation/models/osh_config.dart';
import 'package:oshmobile/features/devices/details/presentation/models/settings_schema.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/presentation/cubit/device_settings_cubit.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_slider_tile.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_switch_tile.dart';

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
          title: const Text('Unsaved changes'),
          content: const Text(
            'You have unsaved changes. Do you want to discard them and leave this page?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_DiscardDialogResult.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_DiscardDialogResult.discard),
              child: const Text('Discard'),
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

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
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
            'Settings', // TODO: localize
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            BlocBuilder<DeviceSettingsCubit, DeviceSettingsState>(
              buildWhen: (prev, next) {
                if (prev is! DeviceSettingsReady || next is! DeviceSettingsReady) {
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
                  onPressed: canSave ? () => context.read<DeviceSettingsCubit>().persist() : null,
                  child: Text(
                    'Save', // TODO: localize
                    style: TextStyle(
                      color: canSave ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
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
      return const Center(
        child: Text('This device does not expose any settings yet.'),
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
            return _buildSettingsList(context, schema, snapshot);
        }
      },
    );
  }

  /// Friendly error UI with "Retry" button.
  Widget _buildError(BuildContext context, String message) {
    final theme = Theme.of(context);

    // Немного гуманизируем текст.
    final isTimeout = message.toLowerCase().contains('timeout');
    final friendly = isTimeout ? 'Device seems offline or not responding.' : 'Failed to load settings.';

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
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<DeviceSettingsCubit>().rebind(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
  ) {
    final groups = schema.groups.toList();
    if (groups.isEmpty) {
      return const Center(child: Text('No settings groups defined.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: groups.length,
      itemBuilder: (ctx, index) {
        final group = groups[index];
        final fields = schema.fieldsInGroup(group.id).toList();
        if (fields.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 8 : 16,
            bottom: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  group.titleKey ?? group.id,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              // group card
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    for (final f in fields) _buildFieldTile(context, f, snapshot),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldTile(
    BuildContext context,
    SettingsFieldMeta meta,
    SettingsSnapshot snapshot,
  ) {
    final cubit = context.read<DeviceSettingsCubit>();

    switch (meta.type) {
      case 'bool':
        final value =
            snapshot.getValue<bool>(meta.id) ?? (meta.defaultValue is bool ? meta.defaultValue as bool : false);

        return SettingsSwitchTile(
          title: meta.titleKey ?? meta.id,
          value: value,
          onChanged: (v) => cubit.changeValue(meta.id, v),
        );

      case 'int':
      case 'double':
        final min = (meta.min ?? 0).toDouble();
        final max = (meta.max ?? 100).toDouble();
        final step = (meta.step ?? 1).toDouble().abs();

        final raw = snapshot.getValue<num>(meta.id) ?? (meta.defaultValue is num ? meta.defaultValue as num : min);
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
        );

      default:
        // Fallback для пока не поддерживаемых типов (string, enum etc.).
        // Можно потом заменить на нормальные контролы.
        return SettingsSwitchTile(
          title: '${meta.titleKey ?? meta.id} (unsupported type: ${meta.type})',
          value: false,
          onChanged: (_) {},
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
