import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';

class ToggleTile extends StatelessWidget {
  final String title, bind;
  final void Function(BuildContext, bool) onChanged;

  const ToggleTile({
    super.key,
    required this.title,
    required this.bind,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool value = (context.select<DeviceStateCubit, dynamic>(
          (c) => c.state.valueOf(bind),
        ) as bool?) ??
        false;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(context, !value),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                onChanged: (v) => onChanged(context, v),
                activeColor: Colors.white,
                activeTrackColor: Colors.white.withOpacity(0.35),
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
