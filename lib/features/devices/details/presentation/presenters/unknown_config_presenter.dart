import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/generated/l10n.dart';

import '../cubit/device_page_cubit.dart';
import '../models/osh_config.dart';
import 'device_presenter.dart';

class UnknownConfigPresenter implements DevicePresenter {
  const UnknownConfigPresenter();

  @override
  Widget build(BuildContext context, Device device, DeviceConfig cfg) {
    final alias = (device.userData.alias.isEmpty) ? device.sn : device.userData.alias;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(alias, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
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
                  _MetaCard(device: device, cfg: cfg),
                  const SizedBox(height: 12),
                  _ActionsRow(device: device),
                  const SizedBox(height: 8),
                  _TipsCard(),
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
      color: Colors.amber.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                S.of(context).UnsupportedDeviceMessage,
                style: TextStyle(color: Colors.white, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.device, required this.cfg});

  final Device device;
  final DeviceConfig cfg;

  @override
  Widget build(BuildContext context) {
    final capCount = cfg.capabilities.length;
    return Card(
      color: Colors.white.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).DeviceDetails, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            _MetaRow(
              label: 'Status',
              value: device.connectionInfo.online ? S.of(context).Online : S.of(context).Offline,
              trailing: device.connectionInfo.online
                  ? Icon(Icons.check_circle, size: 16, color: Colors.green.withValues(alpha: 0.5))
                  : Icon(Icons.offline_bolt, size: 16, color: Colors.white70),
            ),
            _MetaRow(label: 'Serial', value: device.sn),
            _MetaRow(label: 'Model ID', value: device.modelId),
            _MetaRow(label: 'Device ID', value: device.id),
            _MetaRow(
              label: 'Capabilities',
              value: capCount == 0 ? '—' : capCount.toString(),
              trailing: capCount == 0
                  ? null
                  : Tooltip(
                      message: cfg.capabilities.join(', '),
                      child: const Icon(Icons.list_alt, size: 18, color: Colors.white70),
                    ),
            ),
          ].expand((widget) => [widget, const SizedBox(height: 12)]).toList(),
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.refresh,
            label: S.of(context).Update,
            onTap: () => context.read<DevicePageCubit>().load(device.id),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).Tips, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            _TipItem(text: S.of(context).TipEnsureAppUpdated),
            _TipItem(text: S.of(context).TipCheckNetwork),
            _TipItem(text: S.of(context).TipContactSupport),
          ],
        ),
      ),
    );
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
        child: Text(label, style: const TextStyle(color: Colors.white70)),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(color: Colors.white)),
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
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withValues(alpha: 0.95)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
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
          const Text('•  ', style: TextStyle(color: Colors.white70)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}
