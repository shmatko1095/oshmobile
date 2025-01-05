import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/thing_item.dart';
import 'package:oshmobile/generated/l10n.dart';

class ItemList extends StatelessWidget {
  final bool isDemo;

  const ItemList({super.key, required this.isDemo});

  void _onStateChanged(BuildContext context, HomeState state) {
    if (state is HomeFailed) {
      SnackBarUtils.showFail(
        context: context,
        content: state.message ?? "",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => context.read<HomeCubit>().updateDeviceList(),
        child: BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) => _onStateChanged(context, state),
          buildWhen: (previous, current) => current is HomeReady,
          builder: (context, state) {
            if (state is HomeReady) {
              if (state.userDevices.isEmpty) {
                return Center(
                  child: Text(
                    S.of(context).NoDevicesYet,
                    style: TextStyles.contentStyle,
                  ),
                );
              } else {
                return ListView.builder(
                  itemCount: state.userDevices.length,
                  itemBuilder: (context, index) {
                    Device device = state.userDevices[index];
                    return ThingItem(
                      sn: device.sn,
                      name: device.customersData.name.isEmpty
                          ? device.sn
                          : device.customersData.name,
                      room: device.customersData.roomHint,
                      online: device.status.online,
                      unassignDeviceAllowed: false,
                    );
                  },
                );
              }
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
