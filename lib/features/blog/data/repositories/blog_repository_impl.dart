import 'dart:io';

import 'package:fpdart/src/either.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/network/connection_checker.dart';
import 'package:oshmobile/features/blog/data/datasources/blog_local_datasource.dart';
import 'package:oshmobile/features/blog/data/datasources/blog_remote_datasource.dart';
import 'package:oshmobile/features/blog/data/models/blog_model.dart';
import 'package:oshmobile/features/blog/domain/entities/blog.dart';
import 'package:oshmobile/features/blog/domain/repositories/blog_repository.dart';
import 'package:uuid/uuid.dart';

class BlogRepositoryImpl implements BlogRepository {
  final BlogRemoteDatasource blogRemoteDatasource;
  final BlogLocalDataSource blogLocalDataSource;
  final InternetConnectionChecker connectionChecker;

  BlogRepositoryImpl({
    required this.blogRemoteDatasource,
    required this.blogLocalDataSource,
    required this.connectionChecker,
  });

  @override
  Future<Either<Failure, Blog>> uploadBlog({
    required File image,
    required String title,
    required String content,
    required String posterId,
    required List<String> topics,
  }) async {
    try {
      if (!await (connectionChecker.isConnected)) {
        return left(Failure("No internet connection"));
      }

      BlogModel model = BlogModel(
        id: const Uuid().v1(),
        posterId: posterId,
        title: title,
        content: content,
        imageUrl: "",
        topics: topics,
        updatedAt: DateTime.now(),
      );
      final imageUrl = await blogRemoteDatasource.uploadBlogImage(
        image: image,
        blog: model,
      );
      model = model.copyWith(imageUrl: imageUrl);
      final uploaded = await blogRemoteDatasource.uploadBlog(blog: model);
      return right(uploaded);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Blog>>> getAllBlogs() async {
    try {
      if (!await (connectionChecker.isConnected)) {
        final blogs = blogLocalDataSource.loadBlogs();
        return right(blogs);
      } else {
        final blogs = await blogRemoteDatasource.getAllBlogs();
        blogLocalDataSource.uploadLocalBlogs(blogs: blogs);
        return right(blogs);
      }
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
