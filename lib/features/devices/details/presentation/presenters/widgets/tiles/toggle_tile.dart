import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';

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
    final bool value =
        (context.select<DeviceStateCubit, dynamic>((c) => c.state.get(bind))
                as bool?) ??
            false;
    final bool enabled = onChanged != null;

    return GlassStatCard(
      onTap: enabled ? () => onChanged!(context, !value) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: value ? AppPalette.accentSuccess : Colors.white30,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
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
          Switch.adaptive(
            value: value,
            onChanged: enabled ? (v) => onChanged!(context, v) : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
