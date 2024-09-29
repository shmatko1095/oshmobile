import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/constants/constants.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/pick_image.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:oshmobile/features/blog/presentation/pages/blog_page.dart';
import 'package:oshmobile/features/blog/presentation/widgets/blog_editor.dart';

class AddNewBlogPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const AddNewBlogPage(),
      );

  const AddNewBlogPage({super.key});

  @override
  State<AddNewBlogPage> createState() => _AddNewBlogPageState();
}

class _AddNewBlogPageState extends State<AddNewBlogPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedTopics = [];
  File? image;

  void _pickImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null) {
      setState(() {
        image = pickedImage;
      });
    }
  }

  void _uploadBlog() {
    if (_formKey.currentState!.validate() &&
        _selectedTopics.isNotEmpty &&
        image != null) {
      final posterId =
          (context.read<AppUserCubit>().state as AppUserSignedIn).user.id;
      context.read<BlogBloc>().add(
            BlogUpload(
              posterId: posterId,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              image: image!,
              topics: _selectedTopics,
            ),
          );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _uploadBlog(),
            icon: const Icon(Icons.done_rounded),
          )
        ],
      ),
      body: BlocConsumer<BlogBloc, BlogState>(listener: (context, state) {
        if (state is BlogFailure) {
          showSnackBar(context, state.error);
        } else if (state is BlogUploadSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            BlogPage.route(),
            (route) => false,
          );
        }
      }, builder: (context, state) {
        if (state is BlogLoading) {
          return const Loader();
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppPalette.borderColor, width: 2),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    height: 200,
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => _pickImage(),
                      child: image != null
                          ? Image.file(image!, fit: BoxFit.cover)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 40,
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Text(
                                  "Select your image",
                                  style: TextStyle(fontSize: 15),
                                )
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: Constants.topics
                          .map((e) => Padding(
                              padding: const EdgeInsets.all(5),
                              child: GestureDetector(
                                onTap: () {
                                  _selectedTopics.contains(e)
                                      ? _selectedTopics.remove(e)
                                      : _selectedTopics.add(e);
                                  setState(() {});
                                },
                                child: Chip(
                                  label: Text(e),
                                  color: _selectedTopics.contains(e)
                                      ? const WidgetStatePropertyAll(
                                          AppPalette.gradient1)
                                      : null,
                                  side: _selectedTopics.contains(e)
                                      ? null
                                      : const BorderSide(
                                          color: AppPalette.borderColor,
                                        ),
                                ),
                              )))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  BlogEditor(
                    controller: _titleController,
                    hintText: "Title",
                  ),
                  const SizedBox(height: 10),
                  BlogEditor(
                    controller: _contentController,
                    hintText: "Content",
                  )
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
