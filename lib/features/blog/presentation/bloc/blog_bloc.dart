import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/blog/domain/entities/blog.dart';
import 'package:oshmobile/features/blog/domain/usecases/get_all_blogs.dart';
import 'package:oshmobile/features/blog/domain/usecases/upload_blog.dart';

part 'blog_event.dart';
part 'blog_state.dart';

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  final UploadBlog _uploadBlog;
  final GetAllBlogs _getAllBlogs;

  BlogBloc({
    required UploadBlog uploadBlog,
    required GetAllBlogs getAllBlogs,
  })  : _uploadBlog = uploadBlog,
        _getAllBlogs = getAllBlogs,
        super(BlogInitial()) {
    on<BlogEvent>(_onBlogLoading);
    on<BlogUpload>(_onBlogUpload);
    on<BlogFetchAllBlogs>(_onBlogFetchAllBlogs);
  }

  Future<void> _onBlogUpload(BlogUpload event, Emitter<BlogState> emit) async {
    final result = await _uploadBlog(
      UploadBlogParams(
        posterId: event.posterId,
        title: event.title,
        content: event.content,
        image: event.image,
        topics: event.topics,
      ),
    );
    result.fold(
      (l) => emit(BlogFailure(error: l.message ?? "")),
      (r) => emit(BlogUploadSuccess()),
    );
  }

  Future<void> _onBlogFetchAllBlogs(
      BlogFetchAllBlogs event, Emitter<BlogState> emit) async {
    final result = await _getAllBlogs(NoParams());
    result.fold(
      (l) => emit(BlogFailure(error: l.message ?? "")),
      (r) => emit(BlogFetchSuccess(blogs: r)),
    );
  }

  void _onBlogLoading(BlogEvent event, Emitter<BlogState> emit) =>
      emit(const BlogLoading());
}
