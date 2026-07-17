import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

import '../cubit/device_page_cubit.dart';
import 'device_presenter.dart';
import 'device_presenter_chrome.dart';
import 'factories/unknown_config_view_model_factory.dart';
import 'models/unknown_config_view_model.dart';

bool _unknownIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _unknownSurfaceColor(BuildContext context) => _unknownIsDark(context)
    ? AppPalette.white.withValues(alpha: 0.04)
    : AppPalette.white;

Color _unknownSurfaceAltColor(BuildContext context) => _unknownIsDark(context)
    ? AppPalette.white.withValues(alpha: 0.06)
    : AppPalette.lightSurfaceSoft;

Color _unknownBorderColor(BuildContext context) => _unknownIsDark(context)
    ? AppPalette.white.withValues(alpha: 0.08)
    : AppPalette.lightBorder;

Color _unknownPrimaryTextColor(BuildContext context) => _unknownIsDark(context)
    ? AppPalette.textPrimary
    : AppPalette.lightTextPrimary;

Color _unknownSecondaryTextColor(BuildContext context) =>
    _unknownIsDark(context)
        ? AppPalette.textSecondary
        : AppPalette.lightTextSecondary;

class UnknownConfigPresenter implements DevicePresenter {
  const UnknownConfigPresenter({
    UnknownConfigViewModelFactory viewModelFactory =
        const UnknownConfigViewModelFactory(),
  }) : _viewModelFactory = viewModelFactory;

  final UnknownConfigViewModelFactory _viewModelFactory;

  @override
  bool get usesEmbeddedAppBar => false;

  @override
  Widget build(
    BuildContext context,
    Device device,
    DeviceConfigurationBundle bundle, {
    DevicePresenterChrome? chrome,
  }) {
    final viewModel = _viewModelFactory.build(device: device, bundle: bundle);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(viewModel.alias, overflow: TextOverflow.ellipsis),
        backgroundColor: AppPalette.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _ProblemCard(),
                  const SizedBox(height: 12),
                  _MetaCard(meta: viewModel.meta),
                  const SizedBox(height: 12),
                  _ActionsRow(
                    actions: viewModel.actions,
                    onActionTap: (action) {
                      switch (action) {
                        case UnknownConfigAction.refresh:
                          context.read<DevicePageCubit>().load(device.sn);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _TipsCard(tips: viewModel.tips),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppPalette.amber.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppPalette.amber, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                S.of(context).UnsupportedDeviceMessage,
                style: TextStyle(
                  color: _unknownPrimaryTextColor(context),
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.meta});

  final UnknownConfigMeta meta;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _unknownSurfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).DeviceDetails,
              style: TextStyle(
                color: _unknownPrimaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaStatus,
              value:
                  meta.isOnline ? S.of(context).Online : S.of(context).Offline,
              trailing: meta.isOnline
                  ? Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppPalette.green.withValues(alpha: 0.5),
                    )
                  : Icon(
                      Icons.offline_bolt,
                      size: 16,
                      color: _unknownSecondaryTextColor(context),
                    ),
            ),
            _MetaRow(
                label: S.of(context).UnknownMetaSerial, value: meta.serial),
            _MetaRow(
              label: S.of(context).UnknownMetaModelId,
              value: meta.modelId,
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaModelName,
              value: meta.modelName,
            ),
            _MetaRow(
                label: S.of(context).UnknownMetaLayout, value: meta.layout),
            _MetaRow(
              label: S.of(context).UnknownMetaConfigurationId,
              value: meta.configurationId,
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaRevision,
              value: meta.revision.toString(),
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaConfigurationStatus,
              value: meta.status,
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaFirmware,
              value: meta.firmwareVersion,
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaDeviceId,
              value: meta.deviceId,
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaControls,
              value:
                  meta.controlsCount == 0 ? '—' : meta.controlsCount.toString(),
              trailing: meta.controlsCount == 0
                  ? null
                  : Tooltip(
                      message: meta.controlIds.join(', '),
                      child: Icon(
                        Icons.list_alt,
                        size: 18,
                        color: _unknownSecondaryTextColor(context),
                      ),
                    ),
            ),
            _MetaRow(
              label: S.of(context).UnknownMetaWidgets,
              value: meta.widgetsCount.toString(),
            ),
          ].expand((widget) => [widget, const SizedBox(height: 12)]).toList(),
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.actions,
    required this.onActionTap,
  });

  final List<UnknownConfigAction> actions;
  final ValueChanged<UnknownConfigAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    final color = _unknownPrimaryTextColor(context);
    return Row(
      children: [
        for (final action in actions)
          Expanded(
            child: _ActionButton(
              icon: _iconFor(action),
              label: _labelFor(context, action),
              onTap: () => onActionTap(action),
              color: color,
            ),
          ),
      ],
    );
  }

  IconData _iconFor(UnknownConfigAction action) {
    switch (action) {
      case UnknownConfigAction.refresh:
        return Icons.refresh;
    }
  }

  String _labelFor(BuildContext context, UnknownConfigAction action) {
    switch (action) {
      case UnknownConfigAction.refresh:
        return S.of(context).Update;
    }
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.tips});

  final List<UnknownConfigTip> tips;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _unknownSurfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).Tips,
              style: TextStyle(
                color: _unknownPrimaryTextColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            for (final tip in tips)
              _TipItem(
                text: _tipText(context, tip),
              ),
          ],
        ),
      ),
    );
  }

  String _tipText(BuildContext context, UnknownConfigTip tip) {
    switch (tip) {
      case UnknownConfigTip.ensureAppUpdated:
        return S.of(context).TipEnsureAppUpdated;
      case UnknownConfigTip.checkNetwork:
        return S.of(context).TipCheckNetwork;
      case UnknownConfigTip.contactSupport:
        return S.of(context).TipContactSupport;
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 120,
        child: Text(
          label,
          style: TextStyle(color: _unknownSecondaryTextColor(context)),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(color: _unknownPrimaryTextColor(context)),
        ),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _unknownSurfaceAltColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _unknownBorderColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withValues(alpha: 0.95)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(color: _unknownSecondaryTextColor(context)),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _unknownSecondaryTextColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}
