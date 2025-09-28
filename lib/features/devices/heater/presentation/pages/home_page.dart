import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:oshmobile/features/home/presentation/utils/device_page_factory.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/side_menu.dart';

class HomePage extends StatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const HomePage());

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
        title: const Center(
          child: Text("Osh App"),
        ),
        actions: [
          IconButton(
            onPressed: () => {},
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      drawer: const SideMenu(demo: false),
      body: DevicePageFactory.getPage(""),
    );
  }
}
