import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class DeviceAboutPage extends StatefulWidget {
  final String deviceSn;

  const DeviceAboutPage({
    super.key,
    required this.deviceSn,
  });

  @override
  State<DeviceAboutPage> createState() => _DeviceAboutPageState();
}

class _DeviceAboutPageState extends State<DeviceAboutPage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<DeviceFacade>().about.get(force: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(S.of(context).About),
      ),
      body: BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
        buildWhen: (prev, next) =>
            prev.about != next.about || prev.updatedAt != next.updatedAt,
        builder: (context, snap) {
          final about = snap.about;
          final data = about.data;
          if ((about.status == DeviceSliceStatus.loading ||
                  about.status == DeviceSliceStatus.idle) &&
              data == null) {
            return const Loader();
          }

          final payload = _extractDataPayload(data);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                deviceSn: widget.deviceSn,
                receivedAt: snap.updatedAt,
                error: about.error,
              ),
              Expanded(
                child: payload == null
                    ? Center(child: Text(S.of(context).NoDataYet))
                    : _FlatList(data: payload),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic>? _extractDataPayload(Map<String, dynamic>? raw) {
    if (raw == null) return null;

    final params = raw['params'];
    if (params is Map) {
      final data = params['data'];
      if (data is Map) {
        return data.cast<String, dynamic>();
      }
    }

    return raw;
  }
}

class _Header extends StatelessWidget {
  final String deviceSn;
  final DateTime? receivedAt;
  final String? error;

  const _Header({
    required this.deviceSn,
    required this.receivedAt,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String? subtitle;
    if (receivedAt != null) {
      final hh = receivedAt!.hour.toString().padLeft(2, '0');
      final mm = receivedAt!.minute.toString().padLeft(2, '0');
      final ss = receivedAt!.second.toString().padLeft(2, '0');
      subtitle = S.of(context).LastUpdateAt('$hh:$mm:$ss');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deviceSn,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FlatList extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FlatList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text(S.of(context).EmptyPayload));
    }

    final rows = _flatten(data, depth: 0);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: rows.length,
      itemBuilder: (ctx, index) {
        final row = rows[index];
        return _FlatRowWidget(row: row);
      },
    );
  }

  List<_FlatRow> _flatten(Map<String, dynamic> map, {required int depth}) {
    final out = <_FlatRow>[];
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map) {
        out.add(_FlatRow.header(key, depth));
        out.addAll(_flatten(value.cast<String, dynamic>(), depth: depth + 1));
        continue;
      }

      if (value is List) {
        out.add(_FlatRow.header(key, depth));
        for (var i = 0; i < value.length; i++) {
          final v = value[i];
          if (v is Map) {
            out.add(_FlatRow.header('[$i]', depth + 1));
            out.addAll(_flatten(v.cast<String, dynamic>(), depth: depth + 2));
          } else {
            out.add(_FlatRow.value('[$i]', _stringify(v), depth + 1));
          }
        }
        continue;
      }

      out.add(_FlatRow.value(key, _stringify(value), depth));
    }
    return out;
  }

  String _stringify(dynamic v) {
    if (v == null) return 'null';
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    return v.toString();
  }
}

class _FlatRow {
  final String keyText;
  final String? valueText;
  final int depth;
  final bool isHeader;

  const _FlatRow._(this.keyText, this.valueText, this.depth, this.isHeader);

  factory _FlatRow.header(String key, int depth) =>
      _FlatRow._(key, null, depth, true);

  factory _FlatRow.value(String key, String value, int depth) =>
      _FlatRow._(key, value, depth, false);
}

class _FlatRowWidget extends StatelessWidget {
  final _FlatRow row;

  const _FlatRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = 12.0 + row.depth * 12.0;

    if (row.isHeader) {
      return Padding(
        padding: EdgeInsets.fromLTRB(left, 6, 12, 2),
        child: Text(
          row.keyText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(left, 4, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.keyText,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: SelectableText(
              row.valueText ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
