import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';

class ToggleTile extends StatelessWidget {
  final String title;
  final String bind;
  final void Function(BuildContext, bool)? onChanged;

  const ToggleTile({
    super.key,
    required this.title,
    required this.bind,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool value = (context.select<DeviceStateCubit, dynamic>((c) => c.state.get(bind)) as bool?) ?? false;
    final bool enabled = onChanged != null;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? () => onChanged!(context, !value) : null,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // subtle status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: value ? Colors.greenAccent : Colors.white30,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // title
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // switch
              Switch(
                value: value,
                onChanged: enabled ? (v) => onChanged!(context, v) : null,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.35),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
