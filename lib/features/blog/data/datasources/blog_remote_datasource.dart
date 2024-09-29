import 'dart:io';

import 'package:oshmobile/core/constants/constants.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/features/blog/data/models/blog_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class BlogRemoteDatasource {
  Future<BlogModel> uploadBlog({required BlogModel blog});

  Future<String> uploadBlogImage({
    required File image,
    required BlogModel blog,
  });

  Future<List<BlogModel>> getAllBlogs();
}

class BlogRemoteDatasourceImpl implements BlogRemoteDatasource {
  final SupabaseClient supabaseClient;

  BlogRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<BlogModel> uploadBlog({required BlogModel blog}) async {
    try {
      final blogData = await supabaseClient
          .from(Constants.blogsTable)
          .insert(blog.toJson())
          .select();
      return BlogModel.fromJson(blogData.first);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadBlogImage({
    required File image,
    required BlogModel blog,
  }) async {
    try {
      final path = "${blog.id}/images";
      await supabaseClient.storage
          .from(Constants.blogsImagesStorage)
          .upload(path, image);
      return supabaseClient.storage
          .from(Constants.blogsImagesStorage)
          .getPublicUrl(path);
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<BlogModel>> getAllBlogs() async {
    try {
      final blogs = await supabaseClient
          .from(Constants.blogsTable)
          .select("*, profiles (name)");
      return blogs
          .map(
            (e) => BlogModel.fromJson(e).copyWith(
              posterName: e["profiles"]["name"],
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
