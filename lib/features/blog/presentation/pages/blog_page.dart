import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:oshmobile/features/blog/presentation/pages/add_new_blog_page.dart';
import 'package:oshmobile/features/blog/presentation/widgets/blog_card.dart';

class BlogPage extends StatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const BlogPage());

  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  @override
  void initState() {
    super.initState();
    context.read<BlogBloc>().add(BlogFetchAllBlogs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("Blog App"),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, AddNewBlogPage.route()),
            icon: const Icon(CupertinoIcons.add_circled),
          )
        ],
      ),
      body: BlocConsumer<BlogBloc, BlogState>(listener: (context, state) {
        if (state is BlogFailure) {
          showSnackBar(context, state.error);
        }
      }, builder: (context, state) {
        if (state is BlogLoading) {
          return const Loader();
        } else if (state is BlogFetchSuccess) {
          return ListView.builder(
            itemCount: state.blogs.length,
            itemBuilder: (context, index) => BlogCard(
              blog: state.blogs[index],
              color:
                  index % 2 == 0 ? AppPalette.gradient1 : AppPalette.gradient2,
            ),
          );
        } else {
          return const SizedBox();
        }
      }),
    );
  }
}
