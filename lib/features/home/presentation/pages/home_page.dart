import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
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
    // context.read<HomeCubit>().loadUserData();
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
            icon: const Icon(CupertinoIcons.add_circled),
          )
        ],
      ),
      drawer: const SideMenu(),
      body: const Loader(),
      // body: BlocConsumer<BlogBloc, BlogState>(listener: (context, state) {
      //   if (state is BlogFailure) {
      //     showSnackBar(context: context, content: state.error);
      // }
      // }, builder: (context, state) {
      //   if (state is BlogLoading) {
      //     return const Loader();
      //   } else if (state is BlogFetchSuccess) {
      //     return ListView.builder(
      //       itemCount: state.blogs.length,
      //       itemBuilder: (context, index) => BlogCard(
      //         blog: state.blogs[index],
      //         color:
      //             index % 2 == 0 ? AppPalette.gradient1 : AppPalette.gradient2,
      //       ),
      //     );
      //   } else {
      //     return const SizedBox();
      //   }
      // }),
    );
  }
}
