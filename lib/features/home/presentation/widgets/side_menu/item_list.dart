import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/device_catalog/presentation/cubit/device_catalog_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/thing_item.dart';
import 'package:oshmobile/generated/l10n.dart';

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  void initState() {
    context.read<DeviceCatalogCubit>().refresh();
    super.initState();
  }

  List<Device> get devices => context.read<DeviceCatalogCubit>().getAll();

  void _onStateChanged(BuildContext context, DeviceCatalogState state) {
    if (state.status == DeviceCatalogStatus.failure &&
        (state.errorMessage ?? '').isNotEmpty) {
      SnackBarUtils.showFail(
        context: context,
        content: state.errorMessage ?? "",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => context.read<DeviceCatalogCubit>().refresh(),
        child: BlocConsumer<DeviceCatalogCubit, DeviceCatalogState>(
          listener: (context, state) => _onStateChanged(context, state),
          builder: (context, state) {
            if (devices.isEmpty) {
              return Center(
                child: Text(
                  S.of(context).NoDevicesYet,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            } else {
              return ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final selectedId = state.selectedDeviceId;
                  final Device device = devices[index];
                  return ThingItem(
                    id: device.id,
                    serial: device.sn,
                    name: device.userData.alias.isEmpty
                        ? device.sn
                        : device.userData.alias,
                    room: device.userData.description,
                    online: device.connectionInfo.online,
                    selected: device.id == selectedId,
                    // type: device.model.configuration.osh.type,
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
