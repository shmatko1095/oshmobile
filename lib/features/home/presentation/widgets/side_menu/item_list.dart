import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/theme/text_styles.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/thing_item.dart';
import 'package:oshmobile/generated/l10n.dart';

class ItemList extends StatefulWidget {
  final bool isDemo;

  const ItemList({super.key, required this.isDemo});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  void initState() {
    context.read<HomeCubit>().updateDeviceList();
    super.initState();
  }

  List<Device> get devices => context.read<HomeCubit>().getUserDevices();

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
          builder: (context, state) {
            if (devices.isEmpty) {
              return Center(
                child: Text(
                  S.of(context).NoDevicesYet,
                  style: TextStyles.contentStyle,
                ),
              );
            } else {
              return ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  Device device = devices[index];
                  return ThingItem(
                    id: device.id,
                    name: device.userData.alias.isEmpty
                        ? device.sn
                        : device.userData.alias,
                    room: device.userData.description,
                    online: device.connectionInfo.online,
                    // type: device.model.configuration.osh.type,
                    unassignDeviceAllowed: !widget.isDemo,
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
