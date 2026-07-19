import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_card_content.dart';

class DailyHeatingUsageCard extends StatelessWidget {
  const DailyHeatingUsageCard({
    super.key,
    required this.title,
    this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DailyHeatingUsageCubit(
        heatingUsageReader: context.read<DeviceFacade>().telemetryHistory,
      )..startPolling(),
      child: DailyHeatingUsageCardContent(title: title, onTap: onTap),
    );
  }
}
