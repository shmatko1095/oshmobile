import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/pages/device_host_body.dart';
import 'package:oshmobile/features/devices/no_selected_device/presentation/pages/no_selected_device_page.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/side_menu.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(builder: (context) => const HomePage());

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().updateDeviceList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Osh App")),
        actions: [
          IconButton(
            onPressed: () => {},
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      drawer: const SideMenu(),
      body: BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (p, n) => p.selectedDeviceId != n.selectedDeviceId,
        builder: (context, state) {
          final id = state.selectedDeviceId;
          if (id == null) {
            return const NoSelectedDevicePage();
          }
          return DeviceHostBody(deviceId: id);
        },
      ),
    );
  }
}
